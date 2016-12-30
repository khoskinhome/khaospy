BEGIN;

\set ON_ERROR_STOP

-- http://stackoverflow.com/questions/2647158/how-can-i-hash-passwords-in-postgresql

-- sudo apt-get install postgresql postgresql-contrib libpq-dev

-- sql command inside of psql enable the crypto:
-- create extension pgcrypto

---------------------
-- control_types
---------------------

CREATE TABLE control_types (
    control_type TEXT PRIMARY KEY NOT NULL
);
GRANT SELECT ON control_types TO khaospy_read;
GRANT ALL    ON control_types TO khaospy_write;

-- control_type is one of the following
-- enums from Khaospy::Constants :
--    $ORVIBOS20_CONTROL_TYPE
--    $ONEWIRE_THERM_CONTROL_TYPE
--    $PI_GPIO_RELAY_MANUAL_CONTROL_TYPE
--    $PI_GPIO_RELAY_CONTROL_TYPE
--    $PI_GPIO_SWITCH_CONTROL_TYPE
--    $PI_MCP23017_RELAY_MANUAL_CONTROL_TYPE
--    $PI_MCP23017_RELAY_CONTROL_TYPE
--    $PI_MCP23017_SWITCH_CONTROL_TYPE
--    $MAC_SWITCH_CONTROL_TYPE

-- TODO some way of populating this from the code :
INSERT INTO control_types VALUES
    ('orvibos20'),
    ('onewire-thermometer'),

    ('pi-gpio-relay-manual'),
    ('pi-gpio-relay'),
    ('pi-gpio-switch'),

    ('pi-mcp23017-relay-manual'),
    ('pi-mcp23017-relay'),
    ('pi-mcp23017-switch'),

    ('mac-switch')
;

---------------------
-- controls
---------------------
-- eventually control_type should be NOT NULL.

CREATE TABLE controls (
    control_name  TEXT PRIMARY KEY NOT NULL,
    alias         TEXT,
    control_type             TEXT REFERENCES control_types,
    current_state            TEXT,
    current_value            REAL,
    last_change_state_time   TIMESTAMP WITH TIME ZONE,
    last_change_state_by     TEXT,
    manual_auto_timeout_left REAL,
    request_time             TIMESTAMP WITH TIME ZONE,
    db_update_time           TIMESTAMP WITH TIME ZONE
);

GRANT SELECT ON controls TO khaospy_read;
GRANT ALL    ON controls TO khaospy_write;

----------------
-- control_status  ( should really be called control_log )
----------------
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


create index control_status_control_name_idx on control_status (control_name);



ALTER TABLE control_status SET (autovacuum_vacuum_scale_factor = 0.0);
ALTER TABLE control_status SET (autovacuum_vacuum_threshold = 5000);
ALTER TABLE control_status SET (autovacuum_analyze_scale_factor = 0.0);
ALTER TABLE control_status SET (autovacuum_analyze_threshold = 5000);

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

CREATE TABLE control_rooms (
    room_id       INTEGER NOT NULL REFERENCES rooms,
    control_name  TEXT NOT NULL REFERENCES controls,
    CONSTRAINT    u_control_rooms UNIQUE ( control_name, room_id )
);

GRANT SELECT ON control_rooms TO khaospy_read;
GRANT ALL    ON control_rooms TO khaospy_write;

---------------------
-- users
---------------------
CREATE SEQUENCE users_seq;
GRANT SELECT ON users_seq TO khaospy_read;
GRANT ALL ON users_seq TO khaospy_write;
CREATE TABLE users (
    id INTEGER PRIMARY KEY DEFAULT nextval('users_seq') NOT NULL,
    username                        TEXT NOT NULL UNIQUE,
    name                            TEXT NOT NULL UNIQUE,
    email                           TEXT NOT NULL UNIQUE,
    passhash                        TEXT NOT NULL,
    is_api_user                     BOOLEAN NOT NULL DEFAULT FALSE,
    is_admin                        BOOLEAN NOT NULL DEFAULT FALSE,
    mobile_phone                    TEXT NOT NULL UNIQUE,
    can_remote                      BOOLEAN NOT NULL DEFAULT FALSE,
    passhash_expire                 TIMESTAMP WITH TIME ZONE,
    passhash_must_change            BOOLEAN,
    email_confirm_hash              TEXT,
    is_enabled                      BOOLEAN NOT NULL DEFAULT TRUE
);
GRANT SELECT ON users TO khaospy_read;
GRANT ALL ON users TO khaospy_write;

---------------------
-- user_rooms
---------------------
CREATE TABLE user_rooms (
    user_id         INTEGER NOT NULL REFERENCES users,
    room_id         INTEGER NOT NULL REFERENCES rooms,
    can_view        BOOLEAN NOT NULL DEFAULT FALSE,
    can_operate     BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT      u_user_rooms UNIQUE ( user_id, room_id )
);

GRANT SELECT ON user_rooms TO khaospy_read;
GRANT ALL    ON user_rooms TO khaospy_write;

--ROLLBACK;

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

-- update users set passhash crypt('zz_apsswrd', gen_salt('bf', 8)) where id = ? ;

-- select * from users where passhash = crypt(:pass, passhash);

-- delete from  control_status where request_time < now() - interval '16 days';

