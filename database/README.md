# Funeral Spaces database — account and registration foundation

This folder contains the first PostgreSQL migration for account registration and login. It is the database layer only: there is not yet a backend API, password-checking service, OTP delivery integration, or session-token issuer. The Flutter screens must not be treated as real authentication.

For a visual relationship diagram and plain-language registration/login walkthrough, see [ERD.md](ERD.md).

## What the schema stores

The migration is under the `funeral_spaces` schema and separates data by purpose:

- `app_user` stores account lifecycle/status, not profile details or credentials.
- `user_profile` stores names; `user_address` stores street address and locality (province is optional because the current signup form does not ask for it separately); `user_contact` stores normalized email/phone values and their verification state.
- `auth_login_identifier` stores a unique username separately from the password record. Email login resolves through the user's verified `user_contact` row, so username and email cannot be accidentally conflated.
- `auth_credential` stores only the password hash and login-security counters. It must contain a strong, encoded Argon2id (or reviewed provider-compatible) hash—never a plaintext or reversibly encrypted password.
- `space_type`, `registration_form_version`, and `registration_question` define the selected Space category and its versioned extra questions.
- `registration_submission` stores the selected Space type, chosen contact to verify, form version, and registration state. It does **not** create a Space membership.
- `registration_answer` stores each response as a separate row linked to its exact question and form version.
- `verification_challenge` stores a keyed hash of an OTP and delivery/expiry/attempt metadata, not the OTP itself. It supports both post-registration contact verification and password-reset verification.
- `auth_session` stores only a hash of the refresh token so sessions can be revoked without storing a bearer secret.
- `auth_event` stores a limited audit trail without passwords, codes, tokens, or unnecessary personal data.

The initial versioned form prompts mirror the current UI examples for Society, Parlour, Family, and Supplier Spaces. They are product placeholders; update the form version and prompts after confirming the actual questions. Selecting a Space type does not itself grant membership or private access.

## Registration and authentication sequence

1. The API validates the form and normalizes email/phone values (email normalization and phone-number E.164 policy must be agreed and consistently applied).
2. In one database transaction, create the pending `app_user`, `user_profile`, address, contacts, `auth_credential`, `registration_submission`, and required `registration_answer` rows. The password is hashed in the trusted API/authentication service before insertion.
3. Commit the account and registration first. Only then request code delivery from the email/SMS provider. Create/update the `verification_challenge` delivery state only through the backend. A queued/failed delivery has no `sent_at` or `expires_at`; after the provider confirms delivery, set `delivery_status = 'sent'`, `sent_at`, and `expires_at`.
4. Verify the submitted code through the backend using a constant-time comparison of a keyed hash; enforce expiry and attempt limits. In a transaction mark the selected contact verified, the registration verified/completed, and the account active. Never accept a code based only on client-side validation.
5. Login accepts a username or email plus password. Resolve the identifier on the server, verify the stored password hash using a maintained authentication library, reject accounts not active, apply rate limiting/lockout controls, and issue opaque session tokens. Store only a cryptographic hash of the refresh token in `auth_session`.
6. For password recovery, send a purpose-bound code only to an already verified contact. Generic responses and rate limits must avoid revealing whether an account/contact exists. On a successful reset, update the password hash and revoke existing sessions according to the final recovery policy.

Database constraints enforce relationships and uniqueness; they do not replace API authorization, password verification, OTP checks, or transaction rules. Application DB credentials should be least-privilege and secrets must stay outside the repository. The Flutter client must never connect directly to PostgreSQL.

## Apply locally

Requires PostgreSQL 13+ (for built-in `gen_random_uuid()`), and a local development database. The migration is one-time and transactional; check the migration history before applying it again:

```sh
createdb funeral_spaces_dev
psql "postgresql://localhost/funeral_spaces_dev" -v ON_ERROR_STOP=1 -f database/migrations/001_auth_registration.sql
psql "postgresql://localhost/funeral_spaces_dev" -c 'SELECT version, description, applied_at FROM funeral_spaces.schema_migration ORDER BY version;'
```

Run these commands from the repository root. Replace the local connection URL for your own PostgreSQL user/database. Do not put production credentials in shell history or project files. Use synthetic data only in development and tests.

## Not implemented yet

- NestJS (or another agreed backend) API and request validation.
- A maintained password-hashing/authentication library, login rate limiting, account recovery service, and session issuance/rotation.
- Email/SMS provider, OTP generation/key management/delivery, expiry, retry policy, and delivery-failure handling.
- Space directory, concrete Space records, membership/invitation/join approval, permissions, and privileged-role onboarding.
- Automated migration runner, test database setup, production deployment, backups, retention, and privacy/legal review.
