------------------------------------------
				-- STATUS
------------------------------------------
 
/*Create tables ok
 * CONSTRAINTS ok
 * Nulability constraints (nothing is nullable) ok
 * Unique Constraints ok
 * Foreign key constraints ok
 * 	UPDATE ON CASCADE
 * 	DELETE ON CASCADE
 * Check constraints ok
 */

------------------------------------------
				-- TIPS
------------------------------------------

/*   --ALTER TABLE can only be executed one at a time
 * 	 --WITH NOCHECK not supported by MySQL/MariaDB.
 * 	 --FOREIGN KEYS behaviour ON UPDATE / ON DELETE is RESTRIC / NO ACTION meaning that parent value can't be modified to preserve referencial integrity. Other behaviours are
 * 	 CASCADE, SET NULL. 
 * 		ON UPDATE: Esentially we don't mess with this because all of our Foreign keys are meant to be ID field and this aren't supposed to be modified, we modify
 * 				   we modify the dependent fields.
 * 		ON DELETE: Esentially, if we delete a parent entry we don't want CASCADE behaviour because entrys will be lost neither SET NULL because data will lost as well.
 * 	 -- The teacher makes an extensive verification of each constraint, but I think that he did that to meet his academic requirements, I even think that there 
 * 		are some constraints that he didn't verified. Where there is a behaviour that cannot be met with constraints then he used triggers or functions.
 * 	 -- Transactions: to insert values he uses transactions, we are going to use one and see if it works and how transaction fails. He uses BEGIN TRY - END TRY to handle errors
 * 		we aren't going to handle errors for now.
 * 
 * * */


------------------------------------------
				-- TABLE CREATION
------------------------------------------
/* Table name, field name, data type, data length, constraints (UNSIGNED, NOT NULL, DEFAULT, UNIQUE, INDEX, PRIMARY KEY, FOREIGN KEY, CHECK),
 * AUTO_INCREMENT property
 * */

CREATE TABLE app_users
(
  user_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  email VARCHAR(255) NOT NULL,
  national_id INT(8) UNSIGNED NOT NULL UNIQUE,
  national_id_verifier CHAR(1) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  first_name VARCHAR(50) NOT NULL,
  PRIMARY KEY (user_id)
);
CREATE TABLE zones
	(
	  zone_id TINYINT UNSIGNED  NOT NULL AUTO_INCREMENT,
	  name VARCHAR(20) NOT NULL,
	  PRIMARY KEY (zone_id)
	);
CREATE TABLE address_streets
	(
	  address_street_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	  street_name VARCHAR(100) NOT NULL,
	  PRIMARY KEY (address_street_id)
	);
CREATE TABLE addressees
	(
	  addressees_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	  last_name VARCHAR(50) NOT NULL,
	  first_name VARCHAR(50) NOT NULL,
	  phone INT(9) UNSIGNED NOT NULL,
	  	CONSTRAINT phone_constraint CHECK (CHAR_LENGTH(phone)=9),
	  phone_prefix VARCHAR(4) NOT NULL,
	  national_id INT(8) UNSIGNED NOT NULL UNIQUE,
	  national_id_verifier CHAR(1) NOT NULL,
	  PRIMARY KEY (addressees_id)
	);
CREATE TABLE address_districts
	(
	  district_id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
	  name VARCHAR(50) NOT NULL,
	  address_street_id BIGINT UNSIGNED NOT NULL,
	  zone_id TINYINT UNSIGNED NOT NULL,
	  PRIMARY KEY (district_id),
	  FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
	);
CREATE TABLE rates -- NOT implemented
	(
	  rate_id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
	  name VARCHAR(20) NOT NULL,
	  price INT UNSIGNED NOT NULL,
	  zone_id TINYINT UNSIGNED NOT NULL,
	  PRIMARY KEY (rate_id),
	  FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
	);
CREATE TABLE clients
	(
	  client_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
	  national_id INT(8) UNSIGNED NOT NULL UNIQUE,
	  national_id_verifier CHAR(1) NOT NULL,
	  name VARCHAR(50) NOT NULL,
	  legal_name VARCHAR(50) NOT NULL,
	  phone INT(9) UNSIGNED NOT NULL,
	  	CONSTRAINT car_id_len CHECK (CHAR_LENGTH(car_id)=6),
	  phone_prefix VARCHAR(4) NOT NULL,
	  credit_condition VARCHAR(10) NOT NULL,
	  address_street_id BIGINT UNSIGNED NOT NULL,
	  district_id SMALLINT UNSIGNED NOT NULL,
	  PRIMARY KEY (client_id),
	  FOREIGN KEY (address_street_id) REFERENCES address_streets(address_street_id),
	  FOREIGN KEY (district_id) REFERENCES address_districts( district_id)
	);
CREATE TABLE drivers
	(
	  driver_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
	  national_id INT(8) UNSIGNED NOT NULL UNIQUE,
	  national_id_verifier CHAR(1) NOT NULL,
	  first_name VARCHAR(50) NOT NULL,
	  last_name VARCHAR(50) NOT NULL,
	  active BIT NOT NULL,
	  email VARCHAR(255) NOT NULL,
	  phone INT(9) UNSIGNED NOT NULL,
	  	CONSTRAINT phone_constraint CHECK (CHAR_LENGTH(phone)=9),
	  phone_prefix VARCHAR(4) NOT NULL,
	  address_street_id BIGINT UNSIGNED NOT NULL,
	  district_id SMALLINT UNSIGNED NOT NULL,
	  PRIMARY KEY (driver_id),
	  FOREIGN KEY (address_street_id) REFERENCES address_streets(address_street_id),
	  FOREIGN KEY (district_id) REFERENCES address_districts( district_id)
	);
CREATE TABLE shipments
	(
	  shipment_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	  client_internal_id INT UNSIGNED NOT NULL,
	  quantity INT UNSIGNED NOT NULL,
	  status VARCHAR(10) NOT NULL,
	  comments VARCHAR(255) NOT NULL,
	  priority TINYINT UNSIGNED NOT NULL, /*'Priority from 1 to 5*/
	  delivery_date DATE NOT NULL,
	  reception_date DATE NOT NULL,
	  payment_comment VARCHAR(10) NOT NULL,
	  shipment_type TINYINT UNSIGNED NOT NULL, /*Shipment_type 1 = flex, 2 = no flex'*/
	  driver_id INT UNSIGNED NOT NULL,
	  client_id INT UNSIGNED NOT NULL,
	  rate_id SMALLINT UNSIGNED NOT NULL,
	  address_street_id BIGINT UNSIGNED NOT NULL,
	  district_id SMALLINT UNSIGNED NOT NULL,
	  addressees_id BIGINT UNSIGNED NOT NULL,
	  PRIMARY KEY (shipment_id),
	  FOREIGN KEY (driver_id) REFERENCES drivers(driver_id),
	  FOREIGN KEY (client_id) REFERENCES clients(client_id),
	  FOREIGN KEY (rate_id) REFERENCES rates(rate_id),
	  FOREIGN KEY (address_street_id) REFERENCES address_streets(address_street_id),
	  FOREIGN KEY (district_id) REFERENCES address_districts( district_id),
	  FOREIGN KEY (addressees_id) REFERENCES addressees(addressees_id),
	  UNIQUE (client_internal_id)
	);
CREATE TABLE cars
(
  car_id VARCHAR(6) NOT NULL UNIQUE,
  	CONSTRAINT car_id_len CHECK (CHAR_LENGTH(car_id)=6),
  car_model VARCHAR(20) NOT NULL,
  driver_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (car_id),
  FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
);

CREATE TABLE geolocation -- not implemented
	(
	  latitude DECIMAL(19,17) NOT NULL,
	  longitude DECIMAL(19,17) NOT NULL,
	  CONSTRAINT prueba1 CHECK (CHAR_LENGTH(longitude)=5),
	  CONSTRAINT prueba2 CHECK (CHAR_LENGTH(latitude)=4),
	  address_street_id BIGINT UNSIGNED NOT NULL,
	  district_id SMALLINT UNSIGNED NOT NULL,
	  PRIMARY KEY (address_street_id, district_id),
	  CONSTRAINT fk_address_street_id FOREIGN KEY (address_street_id) REFERENCES address_streets(address_street_id)
	  	ON UPDATE CASCADE,
	  FOREIGN KEY (district_id) REFERENCES address_districts(district_id)
	);

CREATE TABLE client_zone_price (
client_id INT(10) UNSIGNED NOT NULL,
zone_id TINYINT(3) UNSIGNED NOT NULL,
price INT UNSIGNED NOT NULL,
FOREIGN KEY fk_client_id (client_id) REFERENCES clients(client_id),
FOREIGN KEY fk_zone_id (zone_id) REFERENCES zones(zone_id),
PRIMARY KEY (client_id, zone_id)
);


------------------------------------------
				-- DROP TABLES
------------------------------------------

DROP TABLE clients
DROP TABLE district
DROP TABLE drivers
DROP TABLE rates
DROP TABLE shipments
DROP TABLE users
DROP TABLE zones
DROP TABLE geolocation

------------------------------------------
				-- DROP COLUMNS
------------------------------------------

ALTER TABLE geolocation  
	DROP COLUMN latitude,
	DROP COLUMN longitude; -- luego la columna si fuera necesario
	
------------------------------------------
			-- DROP CONSTRAINTS
------------------------------------------

ALTER TABLE drivers DROP CONSTRAINT IF EXISTS phone_driver;
ALTER TABLE addressees DROP CONSTRAINT IF EXISTS phone_prefix_constraint; -- check constraint
ALTER TABLE clients DROP CONSTRAINT IF EXISTS phone_prefix_constraint; -- check constraint
ALTER TABLE address_districts DROP CONSTRAINT IF EXISTS address_districts_ibfk_1; -- primero la foreign key
ALTER TABLE address_districts DROP COLUMN columnname; -- then the column if you want to drop it.
ALTER TABLE geolocation  DROP CONSTRAINT IF EXISTS prueba2;

------------------------------------------
			-- ALTER FIELD NAME OR PROPERTIES
------------------------------------------

ALTER TABLE shipments  CHANGE received_date reception_date date NOT NULL;

------------------------------------------
			-- CHECK CONSTRAINTS
------------------------------------------
 /*
 * 	LENGHT CONSTRAINTS
	 * 	Use cases
		 * Lower limit for positive numeric fields (> / >=). If you don't want the field to be negative use UNSIDEGNED on field def.
		 * To see if all the positive numeric fields are okay (UNSIGNED) you can SELECT all table fields and check.
		 * Exact lenght for numeric fields (=)
		
		Not to use
		 * Upper limit (<)  already set on field-table definition.
		 * Exact lenght for alphanumeric fields, use CHAR for that. Can't set lenght check constraints on varchar data types because of datatype definition.
		 * 
	SPECIFIC DATA CONSTRAINTS
		shipments(status, shipment_type)
		clients (credit condition)
		phone_prefix
		
		This fields are supposed to be filled with specific values. We could create a CHECK constraint to accomplish this but
		it could be cumbersome when trying to add a new specific values to enter. So we aren't going to restrict that field with a CHECK constraint. In the 
		first instance we could control this with a front end validation. Or we could create a separate table to store this specific values so we could add
		new ones every time we want and include a foreign key constraint to assure that only existing values are stored in the child table.
	
 * */

ALTER TABLE cars ADD CONSTRAINT car_id_len CHECK (CHAR_LENGTH(car_id)=6);
ALTER TABLE drivers ADD CONSTRAINT phone_constraint CHECK (CHAR_LENGTH(phone)=9);
ALTER TABLE addressees  ADD CONSTRAINT phone_constraint CHECK (CHAR_LENGTH(phone)=9);
ALTER TABLE clients  ADD CONSTRAINT phone_constraint CHECK (CHAR_LENGTH(phone)=9);

------------------------------------------
			-- UNIQUE CONSTRAINTS
------------------------------------------
ALTER TABLE cars ADD UNIQUE (car_id);


------------------------------------------
			-- FOREIGNKEY CONSTRAINTS
------------------------------------------

ALTER TABLE clients ADD FOREIGN KEY (district_id) REFERENCES address_districts(district_id);
ALTER TABLE drivers ADD FOREIGN KEY (district_id) REFERENCES address_districts(district_id);
ALTER TABLE shipments ADD FOREIGN KEY (district_id) REFERENCES address_districts(district_id);

ALTER TABLE clients ADD FOREIGN KEY (address_street_id) REFERENCES address_streets(address_street_id);
ALTER TABLE drivers ADD FOREIGN KEY (address_street_id) REFERENCES address_streets(address_street_id);
ALTER TABLE shipments ADD FOREIGN KEY (address_street_id) REFERENCES address_streets(address_street_id);


------------------------------------------
			-- UPDATES
------------------------------------------

UPDATE rates
SET price = 1001



------------------------------------------
			-- DATABASE INFORMATION
------------------------------------------

/*See all fields */
SELECT *
From INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA Like 'savinglc_personal_finance'

/*See all constraints */
SELECT * 
FROM information_schema.table_constraints
WHERE constraint_schema = 'savinglc_personal_finance'


SELECT * FROM clients;



