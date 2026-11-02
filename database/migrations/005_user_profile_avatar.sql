BEGIN;

ALTER TABLE funeral_spaces.user_profile
    ADD COLUMN avatar_image bytea,
    ADD COLUMN avatar_mime_type text,
    ADD CONSTRAINT user_profile_avatar_size CHECK (
        avatar_image IS NULL OR octet_length(avatar_image) <= 524288
    ),
    ADD CONSTRAINT user_profile_avatar_mime CHECK (
        (avatar_image IS NULL AND avatar_mime_type IS NULL)
        OR (avatar_image IS NOT NULL AND avatar_mime_type IN ('image/png', 'image/jpeg', 'image/webp'))
    );

INSERT INTO funeral_spaces.schema_migration (version, description)
VALUES (
    '005_user_profile_avatar',
    'Store bounded profile avatar images and MIME types'
);

COMMIT;