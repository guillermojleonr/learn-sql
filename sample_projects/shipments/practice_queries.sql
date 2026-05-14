-- Inner Join Test
SELECT * FROM zones INNER JOIN address_districts ON zones.zone_id = address_districts.zone_id 
1

-- ----------------------------------------------------------------
-- Inserting data into the tables to test inner joins --
-- ---------------------------------------------------------------



-- Select and insert on address_districts
SELECT * FROM address_districts ad 
INSERT INTO address_streets (street_name) VALUES 
("PASAJE VEINTISEIS 5006"),
("IRARRAZAVAL 108"),
("DIEZ DE JULIO HUAMACHUCO 22"),
("LAS PERDICES 6678"),
("PRESIDENTE KENNEDY 45"),
("CARMEN 8875"),
("LA CONCEPCION 5643"),
("LUZ 2537"),
("LOS PLATANOS 9526"),
("LAS LOMBRICES 6352");

-- Select and insert on addressees
SELECT * FROM addressees a 
INSERT INTO addressees (last_name, first_name, phone, phone_prefix, national_id, national_id_verifier) VALUES
("GONZALEZ", "GUILLERMO", 999887336,"+56",8776552,8),
("JIMENEZ", "MARIA", 999887336,"+56",8876657,5),
("GUTIERREZ", "JUAN", 988722542,"+56",3366553,3),
("CABELLO", "CAMILA", 983336625, "+56", 9337884,2),
("ALLEL", "FRANCO", 977662552, "+56", 8833766,1);


-- Select and insert on cars
SELECT * FROM cars c 
INSERT INTO cars(car_id,car_model,driver_id) VALUES
("GHJD67","Ford Fiesta",7),
("YHFG78","Toyota Corolla",8);

-- Select and insert on drivers
SELECT * FROM drivers d 
INSERT INTO drivers(national_id, national_id_verifier, first_name, last_name, active, email, phone, phone_prefix, address_street_id, district_id) VALUES
(23777334, 2, "ROBERTO", "PARLOLO", 1, "emailejemplo4@ejemplo.com", 933436675, "+56", 3, 5);
 
-- Select and insert on shipments
SELECT * FROM shipments s 
INSERT INTO `shipments` (`quantity`,`status`,`comments`,`priority`,`delivery_date`,`reception_date`,`shipment_type`,`driver_id`,`client_id`,`rate_id`,`address_street_id`,`district_id`,`addressees_id`)
VALUES
  (1,"RECEIVED","faucibus orci luctus et ultrices",2,"2021-05-26","2021-05-27",1,"7",2,5,2,13,8),
  (2,"SEND","eget magna. Suspendisse tristique",5,"2021-05-28","2021-05-27",3,"7",2,7,12,28,10),
  (1,"RESCHEDULED","montes,",3,"2021-05-26","2021-05-27",3,"8",1,6,13,5,6),
  (1,"RECEIVED","sagittis lobortis mauris.",5,"2021-05-27","2021-05-27",2,"3",1,3,4,27,11),
  (2,"RETURNED","Curae Donec tincidunt. Donec vitae",4,"2021-05-28","2021-05-27",1,"8",3,8,11,2,5);

-- ---------------------------------
-- INNER JOINS --
-- --------------------------------
 
 -- Drivers shipments daily summary
 SELECT d.first_name AS Firstname, d.last_name AS Lastname, Sum(s.quantity) AS "Grand total packages", COUNT(s.Quantity) AS "Grand total shipments"
 FROM drivers AS d INNER JOIN shipments AS s
 ON d.driver_id = s.driver_id
 WHERE delivery_date = "2021-12-26"
 GROUP BY d.first_name, d.last_name;

-- Drivers shipments by delivery date range (aggregated)
 SELECT d.first_name AS Firstname, d.last_name AS Lastname, Sum(s.quantity) AS "Grand total packages", COUNT(s.Quantity) AS "Grand total shipments"
 FROM drivers AS d INNER JOIN shipments AS s
 ON d.driver_id = s.driver_id
 WHERE delivery_date BETWEEN "2021-05-26" AND "2021-12-27"
 GROUP BY d.first_name, d.last_name;

-- Drivers shipments by delivery date range (detailed)
 SELECT s.delivery_date AS "Delivery date", 
 d.first_name AS Firstname, 
 d.last_name AS Lastname, 
 Sum(s.quantity) AS "Grand total packages", 
 COUNT(s.Quantity) AS "Grand total shipments"
 
 FROM drivers AS d INNER JOIN shipments AS s
 ON d.driver_id = s.driver_id
 WHERE delivery_date BETWEEN "2021-05-26" AND "2021-12-27"
 GROUP BY s.delivery_date;

-- Grand totals Shipments by date
SELECT s.delivery_date AS "Delivery Date", SUM(s.Quantity) AS "Grand total packages" , COUNT(s.Quantity) AS "Grand total shipments"
FROM shipments AS s
WHERE delivery_date BETWEEN "2021-12-26" AND "2021-12-27"
GROUP BY s.delivery_date;

-- Grand totals by client and delivery date range
SELECT c.Name AS "Client Name", SUM(r.price) AS "Grand total shipment value", SUM(s.Quantity) AS "Grand total packages" , COUNT(s.Quantity) AS "Grand total shipments"
FROM clients AS c 
INNER JOIN shipments AS s
ON c.client_id = s.client_id 
INNER JOIN rates AS r 
ON r.rate_id = s.rate_id
WHERE delivery_date BETWEEN "2021-12-26" AND "2021-12-27"
GROUP BY c.name;

-- -----------------------------------------------------
-- Shipments table cloning to test Union and Union ALL. This procedure has to be done carefully for resource consuming reasons
-- -----------------------------------------------------

-- Clone/Duplicate a table inheriting null and default definitions,  It does not inherit indexes and auto_increment definitions. 
CREATE TABLE shipments2 AS SELECT * FROM original_table;


-- This makes the structure of new_table exactly like that of original_table, but DOES NOT copy the data. To copy the data, you'll need INSERT ... SELECT:
CREATE TABLE shipments2  LIKE shipments;
INSERT INTO shipments2  SELECT * FROM shipments;
SELECT * FROM shipments2 -- 20 records

-- --------------------------------------------------------
-- UNION AND UNION ALL
-- --------------------------------------------------------

-- 20 records because UNION doesn't account for duplicate data
SELECT * FROM shipments s
UNION
SELECT * FROM shipments2 s2

-- 40 records because UNION ALL accounts for duplicate data
SELECT * FROM shipments s
UNION ALL
SELECT * FROM shipments2 s2

-- -----------------------------------------------------
-- SUBQUERIES or NESTED QUERIES
-- ----------------------------------------------------

-- Scalar Subquery returns a single value which is used by the parent query
SELECT * FROM shipments s2 WHERE priority > (SELECT AVG(PRIORITY) FROM shipments s);

-- Multiple row subqueries
	-- List subqueries: one column, multiple rows

	-- ALL operator requires the condition to be upper to ALL list values. 
	SELECT priority FROM shipments s2 WHERE priority > ALL(SELECT priority FROM shipments s WHERE priority BETWEEN 3 AND 4) 
	
	-- NOT IN
	SELECT priority FROM shipments s2 WHERE priority NOT IN(SELECT priority FROM shipments s WHERE priority BETWEEN 3 AND 4)
	
	-- IN
	SELECT priority FROM shipments s2 WHERE priority IN(SELECT priority FROM shipments s WHERE priority BETWEEN 3 AND 4)
	
	-- ANY operator requires the condition to be upper to ANY list value.
	SELECT priority FROM shipments s2 WHERE priority > ANY(SELECT priority FROM shipments s WHERE priority BETWEEN 3 AND 4)
	
	-- Table subqueries: multiple columns, multiple rows

	
-- Correlated subqueries: Inner query depends on outer query data.
	
	SELECT c.name, 
		(SELECT COUNT(s.quantity) 
		FROM shipments s
		WHERE c.client_id  = 2) AS "Shipments quantity"
	FROM clients c
-- Same results can get achiveved with JOINS, joins are generally faster than subqueries.

	
-- -----------------------------------------------------------------------
-- CROSS REFERENCE QUERIES NOT SUPPORTED IN MYSQL OR MARIADB, ONLY ACCESS
-- ------------------------------------------------------------------------

-- ------------------------------------------------------------------------
-- REDESIGN RATES AND PRICE TABLES, FIGURE HOW TO IMPLEMENT
-- --------------------------------------------------------------------

SELECT * FROM rates r -- Let's see rates table
ALTER TABLE shipments DROP CONSTRAINT shipments_ibfk_3; -- Drop child table foreign key constraint
DROP TABLE rates -- Now we can DROP the table

-- New price table creation
CREATE TABLE client_zone_price (
client_id INT(10) UNSIGNED NOT NULL,
zone_id TINYINT(3) UNSIGNED NOT NULL,
price INT UNSIGNED NOT NULL,
FOREIGN KEY fk_client_id (client_id) REFERENCES clients(client_id),
FOREIGN KEY fk_zone_id (zone_id) REFERENCES zones(zone_id),
PRIMARY KEY (client_id, zone_id)
);

SELECT * FROM clients -- 3 clients

SELECT * FROM zones z -- too many zones, let's delete some

-- deleting zones
DELETE FROM zones 
WHERE zone_id BETWEEN 5 AND 17;

-- Insert some prices

INSERT INTO client_zone_price(client_id, zone_id, price) VALUES
(1, 1, 3000),
(1, 2, 3500),
(1, 3, 4000),
(1, 4, 4000),
(2, 1, 2800),
(2, 2, 3000),
(2, 3, 3500),
(2, 4, 3500),
(3, 1, 2800),
(3, 2, 2800),
(3, 3, 2800),
(3, 4, 3500);

SELECT * FROM client_zone_price

-- Joins to calculate shipments grand totals with the new schema.

-- Price list
SELECT c.name "client name", z.name "zone name", czp.price "price"
FROM clients c
INNER JOIN
client_zone_price czp 
ON
c.client_id = czp.client_id
INNER JOIN
zones z 
ON
z.zone_id = czp.zone_id
ORDER BY c.name;

--
SELECT c.name "client name", z.name "zone name", SUM(czp.price)

FROM shipments s -- first INNER JOIN to retrieve c.name, helps to connect s with c
INNER JOIN 
clients c 
ON
s.client_id = c.client_id

INNER JOIN -- second INNER JOIN, doesn't retrieve any field but helps to connect s with ad
address_districts ad 
ON
ad.district_id = s.district_id

INNER JOIN -- third INNER JOIN helps to retrieve z.name, helps to connect ad with z
zones z 
ON
ad.zone_id = z.zone_id 

INNER JOIN -- retrieve price, connects z with czp and c with czp
client_zone_price czp 
ON
czp.zone_id = z.zone_id AND
czp.client_id = c.client_id

GROUP BY c.name, z.name


INNER JOIN
client_zone_price czp 
-- -------------------------------------------------------------
-- TRANSACTIONS
-- --------------------------------------------------------------

-- Transactions can be executed by highlighting all statements and the pressing "Excecute SQL Script (ALT + X)"
-- Also can be executed line by line.
START TRANSACTION
INSERT INTO drivers(national_id, national_id_verifier, first_name, last_name, active, email, phone, phone_prefix, address_street_id, district_id) VALUES
(27887889, 2, "MATIAS", "PERRUOLO", 1, "emailejemplo5@ejemplo.com", 976546632, "+56", 2, 2)
ROLLBACK;

SELECT * FROM drivers d 

-- -------------------------------------------------------
-- VIEWS
-- ------------------------------------------------------

-- Create view
CREATE VIEW test_view AS
SELECT c.name "client name", z.name "zone name", czp.price "price"
FROM clients c
INNER JOIN
client_zone_price czp 
ON
c.client_id = czp.client_id
INNER JOIN
zones z 
ON
z.zone_id = czp.zone_id
ORDER BY c.name;

-- Select view
SELECT * FROM test_view

-- View columns
SELECT * FROM information_schema.columns WHERE table_name = 'test_view';

-- Select just one field from the view
SELECT `client name` FROM test_view t; -- Spaces in field name enforces to use backticks 

SHOW VARIABLES LIKE '%ssl%'`


