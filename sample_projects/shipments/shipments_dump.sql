-- ============================================================
-- SHIPMENTS DATABASE DUMP
-- SQL Dialect: MariaDB/MySQL
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- DROP TABLES (in reverse order to handle dependencies)
-- ============================================================

DROP TABLE IF EXISTS shipments;
DROP TABLE IF EXISTS cars;
DROP TABLE IF EXISTS client_zone_price;
DROP TABLE IF EXISTS drivers;
DROP TABLE IF EXISTS clients;
DROP TABLE IF EXISTS rates;
DROP TABLE IF EXISTS addressees;
DROP TABLE IF EXISTS address_districts;
DROP TABLE IF EXISTS address_streets;
DROP TABLE IF EXISTS zones;
DROP TABLE IF EXISTS geolocation;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- TABLE CREATION
-- ============================================================

-- Parent tables first (no foreign keys)

CREATE TABLE zones (
    zone_id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(20) NOT NULL,
    PRIMARY KEY (zone_id)
);

CREATE TABLE address_streets (
    address_street_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    street_name VARCHAR(100) NOT NULL,
    PRIMARY KEY (address_street_id)
);

CREATE TABLE addressees (
    addressees_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    phone INT(9) UNSIGNED NOT NULL,
    phone_prefix VARCHAR(4) NOT NULL,
    national_id INT(8) UNSIGNED NOT NULL UNIQUE,
    national_id_verifier CHAR(1) NOT NULL,
    PRIMARY KEY (addressees_id),
    CONSTRAINT addressees_phone_len CHECK (CHAR_LENGTH(phone) = 9)
);

-- Address districts depends on zones and address_streets
CREATE TABLE address_districts (
    district_id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    address_street_id BIGINT UNSIGNED NOT NULL,
    zone_id TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (district_id),
    FOREIGN KEY (address_street_id) REFERENCES address_streets(address_street_id),
    FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
);

-- Rates table (may not be fully implemented)
CREATE TABLE rates (
    rate_id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(20) NOT NULL,
    price INT UNSIGNED NOT NULL,
    zone_id TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (rate_id),
    FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
);

-- Clients depends on address_streets and address_districts
CREATE TABLE clients (
    client_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    national_id INT(8) UNSIGNED NOT NULL UNIQUE,
    national_id_verifier CHAR(1) NOT NULL,
    name VARCHAR(50) NOT NULL,
    legal_name VARCHAR(50) NOT NULL,
    phone INT(9) UNSIGNED NOT NULL,
    phone_prefix VARCHAR(4) NOT NULL,
    credit_condition VARCHAR(10) NOT NULL,
    address_street_id BIGINT UNSIGNED NOT NULL,
    district_id SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (client_id),
    FOREIGN KEY (address_street_id) REFERENCES address_streets(address_street_id),
    FOREIGN KEY (district_id) REFERENCES address_districts(district_id),
    CONSTRAINT clients_phone_len CHECK (CHAR_LENGTH(phone) = 9)
);

-- Client zone price (replaces rates for client-specific pricing)
CREATE TABLE client_zone_price (
    client_id INT(10) UNSIGNED NOT NULL,
    zone_id TINYINT(3) UNSIGNED NOT NULL,
    price INT UNSIGNED NOT NULL,
    PRIMARY KEY (client_id, zone_id),
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
);

-- Drivers depends on address_streets and address_districts
CREATE TABLE drivers (
    driver_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    national_id INT(8) UNSIGNED NOT NULL UNIQUE,
    national_id_verifier CHAR(1) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    active BIT NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone INT(9) UNSIGNED NOT NULL,
    phone_prefix VARCHAR(4) NOT NULL,
    address_street_id BIGINT UNSIGNED NOT NULL,
    district_id SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (driver_id),
    FOREIGN KEY (address_street_id) REFERENCES address_streets(address_street_id),
    FOREIGN KEY (district_id) REFERENCES address_districts(district_id),
    CONSTRAINT drivers_phone_len CHECK (CHAR_LENGTH(phone) = 9)
);

-- Cars depends on drivers
CREATE TABLE cars (
    car_id VARCHAR(6) NOT NULL,
    car_model VARCHAR(20) NOT NULL,
    driver_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (car_id),
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id),
    CONSTRAINT car_id_len CHECK (CHAR_LENGTH(car_id) = 6)
);

-- Shipments depends on multiple tables
CREATE TABLE shipments (
    shipment_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    client_internal_id INT UNSIGNED NOT NULL,
    quantity INT UNSIGNED NOT NULL,
    status VARCHAR(10) NOT NULL,
    comments VARCHAR(255) NOT NULL,
    priority TINYINT UNSIGNED NOT NULL,
    delivery_date DATE NOT NULL,
    reception_date DATE NOT NULL,
    payment_comment VARCHAR(10) NOT NULL,
    shipment_type TINYINT UNSIGNED NOT NULL,
    driver_id INT UNSIGNED NOT NULL,
    client_id INT UNSIGNED NOT NULL,
    rate_id SMALLINT UNSIGNED NOT NULL,
    address_street_id BIGINT UNSIGNED NOT NULL,
    district_id SMALLINT UNSIGNED NOT NULL,
    addressees_id BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (shipment_id),
    UNIQUE (client_internal_id),
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id),
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (rate_id) REFERENCES rates(rate_id),
    FOREIGN KEY (address_street_id) REFERENCES address_streets(address_street_id),
    FOREIGN KEY (district_id) REFERENCES address_districts(district_id),
    FOREIGN KEY (addressees_id) REFERENCES addressees(addressees_id)
);

-- Geolocation (not fully implemented)
CREATE TABLE geolocation (
    address_street_id BIGINT UNSIGNED NOT NULL,
    district_id SMALLINT UNSIGNED NOT NULL,
    latitude DECIMAL(19,17) NOT NULL,
    longitude DECIMAL(19,17) NOT NULL,
    PRIMARY KEY (address_street_id, district_id),
    FOREIGN KEY (address_street_id) REFERENCES address_streets(address_street_id),
    FOREIGN KEY (district_id) REFERENCES address_districts(district_id)
);

-- ============================================================
-- DATA INSERTS (in parent-child order)
-- ============================================================

-- Zones
INSERT INTO zones (name) VALUES
    ('Zona 2'),
    ('Zona 3'),
    ('ZONE 5'),
    ('ZONE 6'),
    ('ZONE 7');

-- Address Streets
INSERT INTO address_streets (street_name) VALUES
    ('RIO DE JANEIRO 385'),
    ('LORETO 362'),
    ('PASAJE COCHABAMBA 332');

-- Address Districts (must reference existing zones and streets)
INSERT INTO address_districts (name, address_street_id, zone_id) VALUES
    ('CERRILLOS', 1, 1),
    ('CERRO NAVIA', 1, 1),
    ('CONCHALI', 1, 1),
    ('ESTACION CENTRAL', 1, 1),
    ('HUECHURABA', 1, 1),
    ('INDEPENDENCIA', 1, 1),
    ('LA CISTERNA', 1, 1),
    ('LA GRANJA', 1, 1),
    ('LA REINA', 1, 1),
    ('LO ESPEJO', 1, 1),
    ('LAS CONDES', 1, 1),
    ('MACUL', 1, 1),
    ('NUNOA', 1, 1),
    ('PEDRO AGUIRRE CERDA', 1, 1),
    ('PENALOLEN', 1, 1),
    ('PROVIDENCIA', 1, 1),
    ('QUINTA NORMAL', 1, 1),
    ('RECOLETA', 1, 1),
    ('SANTIAGO', 1, 1),
    ('SAN JOAQUIN', 1, 1),
    ('SAN MIGUEL', 1, 1),
    ('SAN RAMON', 1, 1),
    ('VITACURA', 1, 1),
    ('EL BOSQUE', 1, 2),
    ('LA FLORIDA', 1, 2),
    ('LA PINTANA', 1, 2),
    ('QUILICURA', 1, 2),
    ('LO BARNECHEA', 1, 3),
    ('MAIPU', 1, 3),
    ('PUDAHUEL', 1, 3),
    ('RENCA', 1, 3),
    ('SAN BERNARDO', 1, 3),
    ('PUENTE ALTO', 1, 3),
    ('PADRE HURTADO', 1, 3),
    ('COLINA', 1, 3);

-- Rates
INSERT INTO rates (name, price, zone_id) VALUES
    ('TFZ1', 3000, 1),
    ('TFZ2', 3500, 2),
    ('TFZ3', 4000, 3),
    ('TNFZ1', 3000, 1),
    ('TNFZ2', 3500, 2),
    ('TNFZ3', 4000, 3);

-- Addressees
INSERT INTO addressees (last_name, first_name, phone, phone_prefix, national_id, national_id_verifier) VALUES
    ('RODRIGUEZ', 'JESUS', 988475512, '+56', 24558889, 4),
    ('PEREZ', 'PEDRO', 966564412, '+56', 25448996, 6),
    ('LOPEZ', 'ALBERTO', 954412274, '+56', 25336958, 2),
    ('GONZALEZ', 'GUILLERMO', 999887336, '+56', 8776552, 8),
    ('JIMENEZ', 'MARIA', 999887336, '+56', 8876657, 5),
    ('GUTIERREZ', 'JUAN', 988722542, '+56', 3366553, 3),
    ('CABELLO', 'CAMILA', 983336625, '+56', 9337884, 2),
    ('ALLEL', 'FRANCO', 977662552, '+56', 8833766, 1);

-- Clients
INSERT INTO clients (national_id, national_id_verifier, name, legal_name, phone, phone_prefix, credit_condition, address_street_id, district_id) VALUES
    (76452889, 8, 'LOS AMIGOS SHOP', 'LOS AMIGOS SPA', 955442217, '+56', 'CONTADO', 1, 21),
    (74112458, 4, 'LA PERFUMERIA', 'LA PERFUMERIA LTDA', 944122787, '+56', 'CONTADO', 1, 21),
    (72112336, 5, 'LA REPRESA', 'LA REPRESA Y ASOCIADOS EIRL', 922586634, '+56', 'CREDITO', 1, 21);

-- Client Zone Prices
INSERT INTO client_zone_price (client_id, zone_id, price) VALUES
    (1, 1, 3000),
    (1, 2, 3500),
    (1, 3, 4000),
    (2, 1, 2800),
    (2, 2, 3000),
    (2, 3, 3500),
    (3, 1, 2800),
    (3, 2, 2800),
    (3, 3, 2800);

-- Drivers
INSERT INTO drivers (national_id, national_id_verifier, first_name, last_name, active, email, phone, phone_prefix, address_street_id, district_id) VALUES
    (26454887, 5, 'GUILLERMO', 'LEON', 1, 'emailejemplo@ejemplo.com', 988577444, '+56', 3, 30),
    (26551228, 5, 'ALBERTO', 'RODRIGUEZ', 1, 'emailejemplo2@ejemplo.com', 966749512, '+56', 1, 21);

-- Cars
INSERT INTO cars (car_id, car_model, driver_id) VALUES
    ('XXTD645', 'Chevrolet prius', 1),
    ('FGJH475', 'Chevrolet NPR400', 2);

-- Shipments
INSERT INTO shipments (client_internal_id, quantity, status, comments, priority, delivery_date, reception_date, payment_comment, shipment_type, driver_id, client_id, rate_id, address_street_id, district_id, addressees_id) VALUES
    (1, 1, 'RECEIVED', 'faucibus orci luctus et ultrices', 2, '2021-05-26', '2021-05-27', 'PAID', 1, 1, 2, 5, 2, 13, 1),
    (2, 2, 'SEND', 'eget magna. Suspendisse tristique', 5, '2021-05-28', '2021-05-27', 'PAID', 3, 1, 2, 7, 12, 28, 2),
    (3, 1, 'RESCHEDULED', 'montes', 3, '2021-05-26', '2021-05-27', 'PAID', 3, 2, 1, 6, 13, 5, 3),
    (4, 1, 'RECEIVED', 'sagittis lobortis mauris', 5, '2021-05-27', '2021-05-27', 'PAID', 2, 2, 1, 3, 4, 27, 1),
    (5, 2, 'RETURNED', 'Curae Donec tincidunt. Donec vitae', 4, '2021-05-28', '2021-05-27', 'PAID', 1, 2, 3, 8, 11, 2, 3);

-- Geolocation (sample data)
INSERT INTO geolocation (address_street_id, district_id, latitude, longitude) VALUES
    (1, 1, -33.448890, -70.669265),
    (1, 2, -33.457890, -70.679265),
    (1, 3, -33.438890, -70.659265);

/* Esta información viene de un repositorio en github, si no funciona lo que acá se muestra lo mejor es clonar el SQL de ese repositorio*/

DROP TABLE IF EXISTS `dim_comuna`;
CREATE TABLE `dim_comuna` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `comuna` varchar(64) NOT NULL,
    `provincia_id` int(11) NOT NULL,
    PRIMARY KEY (`id`)
);
INSERT INTO `dim_comuna` (`id`, `comuna`, `provincia_id`)
VALUES (1, 'Arica', 1),
    (2, 'Camarones', 1),
    (3, 'General Lagos', 2),
    (4, 'Putre', 2),
    (5, 'Alto Hospicio', 3),
    (6, 'Iquique', 3),
    (7, 'Camiña', 4),
    (8, 'Colchane', 4),
    (9, 'Huara', 4),
    (10, 'Pica', 4),
    (11, 'Pozo Almonte', 4),
    (12, 'Tocopilla', 5),
    (13, 'María Elena', 5),
    (14, 'Calama', 6),
    (15, 'Ollague', 6),
    (16, 'San Pedro de Atacama', 6),
    (17, 'Antofagasta', 7),
    (18, 'Mejillones', 7),
    (19, 'Sierra Gorda', 7),
    (20, 'Taltal', 7),
    (21, 'Chañaral', 8),
    (22, 'Diego de Almagro', 8),
    (23, 'Copiapó', 9),
    (24, 'Caldera', 9),
    (25, 'Tierra Amarilla', 9),
    (26, 'Vallenar', 10),
    (27, 'Alto del Carmen', 10),
    (28, 'Freirina', 10),
    (29, 'Huasco', 10),
    (30, 'La Serena', 11),
    (31, 'Coquimbo', 11),
    (32, 'Andacollo', 11),
    (33, 'La Higuera', 11),
    (34, 'Paihuano', 11),
    (35, 'Vicuña', 11),
    (36, 'Ovalle', 12),
    (37, 'Combarbalá', 12),
    (38, 'Monte Patria', 12),
    (39, 'Punitaqui', 12),
    (40, 'Río Hurtado', 12),
    (41, 'Illapel', 13),
    (42, 'Canela', 13),
    (43, 'Los Vilos', 13),
    (44, 'Salamanca', 13),
    (45, 'La Ligua', 14),
    (46, 'Cabildo', 14),
    (47, 'Zapallar', 14),
    (48, 'Papudo', 14),
    (49, 'Petorca', 14),
    (50, 'Los Andes', 15),
    (51, 'San Esteban', 15),
    (52, 'Calle Larga', 15),
    (53, 'Rinconada', 15),
    (54, 'San Felipe', 16),
    (55, 'Llaillay', 16),
    (56, 'Putaendo', 16),
    (57, 'Santa María', 16),
    (58, 'Catemu', 16),
    (59, 'Panquehue', 16),
    (60, 'Quillota', 17),
    (61, 'La Cruz', 17),
    (62, 'La Calera', 17),
    (63, 'Nogales', 17),
    (64, 'Hijuelas', 17),
    (65, 'Valparaíso', 18),
    (66, 'Viña del Mar', 18),
    (67, 'Concón', 18),
    (68, 'Quintero', 18),
    (69, 'Puchuncaví', 18),
    (70, 'Casablanca', 18),
    (71, 'Juan Fernández', 18),
    (72, 'San Antonio', 19),
    (73, 'Cartagena', 19),
    (74, 'El Tabo', 19),
    (75, 'El Quisco', 19),
    (76, 'Algarrobo', 19),
    (77, 'Santo Domingo', 19),
    (78, 'Isla de Pascua', 20),
    (79, 'Quilpué', 21),
    (80, 'Limache', 21),
    (81, 'Olmué', 21),
    (82, 'Villa Alemana', 21),
    (83, 'Colina', 22),
    (84, 'Lampa', 22),
    (85, 'Tiltil', 22),
    (86, 'Santiago', 23),
    (87, 'Vitacura', 23),
    (88, 'San Ramón', 23),
    (89, 'San Miguel', 23),
    (90, 'San Joaquín', 23),
    (91, 'Renca', 23),
    (92, 'Recoleta', 23),
    (93, 'Quinta Normal', 23),
    (94, 'Quilicura', 23),
    (95, 'Pudahuel', 23),
    (96, 'Providencia', 23),
    (97, 'Peñalolén', 23),
    (98, 'Pedro Aguirre Cerda', 23),
    (99, 'Ñuñoa', 23),
    (100, 'Maipú', 23),
    (101, 'Macul', 23),
    (102, 'Lo Prado', 23),
    (103, 'Lo Espejo', 23),
    (104, 'Lo Barnechea', 23),
    (105, 'Las Condes', 23),
    (106, 'La Reina', 23),
    (107, 'La Pintana', 23),
    (108, 'La Granja', 23),
    (109, 'La Florida', 23),
    (110, 'La Cisterna', 23),
    (111, 'Independencia', 23),
    (112, 'Huechuraba', 23),
    (113, 'Estación Central', 23),
    (114, 'El Bosque', 23),
    (115, 'Conchalí', 23),
    (116, 'Cerro Navia', 23),
    (117, 'Cerrillos', 23),
    (118, 'Puente Alto', 24),
    (119, 'San José de Maipo', 24),
    (120, 'Pirque', 24),
    (121, 'San Bernardo', 25),
    (122, 'Buin', 25),
    (123, 'Paine', 25),
    (124, 'Calera de Tango', 25),
    (125, 'Melipilla', 26),
    (126, 'Alhué', 26),
    (127, 'Curacaví', 26),
    (128, 'María Pinto', 26),
    (129, 'San Pedro', 26),
    (130, 'Isla de Maipo', 27),
    (131, 'El Monte', 27),
    (132, 'Padre Hurtado', 27),
    (133, 'Peñaflor', 27),
    (134, 'Talagante', 27),
    (135, 'Codegua', 28),
    (136, 'Coínco', 28),
    (137, 'Coltauco', 28),
    (138, 'Doñihue', 28),
    (139, 'Graneros', 28),
    (140, 'Las Cabras', 28),
    (141, 'Machalí', 28),
    (142, 'Malloa', 28),
    (143, 'Mostazal', 28),
    (144, 'Olivar', 28),
    (145, 'Peumo', 28),
    (146, 'Pichidegua', 28),
    (147, 'Quinta de Tilcoco', 28),
    (148, 'Rancagua', 28),
    (149, 'Rengo', 28),
    (150, 'Requínoa', 28),
    (151, 'San Vicente de Tagua Tagua', 28),
    (152, 'Chépica', 29),
    (153, 'Chimbarongo', 29),
    (154, 'Lolol', 29),
    (155, 'Nancagua', 29),
    (156, 'Palmilla', 29),
    (157, 'Peralillo', 29),
    (158, 'Placilla', 29),
    (159, 'Pumanque', 29),
    (160, 'San Fernando', 29),
    (161, 'Santa Cruz', 29),
    (162, 'La Estrella', 30),
    (163, 'Litueche', 30),
    (164, 'Marchigüe', 30),
    (165, 'Navidad', 30),
    (166, 'Paredones', 30),
    (167, 'Pichilemu', 30),
    (168, 'Curicó', 31),
    (169, 'Hualañé', 31),
    (170, 'Licantén', 31),
    (171, 'Molina', 31),
    (172, 'Rauco', 31),
    (173, 'Romeral', 31),
    (174, 'Sagrada Familia', 31),
    (175, 'Teno', 31),
    (176, 'Vichuquén', 31),
    (177, 'Talca', 32),
    (178, 'San Clemente', 32),
    (179, 'Pelarco', 32),
    (180, 'Pencahue', 32),
    (181, 'Maule', 32),
    (182, 'San Rafael', 32),
    (183, 'Curepto', 33),
    (184, 'Constitución', 32),
    (185, 'Empedrado', 32),
    (186, 'Río Claro', 32),
    (187, 'Linares', 33),
    (188, 'San Javier', 33),
    (189, 'Parral', 33),
    (190, 'Villa Alegre', 33),
    (191, 'Longaví', 33),
    (192, 'Colbún', 33),
    (193, 'Retiro', 33),
    (194, 'Yerbas Buenas', 33),
    (195, 'Cauquenes', 34),
    (196, 'Chanco', 34),
    (197, 'Pelluhue', 34),
    (198, 'Bulnes', 35),
    (199, 'Chillán', 35),
    (200, 'Chillán Viejo', 35),
    (201, 'El Carmen', 35),
    (202, 'Pemuco', 35),
    (203, 'Pinto', 35),
    (204, 'Quillón', 35),
    (205, 'San Ignacio', 35),
    (206, 'Yungay', 35),
    (207, 'Cobquecura', 36),
    (208, 'Coelemu', 36),
    (209, 'Ninhue', 36),
    (210, 'Portezuelo', 36),
    (211, 'Quirihue', 36),
    (212, 'Ránquil', 36),
    (213, 'Treguaco', 36),
    (214, 'San Carlos', 37),
    (215, 'Coihueco', 37),
    (216, 'San Nicolás', 37),
    (217, 'Ñiquén', 37),
    (218, 'San Fabián', 37),
    (219, 'Alto Biobío', 38),
    (220, 'Antuco', 38),
    (221, 'Cabrero', 38),
    (222, 'Laja', 38),
    (223, 'Los Ángeles', 38),
    (224, 'Mulchén', 38),
    (225, 'Nacimiento', 38),
    (226, 'Negrete', 38),
    (227, 'Quilaco', 38),
    (228, 'Quilleco', 38),
    (229, 'San Rosendo', 38),
    (230, 'Santa Bárbara', 38),
    (231, 'Tucapel', 38),
    (232, 'Yumbel', 38),
    (233, 'Concepción', 39),
    (234, 'Coronel', 39),
    (235, 'Chiguayante', 39),
    (236, 'Florida', 39),
    (237, 'Hualpén', 39),
    (238, 'Hualqui', 39),
    (239, 'Lota', 39),
    (240, 'Penco', 39),
    (241, 'San Pedro de La Paz', 39),
    (242, 'Santa Juana', 39),
    (243, 'Talcahuano', 39),
    (244, 'Tomé', 39),
    (245, 'Arauco', 40),
    (246, 'Cañete', 40),
    (247, 'Contulmo', 40),
    (248, 'Curanilahue', 40),
    (249, 'Lebu', 40),
    (250, 'Los Álamos', 40),
    (251, 'Tirúa', 40),
    (252, 'Angol', 41),
    (253, 'Collipulli', 41),
    (254, 'Curacautín', 41),
    (255, 'Ercilla', 41),
    (256, 'Lonquimay', 41),
    (257, 'Los Sauces', 41),
    (258, 'Lumaco', 41),
    (259, 'Purén', 41),
    (260, 'Renaico', 41),
    (261, 'Traiguén', 41),
    (262, 'Victoria', 41),
    (263, 'Temuco', 42),
    (264, 'Carahue', 42),
    (265, 'Cholchol', 42),
    (266, 'Cunco', 42),
    (267, 'Curarrehue', 42),
    (268, 'Freire', 42),
    (269, 'Galvarino', 42),
    (270, 'Gorbea', 42),
    (271, 'Lautaro', 42),
    (272, 'Loncoche', 42),
    (273, 'Melipeuco', 42),
    (274, 'Nueva Imperial', 42),
    (275, 'Padre Las Casas', 42),
    (276, 'Perquenco', 42),
    (277, 'Pitrufquén', 42),
    (278, 'Pucón', 42),
    (279, 'Saavedra', 42),
    (280, 'Teodoro Schmidt', 42),
    (281, 'Toltén', 42),
    (282, 'Vilcún', 42),
    (283, 'Villarrica', 42),
    (284, 'Valdivia', 43),
    (285, 'Corral', 43),
    (286, 'Lanco', 43),
    (287, 'Los Lagos', 43),
    (288, 'Máfil', 43),
    (289, 'Mariquina', 43),
    (290, 'Paillaco', 43),
    (291, 'Panguipulli', 43),
    (292, 'La Unión', 44),
    (293, 'Futrono', 44),
    (294, 'Lago Ranco', 44),
    (295, 'Río Bueno', 44),
    (296, 'Osorno', 45),
    (297, 'Puerto Octay', 45),
    (298, 'Purranque', 45),
    (299, 'Puyehue', 45),
    (300, 'Río Negro', 45),
    (301, 'San Juan de la Costa', 45),
    (302, 'San Pablo', 45),
    (303, 'Calbuco', 46),
    (304, 'Cochamó', 46),
    (305, 'Fresia', 46),
    (306, 'Frutillar', 46),
    (307, 'Llanquihue', 46),
    (308, 'Los Muermos', 46),
    (309, 'Maullín', 46),
    (310, 'Puerto Montt', 46),
    (311, 'Puerto Varas', 46),
    (312, 'Ancud', 47),
    (313, 'Castro', 47),
    (314, 'Chonchi', 47),
    (315, 'Curaco de Vélez', 47),
    (316, 'Dalcahue', 47),
    (317, 'Puqueldón', 47),
    (318, 'Queilén', 47),
    (319, 'Quellón', 47),
    (320, 'Quemchi', 47),
    (321, 'Quinchao', 47),
    (322, 'Chaitén', 48),
    (323, 'Futaleufú', 48),
    (324, 'Hualaihué', 48),
    (325, 'Palena', 48),
    (326, 'Lago Verde', 49),
    (327, 'Coihaique', 49),
    (328, 'Aysén', 50),
    (329, 'Cisnes', 50),
    (330, 'Guaitecas', 50),
    (331, 'Río Ibáñez', 51),
    (332, 'Chile Chico', 51),
    (333, 'Cochrane', 52),
    (334, 'OHiggins', 52),
    (335, 'Tortel', 52),
    (336, 'Natales', 53),
    (337, 'Torres del Paine', 53),
    (338, 'Laguna Blanca', 54),
    (339, 'Punta Arenas', 54),
    (340, 'Río Verde', 54),
    (341, 'San Gregorio', 54),
    (342, 'Porvenir', 55),
    (343, 'Primavera', 55),
    (344, 'Timaukel', 55),
    (345, 'Cabo de Hornos', 56),
    (346, 'Antártica', 56);
DROP TABLE IF EXISTS `dim_provincia`;
CREATE TABLE `dim_provincia` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `provincia` varchar(64) NOT NULL,
    `region_id` int(11) NOT NULL,
    PRIMARY KEY (`id`)
);
INSERT INTO `dim_provincia` (`id`, `provincia`, `region_id`)
VALUES (1, 'Arica', 1),
    (2, 'Parinacota', 1),
    (3, 'Iquique', 2),
    (4, 'El Tamarugal', 2),
    (5, 'Tocopilla', 3),
    (6, 'El Loa', 3),
    (7, 'Antofagasta', 3),
    (8, 'Chañaral', 4),
    (9, 'Copiapó', 4),
    (10, 'Huasco', 4),
    (11, 'Elqui', 5),
    (12, 'Limarí', 5),
    (13, 'Choapa', 5),
    (14, 'Petorca', 6),
    (15, 'Los Andes', 6),
    (16, 'San Felipe de Aconcagua', 6),
    (17, 'Quillota', 6),
    (18, 'Valparaiso', 6),
    (19, 'San Antonio', 6),
    (20, 'Isla de Pascua', 6),
    (21, 'Marga Marga', 6),
    (22, 'Chacabuco', 7),
    (23, 'Santiago', 7),
    (24, 'Cordillera', 7),
    (25, 'Maipo', 7),
    (26, 'Melipilla', 7),
    (27, 'Talagante', 7),
    (28, 'Cachapoal', 8),
    (29, 'Colchagua', 8),
    (30, 'Cardenal Caro', 8),
    (31, 'Curicó', 9),
    (32, 'Talca', 9),
    (33, 'Linares', 9),
    (34, 'Cauquenes', 9),
    (35, 'Diguillín', 10),
    (36, 'Itata', 10),
    (37, 'Punilla', 10),
    (38, 'Bio Bío', 11),
    (39, 'Concepción', 11),
    (40, 'Arauco', 11),
    (41, 'Malleco', 12),
    (42, 'Cautín', 12),
    (43, 'Valdivia', 13),
    (44, 'Ranco', 13),
    (45, 'Osorno', 14),
    (46, 'Llanquihue', 14),
    (47, 'Chiloé', 14),
    (48, 'Palena', 14),
    (49, 'Coyhaique', 15),
    (50, 'Aysén', 15),
    (51, 'General Carrera', 15),
    (52, 'Capitán Prat', 15),
    (53, 'Última Esperanza', 16),
    (54, 'Magallanes', 16),
    (55, 'Tierra del Fuego', 16),
    (56, 'Antártica Chilena', 16);
DROP TABLE IF EXISTS `dim_region`;
CREATE TABLE `dim_region` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `region` varchar(64) NOT NULL,
    `abreviatura` varchar(4) NOT NULL,
    `capital` varchar(64) NOT NULL,
    PRIMARY KEY (`id`)
);
INSERT INTO `dim_region` (`id`, `region`, `abreviatura`, `capital`)
VALUES (1, 'Arica y Parinacota', 'AP', 'Arica'),
    (2, 'Tarapacá', 'TA', 'Iquique'),
    (3, 'Antofagasta', 'AN', 'Antofagasta'),
    (4, 'Atacama', 'AT', 'Copiapó'),
    (5, 'Coquimbo', 'CO', 'La Serena'),
    (6, 'Valparaiso', 'VA', 'valparaíso'),
    (7, 'Metropolitana de Santiago', 'RM', 'Santiago'),
    (8,'Libertador General Bernardo OHiggins','OH','Rancagua'),
    (9, 'Maule', 'MA', 'Talca'),
    (10, 'Ñuble', 'NB', 'Chillán'),
    (11, 'Biobío', 'BI', 'Concepción'),
    (12, 'La Araucanía', 'IAR', 'Temuco'),
    (13, 'Los Ríos', 'LR', 'Valdivia'),
    (14, 'Los Lagos', 'LL', 'Puerto Montt'),
    (15,'Aysén del General Carlos Ibáñez del Campo','AI','Coyhaique'),
    (16,'Magallanes y de la Antártica Chilena','MG','Punta Arenas');

DROP TABLE IF EXISTS dim_location;
CREATE TABLE dim_location (
    id INT PRIMARY KEY AUTO_INCREMENT,
    country VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    municipality VARCHAR(100)
);
INSERT INTO dim_location (country, state, municipality)
SELECT 
	'Chile' AS country,
    r.region AS state,
    c.comuna AS municipality
FROM comuna c
    JOIN provincia p ON c.provincia_id = p.id
    JOIN region r ON p.region_id = r.id;

- TODO:
- Recrear esto en sqlite a ver si es posible
- crear un dump pero con data erronea, con problemas, para crear un pipeline bronze, silver, gold, practicar limpieza y todo eso