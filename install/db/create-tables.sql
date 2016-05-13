BEGIN;

\set ON_ERROR_STOP

-- http://stackoverflow.com/questions/2647158/how-can-i-hash-passwords-in-postgresql

-- sudo apt-get install postgresql postgresql-contrib libpq-dev

-- sql command inside of psql enable the crypto:
-- create extension pgcrypto

---------------------
-- controls
---------------------
CREATE TABLE controls (
    control_name  TEXT PRIMARY KEY,
    alias         TEXT,
    in_json_cfg   BOOLEAN NOT NULL
);
GRANT SELECT ON controls TO khaospy_read;
GRANT ALL    ON controls TO khaospy_write;

---------------------
-- control_status
---------------------
CREATE SEQUENCE control_status_seq;
GRANT SELECT ON control_status_seq TO khaospy_read;
GRANT ALL ON control_status_seq TO khaospy_write;
create table control_status (
    id INTEGER PRIMARY KEY DEFAULT nextval('control_status_seq') NOT NULL,
    control_name             TEXT NOT NULL REFERENCES controls,
    current_state            TEXT,
    current_value            REAL,
    last_change_state_time   TIMESTAMP WITH TIME ZONE,
    last_change_state_by     TEXT,
    manual_auto_timeout_left REAL,
    request_time             TIMESTAMP WITH TIME ZONE NOT NULL,
    db_update_time           TIMESTAMP WITH TIME ZONE NOT NULL
);

-- select control_name, request_time, current_state, current_value from control_status where id in ( select max(id) from control_status group by control_name );

GRANT SELECT ON control_status TO khaospy_read;
GRANT ALL    ON control_status TO khaospy_write;

---------------------
-- rooms
---------------------
CREATE SEQUENCE rooms_seq;
GRANT SELECT ON rooms_seq TO khaospy_read;
GRANT ALL ON rooms_seq TO khaospy_write;
create table rooms (
    id INTEGER PRIMARY KEY DEFAULT nextval('rooms_seq') NOT NULL,
    name    TEXT NOT NULL UNIQUE,
    tag     TEXT NOT NULL UNIQUE
);
GRANT SELECT ON rooms TO khaospy_read;
GRANT ALL    ON rooms TO khaospy_write;

---------------------
-- control_rooms
---------------------
CREATE SEQUENCE control_rooms_seq;
GRANT SELECT ON control_rooms_seq TO khaospy_read;
GRANT ALL ON control_rooms_seq TO khaospy_write;
CREATE TABLE control_rooms (
    id INTEGER PRIMARY KEY DEFAULT nextval('control_rooms_seq') NOT NULL,
    name            TEXT NOT NULL UNIQUE,
    tag             TEXT NOT NULL UNIQUE,
    control_name    TEXT NOT NULL REFERENCES controls,
    room            INTEGER NOT NULL REFERENCES rooms,
    can_view        BOOLEAN NOT NULL DEFAULT FALSE,
    can_operate     BOOLEAN NOT NULL DEFAULT FALSE
);
GRANT SELECT ON control_rooms TO khaospy_read;
GRANT ALL    ON control_rooms TO khaospy_write;

---------------------
-- users
---------------------
CREATE SEQUENCE users_seq;
GRANT SELECT ON users_seq TO khaospy_read;
GRANT ALL ON users_seq TO khaospy_write;
create table users (
    id INTEGER PRIMARY KEY DEFAULT nextval('users_seq') NOT NULL,
    username                        text not null unique,
    name                            text NOT NULL UNIQUE,
    email                           text not null unique,
    passhash                        text NOT NULL,
    passhash_expire                 timestamp with time zone,
    passhash_change_token           text NOT NULL,
    passhash_change_token_expire    timestamp with time zone,
    is_api_user                     boolean not null default false,
    is_admin                        boolean not null default false,
    can_remote                      boolean not null default false,
    mobile_phone                    text not null unique
);
GRANT SELECT ON users TO khaospy_read;
GRANT ALL ON users TO khaospy_write;

---------------------
-- user_control_rooms
---------------------
create table user_control_rooms (
    user_id         INTEGER NOT NULL REFERENCES users,
    control_room    INTEGER NOT NULL REFERENCES control_rooms
);

GRANT SELECT ON user_control_rooms TO khaospy_read;
GRANT ALL    ON user_control_rooms TO khaospy_write;


--INSERT INTO users (name, name ) VALUES( 'blah', 'uk-gpms');

--UPDATE blahtable
--    SET afield = ( SELECT id FROM users WHERE tag = 'blah' ),
--        name = 'dosumin'
--    WHERE id = 1;

-- ROLLBACK

COMMIT;

--khaospy=# INSERT INTO users
--khaospy-# (name, email,passsalt,passhash, mobile_phone)
--khaospy-# VALUES(
--khaospy(#     'test',
--khaospy(#     'test@blah.com',
--khaospy(#     crypt('zz_apsswrd', gen_salt('bf', 8)),
--khaospy(#     '07123456789'
--khaospy(# )
--khaospy-# ;
--INSERT 0 1
--khaospy=#
--khaospy=#
--khaospy=# select * from users;
-- id | name | email  | passsalt |                           passhash                           | mobile_phone
------+------+--------+----------+--------------------------------------------------------------+--------------
--  1 | test | uk-gsc | no-salt  | $2a$08$n4OzrBPHN57uF23uS/z60Oe08ZCPVllw6nIWx5V36Q9rBLXcv/XoC | 07123456789
--(1 row)
--
--khaospy=# select * from users where passhash=crypt('zz_apsswrd', '$2a$08$n4OzrBPHN57uF23uS/z60Oe08ZCPVllw6nIWx5V36Q9rBLXcv/XoC' );
-- id | name | email  | passsalt |                           passhash                           | mobile_phone
------+------+--------+----------+--------------------------------------------------------------+--------------
--  1 | test | uk-gsc | no-salt  | $2a$08$n4OzrBPHN57uF23uS/z60Oe08ZCPVllw6nIWx5V36Q9rBLXcv/XoC | 07123456789
--(1 row)
--
--khaospy=# select * from users where passhash=crypt('rzz_apsswrd', '$2a$08$n4OzrBPHN57uF23uS/z60Oe08ZCPVllw6nIWx5V36Q9rBLXcv/XoC' );
-- id | name | email | passsalt | passhash | mobile_phone
------+------+-------+----------+----------+--------------
--(0 rows)
--

--
--INSERT INTO users
--(username, name, email,passhash, mobile_phone)
--VALUES(
--    'testacc',
--    'test person',
--    'test@example.com',
--    crypt('zz_apsswrd', gen_salt('bf', 8)),
--    '07654321765'
--
--)
--;

-- select * from users where passhash = crypt(:pass, passhash);

