
BEGIN;

\set ON_ERROR_STOP

DELETE FROM users where username = 'admin';

-- and the webui should enforce that "changepassword" is changed
-- upon login.

-- This will delete any user-rooms ... hmmm.
-- could do with something that just resets the password.

INSERT INTO users
(username, name, email, passhash, is_enabled, is_admin)
VALUES(
    'admin',
    'Administrator',
    'admin@example.org',
    crypt('changepassword', gen_salt('bf', 8)),
    true,
    true
);

COMMIT;
