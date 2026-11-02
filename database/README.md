# Funeral Spaces database — account and registration foundation

This folder contains the PostgreSQL schema for account registration and login. The local NestJS API now verifies passwords and issues revocable sessions, but this remains a development implementation: there is no real OTP delivery integration, refresh-token rotation, or production-ready authentication service.

For a visual relationship diagram and plain-language registration/login walkthrough, see [ERD.md](ERD.md).

## What the schema stores

The migration is under the `funeral_spaces` schema and separates data by purpose:

- `app_user` stores account lifecycle/status, not profile details or credentials.
- `user_profile` stores names and an optional PNG/JPEG/WebP avatar (maximum 512 KiB); `user_address` stores street address and locality (province is optional because the current signup form does not ask for it separately); `user_contact` stores normalized email/phone values and their verification state.
- `auth_login_identifier` stores a unique username separately from the password record. Email login resolves through the user's verified `user_contact` row, so username and email cannot be accidentally conflated.
- `auth_credential` stores only the password hash and login-security counters. It must contain a strong, encoded Argon2id (or reviewed provider-compatible) hash—never a plaintext or reversibly encrypted password.
- `space_type`, `registration_form_version`, and `registration_question` define the selected Space category and its versioned extra questions.
- `society`, `space`, and `society_onboarding_batch` represent a society, its actual Society Space, and an idempotent onboarding/import batch.
- `society_member`, `covered_life`, `society_office_role`, and `society_office_assignment` hold organization records. Imported members are not platform accounts; `linked_app_user_id` is null unless a separately verified workflow or local synthetic test fixture links it.
- `space_membership` grants an account active access to a specific Space. It is separate from public discovery and from a roster link; the API requires a live session and an active membership before listing a Space as accessible.
- `society_fee_schedule` stores society-specific, effective-dated amounts as fixed-precision ZAR values. A fee schedule is a policy record, not a payment or contribution ledger.
- `registration_submission` stores the selected Space type, chosen contact to verify, form version, and registration state. It does **not** create a Space membership.
- `registration_answer` stores each response as a separate row linked to its exact question and form version.
- `verification_challenge` stores a keyed hash of an OTP and delivery/expiry/attempt metadata, not the OTP itself. It supports both post-registration contact verification and password-reset verification.
- `auth_session` stores only a hash of the opaque 12-hour session token so sessions can be revoked without storing the bearer secret. The column is currently named `refresh_token_hash`; the local API does not yet implement a refresh/rotation flow.
- `auth_event` stores a limited audit trail without passwords, codes, tokens, or unnecessary personal data.

The initial versioned form prompts mirror the current UI examples for Society, Parlour, Family, and Supplier Spaces. They are product placeholders; update the form version and prompts after confirming the actual questions. Selecting a Space type does not itself grant membership or private access.

The society-onboarding migration adds actual Space and society records, an idempotent batch record, society roster/covered-life/governance data, and effective-dated fees. Public Space discovery is separate from these private records and returns only explicitly discoverable Space profile fields.

## Registration and authentication sequence

1. The API validates the form and normalizes email/phone values (email normalization and phone-number E.164 policy must be agreed and consistently applied).
2. In one database transaction, create the pending `app_user`, `user_profile`, address, contacts, `auth_credential`, `registration_submission`, and required `registration_answer` rows. The password is hashed in the trusted API/authentication service before insertion.
3. Commit the account and registration first. Only then request code delivery from the email/SMS provider. Create/update the `verification_challenge` delivery state only through the backend. A queued/failed delivery has no `sent_at` or `expires_at`; after the provider confirms delivery, set `delivery_status = 'sent'`, `sent_at`, and `expires_at`.
4. Verify the submitted code through the backend using a constant-time comparison of a keyed hash; enforce expiry and attempt limits. In a transaction mark the selected contact verified, the registration verified/completed, and the account active. Never accept a code based only on client-side validation.
5. Login accepts a username or verified email plus password. The NestJS API resolves the identifier, verifies the Argon2id hash, rejects accounts that are not active, applies a per-process request throttle and credential lockout, and issues a 12-hour opaque session token. Store only its SHA-256 hash in `auth_session`; Flutter currently keeps the raw token in memory and sends it only when signing out.
6. For password recovery, send a purpose-bound code only to an already verified contact. Generic responses and rate limits must avoid revealing whether an account/contact exists. On a successful reset, update the password hash and revoke existing sessions according to the final recovery policy.

Database constraints enforce relationships and uniqueness; they do not replace API authorization, password verification, OTP checks, or transaction rules. Application DB credentials should be least-privilege and secrets must stay outside the repository. The Flutter client must never connect directly to PostgreSQL.

## Apply locally

Requires PostgreSQL 13+ (for built-in `gen_random_uuid()`), and a local development database. Migrations are one-time and transactional; check the migration history before applying them again:

```sh
createdb funeral_spaces_dev
psql "postgresql://localhost/funeral_spaces_dev" -v ON_ERROR_STOP=1 -f database/migrations/001_auth_registration.sql
psql "postgresql://localhost/funeral_spaces_dev" -v ON_ERROR_STOP=1 -f database/migrations/002_society_onboarding.sql
psql "postgresql://localhost/funeral_spaces_dev" -v ON_ERROR_STOP=1 -f database/migrations/003_space_membership.sql
psql "postgresql://localhost/funeral_spaces_dev" -v ON_ERROR_STOP=1 -f database/migrations/004_society_transparency.sql
psql "postgresql://localhost/funeral_spaces_dev" -v ON_ERROR_STOP=1 -f database/migrations/005_user_profile_avatar.sql
psql "postgresql://localhost/funeral_spaces_dev" -v ON_ERROR_STOP=1 -f database/seeds/001_stronger_together_society.sql
# Optional: requires an existing active testperson / test@email.com account; does not create or reset its password.
psql "postgresql://localhost/funeral_spaces_dev" -v ON_ERROR_STOP=1 -f database/seeds/002_testperson_active_society.sql
psql "postgresql://localhost/funeral_spaces_dev" -c 'SELECT version, description, applied_at FROM funeral_spaces.schema_migration ORDER BY version;'
```

Run these commands from the repository root in order. Check `funeral_spaces.schema_migration` before applying an already-applied migration. The main demo seed is idempotent and creates Stronger Together Society with 25 active members, 10 deactivated members, 250 active covered lives, six active office assignments, a discoverable Society Space, and a society-specific R250.00 monthly / R1,000.00 joining fee schedule. The separate development-only `002_testperson_active_society.sql` seed links the existing active `testperson` / `test@email.com` account to member `STS-036` and grants it an active Society Space membership. It does not create or reset an app account or password. Both seeds refuse to run unless the current database is named `funeral_spaces_dev`; use synthetic data only in development and tests. Replace the local connection URL for your own PostgreSQL user/database. Do not put production credentials in shell history or project files.

## Not implemented yet

- Password recovery service and session refresh/rotation.
- Production-grade distributed rate limiting, monitoring, and authentication/security review.
- Email/SMS provider, OTP generation/key management/delivery, expiry, retry policy, and delivery-failure handling.
- CSV upload/review UI, authority verification, production member-account linking, invitations/join requests and approval workflows, and role-based Space permissions. The test account membership is a local synthetic fixture only.
- Contribution/payment ledger, reconciliation, and fee collection. The fee schedule only stores approved amounts and effective dates.
- Automated migration runner, test database setup, production deployment, backups, retention, and privacy/legal review.
