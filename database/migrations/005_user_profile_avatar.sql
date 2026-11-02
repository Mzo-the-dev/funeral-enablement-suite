begin;


alter table funeral_spaces.user_profile
add column avatar_image bytea,
add column avatar_mime_type text,
add constraint user_profile_avatar_size check (
    avatar_image is null
    or octet_length(avatar_image) <= 524288
),
add constraint user_profile_avatar_mime check (
    (
        avatar_image is null
        and avatar_mime_type is null
    )
    or (
        avatar_image is not null
        and avatar_mime_type in ('image/png', 'image/jpeg', 'image/webp')
    )
);


insert into
    funeral_spaces.schema_migration (version, description)
values
    (
        '005_user_profile_avatar',
        'Store bounded profile avatar images and MIME types'
    );


commit;