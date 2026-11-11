begin;


alter table funeral_spaces.platform_admin_audit
drop constraint platform_admin_audit_action_check,
add constraint platform_admin_audit_action_check check (
    action in (
        'platform_admin_granted',
        'platform_admin_revoked',
        'member_account_linked'
    )
),
drop constraint platform_admin_audit_target_consistency,
add constraint platform_admin_audit_target_consistency check (
    (
        action in (
            'platform_admin_granted',
            'platform_admin_revoked'
        )
        and society_id is null
        and target_member_id is null
    )
    or (
        action = 'member_account_linked'
        and actor_user_id is not null
        and society_id is not null
        and target_member_id is not null
    )
);


insert into
    funeral_spaces.schema_migration (version, description)
values
    (
        '015_platform_admin_revocation_audit',
        'Record operator-driven platform-admin revocation'
    );


commit;