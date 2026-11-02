import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { createHash, createHmac, randomBytes, randomInt, randomUUID, timingSafeEqual } from 'node:crypto';
import * as argon2 from 'argon2';
import { PoolClient } from 'pg';

import { DatabaseService } from '../database/database.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { VerifyRegistrationDto } from './dto/verify-registration.dto';

interface SocietyAccessRow {
  society_id: string;
  user_id: string;
  space_id: string;
  society_name: string;
  space_name: string;
  member_id: string | null;
  member_number: string | null;
  member_given_name: string | null;
  role_code: string;
  office_roles: string[];
  can_approve_funeral_cases: boolean;
  can_approve_memberships: boolean;
}

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

interface LoginRow {
  user_id: string;
  status: string;
  password_hash: string;
  failed_login_count: number;
  locked_until: Date | null;
}

interface SpaceTypeRow {
  code: string;
  display_name: string;
}

interface DiscoverableSpaceRow {
  space_id: string;
  display_name: string;
  space_code: string;
  public_description: string | null;
}

interface ActiveSpaceRow {
  space_id: string;
  display_name: string;
  society_name: string;
  space_code: string;
  role_code: string;
  member_number: string | null;
  joined_at: string | null;
  covered_life_count: number;
}

interface UserProfileRow {
  given_name: string;
  surname: string;
  preferred_name: string;
  avatar_mime_type: string | null;
  avatar_base64: string | null;
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

  async login(input: LoginDto): Promise<{ sessionToken: string; expiresAt: Date }> {
    const identity = input.identity.trim().toLowerCase();
    const result = await this.database.transaction(async (client) => {
      const accountResult = await client.query<LoginRow>(
        `WITH candidate AS (
           SELECT user_id, 1 AS priority
             FROM funeral_spaces.auth_login_identifier
            WHERE normalized_value = $1
           UNION ALL
           SELECT contact.user_id, 2 AS priority
             FROM funeral_spaces.user_contact contact
            WHERE contact.contact_type = 'email'
              AND contact.normalized_value = $1
              AND contact.is_verified = true
              AND NOT EXISTS (
                SELECT 1 FROM funeral_spaces.auth_login_identifier
                 WHERE normalized_value = $1
              )
         )
         SELECT account.user_id, account.status, credential.password_hash,
                credential.failed_login_count, credential.locked_until
           FROM candidate
           JOIN funeral_spaces.app_user account ON account.user_id = candidate.user_id
           JOIN funeral_spaces.auth_credential credential ON credential.user_id = account.user_id
          ORDER BY candidate.priority
          LIMIT 1
          FOR UPDATE OF credential`,
        [identity],
      );
      const account = accountResult.rows[0];

      if (!account) {
        await client.query(
          `INSERT INTO funeral_spaces.auth_event (event_type) VALUES ('login_failed')`,
        );
        return null;
      }

      if (account.locked_until && new Date(account.locked_until).getTime() > Date.now()) {
        await client.query(
          `INSERT INTO funeral_spaces.auth_event (user_id, event_type)
           VALUES ($1, 'login_failed')`,
          [account.user_id],
        );
        return null;
      }

      const passwordMatches = await argon2.verify(account.password_hash, input.password);
      if (!passwordMatches || account.status !== 'active') {
        if (!passwordMatches) {
          await client.query(
            `UPDATE funeral_spaces.auth_credential
                SET failed_login_count = failed_login_count + 1,
                    locked_until = CASE
                      WHEN failed_login_count + 1 >= 5 THEN now() + interval '15 minutes'
                      ELSE locked_until
                    END,
                    updated_at = now()
              WHERE user_id = $1`,
            [account.user_id],
          );
        }
        await client.query(
          `INSERT INTO funeral_spaces.auth_event (user_id, event_type)
           VALUES ($1, 'login_failed')`,
          [account.user_id],
        );
        return null;
      }

      const sessionToken = randomBytes(32).toString('base64url');
      const session = await client.query<{ expires_at: Date }>(
        `INSERT INTO funeral_spaces.auth_session (user_id, refresh_token_hash, expires_at)
         VALUES ($1, $2, now() + interval '12 hours')
         RETURNING expires_at`,
        [account.user_id, hashSessionToken(sessionToken)],
      );
      await client.query(
        `UPDATE funeral_spaces.auth_credential
            SET failed_login_count = 0, locked_until = NULL, updated_at = now()
          WHERE user_id = $1`,
        [account.user_id],
      );
      await client.query(
        `INSERT INTO funeral_spaces.auth_event (user_id, event_type)
         VALUES ($1, 'login_succeeded')`,
        [account.user_id],
      );

      return { sessionToken, expiresAt: session.rows[0].expires_at };
    });

    if (!result) throw new UnauthorizedException('Invalid username/email or password.');
    return result;
  }

  async logout(sessionToken: string): Promise<{ status: string }> {
    await this.database.transaction(async (client) => {
      const session = await client.query<{ user_id: string }>(
        `UPDATE funeral_spaces.auth_session
            SET revoked_at = now(), last_seen_at = now()
          WHERE refresh_token_hash = $1 AND revoked_at IS NULL
          RETURNING user_id`,
        [hashSessionToken(sessionToken)],
      );
      if (session.rowCount === 1) {
        await client.query(
          `INSERT INTO funeral_spaces.auth_event (user_id, event_type)
           VALUES ($1, 'session_revoked')`,
          [session.rows[0].user_id],
        );
      }
    });
    return { status: 'signed_out' };
  }

  async getMyProfile(sessionToken: string | undefined): Promise<Record<string, unknown>> {
    if (!sessionToken?.trim()) throw new UnauthorizedException('A valid session is required.');
    const result = await this.database.query<UserProfileRow>(
      `SELECT profile.given_name, profile.surname, profile.preferred_name,
              profile.avatar_mime_type, encode(profile.avatar_image, 'base64') AS avatar_base64
         FROM funeral_spaces.auth_session session
         JOIN funeral_spaces.app_user account ON account.user_id = session.user_id
         JOIN funeral_spaces.user_profile profile ON profile.user_id = account.user_id
        WHERE session.refresh_token_hash = $1 AND session.revoked_at IS NULL
          AND session.expires_at > now() AND account.status = 'active'`,
      [hashSessionToken(sessionToken)],
    );
    if (!result.rows[0]) throw new UnauthorizedException('A valid session is required.');
    return { ...result.rows[0] };
  }

  async updateMyProfile(
    sessionToken: string | undefined,
    input: UpdateProfileDto,
  ): Promise<Record<string, unknown>> {
    if (!sessionToken?.trim()) throw new UnauthorizedException('A valid session is required.');
    const preferredName = input.preferredName?.trim();
    if (input.preferredName !== undefined && !preferredName) {
      throw new BadRequestException('Enter a preferred name.');
    }
    if (preferredName && preferredName.length > 120) {
      throw new BadRequestException('Preferred name must be 120 characters or fewer.');
    }
    if (input.clearAvatar && (input.avatarBase64 || input.avatarMimeType)) {
      throw new BadRequestException('Choose an image or remove the current image, not both.');
    }
    if (Boolean(input.avatarBase64) !== Boolean(input.avatarMimeType)) {
      throw new BadRequestException('Both avatar image data and image type are required.');
    }
    if (!preferredName && !input.avatarBase64 && !input.clearAvatar) {
      throw new BadRequestException('There are no profile changes to save.');
    }

    if (input.avatarBase64 && input.avatarMimeType) {
      this.validateAvatar(input.avatarBase64, input.avatarMimeType);
    }

    const result = await this.database.query<UserProfileRow>(
      `UPDATE funeral_spaces.user_profile profile
          SET preferred_name = coalesce($2, profile.preferred_name),
              avatar_image = CASE
                WHEN $5::boolean THEN NULL
                WHEN $3::text IS NOT NULL THEN decode($3, 'base64')
                ELSE profile.avatar_image
              END,
              avatar_mime_type = CASE
                WHEN $5::boolean THEN NULL
                WHEN $3::text IS NOT NULL THEN $4
                ELSE profile.avatar_mime_type
              END,
              updated_at = now()
         FROM funeral_spaces.auth_session session
         JOIN funeral_spaces.app_user account ON account.user_id = session.user_id
        WHERE profile.user_id = account.user_id
          AND session.refresh_token_hash = $1 AND session.revoked_at IS NULL
          AND session.expires_at > now() AND account.status = 'active'
      RETURNING profile.given_name, profile.surname, profile.preferred_name,
                profile.avatar_mime_type, encode(profile.avatar_image, 'base64') AS avatar_base64`,
      [
        hashSessionToken(sessionToken),
        preferredName || null,
        input.avatarBase64 || null,
        input.avatarMimeType || null,
        input.clearAvatar ?? false,
      ],
    );
    if (!result.rows[0]) throw new UnauthorizedException('A valid session is required.');
    return { ...result.rows[0] };
  }

  private validateAvatar(base64: string, mimeType: string): void {
    if (!['image/png', 'image/jpeg', 'image/webp'].includes(mimeType)) {
      throw new BadRequestException('Use a PNG, JPEG, or WebP profile image.');
    }
    if (!/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(base64)) {
      throw new BadRequestException('The selected profile image is invalid.');
    }
    const bytes = Buffer.from(base64, 'base64');
    if (bytes.length === 0 || bytes.length > 512 * 1024 || bytes.toString('base64') !== base64) {
      throw new BadRequestException('Profile images must be 512 KB or smaller.');
    }
    const isPng = mimeType === 'image/png' && bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]));
    const isJpeg = mimeType === 'image/jpeg' && bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255;
    const isWebp = mimeType === 'image/webp'
      && bytes.toString('ascii', 0, 4) === 'RIFF'
      && bytes.toString('ascii', 8, 12) === 'WEBP';
    if (!isPng && !isJpeg && !isWebp) {
      throw new BadRequestException('The selected file is not a supported image.');
    }
  }

  async listSpaceTypes(): Promise<SpaceTypeRow[]> {
    const result = await this.database.query<SpaceTypeRow>(
      `SELECT code, display_name
         FROM funeral_spaces.space_type
        WHERE is_enabled = true
        ORDER BY space_type_id`,
    );
    return result.rows;
  }

  async listDiscoverableSpaces(): Promise<DiscoverableSpaceRow[]> {
    const result = await this.database.query<DiscoverableSpaceRow>(
      `SELECT space.space_id, space.display_name, type.code AS space_code,
              space.public_description
         FROM funeral_spaces.space space
         JOIN funeral_spaces.space_type type USING (space_type_id)
        WHERE space.status = 'active' AND space.is_discoverable = true
        ORDER BY space.display_name`,
    );
    return result.rows;
  }

  async listMySpaces(sessionToken: string | undefined): Promise<ActiveSpaceRow[]> {
    if (!sessionToken?.trim()) {
      throw new UnauthorizedException('A valid session is required.');
    }

    const result = await this.database.query<ActiveSpaceRow>(
      `SELECT space.space_id, space.display_name, society.display_name AS society_name,
              type.code AS space_code, membership.role_code,
              member.member_number, member.joined_at::text AS joined_at,
              CASE WHEN member.member_id IS NULL THEN 0
             ELSE (SELECT count(*)::integer
               FROM funeral_spaces.covered_life life
              WHERE life.member_id = member.member_id
                AND life.status = 'active')
              END AS covered_life_count
         FROM funeral_spaces.auth_session session
         JOIN funeral_spaces.app_user account ON account.user_id = session.user_id
         JOIN funeral_spaces.space_membership membership ON membership.user_id = account.user_id
         JOIN funeral_spaces.space space
           ON space.space_id = membership.space_id AND space.society_id = membership.society_id
         JOIN funeral_spaces.society society ON society.society_id = membership.society_id
         JOIN funeral_spaces.space_type type USING (space_type_id)
         LEFT JOIN funeral_spaces.society_member member
           ON member.member_id = membership.society_member_id
          AND member.society_id = membership.society_id
        WHERE session.refresh_token_hash = $1
          AND session.revoked_at IS NULL
          AND session.expires_at > now()
          AND account.status = 'active'
          AND membership.status = 'active'
          AND space.status = 'active'
          AND society.status = 'active'
          AND (membership.society_member_id IS NULL
               OR (member.status = 'active' AND member.linked_app_user_id = account.user_id))
        ORDER BY space.display_name`,
      [hashSessionToken(sessionToken)],
    );
    return result.rows;
  }

  async getSocietyDashboard(spaceId: string, sessionToken: string | undefined): Promise<Record<string, unknown>> {
    const access = await this.findSocietyAccess(spaceId, sessionToken);

    const [summary, members, contributions, cases, membershipRequests] = await Promise.all([
      this.database.query(
        `WITH current_period AS (
           SELECT max(period_start) AS period_start
             FROM funeral_spaces.society_contribution
            WHERE society_id = $1
         ), period_totals AS (
           SELECT coalesce(sum(contribution.amount_due), 0)::float8 AS total_due,
                  coalesce(sum(contribution.amount_paid), 0)::float8 AS total_collected,
                  coalesce(sum(contribution.amount_due - contribution.amount_paid)
                    FILTER (WHERE contribution.status <> 'waived'), 0)::float8 AS outstanding
             FROM funeral_spaces.society_contribution contribution
             JOIN current_period ON contribution.period_start = current_period.period_start
            WHERE contribution.society_id = $1
         )
         SELECT current_period.period_start::text AS period_start,
                (SELECT count(*)::integer FROM funeral_spaces.society_member
                  WHERE society_id = $1 AND status = 'active') AS active_members,
                (SELECT count(*)::integer FROM funeral_spaces.society_member
                  WHERE society_id = $1 AND status = 'deactivated') AS deactivated_members,
                (SELECT count(*)::integer
                   FROM funeral_spaces.covered_life life
                   JOIN funeral_spaces.society_member member USING (member_id)
                  WHERE member.society_id = $1 AND member.status = 'active' AND life.status = 'active') AS covered_lives,
                period_totals.total_due, period_totals.total_collected, period_totals.outstanding,
                (SELECT count(DISTINCT member.member_id)::integer
                   FROM funeral_spaces.society_member member
                   JOIN funeral_spaces.society_contribution contribution USING (member_id)
                  WHERE member.society_id = $1 AND member.status = 'active'
                    AND contribution.due_date < current_date
                    AND contribution.status <> 'waived'
                    AND contribution.amount_paid < contribution.amount_due) AS members_in_arrears,
                (SELECT count(*)::integer FROM funeral_spaces.funeral_case
                  WHERE society_id = $1 AND status = 'pending') AS pending_cases,
                (SELECT count(*)::integer FROM funeral_spaces.funeral_case
                  WHERE society_id = $1 AND status = 'approved') AS approved_cases,
                (SELECT monthly_contribution_amount::float8
                   FROM funeral_spaces.society_fee_schedule
                  WHERE society_id = $1 AND effective_to IS NULL) AS monthly_contribution,
                (SELECT joining_fee_amount::float8
                   FROM funeral_spaces.society_fee_schedule
                  WHERE society_id = $1 AND effective_to IS NULL) AS joining_fee
           FROM current_period CROSS JOIN period_totals`,
        [access.society_id],
      ),
      this.database.query(
        `SELECT member.member_id, member.member_number, member.given_name, member.surname,
                member.status::text AS status,
                (SELECT count(*)::integer FROM funeral_spaces.covered_life life
                  WHERE life.member_id = member.member_id AND life.status = 'active') AS covered_lives,
                coalesce((SELECT sum(contribution.amount_due - contribution.amount_paid)::float8
                            FROM funeral_spaces.society_contribution contribution
                           WHERE contribution.member_id = member.member_id
                             AND contribution.due_date < current_date
                             AND contribution.status <> 'waived'), 0)::float8 AS arrears_amount
           FROM funeral_spaces.society_member member
          WHERE member.society_id = $1
          ORDER BY CASE member.status WHEN 'active' THEN 0 ELSE 1 END,
                   member.surname, member.given_name, member.member_number`,
        [access.society_id],
      ),
      access.member_id
        ? this.database.query(
            `SELECT period_start::text AS period_start, due_date::text AS due_date,
                    amount_due::float8 AS amount_due, amount_paid::float8 AS amount_paid,
                    status::text AS status, paid_at::text AS paid_at, receipt_reference
               FROM funeral_spaces.society_contribution
              WHERE society_id = $1 AND member_id = $2
              ORDER BY period_start DESC
              LIMIT 12`,
            [access.society_id, access.member_id],
          )
        : Promise.resolve({ rows: [] }),
      this.database.query(
        `SELECT case_record.funeral_case_id, case_record.case_reference,
                case_record.status::text AS status, case_record.summary,
                case_record.reported_at::text AS reported_at,
                member.member_number, member.given_name, member.surname,
                approver.member_number AS approved_by_member_number
           FROM funeral_spaces.funeral_case case_record
           JOIN funeral_spaces.society_member member ON member.member_id = case_record.member_id
           LEFT JOIN funeral_spaces.society_member approver
             ON approver.member_id = case_record.approved_by_member_id
            AND approver.society_id = case_record.society_id
          WHERE case_record.society_id = $1
          ORDER BY CASE case_record.status WHEN 'pending' THEN 0 ELSE 1 END,
                   case_record.reported_at DESC`,
        [access.society_id],
      ),
      access.can_approve_memberships
        ? this.database.query(
            `SELECT request.membership_request_id, request.requested_member_number,
                    request.requested_at::text AS requested_at,
                    profile.given_name, profile.surname
               FROM funeral_spaces.society_membership_request request
               JOIN funeral_spaces.user_profile profile USING (user_id)
              WHERE request.society_id = $1 AND request.status = 'pending'
              ORDER BY request.requested_at`,
            [access.society_id],
          )
        : Promise.resolve({ rows: [] }),
    ]);

    return {
      society: {
        space_id: access.space_id,
        space_name: access.space_name,
        society_name: access.society_name,
      },
      current_member: {
        member_number: access.member_number,
        given_name: access.member_given_name,
        role_code: access.role_code,
        office_roles: access.office_roles,
      },
      permissions: {
        can_approve_funeral_cases: access.can_approve_funeral_cases,
        can_approve_memberships: access.can_approve_memberships,
      },
      summary: summary.rows[0],
      members: members.rows.map((member) => ({
        ...member,
        is_in_arrears: Number(member.arrears_amount) > 0,
      })),
      my_contributions: contributions.rows,
      funeral_cases: cases.rows,
      membership_requests: membershipRequests.rows,
    };
  }

  async submitSocietyMembershipRequest(
    spaceId: string,
    sessionToken: string | undefined,
    requestedMemberNumber: string,
  ): Promise<{ status: string }> {
    if (!sessionToken?.trim()) throw new UnauthorizedException('A valid session is required.');
    const normalizedMemberNumber = requestedMemberNumber.trim().toUpperCase();
    if (normalizedMemberNumber.length < 1 || normalizedMemberNumber.length > 80) {
      throw new BadRequestException('Enter a valid society member number.');
    }

    const created = await this.database.query(
      `INSERT INTO funeral_spaces.society_membership_request
         (society_id, user_id, requested_member_number)
       SELECT society.society_id, account.user_id, $3
         FROM funeral_spaces.auth_session session
         JOIN funeral_spaces.app_user account ON account.user_id = session.user_id
         JOIN funeral_spaces.space space ON space.space_id = $2
         JOIN funeral_spaces.society society ON society.society_id = space.society_id
        WHERE session.refresh_token_hash = $1 AND session.revoked_at IS NULL
          AND session.expires_at > now() AND account.status = 'active'
          AND space.status = 'active' AND space.is_discoverable = true
          AND society.status = 'active'
          AND NOT EXISTS (
            SELECT 1 FROM funeral_spaces.space_membership membership
             WHERE membership.user_id = account.user_id AND membership.space_id = space.space_id
               AND membership.status = 'active'
          )
       ON CONFLICT (society_id, user_id) WHERE status = 'pending' DO NOTHING
       RETURNING membership_request_id`,
      [hashSessionToken(sessionToken), spaceId, normalizedMemberNumber],
    );
    if (created.rowCount !== 1) {
      throw new ConflictException('A request could not be submitted. You may already have access or a pending request.');
    }
    return { status: 'pending' };
  }

  async approveFuneralCase(
    spaceId: string,
    caseId: string,
    sessionToken: string | undefined,
  ): Promise<{ status: string }> {
    if (!sessionToken?.trim()) throw new UnauthorizedException('A valid session is required.');
    return this.database.transaction(async (client) => {
      const approver = await this.findOfficeApprover(client, spaceId, sessionToken, 'funeral_approver');
      const result = await client.query(
        `UPDATE funeral_spaces.funeral_case
            SET status = 'approved', approved_at = now(),
                approved_by_member_id = $3, approved_by_user_id = $4
          WHERE funeral_case_id = $1 AND society_id = $2 AND status = 'pending'
          RETURNING funeral_case_id`,
        [caseId, approver.society_id, approver.member_id, approver.user_id],
      );
      if (result.rowCount !== 1) throw new ConflictException('This case is no longer pending approval.');
      return { status: 'approved' };
    });
  }

  async approveSocietyMembershipRequest(
    spaceId: string,
    requestId: string,
    sessionToken: string | undefined,
  ): Promise<{ status: string }> {
    if (!sessionToken?.trim()) throw new UnauthorizedException('A valid session is required.');
    return this.database.transaction(async (client) => {
      const chairperson = await this.findOfficeApprover(client, spaceId, sessionToken, 'chairperson');
      const requestResult = await client.query<{
        membership_request_id: string;
        user_id: string;
        requested_member_number: string;
      }>(
        `SELECT membership_request_id, user_id, requested_member_number
           FROM funeral_spaces.society_membership_request
          WHERE membership_request_id = $1 AND society_id = $2 AND status = 'pending'
          FOR UPDATE`,
        [requestId, chairperson.society_id],
      );
      const request = requestResult.rows[0];
      if (!request) throw new ConflictException('This membership request is no longer pending.');

      const memberResult = await client.query<{ member_id: string }>(
        `SELECT member_id
           FROM funeral_spaces.society_member
          WHERE society_id = $1 AND member_number = $2
            AND status = 'active' AND linked_app_user_id IS NULL
          FOR UPDATE`,
        [chairperson.society_id, request.requested_member_number],
      );
      const member = memberResult.rows[0];
      if (!member) throw new ConflictException('The member number could not be matched to an unlinked active society record.');

      await client.query(
        `UPDATE funeral_spaces.society_member
            SET linked_app_user_id = $1, updated_at = now()
          WHERE member_id = $2 AND society_id = $3`,
        [request.user_id, member.member_id, chairperson.society_id],
      );
      await client.query(
        `INSERT INTO funeral_spaces.space_membership
           (user_id, space_id, society_id, society_member_id, role_code,
            status, requested_at, activated_at, granted_by_user_id)
         VALUES ($1, $2, $3, $4, 'member', 'active', now(), now(), $5)`,
        [request.user_id, spaceId, chairperson.society_id, member.member_id, chairperson.user_id],
      );
      await client.query(
        `UPDATE funeral_spaces.society_membership_request
            SET status = 'approved', decided_at = now(), decided_by_user_id = $2,
                society_member_id = $3
          WHERE membership_request_id = $1`,
        [request.membership_request_id, chairperson.user_id, member.member_id],
      );
      return { status: 'approved' };
    });
  }

  private async findSocietyAccess(
    spaceId: string,
    sessionToken: string | undefined,
  ): Promise<SocietyAccessRow> {
    if (!sessionToken?.trim()) throw new UnauthorizedException('A valid session is required.');
    const result = await this.database.query<SocietyAccessRow>(
      `SELECT society.society_id, account.user_id, space.space_id,
              society.display_name AS society_name, space.display_name AS space_name,
              member.member_id, member.member_number, member.given_name AS member_given_name,
              membership.role_code,
              coalesce((SELECT array_agg(assignment.role_code ORDER BY assignment.role_code)
                          FROM funeral_spaces.society_office_assignment assignment
                         WHERE assignment.society_id = society.society_id
                           AND assignment.member_id = member.member_id
                           AND assignment.ended_at IS NULL
                           AND assignment.effective_from <= current_date), ARRAY[]::text[]) AS office_roles,
              EXISTS (
                SELECT 1 FROM funeral_spaces.society_office_assignment assignment
                 WHERE assignment.society_id = society.society_id
                   AND assignment.member_id = member.member_id
                   AND assignment.role_code = 'funeral_approver'
                   AND assignment.ended_at IS NULL
                   AND assignment.effective_from <= current_date
              ) AS can_approve_funeral_cases,
              EXISTS (
                SELECT 1 FROM funeral_spaces.society_office_assignment assignment
                 WHERE assignment.society_id = society.society_id
                   AND assignment.member_id = member.member_id
                   AND assignment.role_code = 'chairperson'
                   AND assignment.ended_at IS NULL
                   AND assignment.effective_from <= current_date
              ) AS can_approve_memberships
         FROM funeral_spaces.auth_session session
         JOIN funeral_spaces.app_user account ON account.user_id = session.user_id
         JOIN funeral_spaces.space_membership membership ON membership.user_id = account.user_id
         JOIN funeral_spaces.space space
           ON space.space_id = membership.space_id AND space.society_id = membership.society_id
         JOIN funeral_spaces.society society ON society.society_id = membership.society_id
         LEFT JOIN funeral_spaces.society_member member
           ON member.member_id = membership.society_member_id
          AND member.society_id = membership.society_id
        WHERE session.refresh_token_hash = $1 AND session.revoked_at IS NULL
          AND session.expires_at > now() AND account.status = 'active'
          AND membership.status = 'active' AND space.space_id = $2
          AND space.status = 'active' AND society.status = 'active'
          AND (membership.society_member_id IS NULL
               OR (member.status = 'active' AND member.linked_app_user_id = account.user_id))`,
      [hashSessionToken(sessionToken), spaceId],
    );
    const access = result.rows[0];
    if (!access) throw new ForbiddenException('Active membership in this Society Space is required.');
    return access;
  }

  private async findOfficeApprover(
    client: PoolClient,
    spaceId: string,
    sessionToken: string,
    requiredRole: 'chairperson' | 'funeral_approver',
  ): Promise<{ society_id: string; user_id: string; member_id: string }> {
    const result = await client.query<{ society_id: string; user_id: string; member_id: string }>(
      `SELECT society.society_id, account.user_id, member.member_id
         FROM funeral_spaces.auth_session session
         JOIN funeral_spaces.app_user account ON account.user_id = session.user_id
         JOIN funeral_spaces.space_membership membership ON membership.user_id = account.user_id
         JOIN funeral_spaces.space space
           ON space.space_id = membership.space_id AND space.society_id = membership.society_id
         JOIN funeral_spaces.society society ON society.society_id = membership.society_id
         JOIN funeral_spaces.society_member member
           ON member.member_id = membership.society_member_id
          AND member.society_id = membership.society_id
          AND member.linked_app_user_id = account.user_id
         JOIN funeral_spaces.society_office_assignment assignment
           ON assignment.society_id = society.society_id
          AND assignment.member_id = member.member_id
          AND assignment.role_code = $3
          AND assignment.ended_at IS NULL
          AND assignment.effective_from <= current_date
        WHERE session.refresh_token_hash = $1 AND session.revoked_at IS NULL
          AND session.expires_at > now() AND account.status = 'active'
          AND membership.status = 'active' AND membership.space_id = $2
          AND space.status = 'active' AND society.status = 'active'
          AND member.status = 'active'
        LIMIT 1`,
      [hashSessionToken(sessionToken), spaceId, requiredRole],
    );
    const approver = result.rows[0];
    if (!approver) throw new ForbiddenException(`Only the assigned ${requiredRole.replace('_', ' ')} can approve this request.`);
    return approver;
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

function hashSessionToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
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
