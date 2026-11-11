begin;


alter table funeral_spaces.covered_life
add column identity_number text,
add constraint covered_life_identity_number_format check (
    identity_number is null
    or length(trim(identity_number)) between 6 and 32
);


alter table funeral_spaces.funeral_case
add column deceased_given_name text,
add column deceased_surname text,
add column deceased_id_number text,
add column date_of_death date,
add column uses_existing_bank_details boolean not null default false,
add column payout_bank_name text,
add column payout_account_name text,
add column payout_account_number text,
add constraint funeral_case_identity_present check (
    (
        deceased_given_name is not null
        and deceased_surname is not null
    )
    or deceased_id_number is not null
    or (
        deceased_given_name is null
        and deceased_surname is null
        and date_of_death is null
    )
),
add constraint funeral_case_payout_details_complete check (
    (
        payout_bank_name is null
        and payout_account_name is null
        and payout_account_number is null
    )
    or (
        length(trim(payout_bank_name)) > 0
        and length(trim(payout_account_name)) > 0
        and length(trim(payout_account_number)) > 0
    )
);


create index covered_life_by_identity_number on funeral_spaces.covered_life (identity_number)
where
    identity_number is not null;


insert into
    funeral_spaces.schema_migration (version, description)
values
    (
        '008_funeral_registration_details',
        'Store structured funeral, covered-life identity, and payout details'
    );


commit;