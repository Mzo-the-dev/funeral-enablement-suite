begin;


do $$ begin if current_database () <> 'funeral_spaces_dev' then RAISE exception 'The test account society seed is restricted to funeral_spaces_dev; current database is %',
current_database ();


end if;


end;


$$;


insert into
    funeral_spaces.society_onboarding_batch (
        society_id,
        idempotency_key,
        source_type,
        status,
        received_member_count,
        active_member_count,
        deactivated_member_count,
        covered_life_count,
        office_assignment_count,
        rejected_row_count,
        committed_at
    )
select
    society.society_id,
    'stronger-together-testperson-v1',
    'synthetic_seed',
    'committed',
    1,
    1,
    0,
    0,
    0,
    0,
    now()
from
    funeral_spaces.society society
where
    society.society_code = 'STRONGER-TOGETHER-DEMO' on CONFLICT (idempotency_key) do NOTHING;


with
    account as (
        select
            app_user.user_id
        from
            funeral_spaces.app_user
            join funeral_spaces.auth_login_identifier identifier using (user_id)
            join funeral_spaces.user_contact contact using (user_id)
        where
            app_user.status = 'active'
            and identifier.identifier_type = 'username'
            and identifier.normalized_value = 'testperson'
            and contact.contact_type = 'email'
            and contact.normalized_value = 'test@email.com'
    ),
    context as (
        select
            society.society_id,
            batch.onboarding_batch_id
        from
            funeral_spaces.society society
            join funeral_spaces.society_onboarding_batch batch using (society_id)
        where
            society.society_code = 'STRONGER-TOGETHER-DEMO'
            and batch.idempotency_key = 'stronger-together-testperson-v1'
    )
insert into
    funeral_spaces.society_member (
        society_id,
        onboarding_batch_id,
        member_number,
        given_name,
        surname,
        status,
        joined_at,
        linked_app_user_id
    )
select
    context.society_id,
    context.onboarding_batch_id,
    'STS-036',
    'Test',
    'Account',
    'active',
    current_date,
    account.user_id
from
    context
    cross join account on CONFLICT (society_id, member_number) do
update set
    linked_app_user_id = EXCLUDED.linked_app_user_id,
    updated_at = now()
where
    funeral_spaces.society_member.linked_app_user_id is null
    or funeral_spaces.society_member.linked_app_user_id = EXCLUDED.linked_app_user_id;


insert into
    funeral_spaces.space_membership (
        user_id,
        space_id,
        society_id,
        society_member_id,
        role_code,
        status,
        requested_at,
        activated_at
    )
select
    member.linked_app_user_id,
    space.space_id,
    member.society_id,
    member.member_id,
    'member',
    'active',
    now(),
    now()
from
    funeral_spaces.society_member member
    join funeral_spaces.society society using (society_id)
    join funeral_spaces.space space using (society_id)
where
    society.society_code = 'STRONGER-TOGETHER-DEMO'
    and member.member_number = 'STS-036'
    and member.status = 'active'
    and member.linked_app_user_id is not null
    and space.status = 'active'
    and space.space_type_id = (
        select
            space_type_id
        from
            funeral_spaces.space_type
        where
            code = 'society'
    ) on CONFLICT do NOTHING;


do $$
declare linked_member_count integer;


active_membership_count integer;


begin
select
    count(*)
into
    linked_member_count
from
    funeral_spaces.society_member member
    join funeral_spaces.society society using (society_id)
    join funeral_spaces.app_user account on account.user_id = member.linked_app_user_id
    join funeral_spaces.auth_login_identifier identifier using (user_id)
    join funeral_spaces.user_contact contact using (user_id)
where
    society.society_code = 'STRONGER-TOGETHER-DEMO'
    and member.member_number = 'STS-036'
    and member.status = 'active'
    and account.status = 'active'
    and identifier.normalized_value = 'testperson'
    and contact.normalized_value = 'test@email.com';


select
    count(*)
into
    active_membership_count
from
    funeral_spaces.space_membership membership
    join funeral_spaces.society_member member on member.member_id = membership.society_member_id
    and member.society_id = membership.society_id
    join funeral_spaces.app_user account on account.user_id = membership.user_id
where
    member.member_number = 'STS-036'
    and account.status = 'active'
    and membership.status = 'active';


if linked_member_count <> 1
or active_membership_count <> 1 then RAISE exception 'Expected one active STS-036 account link and membership; found % and %',
linked_member_count,
active_membership_count;


end if;


end;


$$;


commit;