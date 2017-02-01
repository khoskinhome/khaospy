
--CREATE DATABASE IF NOT EXISTS khaospy ;
CREATE DATABASE khaospy ;
\c khaospy;

BEGIN;

\set ON_ERROR_STOP

--TODO make something error if we are not in a blank Database.

--To be honest the code is currently only using khaospy_write user (role)
--but I'm leaving khaospy_read in for things that might connect read-only.

CREATE USER khaospy_read  with LOGIN;
CREATE USER khaospy_write with LOGIN;

--TODO get Ansible to set these passwords so they don't get
-- left as defaults.
ALTER USER khaospy_read WITH PASSWORD 'changepassword';
ALTER USER khaospy_write WITH PASSWORD 'changepassword';

REVOKE CONNECT ON DATABASE khaospy FROM PUBLIC;
--REVOKE
GRANT  CONNECT ON DATABASE khaospy TO khaospy_read;
-- GRANT
GRANT  CONNECT ON DATABASE khaospy TO khaospy_write;


-- http://stackoverflow.com/questions/2647158/how-can-i-hash-passwords-in-postgresql
-- sql command inside of psql enable the crypto:
-- create extension pgcrypto
-- This needs I believe the extra apt packages postgresql-contrib libpq-dev
-- installed with something like this (along with postgres)
--      sudo apt-get install postgresql postgresql-contrib libpq-dev
CREATE EXTENSION IF NOT EXISTS pgcrypto;

---------------------
-- control_types
---------------------

-- CITEXT for case-insensitive UNIQUE constraints on TEXT fields.
CREATE EXTENSION IF NOT EXISTS CITEXT;

CREATE TABLE control_types (
    control_type CITEXT PRIMARY KEY NOT NULL
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
-- TODO in the Ansible setup.
INSERT INTO control_types VALUES
    ('orvibos20'),
    ('onewire-thermometer'),

    ('pi-gpio-relay-manual'),
    ('pi-gpio-relay'),
    ('pi-gpio-switch'),

    ('pi-mcp23017-relay-manual'),
    ('pi-mcp23017-relay'),
    ('pi-mcp23017-switch'),

    ('webui-var-float'),
    ('webui-var-integer'),
    ('webui-var-string'),
    ('mac-switch')
;

---------------------
-- controls
---------------------
CREATE SEQUENCE controls_seq;
GRANT SELECT ON controls_seq TO khaospy_read;
GRANT ALL    ON controls_seq TO khaospy_write;

CREATE TABLE controls (
    id INTEGER UNIQUE DEFAULT nextval('controls_seq') NOT NULL,
    control_name             CITEXT PRIMARY KEY NOT NULL,
    alias                    TEXT,
    control_type             CITEXT REFERENCES control_types NOT NULL,
    -- some times controls will be null(orviboS20s can be an issue) :
    current_state            TEXT,
    last_lowest_state_time   TIMESTAMP WITH TIME ZONE,
    last_lowest_state        TEXT,
    last_highest_state_time  TIMESTAMP WITH TIME ZONE,
    last_highest_state       TEXT,
    -- config_json will eventually be NOT NULL
    config_json              CITEXT,

    -- both these should be NOT NULL :
    last_change_state_time   TIMESTAMP WITH TIME ZONE,
    last_change_state_by     TEXT,
    manual_auto_timeout_left REAL,

    request_time             TIMESTAMP WITH TIME ZONE NOT NULL,
    db_update_time           TIMESTAMP WITH TIME ZONE NOT NULL
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
    control_name             CITEXT REFERENCES controls (control_name) NOT NULL,
    current_state            TEXT,
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

-- select control_name, request_time, current_state from control_status where id in ( select max(id) from control_status group by control_name );

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
    name    CITEXT NOT NULL UNIQUE,
    tag     CITEXT NOT NULL UNIQUE
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
    room_id       INTEGER NOT NULL REFERENCES rooms ON DELETE CASCADE,
    control_id    INTEGER NOT NULL REFERENCES controls (id) ON DELETE CASCADE,
    CONSTRAINT    u_control_rooms UNIQUE ( control_id, room_id )
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
    username               CITEXT NOT NULL UNIQUE,
    name                   CITEXT NOT NULL,
    email                  CITEXT NOT NULL UNIQUE,
    mobile_phone           CITEXT UNIQUE,
    is_admin               BOOLEAN NOT NULL DEFAULT FALSE,
    is_enabled             BOOLEAN NOT NULL DEFAULT TRUE,
    is_api_user            BOOLEAN NOT NULL DEFAULT FALSE,
    can_remote             BOOLEAN NOT NULL DEFAULT FALSE,
    passhash               TEXT NOT NULL,
    passhash_expire        TIMESTAMP WITH TIME ZONE,
    passhash_must_change   BOOLEAN,
    email_confirm_hash     TEXT,
    phone_mac_control_name CITEXT REFERENCES controls (control_name)
);

--TODO user the phone_mac_control_name will only be settable by the administrator.

--TODO user to have a "home" room_id
--    this will be settable by the user or the administrator.
--    really need a pivot table user_home_rooms where the user or the admin
--    can define the standard rooms that display when the Webui "Room Status" is selected.

GRANT SELECT ON users TO khaospy_read;
GRANT ALL ON users TO khaospy_write;

---------------------
-- user_rooms
---------------------
CREATE SEQUENCE user_rooms_seq;
GRANT SELECT ON user_rooms_seq TO khaospy_read;
GRANT ALL ON user_rooms_seq TO khaospy_write;

CREATE TABLE user_rooms (

    id INTEGER PRIMARY KEY DEFAULT nextval('user_rooms_seq') NOT NULL,

    user_id         INTEGER NOT NULL REFERENCES users ON DELETE CASCADE,
    room_id         INTEGER NOT NULL REFERENCES rooms ON DELETE CASCADE,
    can_view        BOOLEAN NOT NULL DEFAULT TRUE,
    can_operate     BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT      u_user_rooms UNIQUE ( user_id, room_id )
);

GRANT SELECT ON user_rooms TO khaospy_read;
GRANT ALL    ON user_rooms TO khaospy_write;

-- TODO the Ansible setup should force the installer
-- to set a valid password.
-- could get the webui to enforce this password change :)

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

