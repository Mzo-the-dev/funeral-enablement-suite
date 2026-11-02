# Funeral Spaces account and registration ERD

This document explains the PostgreSQL schema implemented by migrations `001_auth_registration.sql` through `005_user_profile_avatar.sql`. It covers account registration/authentication, society onboarding records, active Space membership, and profile avatars. Contribution, claim, invitation, and join-request workflows remain future work.

## 1. Relationship diagram

```mermaid
erDiagram
    APP_USER {
        uuid user_id PK
        account_status status
        timestamptz created_at
        timestamptz updated_at
        timestamptz deactivated_at
    }

    USER_PROFILE {
        uuid user_id PK, FK
        text given_name
        text surname
        text preferred_name
        bytea avatar_image
        text avatar_mime_type
    }

    USER_ADDRESS {
        uuid address_id PK
        uuid user_id FK
        text address_line_1
        text address_line_2
        text locality
        text province
        text postal_code
        char country_code
        boolean is_primary
    }

    USER_CONTACT {
        uuid contact_id PK
        uuid user_id FK
        contact_type contact_type
        text contact_value
        text normalized_value UK
        boolean is_verified
        timestamptz verified_at
        boolean is_primary
    }

    AUTH_CREDENTIAL {
        uuid user_id PK, FK
        text password_hash
        timestamptz password_changed_at
        int failed_login_count
        timestamptz locked_until
    }

    AUTH_LOGIN_IDENTIFIER {
        uuid identifier_id PK
        uuid user_id FK
        login_identifier_type identifier_type
        text identifier_value
        text normalized_value UK
    }

    SPACE_TYPE {
        smallint space_type_id PK
        text code UK
        text display_name UK
        boolean is_enabled
    }

    REGISTRATION_FORM_VERSION {
        bigint form_version_id PK
        smallint space_type_id FK
        int version_number
        boolean is_active
    }

    REGISTRATION_QUESTION {
        bigint question_id PK
        bigint form_version_id FK
        text question_key
        text prompt
        smallint display_order
        boolean is_required
    }

    REGISTRATION_SUBMISSION {
        uuid registration_id PK
        uuid user_id FK
        smallint space_type_id FK
        bigint form_version_id FK
        uuid verification_contact_id FK
        registration_status status
        timestamptz submitted_at
        timestamptz verified_at
        timestamptz completed_at
    }

    REGISTRATION_ANSWER {
        uuid registration_id PK, FK
        bigint question_id PK, FK
        bigint form_version_id FK
        text answer_text
    }

    VERIFICATION_CHALLENGE {
        uuid challenge_id PK
        uuid user_id FK
        uuid registration_id FK, nullable
        uuid contact_id FK
        verification_channel channel
        verification_purpose purpose
        verification_delivery_status delivery_status
        text code_hash
        timestamptz sent_at
        timestamptz expires_at
        smallint attempt_count
        smallint max_attempts
        timestamptz consumed_at
        timestamptz invalidated_at
    }

    AUTH_SESSION {
        uuid session_id PK
        uuid user_id FK
        text refresh_token_hash UK
        timestamptz created_at
        timestamptz last_seen_at
        timestamptz expires_at
        timestamptz revoked_at
    }

    AUTH_EVENT {
        bigint auth_event_id PK
        uuid user_id FK, nullable
        text event_type
        timestamptz occurred_at
        uuid correlation_id
    }

    SOCIETY {
        uuid society_id PK
        text society_code UK
        text display_name
        society_status status
    }

    SPACE {
        uuid space_id PK
        uuid society_id FK
        smallint space_type_id FK
        space_status status
        boolean is_discoverable
    }

    SOCIETY_MEMBER {
        uuid member_id PK
        uuid society_id FK
        uuid linked_app_user_id FK, nullable
        text member_number
        society_member_status status
    }

    SPACE_MEMBERSHIP {
        uuid membership_id PK
        uuid user_id FK
        uuid space_id FK
        uuid society_id FK
        uuid society_member_id FK, nullable
        text role_code
        space_membership_status status
        timestamptz activated_at
        timestamptz revoked_at
    }

    SCHEMA_MIGRATION {
        text version PK
        text description
        timestamptz applied_at
    }

    APP_USER ||--o| USER_PROFILE : "profile (0 or 1 row)"
    APP_USER ||--o{ USER_ADDRESS : "has addresses"
    APP_USER ||--o{ USER_CONTACT : "has email/phone"
    APP_USER ||--o| AUTH_CREDENTIAL : "has password hash (0 or 1)"
    APP_USER ||--o{ AUTH_LOGIN_IDENTIFIER : "has login names"
    APP_USER ||--o{ REGISTRATION_SUBMISSION : "submits"
    APP_USER ||--o{ VERIFICATION_CHALLENGE : "requests"
    APP_USER ||--o{ AUTH_SESSION : "has sessions"
    APP_USER o|--o{ AUTH_EVENT : "appears in events"
    APP_USER ||--o{ SPACE_MEMBERSHIP : "receives Space access"
    APP_USER o|--o{ SOCIETY_MEMBER : "may be linked to"
    SOCIETY ||--o{ SPACE : "has Spaces"
    SOCIETY ||--o{ SOCIETY_MEMBER : "registers members"
    SOCIETY ||--o{ SPACE_MEMBERSHIP : "scopes access"
    SPACE ||--o{ SPACE_MEMBERSHIP : "grants access through"
    SOCIETY_MEMBER o|--o{ SPACE_MEMBERSHIP : "identifies member"

    SPACE_TYPE ||--o{ REGISTRATION_FORM_VERSION : "defines versions"
    SPACE_TYPE ||--o{ REGISTRATION_SUBMISSION : "selected for"
    REGISTRATION_FORM_VERSION ||--o{ REGISTRATION_QUESTION : "defines questions"
    REGISTRATION_FORM_VERSION ||--o{ REGISTRATION_SUBMISSION : "used by"
    REGISTRATION_SUBMISSION ||--o{ REGISTRATION_ANSWER : "contains answers"
    REGISTRATION_QUESTION ||--o{ REGISTRATION_ANSWER : "answered by"
    USER_CONTACT ||--o{ REGISTRATION_SUBMISSION : "chosen for verification"
    USER_CONTACT ||--o{ VERIFICATION_CHALLENGE : "receives code"
    REGISTRATION_SUBMISSION o|--o{ VERIFICATION_CHALLENGE : "registration code; optional for reset"
```

`SCHEMA_MIGRATION` is shown as a standalone table because it records database migration history; it does not contain user or business records and has no foreign-key relationships.

## 2. How to read the diagram

- **PK** means primary key: the table’s unique row identifier.
- **FK** means foreign key: a link to a row in another table.
- **UK** means unique value: the database prevents duplicates.
- In this diagram, `||` means exactly one, `o|` means zero or one, and `o{` means zero or many. The diagram follows the foreign keys; application rules may require a profile or credential even where the database allows that row to be temporarily absent.
- A composite foreign key is a relationship that checks more than one column together. It is used here to ensure a selected contact belongs to the same user and that a question/answer belongs to the registration form version actually submitted.

## 3. What each table does

| Table                       | Purpose                                                                                | Example contents                                                                                                                                                                |
| --------------------------- | -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `app_user`                  | Account identity and lifecycle state, independent of any Society membership.           | Pending verification, active, suspended, or deactivated account.                                                                                                                |
| `user_profile`              | Person’s names, stored separately from credentials.                                    | Given name, surname, preferred name.                                                                                                                                            |
| `user_address`              | One or more postal/physical addresses for the account.                                 | Street address, town/locality, optional province, country.                                                                                                                      |
| `user_contact`              | Email and phone contacts, including verified/primary flags.                            | Email address or phone number and whether it was verified.                                                                                                                      |
| `auth_login_identifier`     | Username used to log in. It is separate from the password and email contact.           | Normalized username such as `member123`.                                                                                                                                        |
| `auth_credential`           | Password authentication data and basic failed-login/lockout counters.                  | Encoded password hash; never the original password.                                                                                                                             |
| `space_type`                | The available registration categories.                                                 | Society, Parlour, Family, Supplier. This is a category, **not an actual Space or membership**.                                                                                  |
| `registration_form_version` | A numbered revision of the questions for one Space type.                               | Society registration form version 1.                                                                                                                                            |
| `registration_question`     | One question in a form version.                                                        | “Society name or invitation code”.                                                                                                                                              |
| `registration_submission`   | A user’s registration attempt, chosen Space type, form version, and contact to verify. | Pending Society Space registration using email for verification. This does **not** grant membership.                                                                            |
| `registration_answer`       | One answer per submitted question.                                                     | Answer text linked to its exact question and form version.                                                                                                                      |
| `verification_challenge`    | OTP verification metadata for registration or password reset.                          | Delivery state, code hash, expiry, attempt count, and whether used. The plaintext OTP is not stored.                                                                            |
| `auth_session`              | Opaque session lifecycle.                                                              | SHA-256 hash of the 12-hour session token, expiry, last seen, and revocation time. The column is named `refresh_token_hash`, but token refresh/rotation is not implemented yet. |
| `auth_event`                | Minimal account-security audit events.                                                 | Login success/failure, registration, verification, password change, or session revocation.                                                                                      |
| `society` / `space`         | Society organization and its Space directory profile.                                  | Active Stronger Together Society and discoverable Society Space.                                                                                                                |
| `society_member`            | Society roster identity, distinct from an app account.                                 | Synthetic member number and optional linked app account.                                                                                                                        |
| `space_membership`          | Account authorization to one Space, with an explicit lifecycle.                        | Active member access, scoped to a society and optionally linked roster record.                                                                                                  |
| `schema_migration`          | Applied database migration versions.                                                   | Versions `001_auth_registration` through `005_user_profile_avatar`.                                                                                                             |

## 4. Registration journey through the tables

1. The backend validates the submitted form and normalizes email/phone values.
2. In one transaction it creates an `app_user` in `pending_verification`, a `user_profile`, an address, email/phone rows in `user_contact`, a username in `auth_login_identifier`, and a password hash in `auth_credential`.
3. It reads the active `registration_form_version` for the chosen `space_type`, creates a `registration_submission`, and stores each Space-specific response as a `registration_answer` linked to the form’s `registration_question`.
4. The transaction commits. **Only after that succeeds** may the backend ask an email/SMS provider to send the OTP. A `verification_challenge` tracks delivery state and limits; it stores a protected code hash, not the code itself.
5. After valid code verification, the backend marks the selected `user_contact` verified, marks the submission complete, and activates the account in a transaction. The database does not perform OTP delivery or verification by itself.
6. Account creation and selecting a `space_type` do not create an actual Space or membership. An active row in `space_membership`, backed by an unexpired authenticated session, is required before the API lists a Space as accessible. Public discovery does not grant access.

## 5. Login journey through the tables

1. The user submits either their username/email and password to the backend over HTTPS.
2. For a username, the backend finds the row in `auth_login_identifier` by `normalized_value`. For an email, it finds the matching verified email row in `user_contact`. It then obtains the user’s `auth_credential` and `app_user` status.
3. Argon2id verifies the submitted password against `password_hash`. Reject pending, suspended, or deactivated accounts. Apply server-side rate limiting, lockout, and generic error messages; the current per-process throttle is not a production abuse-control system.
4. After a successful login, the backend issues a 12-hour opaque session token. `auth_session` stores only its SHA-256 hash; the raw bearer token is returned once and held in Flutter memory. Sessions can be revoked, but refresh/rotation is not implemented yet.
5. Ordinary login does not send an OTP. OTP is for registration contact verification and password-reset flows, according to the current product decision.

## 6. Why the data is split up

This is normalization: each kind of fact is stored in the table responsible for that fact and referenced by keys instead of repeatedly copying it into every record. For example, a question prompt is stored once in `registration_question`; each user’s response is stored separately in `registration_answer`. If the wording changes, a new form version can be created while past submissions still point to their original questions.

Likewise, password hashes do not sit beside profile/address fields, and email/phone contacts are not embedded in the account row. This supports verification, updates, uniqueness checks, and clearer access/privacy boundaries.

## 7. Implemented versus future schema

**Implemented by migrations 001-003:** account and profile, contact verification, password-login storage, versioned registration questions/answers, OTP challenge metadata, sessions and auth events; society/Space/onboarding/member records; and session-checked active Space membership listing. The development seed links `testperson` to a separate synthetic member and grants active access for UI testing.

**Not implemented yet:** a production-verified member-account linking and approval workflow, invitation/join-request handling, role-based authorization for private Society workspace endpoints, contribution ledger, funeral cases, and their operational audit trail. The local synthetic fixture does not establish a production identity or approval process.
