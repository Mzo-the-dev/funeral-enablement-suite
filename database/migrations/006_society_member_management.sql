begin;


create table
    funeral_spaces.society_record_change (
        change_id uuid primary key default gen_random_uuid (),
        society_id uuid not null references funeral_spaces.society (society_id) on delete RESTRICT,
        member_id uuid not null,
        covered_life_id uuid references funeral_spaces.covered_life (covered_life_id) on delete RESTRICT,
        actor_user_id uuid not null references funeral_spaces.app_user (user_id) on delete RESTRICT,
        action text not null check (
            action in (
                'member_created',
                'member_updated',
                'member_deactivated',
                'covered_life_added',
                'covered_life_updated',
                'covered_life_deactivated'
            )
        ),
        before_data jsonb,
        after_data jsonb not null,
        occurred_at timestamptz not null default now(),
        foreign key (member_id, society_id) references funeral_spaces.society_member (member_id, society_id) on delete RESTRICT,
        constraint society_record_change_target_matches_action check (
            (
                covered_life_id is null
                and action like 'member_%'
            )
            or (
                covered_life_id is not null
                and action like 'covered_life_%'
            )
        )
    );


create index society_record_change_by_member on funeral_spaces.society_record_change (society_id, member_id, occurred_at desc);


insert into
    funeral_spaces.schema_migration (version, description)
values
    (
        '006_society_member_management',
        'Audited society member and covered-life maintenance'
    );


commit;