-- Show the current grants for the current user
SHOW GRANTS;

-- 1. Privilegios globales sobre todas las bases de datos (*.*)
GRANT RELOAD,
SHOW DATABASES,
REPLICATION SLAVE,
REPLICATION CLIENT ON *.* TO 'savinglc_querier_reader' @'%';

-- 2. Privilegio SELECT sobre la base de datos específica
GRANT
SELECT ON savinglc_querier.* TO 'savinglc_querier_reader' @'%';

-- user@host the host can be in the form of an IP address, a hostname, or a wildcard (%), in this case it is a wildcard meaning any host

-- Show the grants for the specific user for all databases of the database server
SHOW GRANTS FOR 'savinglc_querier_reader' @'%';

-- Show grants in a specific database
SHOW GRANTS FOR 'savinglc_querier_reader' @'%' ON savinglc_querier.*;
-- MariaDB/MySQL cannot use ON database_name.*

/* In the valefor database server you cannot see privileges from other users even if the user that is requesting the privileges has 'all' privileges on the database server, when you create an user in the database administrator 'all' privileges are not every existing privilege. Therefore you have to login as the user you want to inspect and check its privileges from within*/