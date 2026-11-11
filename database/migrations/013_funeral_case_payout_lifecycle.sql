begin;


create type funeral_spaces.funeral_payout_status as ENUM ('not_started', 'in_progress', 'completed');


alter table funeral_spaces.funeral_case
add column payout_status funeral_spaces.funeral_payout_status not null default 'not_started',
add column payout_completed_at timestamptz,
add column payout_completed_by_member_id uuid,
add column payout_completed_by_user_id uuid references funeral_spaces.app_user (user_id) on delete set null;


update funeral_spaces.funeral_case
set
    payout_status = 'in_progress'
where
    status = 'approved';


alter table funeral_spaces.funeral_case
add constraint funeral_case_payout_status_consistency check (
    (
        status = 'pending'
        and payout_status = 'not_started'
    )
    or (
        status = 'approved'
        and payout_status in ('in_progress', 'completed')
    )
    or (
        status = 'declined'
        and payout_status = 'not_started'
    )
),
add constraint funeral_case_payout_completion_audit check (
    (
        payout_status = 'completed'
        and payout_completed_at is not null
        and payout_completed_by_member_id is not null
    )
    or (
        payout_status <> 'completed'
        and payout_completed_at is null
        and payout_completed_by_member_id is null
        and payout_completed_by_user_id is null
    )
),
add constraint funeral_case_payout_completed_by_member_same_society foreign key (payout_completed_by_member_id, society_id) references funeral_spaces.society_member (member_id, society_id) on delete RESTRICT;


insert into
    funeral_spaces.schema_migration (version, description)
values
    (
        '013_funeral_case_payout_lifecycle',
        'Track funeral case payout progress and completion'
    );


commit;