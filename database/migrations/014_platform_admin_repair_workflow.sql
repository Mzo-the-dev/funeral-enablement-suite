BEGIN;

CREATE TABLE funeral_spaces.platform_admin (
    user_id uuid PRIMARY KEY REFERENCES funeral_spaces.app_user(user_id) ON DELETE RESTRICT,
    is_active boolean NOT NULL DEFAULT true,
    granted_at timestamptz NOT NULL DEFAULT now(),
    granted_by_user_id uuid REFERENCES funeral_spaces.app_user(user_id) ON DELETE SET NULL,
    grant_reason text NOT NULL CHECK (length(trim(grant_reason)) BETWEEN 1 AND 500),
    revoked_at timestamptz,
    revoked_by_user_id uuid REFERENCES funeral_spaces.app_user(user_id) ON DELETE SET NULL,
    CONSTRAINT platform_admin_revocation_consistency CHECK (
        (is_active AND revoked_at IS NULL AND revoked_by_user_id IS NULL)
        OR (NOT is_active AND revoked_at IS NOT NULL)
    )
);

CREATE TABLE funeral_spaces.platform_admin_audit (
    platform_admin_audit_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    actor_user_id uuid REFERENCES funeral_spaces.app_user(user_id) ON DELETE SET NULL,
    operator_name text NOT NULL DEFAULT session_user,
    action text NOT NULL CHECK (action IN ('platform_admin_granted', 'member_account_linked')),
    target_user_id uuid NOT NULL REFERENCES funeral_spaces.app_user(user_id) ON DELETE RESTRICT,
    society_id uuid REFERENCES funeral_spaces.society(society_id) ON DELETE RESTRICT,
    target_member_id uuid,
    reason text NOT NULL CHECK (length(trim(reason)) BETWEEN 1 AND 500),
    before_data jsonb NOT NULL DEFAULT '{}'::jsonb,
    after_data jsonb NOT NULL DEFAULT '{}'::jsonb,
    occurred_at timestamptz NOT NULL DEFAULT now(),
    FOREIGN KEY (target_member_id, society_id)
        REFERENCES funeral_spaces.society_member(member_id, society_id) ON DELETE RESTRICT,
    CONSTRAINT platform_admin_audit_target_consistency CHECK (
        (action = 'platform_admin_granted' AND society_id IS NULL AND target_member_id IS NULL)
        OR (action = 'member_account_linked' AND actor_user_id IS NOT NULL
            AND society_id IS NOT NULL AND target_member_id IS NOT NULL)
    )
);

CREATE INDEX platform_admin_audit_by_target
    ON funeral_spaces.platform_admin_audit(target_user_id, occurred_at DESC);

INSERT INTO funeral_spaces.schema_migration (version, description)
VALUES (
    '014_platform_admin_repair_workflow',
    'Add operator-provisioned platform admins and audited data-repair actions'
);

COMMIT;