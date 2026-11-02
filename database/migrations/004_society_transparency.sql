begin;


create type funeral_spaces.society_contribution_status as ENUM ('paid', 'partial', 'unpaid', 'waived');


create type funeral_spaces.funeral_case_status as ENUM ('pending', 'approved', 'declined');


create type funeral_spaces.society_membership_request_status as ENUM ('pending', 'approved', 'declined');


insert into
    funeral_spaces.society_office_role (role_code, display_name)
values
    ('funeral_approver', 'Funeral Approver') on CONFLICT (role_code) do
update set
    display_name = EXCLUDED.display_name;


update funeral_spaces.society_office_assignment
set
    role_code = 'funeral_approver'
where
    role_code = 'claim_approver';


delete from funeral_spaces.society_office_role role
where
    role.role_code = 'claim_approver'
    and not exists (
        select
            1
        from
            funeral_spaces.society_office_assignment assignment
        where
            assignment.role_code = role.role_code
    );


create table
    funeral_spaces.society_contribution (
        contribution_id uuid primary key default gen_random_uuid (),
        society_id uuid not null,
        member_id uuid not null,
        period_start date not null,
        due_date date not null,
        amount_due numeric (12, 2) not null check (amount_due > 0),
        amount_paid numeric (12, 2) not null default 0 check (amount_paid >= 0),
        status funeral_spaces.society_contribution_status not null,
        paid_at timestamptz,
        receipt_reference text,
        created_at timestamptz not null default now(),
        foreign key (member_id, society_id) references funeral_spaces.society_member (member_id, society_id) on delete RESTRICT,
        unique (member_id, period_start),
        constraint society_contribution_period_dates check (due_date >= period_start),
        constraint society_contribution_amount_limit check (amount_paid <= amount_due),
        constraint society_contribution_payment_consistency check (
            (
                status = 'paid'
                and amount_paid = amount_due
                and paid_at is not null
            )
            or (
                status = 'partial'
                and amount_paid > 0
                and amount_paid < amount_due
                and paid_at is not null
            )
            or (
                status = 'unpaid'
                and amount_paid = 0
                and paid_at is null
            )
            or (
                status = 'waived'
                and amount_paid = 0
                and paid_at is null
            )
        )
    );


create index society_contribution_by_society_period on funeral_spaces.society_contribution (society_id, period_start desc, due_date);


create index society_contribution_by_member_period on funeral_spaces.society_contribution (member_id, period_start desc);


create table
    funeral_spaces.funeral_case (
        funeral_case_id uuid primary key default gen_random_uuid (),
        society_id uuid not null,
        member_id uuid not null,
        case_reference text not null,
        status funeral_spaces.funeral_case_status not null default 'pending',
        summary text not null,
        reported_at timestamptz not null default now(),
        approved_at timestamptz,
        approved_by_member_id uuid,
        approved_by_user_id uuid references funeral_spaces.app_user (user_id) on delete set null,
        unique (society_id, case_reference),
        foreign key (member_id, society_id) references funeral_spaces.society_member (member_id, society_id) on delete RESTRICT,
        foreign key (approved_by_member_id, society_id) references funeral_spaces.society_member (member_id, society_id) on delete RESTRICT,
        constraint funeral_case_reference_not_blank check (length(trim(case_reference)) between 1 and 80),
        constraint funeral_case_summary_not_blank check (length(trim(summary)) between 1 and 500),
        constraint funeral_case_approval_consistency check (
            (
                status = 'approved'
                and approved_at is not null
                and approved_by_member_id is not null
            )
            or (
                status <> 'approved'
                and approved_at is null
                and approved_by_member_id is null
                and approved_by_user_id is null
            )
        )
    );


create index funeral_case_by_society_status on funeral_spaces.funeral_case (society_id, status, reported_at desc);


create table
    funeral_spaces.society_membership_request (
        membership_request_id uuid primary key default gen_random_uuid (),
        society_id uuid not null references funeral_spaces.society (society_id) on delete RESTRICT,
        user_id uuid not null references funeral_spaces.app_user (user_id) on delete CASCADE,
        requested_member_number text not null,
        status funeral_spaces.society_membership_request_status not null default 'pending',
        requested_at timestamptz not null default now(),
        decided_at timestamptz,
        decided_by_user_id uuid references funeral_spaces.app_user (user_id) on delete set null,
        society_member_id uuid,
        constraint society_membership_request_member_number check (
            length(trim(requested_member_number)) between 1 and 80
        ),
        foreign key (society_member_id, society_id) references funeral_spaces.society_member (member_id, society_id) on delete RESTRICT,
        constraint society_membership_request_decision_consistency check (
            (
                status = 'pending'
                and decided_at is null
                and decided_by_user_id is null
                and society_member_id is null
            )
            or (
                status = 'approved'
                and decided_at is not null
                and decided_by_user_id is not null
                and society_member_id is not null
            )
            or (
                status = 'declined'
                and decided_at is not null
                and decided_by_user_id is not null
                and society_member_id is null
            )
        )
    );


create unique index society_one_pending_membership_request_per_user on funeral_spaces.society_membership_request (society_id, user_id)
where
    status = 'pending';


create index society_membership_requests_pending on funeral_spaces.society_membership_request (society_id, requested_at)
where
    status = 'pending';


insert into
    funeral_spaces.schema_migration (version, description)
values
    (
        '004_society_transparency',
        'Society-wide contribution and case visibility with chairperson and funeral-approver workflows'
    );


commit;