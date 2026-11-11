begin;


alter table funeral_spaces.funeral_case
drop constraint funeral_case_payout_details_complete,
add constraint funeral_case_payout_details_complete check (
    (
        payout_bank_name is null
        and payout_account_name is null
        and payout_account_number is null
    )
    or (
        payout_bank_name is not null
        and payout_account_name is not null
        and payout_account_number is not null
        and length(trim(payout_bank_name)) > 0
        and length(trim(payout_account_name)) > 0
        and length(trim(payout_account_number)) > 0
    )
);


insert into
    funeral_spaces.schema_migration (version, description)
values
    (
        '009_funeral_case_payout_constraint',
        'Require all payout bank fields together and nonblank'
    );


commit;