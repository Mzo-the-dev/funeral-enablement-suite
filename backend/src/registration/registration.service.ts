import {
  BadRequestException,
  ConflictException,
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { createHmac, randomInt, randomUUID, timingSafeEqual } from 'node:crypto';
import * as argon2 from 'argon2';
import { PoolClient } from 'pg';

import { DatabaseService } from '../database/database.service';
import { RegisterDto } from './dto/register.dto';
import { VerifyRegistrationDto } from './dto/verify-registration.dto';

interface QuestionRow {
  form_version_id: string;
  question_id: string;
  question_key: string;
  is_required: boolean;
}

interface ChallengeRow {
  challenge_id: string;
  user_id: string;
  contact_id: string;
  code_hash: string;
  delivery_status: string;
  expires_at: Date;
  attempt_count: number;
  max_attempts: number;
  consumed_at: Date | null;
  invalidated_at: Date | null;
}

@Injectable()
export class RegistrationService {
  constructor(private readonly database: DatabaseService) {}

  async register(input: RegisterDto): Promise<Record<string, unknown>> {
    this.requireDevelopmentOtpSink();
    const email = input.email.trim().toLowerCase();
    const phone = normalizeSouthAfricanPhone(input.phone);
    const username = input.username.trim().toLowerCase();
    const answers = validateAnswers(input.answers);
    const passwordHash = await argon2.hash(input.password, { type: argon2.argon2id });
    const code = randomInt(0, 1_000_000).toString().padStart(6, '0');
    const challengeId = randomUUID();
    const pepper = this.otpPepper();

    try {
      const created = await this.database.transaction(async (client) => {
        const type = await client.query<{ space_type_id: number }>(
          `SELECT space_type_id
             FROM funeral_spaces.space_type
            WHERE code = $1 AND is_enabled = true`,
          [input.spaceCode],
        );
        if (type.rowCount !== 1) throw new BadRequestException('That Space type is not available.');
        const spaceTypeId = type.rows[0].space_type_id;

        const form = await client.query<{ form_version_id: string }>(
          `SELECT form_version_id
             FROM funeral_spaces.registration_form_version
            WHERE space_type_id = $1 AND is_active = true`,
          [spaceTypeId],
        );
        if (form.rowCount !== 1) throw new ServiceUnavailableException('The registration form is not configured.');
        const formVersionId = form.rows[0].form_version_id;

        const questionResult = await client.query<QuestionRow>(
          `SELECT question_id, question_key, form_version_id, is_required
             FROM funeral_spaces.registration_question
            WHERE form_version_id = $1
            ORDER BY display_order`,
          [formVersionId],
        );
        assertAnswersMatchForm(questionResult.rows, answers);

        const user = await client.query<{ user_id: string }>(
          `INSERT INTO funeral_spaces.app_user (status)
           VALUES ('pending_verification')
           RETURNING user_id`,
        );
        const userId = user.rows[0].user_id;

        await client.query(
          `INSERT INTO funeral_spaces.user_profile (user_id, given_name, surname, preferred_name)
           VALUES ($1, $2, $3, $4)`,
          [userId, input.givenName.trim(), input.surname.trim(), input.preferredName.trim()],
        );
        await client.query(
          `INSERT INTO funeral_spaces.user_address (user_id, address_line_1, locality, country_code)
           VALUES ($1, $2, $3, 'ZA')`,
          [userId, input.address.trim(), input.location.trim()],
        );

        const contacts = await client.query<{ contact_id: string; contact_type: string }>(
          `INSERT INTO funeral_spaces.user_contact
             (user_id, contact_type, contact_value, normalized_value, is_primary)
           VALUES
             ($1, 'email', $2, $3, $4),
             ($1, 'phone', $5, $6, $7)
           RETURNING contact_id, contact_type`,
          [
            userId,
            input.email.trim(),
            email,
            input.verificationChannel === 'email',
            input.phone.trim(),
            phone,
            input.verificationChannel === 'sms',
          ],
        );
        const contactId = contacts.rows.find((row) => row.contact_type === (input.verificationChannel === 'email' ? 'email' : 'phone'))?.contact_id;
        if (!contactId) throw new ServiceUnavailableException('Could not create the verification contact.');

        await client.query(
          `INSERT INTO funeral_spaces.auth_login_identifier
             (user_id, identifier_type, identifier_value, normalized_value)
           VALUES ($1, 'username', $2, $3)`,
          [userId, input.username.trim(), username],
        );
        await client.query(
          `INSERT INTO funeral_spaces.auth_credential (user_id, password_hash)
           VALUES ($1, $2)`,
          [userId, passwordHash],
        );

        const registration = await client.query<{ registration_id: string }>(
          `INSERT INTO funeral_spaces.registration_submission
             (user_id, space_type_id, form_version_id, verification_contact_id)
           VALUES ($1, $2, $3, $4)
           RETURNING registration_id`,
          [userId, spaceTypeId, formVersionId, contactId],
        );
        const registrationId = registration.rows[0].registration_id;

        for (const question of questionResult.rows) {
          const answer = answers[question.question_key];
          if (answer !== undefined) {
            await client.query(
              `INSERT INTO funeral_spaces.registration_answer
                 (registration_id, form_version_id, question_id, answer_text)
               VALUES ($1, $2, $3, $4)`,
              [registrationId, formVersionId, question.question_id, answer],
            );
          }
        }

        await client.query(
          `INSERT INTO funeral_spaces.verification_challenge
             (challenge_id, user_id, registration_id, contact_id, channel, purpose,
              delivery_status, code_hash, sent_at, expires_at)
           VALUES ($1, $2, $3, $4, $5, 'registration_contact', 'sent', $6, now(), now() + interval '10 minutes')`,
          [
            challengeId,
            userId,
            registrationId,
            contactId,
            input.verificationChannel,
            hashOtp(pepper, challengeId, code),
          ],
        );

        await client.query(
          `INSERT INTO funeral_spaces.auth_event (user_id, event_type)
           VALUES ($1, 'registration_created')`,
          [userId],
        );

        return { registrationId, contact: input.verificationChannel === 'email' ? email : phone };
      });

      const destination = input.verificationChannel === 'email'
        ? maskEmail(created.contact)
        : maskPhone(created.contact);
      return {
        registrationId: created.registrationId,
        status: 'pending_verification',
        channel: input.verificationChannel,
        destination,
        ...(process.env.NODE_ENV !== 'production' && process.env.DEV_RETURN_OTP === 'true'
          ? { otpForDevelopment: code }
          : {}),
      };
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw new ConflictException('That username, email address, or phone number is already registered.');
      }
      throw error;
    }
  }

  async verify(input: VerifyRegistrationDto): Promise<{ status: string; message: string }> {
    const pepper = this.otpPepper();
    const verified = await this.database.transaction(async (client) => {
      const result = await client.query<ChallengeRow>(
        `SELECT challenge_id, user_id, contact_id, code_hash, delivery_status,
                expires_at, attempt_count, max_attempts, consumed_at, invalidated_at
           FROM funeral_spaces.verification_challenge
          WHERE registration_id = $1 AND purpose = 'registration_contact'
          FOR UPDATE`,
        [input.registrationId],
      );
      const challenge = result.rows[0];
      if (!challenge || challenge.delivery_status !== 'sent' || challenge.consumed_at || challenge.invalidated_at) {
        return false;
      }

      if (new Date(challenge.expires_at).getTime() <= Date.now() || challenge.attempt_count >= challenge.max_attempts) {
        await client.query(
          `UPDATE funeral_spaces.verification_challenge SET invalidated_at = now() WHERE challenge_id = $1`,
          [challenge.challenge_id],
        );
        return false;
      }

      const submittedHash = hashOtp(pepper, challenge.challenge_id, input.code);
      if (!safeHashEquals(challenge.code_hash, submittedHash)) {
        await client.query(
          `UPDATE funeral_spaces.verification_challenge
              SET attempt_count = attempt_count + 1,
                  invalidated_at = CASE WHEN attempt_count + 1 >= max_attempts THEN now() ELSE NULL END
            WHERE challenge_id = $1`,
          [challenge.challenge_id],
        );
        await client.query(
          `INSERT INTO funeral_spaces.auth_event (user_id, event_type)
           VALUES ($1, 'contact_verification_failed')`,
          [challenge.user_id],
        );
        return false;
      }

      await client.query(
        `UPDATE funeral_spaces.user_contact
            SET is_verified = true, verified_at = now(), updated_at = now()
          WHERE contact_id = $1 AND user_id = $2`,
        [challenge.contact_id, challenge.user_id],
      );
      await client.query(
        `UPDATE funeral_spaces.registration_submission
            SET status = 'verified', verified_at = now(), completed_at = now()
          WHERE registration_id = $1 AND user_id = $2 AND status = 'pending_verification'`,
        [input.registrationId, challenge.user_id],
      );
      await client.query(
        `UPDATE funeral_spaces.app_user
            SET status = 'active', updated_at = now()
          WHERE user_id = $1 AND status = 'pending_verification'`,
        [challenge.user_id],
      );
      await client.query(
        `UPDATE funeral_spaces.verification_challenge
            SET consumed_at = now() WHERE challenge_id = $1`,
        [challenge.challenge_id],
      );
      await client.query(
        `INSERT INTO funeral_spaces.auth_event (user_id, event_type)
         VALUES ($1, 'contact_verification_succeeded')`,
        [challenge.user_id],
      );
      return true;
    });

    if (!verified) throw new UnauthorizedException('The verification code is invalid, expired, or already used.');
    return { status: 'active', message: 'Contact verified. Your account is active.' };
  }

  private requireDevelopmentOtpSink(): void {
    if (process.env.NODE_ENV === 'production' || process.env.DEV_RETURN_OTP !== 'true') {
      throw new ServiceUnavailableException(
        'OTP delivery is not configured. Registration is disabled until an email/SMS delivery provider is connected.',
      );
    }
  }

  private otpPepper(): string {
    const pepper = process.env.OTP_PEPPER;
    if (!pepper || pepper.length < 32 || pepper.startsWith('replace-with-')) {
      throw new ServiceUnavailableException('Configure a random OTP_PEPPER of at least 32 characters in backend/.env.');
    }
    return pepper;
  }
}

function validateAnswers(input: Record<string, unknown>): Record<string, string> {
  const answers: Record<string, string> = {};
  for (const [key, value] of Object.entries(input)) {
    if (!/^[a-z][a-z0-9_]{0,79}$/.test(key) || typeof value !== 'string') {
      throw new BadRequestException('Each Space question answer must be a named text value.');
    }
    const answer = value.trim();
    if (answer.length === 0 || answer.length > 1000) {
      throw new BadRequestException('Space question answers must contain between 1 and 1000 characters.');
    }
    answers[key] = answer;
  }
  return answers;
}

function assertAnswersMatchForm(questions: QuestionRow[], answers: Record<string, string>): void {
  const allowed = new Set(questions.map((question) => question.question_key));
  const unknown = Object.keys(answers).filter((key) => !allowed.has(key));
  if (unknown.length > 0) throw new BadRequestException('One or more answers do not belong to the selected Space form.');
  const missing = questions.find((question) => question.is_required && !answers[question.question_key]);
  if (missing) throw new BadRequestException(`Answer the required question: ${missing.question_key}.`);
}

function normalizeSouthAfricanPhone(value: string): string {
  const trimmed = value.trim();
  const digits = trimmed.replace(/\D/g, '');
  if (trimmed.startsWith('+') && digits.startsWith('27') && digits.length === 11) return `+${digits}`;
  if (digits.startsWith('0') && digits.length === 10) return `+27${digits.slice(1)}`;
  if (digits.startsWith('27') && digits.length === 11) return `+${digits}`;
  throw new BadRequestException('Enter a South African phone number, for example 082 123 4567 or +27 82 123 4567.');
}

function hashOtp(pepper: string, challengeId: string, code: string): string {
  return createHmac('sha256', pepper).update(`${challengeId}:${code}`).digest('hex');
}

function safeHashEquals(expected: string, actual: string): boolean {
  const expectedBuffer = Buffer.from(expected, 'hex');
  const actualBuffer = Buffer.from(actual, 'hex');
  return expectedBuffer.length === actualBuffer.length && timingSafeEqual(expectedBuffer, actualBuffer);
}

function maskEmail(email: string): string {
  const [name, domain] = email.split('@');
  return `${name.slice(0, 1)}•••@${domain}`;
}

function maskPhone(phone: string): string {
  return `${phone.slice(0, 3)}•••${phone.slice(-2)}`;
}

function isUniqueViolation(error: unknown): boolean {
  return typeof error === 'object' && error !== null && 'code' in error && error.code === '23505';
}
