begin;


alter table funeral_spaces.funeral_case
add column assigned_to_member_id uuid,
add constraint funeral_case_assignee_same_society foreign key (assigned_to_member_id, society_id) references funeral_spaces.society_member (member_id, society_id) on delete RESTRICT;


update funeral_spaces.funeral_case case_record
set
    assigned_to_member_id = assignment.member_id
from
    funeral_spaces.society_office_assignment assignment
where
    assignment.society_id = case_record.society_id
    and assignment.role_code = 'vice_chairperson'
    and assignment.ended_at is null
    and assignment.effective_from <= current_date
    and case_record.status = 'pending';


create index funeral_case_by_assignee_status on funeral_spaces.funeral_case (assigned_to_member_id, status, reported_at desc);


insert into
    funeral_spaces.schema_migration (version, description)
values
    (
        '007_funeral_case_routing',
        'Route newly registered funeral cases to the Society Vice Chairperson'
    );


commit;