--ALTER TABLE control_status
--  ADD CONSTRAINT control_status_control_name_fkey FOREIGN KEY (control_name)
--      REFERENCES controls (control_name);


-- http://stackoverflow.com/questions/2647158/how-can-i-hash-passwords-in-postgresql

-- sudo apt-get install postgresql postgresql-contrib libpq-dev

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

