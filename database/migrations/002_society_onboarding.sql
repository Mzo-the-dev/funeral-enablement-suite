BEGIN;

CREATE TYPE funeral_spaces.society_status AS ENUM (
    'onboarding',
    'active',
    'suspended',
    'closed'
);

CREATE TYPE funeral_spaces.space_status AS ENUM (
    'onboarding',
    'active',
    'suspended',
    'closed'
);

CREATE TYPE funeral_spaces.society_member_status AS ENUM (
    'active',
    'deactivated'
);

CREATE TYPE funeral_spaces.onboarding_batch_status AS ENUM (
    'received',
    'validated',
    'committed',
    'rejected'
);

CREATE TABLE funeral_spaces.society (
    society_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    society_code text NOT NULL UNIQUE,
    display_name text NOT NULL,
    status funeral_spaces.society_status NOT NULL DEFAULT 'onboarding',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT society_code_format CHECK (society_code ~ '^[A-Z0-9-]{3,80}$'),
    CONSTRAINT society_display_name_not_blank CHECK (length(trim(display_name)) BETWEEN 1 AND 160)
);

CREATE TABLE funeral_spaces.space (
    space_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    society_id uuid NOT NULL REFERENCES funeral_spaces.society(society_id) ON DELETE RESTRICT,
    space_type_id smallint NOT NULL REFERENCES funeral_spaces.space_type(space_type_id),
    display_name text NOT NULL,
    status funeral_spaces.space_status NOT NULL DEFAULT 'onboarding',
    is_discoverable boolean NOT NULL DEFAULT false,
    public_description text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (society_id, space_type_id),
    UNIQUE (space_id, society_id),
    CONSTRAINT space_display_name_not_blank CHECK (length(trim(display_name)) BETWEEN 1 AND 160),
    CONSTRAINT space_public_description_length CHECK (
        public_description IS NULL OR length(public_description) <= 500
    )
);

CREATE INDEX space_discoverable_by_type
    ON funeral_spaces.space(space_type_id, display_name)
    WHERE is_discoverable AND status = 'active';

CREATE TABLE funeral_spaces.society_onboarding_batch (
    onboarding_batch_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    society_id uuid NOT NULL REFERENCES funeral_spaces.society(society_id) ON DELETE RESTRICT,
    idempotency_key text NOT NULL UNIQUE,
    source_type text NOT NULL CHECK (source_type IN ('admin_assisted', 'csv_import', 'synthetic_seed')),
    status funeral_spaces.onboarding_batch_status NOT NULL DEFAULT 'received',
    received_member_count integer NOT NULL DEFAULT 0 CHECK (received_member_count >= 0),
    active_member_count integer NOT NULL DEFAULT 0 CHECK (active_member_count >= 0),
    deactivated_member_count integer NOT NULL DEFAULT 0 CHECK (deactivated_member_count >= 0),
    covered_life_count integer NOT NULL DEFAULT 0 CHECK (covered_life_count >= 0),
    office_assignment_count integer NOT NULL DEFAULT 0 CHECK (office_assignment_count >= 0),
    rejected_row_count integer NOT NULL DEFAULT 0 CHECK (rejected_row_count >= 0),
    created_by_user_id uuid REFERENCES funeral_spaces.app_user(user_id) ON DELETE SET NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    committed_at timestamptz,
    CONSTRAINT onboarding_member_counts_fit_batch CHECK (
        active_member_count + deactivated_member_count <= received_member_count
    ),
    CONSTRAINT onboarding_commit_timestamp CHECK (
        (status = 'committed' AND committed_at IS NOT NULL)
        OR (status <> 'committed' AND committed_at IS NULL)
    ),
    CONSTRAINT onboarding_idempotency_key_not_blank CHECK (length(trim(idempotency_key)) BETWEEN 1 AND 160)
);

CREATE INDEX society_onboarding_history
    ON funeral_spaces.society_onboarding_batch(society_id, created_at DESC);

CREATE TABLE funeral_spaces.society_member (
    member_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    society_id uuid NOT NULL REFERENCES funeral_spaces.society(society_id) ON DELETE RESTRICT,
    onboarding_batch_id uuid REFERENCES funeral_spaces.society_onboarding_batch(onboarding_batch_id) ON DELETE SET NULL,
    member_number text NOT NULL,
    given_name text NOT NULL,
    surname text NOT NULL,
    status funeral_spaces.society_member_status NOT NULL DEFAULT 'active',
    joined_at date NOT NULL,
    deactivated_at timestamptz,
    linked_app_user_id uuid REFERENCES funeral_spaces.app_user(user_id) ON DELETE SET NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (society_id, member_number),
    UNIQUE (member_id, society_id),
    CONSTRAINT society_member_number_not_blank CHECK (length(trim(member_number)) BETWEEN 1 AND 80),
    CONSTRAINT society_member_names_not_blank CHECK (
        length(trim(given_name)) BETWEEN 1 AND 120 AND length(trim(surname)) BETWEEN 1 AND 120
    ),
    CONSTRAINT society_member_deactivation_consistency CHECK (
        (status = 'active' AND deactivated_at IS NULL)
        OR (status = 'deactivated' AND deactivated_at IS NOT NULL)
    )
);

CREATE UNIQUE INDEX society_member_one_account_link
    ON funeral_spaces.society_member(society_id, linked_app_user_id)
    WHERE linked_app_user_id IS NOT NULL;
CREATE INDEX society_member_by_status
    ON funeral_spaces.society_member(society_id, status, member_number);

CREATE TABLE funeral_spaces.covered_life (
    covered_life_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id uuid NOT NULL REFERENCES funeral_spaces.society_member(member_id) ON DELETE RESTRICT,
    onboarding_batch_id uuid REFERENCES funeral_spaces.society_onboarding_batch(onboarding_batch_id) ON DELETE SET NULL,
    person_number smallint NOT NULL CHECK (person_number BETWEEN 1 AND 100),
    display_name text NOT NULL,
    relationship_code text NOT NULL CHECK (relationship_code IN ('member', 'spouse', 'dependent')),
    status funeral_spaces.society_member_status NOT NULL DEFAULT 'active',
    effective_from date NOT NULL,
    effective_to date,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (member_id, person_number),
    CONSTRAINT covered_life_display_name_not_blank CHECK (length(trim(display_name)) BETWEEN 1 AND 160),
    CONSTRAINT covered_life_effective_dates CHECK (effective_to IS NULL OR effective_to >= effective_from)
);

CREATE INDEX covered_life_by_member_status
    ON funeral_spaces.covered_life(member_id, status, person_number);

CREATE TABLE funeral_spaces.society_office_role (
    role_code text PRIMARY KEY,
    display_name text NOT NULL UNIQUE,
    CONSTRAINT society_office_role_code_format CHECK (role_code ~ '^[a-z][a-z0-9_]{1,79}$'),
    CONSTRAINT society_office_role_name_not_blank CHECK (length(trim(display_name)) BETWEEN 1 AND 120)
);

INSERT INTO funeral_spaces.society_office_role (role_code, display_name) VALUES
    ('chairperson', 'Chairperson'),
    ('vice_chairperson', 'Vice Chairperson'),
    ('secretary', 'Secretary'),
    ('treasurer', 'Treasurer'),
    ('claim_assessor', 'Claim Assessor'),
    ('claim_approver', 'Claim Approver');

CREATE TABLE funeral_spaces.society_office_assignment (
    office_assignment_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    society_id uuid NOT NULL,
    member_id uuid NOT NULL,
    role_code text NOT NULL REFERENCES funeral_spaces.society_office_role(role_code),
    onboarding_batch_id uuid REFERENCES funeral_spaces.society_onboarding_batch(onboarding_batch_id) ON DELETE SET NULL,
    effective_from date NOT NULL,
    ended_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    FOREIGN KEY (member_id, society_id)
        REFERENCES funeral_spaces.society_member(member_id, society_id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX society_one_active_holder_per_office
    ON funeral_spaces.society_office_assignment(society_id, role_code)
    WHERE ended_at IS NULL;
CREATE INDEX society_office_assignments_by_member
    ON funeral_spaces.society_office_assignment(society_id, member_id)
    WHERE ended_at IS NULL;

CREATE TABLE funeral_spaces.society_fee_schedule (
    fee_schedule_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    society_id uuid NOT NULL REFERENCES funeral_spaces.society(society_id) ON DELETE RESTRICT,
    onboarding_batch_id uuid REFERENCES funeral_spaces.society_onboarding_batch(onboarding_batch_id) ON DELETE SET NULL,
    version_number integer NOT NULL CHECK (version_number > 0),
    monthly_contribution_amount numeric(12, 2) NOT NULL CHECK (monthly_contribution_amount >= 0),
    joining_fee_amount numeric(12, 2) NOT NULL CHECK (joining_fee_amount >= 0),
    currency_code char(3) NOT NULL DEFAULT 'ZAR' CHECK (currency_code ~ '^[A-Z]{3}$'),
    effective_from date NOT NULL,
    effective_to date,
    approved_by_user_id uuid REFERENCES funeral_spaces.app_user(user_id) ON DELETE SET NULL,
    approved_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (society_id, version_number),
    CONSTRAINT society_fee_schedule_effective_dates CHECK (
        effective_to IS NULL OR effective_to >= effective_from
    ),
    CONSTRAINT society_fee_schedule_approval_pair CHECK (
        (approved_by_user_id IS NULL AND approved_at IS NULL)
        OR (approved_by_user_id IS NOT NULL AND approved_at IS NOT NULL)
    )
);

CREATE UNIQUE INDEX society_one_current_fee_schedule
    ON funeral_spaces.society_fee_schedule(society_id)
    WHERE effective_to IS NULL;

INSERT INTO funeral_spaces.schema_migration (version, description)
VALUES ('002_society_onboarding', 'Society, Space, member, covered-life, office, fee schedule, and onboarding batch tables');

COMMIT;