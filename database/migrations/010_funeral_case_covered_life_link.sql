begin;


alter table funeral_spaces.funeral_case
add column deceased_covered_life_id uuid,
add constraint funeral_case_deceased_covered_life_fk foreign key (deceased_covered_life_id) references funeral_spaces.covered_life (covered_life_id) on delete RESTRICT;


insert into
    funeral_spaces.schema_migration (version, description)
values
    (
        '010_funeral_case_covered_life_link',
        'Link funeral cases to the validated covered life'
    );


commit;