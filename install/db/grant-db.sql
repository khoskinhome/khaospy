--REVOKE CONNECT ON DATABASE your_database FROM PUBLIC;
--
--GRANT CONNECT
--ON DATABASE database_name
--TO user_name;
--

--create the roles khaospy_read and khaospy_write

-- http://dba.stackexchange.com/questions/33943/granting-access-to-all-tables-for-a-user
-- http://serverfault.com/questions/48471/how-to-change-in-postgresql-password-of-the-user-using-sql

ALTER USER khaospy_read WITH PASSWORD 'password';

ALTER USER khaospy_write WITH PASSWORD 'password';

revoke connect on database khaospy from public;
--REVOKE
grant connect on database khaospy to khaospy_read;
-- GRANT
grant connect on database khaospy to khaospy_write;

