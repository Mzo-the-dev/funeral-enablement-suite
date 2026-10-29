BEGIN;

CREATE SCHEMA IF NOT EXISTS funeral_spaces;

CREATE TABLE funeral_spaces.schema_migration (
    version text PRIMARY KEY,
    description text NOT NULL,
    applied_at timestamptz NOT NULL DEFAULT now()
);

CREATE TYPE funeral_spaces.account_status AS ENUM (
    'pending_verification',
    'active',
    'suspended',
    'deactivated'
);

CREATE TYPE funeral_spaces.contact_type AS ENUM ('email', 'phone');
CREATE TYPE funeral_spaces.login_identifier_type AS ENUM ('username');
CREATE TYPE funeral_spaces.verification_channel AS ENUM ('email', 'sms');
CREATE TYPE funeral_spaces.registration_status AS ENUM (
    'pending_verification',
    'verified',
    'rejected',
    'expired',
    'cancelled'
);
CREATE TYPE funeral_spaces.verification_purpose AS ENUM (
    'registration_contact',
    'password_reset'
);
CREATE TYPE funeral_spaces.verification_delivery_status AS ENUM (
    'queued',
    'sent',
    'failed',
    'cancelled'
);

CREATE TABLE funeral_spaces.space_type (
    space_type_id smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code text NOT NULL UNIQUE,
    display_name text NOT NULL UNIQUE,
    is_enabled boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT space_type_code_format CHECK (code ~ '^[a-z][a-z0-9_]*$')
);

CREATE TABLE funeral_spaces.app_user (
    user_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    status funeral_spaces.account_status NOT NULL DEFAULT 'pending_verification',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    deactivated_at timestamptz,
    CONSTRAINT app_user_deactivated_at_consistency CHECK (
        (status = 'deactivated' AND deactivated_at IS NOT NULL)
        OR (status <> 'deactivated' AND deactivated_at IS NULL)
    )
);

CREATE TABLE funeral_spaces.user_profile (
    user_id uuid PRIMARY KEY REFERENCES funeral_spaces.app_user(user_id) ON DELETE CASCADE,
    given_name text NOT NULL CHECK (length(trim(given_name)) BETWEEN 1 AND 120),
    surname text NOT NULL CHECK (length(trim(surname)) BETWEEN 1 AND 120),
    preferred_name text NOT NULL CHECK (length(trim(preferred_name)) BETWEEN 1 AND 120),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE funeral_spaces.user_address (
    address_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES funeral_spaces.app_user(user_id) ON DELETE CASCADE,
    address_line_1 text NOT NULL CHECK (length(trim(address_line_1)) BETWEEN 1 AND 200),
    address_line_2 text,
    locality text NOT NULL CHECK (length(trim(locality)) BETWEEN 1 AND 120),
    province text CHECK (province IS NULL OR length(trim(province)) BETWEEN 1 AND 120),
    postal_code text,
    country_code char(2) NOT NULL DEFAULT 'ZA' CHECK (country_code ~ '^[A-Z]{2}$'),
    is_primary boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (address_id, user_id)
);

CREATE UNIQUE INDEX user_address_one_primary_per_user
    ON funeral_spaces.user_address(user_id)
    WHERE is_primary;

CREATE TABLE funeral_spaces.user_contact (
    contact_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES funeral_spaces.app_user(user_id) ON DELETE CASCADE,
    contact_type funeral_spaces.contact_type NOT NULL,
    contact_value text NOT NULL,
    normalized_value text NOT NULL,
    is_verified boolean NOT NULL DEFAULT false,
    verified_at timestamptz,
    is_primary boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (contact_id, user_id),
    UNIQUE (contact_type, normalized_value),
    CONSTRAINT user_contact_value_not_blank CHECK (length(trim(contact_value)) > 0),
    CONSTRAINT user_contact_verified_at_consistency CHECK (
        (is_verified AND verified_at IS NOT NULL)
        OR (NOT is_verified AND verified_at IS NULL)
    ),
    CONSTRAINT user_contact_normalized_not_blank CHECK (length(trim(normalized_value)) > 0)
);

CREATE UNIQUE INDEX user_contact_one_primary_per_type
    ON funeral_spaces.user_contact(user_id, contact_type)
    WHERE is_primary;

CREATE TABLE funeral_spaces.auth_credential (
    user_id uuid PRIMARY KEY REFERENCES funeral_spaces.app_user(user_id) ON DELETE CASCADE,
    password_hash text NOT NULL,
    password_changed_at timestamptz NOT NULL DEFAULT now(),
    failed_login_count integer NOT NULL DEFAULT 0 CHECK (failed_login_count >= 0),
    locked_until timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT auth_password_hash_nonblank CHECK (length(trim(password_hash)) > 0)
);

CREATE TABLE funeral_spaces.auth_login_identifier (
    identifier_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES funeral_spaces.app_user(user_id) ON DELETE CASCADE,
    identifier_type funeral_spaces.login_identifier_type NOT NULL,
    identifier_value text NOT NULL,
    normalized_value text NOT NULL UNIQUE,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (user_id, identifier_type),
    CONSTRAINT auth_username_identifier_not_email CHECK (
        position('@' IN identifier_value) = 0
    ),
    CONSTRAINT auth_login_identifier_length CHECK (
        length(trim(identifier_value)) BETWEEN 3 AND 80
        AND length(trim(normalized_value)) BETWEEN 3 AND 80
    )
);

CREATE TABLE funeral_spaces.registration_form_version (
    form_version_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    space_type_id smallint NOT NULL REFERENCES funeral_spaces.space_type(space_type_id),
    version_number integer NOT NULL CHECK (version_number > 0),
    is_active boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (space_type_id, version_number),
    UNIQUE (form_version_id, space_type_id)
);

CREATE UNIQUE INDEX registration_form_one_active_version
    ON funeral_spaces.registration_form_version(space_type_id)
    WHERE is_active;

CREATE TABLE funeral_spaces.registration_question (
    question_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    form_version_id bigint NOT NULL REFERENCES funeral_spaces.registration_form_version(form_version_id),
    question_key text NOT NULL,
    prompt text NOT NULL,
    display_order smallint NOT NULL CHECK (display_order > 0),
    is_required boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (form_version_id, question_key),
    UNIQUE (form_version_id, display_order),
    UNIQUE (question_id, form_version_id)
);

CREATE TABLE funeral_spaces.registration_submission (
    registration_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES funeral_spaces.app_user(user_id) ON DELETE RESTRICT,
    space_type_id smallint NOT NULL REFERENCES funeral_spaces.space_type(space_type_id),
    form_version_id bigint NOT NULL,
    verification_contact_id uuid NOT NULL,
    status funeral_spaces.registration_status NOT NULL DEFAULT 'pending_verification',
    submitted_at timestamptz NOT NULL DEFAULT now(),
    verified_at timestamptz,
    completed_at timestamptz,
    CONSTRAINT registration_form_matches_space_type FOREIGN KEY (form_version_id, space_type_id)
        REFERENCES funeral_spaces.registration_form_version(form_version_id, space_type_id),
    CONSTRAINT registration_contact_belongs_to_user FOREIGN KEY (verification_contact_id, user_id)
        REFERENCES funeral_spaces.user_contact(contact_id, user_id),
    UNIQUE (registration_id, user_id, verification_contact_id),
    UNIQUE (registration_id, form_version_id),
    CONSTRAINT registration_status_timestamps CHECK (
        (status = 'verified' AND verified_at IS NOT NULL AND completed_at IS NOT NULL)
        OR (status <> 'verified' AND completed_at IS NULL)
    )
);

CREATE INDEX registration_submission_user_history
    ON funeral_spaces.registration_submission(user_id, submitted_at DESC);
CREATE INDEX registration_submission_pending
    ON funeral_spaces.registration_submission(status, submitted_at)
    WHERE status = 'pending_verification';

CREATE TABLE funeral_spaces.registration_answer (
    registration_id uuid NOT NULL REFERENCES funeral_spaces.registration_submission(registration_id) ON DELETE CASCADE,
    form_version_id bigint NOT NULL,
    question_id bigint NOT NULL,
    answer_text text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (registration_id, question_id),
    CONSTRAINT registration_answer_question_matches_form FOREIGN KEY (question_id, form_version_id)
        REFERENCES funeral_spaces.registration_question(question_id, form_version_id),
    CONSTRAINT registration_answer_submission_matches_form FOREIGN KEY (registration_id, form_version_id)
        REFERENCES funeral_spaces.registration_submission(registration_id, form_version_id)
        ON DELETE CASCADE,
    CONSTRAINT registration_answer_not_blank CHECK (length(trim(answer_text)) > 0)
);

CREATE TABLE funeral_spaces.verification_challenge (
    challenge_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES funeral_spaces.app_user(user_id) ON DELETE CASCADE,
    registration_id uuid,
    contact_id uuid NOT NULL,
    channel funeral_spaces.verification_channel NOT NULL,
    purpose funeral_spaces.verification_purpose NOT NULL DEFAULT 'registration_contact',
    delivery_status funeral_spaces.verification_delivery_status NOT NULL DEFAULT 'queued',
    code_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    sent_at timestamptz,
    expires_at timestamptz,
    attempt_count smallint NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
    max_attempts smallint NOT NULL DEFAULT 5 CHECK (max_attempts BETWEEN 1 AND 10),
    consumed_at timestamptz,
    invalidated_at timestamptz,
    CONSTRAINT verification_contact_belongs_to_user FOREIGN KEY (contact_id, user_id)
        REFERENCES funeral_spaces.user_contact(contact_id, user_id),
    CONSTRAINT verification_registration_matches_user_and_contact
        FOREIGN KEY (registration_id, user_id, contact_id)
        REFERENCES funeral_spaces.registration_submission(registration_id, user_id, verification_contact_id)
        ON DELETE CASCADE,
    CONSTRAINT verification_purpose_matches_registration CHECK (
        (purpose = 'registration_contact' AND registration_id IS NOT NULL)
        OR (purpose = 'password_reset' AND registration_id IS NULL)
    ),
    CONSTRAINT verification_delivery_timestamps CHECK (
        (delivery_status = 'sent' AND sent_at IS NOT NULL AND expires_at > sent_at)
        OR (delivery_status <> 'sent' AND sent_at IS NULL AND expires_at IS NULL)
    ),
    CONSTRAINT verification_challenge_hash_nonblank CHECK (length(trim(code_hash)) > 0),
    CONSTRAINT verification_challenge_terminal_state CHECK (
        consumed_at IS NULL OR invalidated_at IS NULL
    )
);

CREATE UNIQUE INDEX verification_one_live_challenge_per_registration
    ON funeral_spaces.verification_challenge(registration_id)
    WHERE registration_id IS NOT NULL AND consumed_at IS NULL AND invalidated_at IS NULL;
CREATE UNIQUE INDEX verification_one_live_reset_per_user
    ON funeral_spaces.verification_challenge(user_id)
    WHERE purpose = 'password_reset' AND consumed_at IS NULL AND invalidated_at IS NULL;
CREATE INDEX verification_challenge_expiry
    ON funeral_spaces.verification_challenge(expires_at)
    WHERE delivery_status = 'sent' AND consumed_at IS NULL AND invalidated_at IS NULL;

CREATE TABLE funeral_spaces.auth_session (
    session_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES funeral_spaces.app_user(user_id) ON DELETE CASCADE,
    refresh_token_hash text NOT NULL UNIQUE,
    created_at timestamptz NOT NULL DEFAULT now(),
    last_seen_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz NOT NULL,
    revoked_at timestamptz,
    device_label text,
    CONSTRAINT auth_session_expiry_after_creation CHECK (expires_at > created_at),
    CONSTRAINT auth_session_token_hash_nonblank CHECK (length(trim(refresh_token_hash)) > 0)
);

CREATE INDEX auth_session_active_by_user
    ON funeral_spaces.auth_session(user_id, expires_at)
    WHERE revoked_at IS NULL;

CREATE TABLE funeral_spaces.auth_event (
    auth_event_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id uuid REFERENCES funeral_spaces.app_user(user_id) ON DELETE SET NULL,
    event_type text NOT NULL CHECK (event_type IN (
        'registration_created',
        'contact_verification_succeeded',
        'contact_verification_failed',
        'login_succeeded',
        'login_failed',
        'password_changed',
        'password_reset_requested',
        'session_revoked',
        'account_suspended',
        'account_deactivated'
    )),
    occurred_at timestamptz NOT NULL DEFAULT now(),
    correlation_id uuid,
    CONSTRAINT auth_event_type_not_blank CHECK (length(trim(event_type)) > 0)
);

CREATE INDEX auth_event_by_user_and_time
    ON funeral_spaces.auth_event(user_id, occurred_at DESC);

INSERT INTO funeral_spaces.space_type (code, display_name) VALUES
    ('society', 'Society Space'),
    ('parlour', 'Parlour Space'),
    ('family', 'Family Space'),
    ('supplier', 'Supplier Space');

INSERT INTO funeral_spaces.registration_form_version (space_type_id, version_number, is_active)
SELECT space_type_id, 1, true
FROM funeral_spaces.space_type;

INSERT INTO funeral_spaces.registration_question
    (form_version_id, question_key, prompt, display_order, is_required)
SELECT form.form_version_id, questions.question_key, questions.prompt, questions.display_order, true
FROM funeral_spaces.registration_form_version AS form
JOIN funeral_spaces.space_type AS type USING (space_type_id)
JOIN (VALUES
    ('society', 'society_reference', 'Society name or invitation code', 1),
    ('society', 'society_role', 'Your role in the society', 2),
    ('parlour', 'parlour_name', 'Funeral parlour or business name', 1),
    ('parlour', 'parlour_services', 'Services you provide', 2),
    ('family', 'family_reference', 'Family or society reference', 1),
    ('family', 'family_relationship', 'Your relationship to the family', 2),
    ('supplier', 'supplier_business_name', 'Business name', 1),
    ('supplier', 'supplier_services', 'Products or services you provide', 2)
) AS questions(space_code, question_key, prompt, display_order)
  ON questions.space_code = type.code
WHERE form.version_number = 1;

INSERT INTO funeral_spaces.schema_migration (version, description)
VALUES ('001_auth_registration', 'Normalized account, registration, verification, and session tables');

COMMIT;
