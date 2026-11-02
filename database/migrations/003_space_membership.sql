BEGIN;

CREATE TYPE funeral_spaces.space_membership_status AS ENUM (
    'pending',
    'active',
    'suspended',
    'revoked'
);

CREATE TABLE funeral_spaces.space_membership (
    membership_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES funeral_spaces.app_user(user_id) ON DELETE CASCADE,
    space_id uuid NOT NULL,
    society_id uuid NOT NULL,
    society_member_id uuid,
    role_code text NOT NULL DEFAULT 'member',
    status funeral_spaces.space_membership_status NOT NULL DEFAULT 'pending',
    requested_at timestamptz NOT NULL DEFAULT now(),
    activated_at timestamptz,
    revoked_at timestamptz,
    granted_by_user_id uuid REFERENCES funeral_spaces.app_user(user_id) ON DELETE SET NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    FOREIGN KEY (space_id, society_id)
        REFERENCES funeral_spaces.space(space_id, society_id) ON DELETE RESTRICT,
    FOREIGN KEY (society_member_id, society_id)
        REFERENCES funeral_spaces.society_member(member_id, society_id) ON DELETE RESTRICT,
    CONSTRAINT space_membership_role_code_format CHECK (role_code ~ '^[a-z][a-z0-9_]{1,79}$'),
    CONSTRAINT space_membership_status_timestamps CHECK (
        (status = 'pending' AND activated_at IS NULL AND revoked_at IS NULL)
        OR (status IN ('active', 'suspended') AND activated_at IS NOT NULL AND revoked_at IS NULL)
        OR (status = 'revoked' AND revoked_at IS NOT NULL)
    )
);

CREATE UNIQUE INDEX space_membership_one_active_per_user
    ON funeral_spaces.space_membership(user_id, space_id)
    WHERE status = 'active';
CREATE INDEX space_membership_active_by_user
    ON funeral_spaces.space_membership(user_id, activated_at DESC)
    WHERE status = 'active';

INSERT INTO funeral_spaces.schema_migration (version, description)
VALUES ('003_space_membership', 'Session-scoped Space membership and access lifecycle');

COMMIT;