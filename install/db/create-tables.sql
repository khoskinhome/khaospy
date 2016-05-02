BEGIN;

\set ON_ERROR_STOP

-- http://stackoverflow.com/questions/2647158/how-can-i-hash-passwords-in-postgresql

-- sudo apt-get install postgresql postgresql-contrib libpq-dev

-- sql command inside of psql enable the crypto:
-- create extension pgcrypto


CREATE SEQUENCE users_seq;
GRANT SELECT ON users_seq TO khaospy_read;
GRANT ALL ON users_seq TO khaospy_write;
create table users (
    id INTEGER PRIMARY KEY DEFAULT nextval('users_seq') NOT NULL,
    username     text not null unique,
    name         text NOT NULL UNIQUE,
    email        text not null unique,
    passhash     text NOT NULL,
    passhash_expire_timestamp timestamp with time zone,
    is_api_user  boolean not null default false,
    is_admin     boolean not null default false,
    mobile_phone text not null unique,
    can_remote   boolean not null default false

);
GRANT SELECT ON users TO khaospy_read;
GRANT ALL ON users TO khaospy_write;


CREATE SEQUENCE control_status_seq;
GRANT SELECT ON control_status_seq TO khaospy_read;
GRANT ALL ON control_status_seq TO khaospy_write;
create table control_status (
    id INTEGER PRIMARY KEY DEFAULT nextval('control_status_seq') NOT NULL,
    control_name             text not null,
    current_state            text,
    current_value            real,
    last_change_state_time   timestamp with time zone null,
    last_change_state_by     text null,
    manual_auto_timeout_left integer null,
    request_time             timestamp with time zone not null,
    db_update_time           timestamp with time zone not null
);

# select control_name, request_time, current_state, current_value from control_status where id in ( select max(id) from control_status group by control_name );



GRANT SELECT ON control_status TO khaospy_read;
GRANT ALL    ON control_status TO khaospy_write;



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
--    '07786162000'
--
--)
--;

-- select * from users where passhash = crypt(:pass, passhash);

