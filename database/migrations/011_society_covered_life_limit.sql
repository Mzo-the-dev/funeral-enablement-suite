begin;


alter table funeral_spaces.society
add column max_covered_lives_per_member smallint not null default 10,
add constraint society_covered_life_limit_range check (max_covered_lives_per_member between 1 and 100);


insert into
    funeral_spaces.schema_migration (version, description)
values
    (
        '011_society_covered_life_limit',
        'Configure each Society maximum active covered lives per member'
    );


commit;