begin;


alter table funeral_spaces.society_member
add constraint society_member_member_society_app_user_unique unique (member_id, society_id, linked_app_user_id);


alter table funeral_spaces.space_membership
add constraint space_membership_member_user_match foreign key (society_member_id, society_id, user_id) references funeral_spaces.society_member (member_id, society_id, linked_app_user_id) DEFERRABLE INITIALLY DEFERRED;


insert into
    funeral_spaces.schema_migration (version, description)
values
    (
        '012_society_membership_account_link',
        'Ensure Society Space membership belongs to its linked Society member account'
    );


commit;