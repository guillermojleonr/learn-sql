-- Base de datos: `savinglc_personal_finance`
-- --------------------------------------------------------

-- Estructura de tabla para la tabla `category`
CREATE TABLE `category_1` (
  `id` VARCHAR(11) NOT NULL,
  `name` varchar(10) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Estructura de tabla para la tabla `category_2`
CREATE TABLE `category_2` (
  `id` VARCHAR(11) NOT NULL,
  `name` varchar(20) NOT NULL,
  `category_1` VARCHAR(11) NOT NULL,
  PRIMARY KEY (id),
  FOREIGN KEY (`category_1`) REFERENCES `category_1`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Estructura de tabla para la tabla `category_3`
CREATE TABLE `category_3` (
  `id` VARCHAR(11) NOT NULL,
  `name` varchar(20) NOT NULL,
  `category_2` VARCHAR(11) NOT NULL,
  PRIMARY KEY (id),
  FOREIGN KEY (`category_2`) REFERENCES `category_2`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Estructura de tabla para la tabla `account`
CREATE TABLE `account` (
  `name` varchar(50) NOT NULL,
  `id` VARCHAR(11) NOT NULL,
  `category_3` VARCHAR(11) NOT NULL,
  PRIMARY KEY (id),
  FOREIGN KEY (`category_3`) REFERENCES `category_3`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Estructura de tabla para la tabla `cost_center`
CREATE TABLE `cost_center` (
  `id` VARCHAR(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(20) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Estructura de tabla para la tabla `counterpart`
CREATE TABLE `counterpart` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Estructura de tabla para la tabla `currency`
CREATE TABLE `currency` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(11) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Estructura de tabla para la tabla `exchange_rate`
CREATE TABLE `exchange_rate` (
  `name` varchar(10) NOT NULL,
  `value` int(11) NOT NULL,
  `id_currency1` int(11) NOT NULL,
  `id_currency2` int(11) NOT NULL,
  PRIMARY KEY (name),
  FOREIGN KEY (`id_currency1`) REFERENCES `currency` (`id`),
  FOREIGN KEY (`id_currency2`) REFERENCES `currency` (`id`);
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Estructura de tabla para la tabla `finance_transactions`
CREATE TABLE `finance_transactions` (
  `ID` int(4) DEFAULT NULL,
  `FECHA` varchar(11) DEFAULT NULL,
  `DESCRIPCION` varchar(22) DEFAULT NULL,
  `DEBE` int(7) DEFAULT NULL,
  `HABER` int(7) DEFAULT NULL,
  `N DOC` varchar(10) DEFAULT NULL,
  `CUENTA` varchar(35) DEFAULT NULL,
  `MONEDA` varchar(3) DEFAULT NULL,
  `CENTRO DE COSTO` varchar(15) DEFAULT NULL,
  `CONTRAPARTE` varchar(23) DEFAULT NULL,
  `ID.RENDICION` varchar(2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Sample table storing finance transactions';


-- Drop constraints
ALTER TABLE category_2
  DROP CONSTRAINT `category_2_ibfk_1`;

ALTER TABLE category_3
  DROP CONSTRAINT `category_3_ibfk_1`;

ALTER TABLE account
  DROP CONSTRAINT account_ibfk_1;

ALTER TABLE exchange_rate
  DROP CONSTRAINT exchange_rate_ibfk_1;
  DROP CONSTRAINT exchange_rate_ibfk_2;

-- Drop tables

DROP TABLE category_1
DROP TABLE category_2
DROP TABLE category_3
DROP TABLE account

-- Populate category_1
INSERT INTO `category_1` (`id`,`name`) VALUES
('1','ACTIVO'),
('2','PASIVO'),
('3','PATRIMONIO'),
('4','INGRESOS'),
('5','COSTOS'),
('6','GASTOS'),
('7','VALUACION DE ACTIVOS');


-- Volcado de datos para la tabla `category_2`
INSERT INTO `category_2` (`id`,`name`,`category_1`) VALUES
('1.1','ACTIVO CIRCULANTE','1'),
('1.2','ACTIVO FIJOS','1'),
('1.3','INVERSIONES','1'),
('2.1','PASIVO CIRCULANTE','2'),
('2.2','PASIVO NO CIRCULANTE','2'),
('3.1','PATRIMONIO NETO','3'),
('4.1','INGRESOS CORRIENTES','4'),
('6.1', 'GASTOS CORRIENTES','6'),
('5.1', 'COSTO GENERAL','5'),
('7.1','VALUACION DE INVERSIONES','7'),
('7.2','VALUACION DE ACTIVO CIRCULANTE','7');

-- Volcado de datos para la tabla `category_3`
INSERT INTO `category_3` (`id`,`name`,`category_2`) VALUES
('1.1.1','ACTIVO CIRCULANTE DISPONIBLE','1.1'),
('1.1.2','ACTIVO CIRCULANTE EXIGIBLE','1.1'),
('1.2.1','MAQUINARIA Y EQUIPOS','1.2'),
('1.2.2','MUEBLES Y ENSERES','1.2'),
('1.2.3','(-) DEPRECIACION','1.2'),
('1.2.4','ACTIVOS DIFERIDOS','1.2'),
('1.3.1','INVERSIONES A LARGO PLAZO','1.3'),
('2.1.1','CUENTAS POR PAGAR CORTO PLAZO','2.1'),
('2.2.1','CUENTAS POR PAGAR LARGO PLAZO','2.2'),
('3.1.1','CAPITAL SUSCRITO','3.1'),
('3.1.2','RESERVAS DE CAPITAL','3.1'),
('3.1.3','UTILIDADES/PERDIDAS ACUMULADAS','3.1'),
('4.1.1','INGRESOS CORRIENTES ESPECIFICOS','4.1'),
('5.1.1','COSTO DE PRODUCCION','5.1'),
('5.1.2','COSTO DE VENTA','5.1'),
('6.1.1','GASTOS CORRIENTES ESPECIFICOS','6.1'),
('7.1.1','VALUACION DE INVERSIONES','7.2'),
('7.2.1','VALUACION DE ACTIVO CIRCULANTE DISPONIBLE','7.2');


-- Populate `account` --
-- valuacion
INSERT INTO `account`(`id`,`name`,`category_3`) VALUES
('7.2.1.01','AJUSTE','7.2.1'),
('7.1.1.01','AJUSTE','7.1.1'),
('7.1.1.02','VALUACION ACTIVOS FINANCIEROS','7.1.1');

-- gastos
INSERT INTO `account`(`id`,`name`,`category_3`) VALUES
('6.1.1.02','ALIMENTACION Y CONSUMIBLES','6.1.1'),
('6.1.1.03','ALQUILER','6.1.1'),
('6.1.1.01','AMIGO5','6.1.1'),
('6.1.1.04','COMISION FINANCIERA','6.1.1'),
('6.1.1.05','COMUNICACION','6.1.1'),
('6.1.1.06','CONSULTA MEDICA','6.1.1'),
('6.1.1.07','AMIGO5','6.1.1'),
('6.1.1.08','CUIDADO PERSONAL','6.1.1'),
('6.1.1.09','EDUCACION','6.1.1'),
('6.1.1.10','ELECTRONICA','6.1.1'),
('6.1.1.11','ENSERES','6.1.1'),
('6.1.1.12','ENTRETENIMIENTO','6.1.1'),
('6.1.1.13','EXAMEN MEDICO','6.1.1'),
('6.1.1.14','FAMILIA','6.1.1'),
('6.1.1.15','MEDICINAS','6.1.1'),
('6.1.1.16','OTROS INGRESOS','6.1.1'),
('6.1.1.17','PERDIDA','6.1.1'),
('6.1.1.18','PRESTAMO A TERCEROS','6.1.1'),
('6.1.1.19','ROPA','6.1.1'),
('6.1.1.20','SALUD DENTAL','6.1.1'),
('6.1.1.21','SERVICIOS DEL HOGAR','6.1.1'),
('6.1.1.22','TRAMITES','6.1.1'),
('6.1.1.23','TRANSPORTE','6.1.1');

-- ingresos
INSERT INTO `account`(`id`,`name`,`category_3`) VALUES
('4.1.1.01','BONO ESTATAL','4.1.1'),
('4.1.1.02','SALARIO','4.1.1'),
('4.1.1.03','VENTAS','4.1.1');
-- activos
INSERT INTO `account`(`id`,`name`,`category_3`) VALUES
('1.3.1.01','CAI_BTC','1.3.1'),
('1.3.1.02','CAI_DAP_INSTITUCION_FINANCIERA6_CLP','1.3.1'),
('1.3.1.03','CAI_DAP_INSTITUCION_FINANCIERA6_USD','1.3.1'),
('1.3.1.04','CAI_DAP_INSTITUCION_FINANCIERA1','1.3.1'),
('1.3.1.05','CAI_DAP_INSTITUCION_FINANCIERA2','1.3.1'),
('1.3.1.06','CAI_INSTITUCION_FINANCIERA4_CLP','1.3.1'),
('1.3.1.07','CAI_INSTITUCION_FINANCIERA4_USD','1.3.1'),
('1.3.1.08','CAI_INSTITUCION_FINANCIERA5','1.3.1'),
('1.1.1.01','CTA_AH_INSTITUCION_FINANCIERA3','1.1.1'),
('1.1.1.02','CTA_AH_INSTITUCION_FINANCIERA6','1.1.1'),
('1.1.1.03','CTA_AMAZON','1.1.1'),
('1.1.1.04','CTA_CAJA_FUERTE_CLP','1.1.1'),
('1.1.1.05','CTA_EFECTIVO_CLP','1.1.1'),
('1.1.1.06','CTA_EFECTIVO_USD','1.1.1'),
('1.1.1.07','CTA_RUT_INSTITUCION_FINANCIERA6','1.1.1'),
('1.1.1.08','CTA_TDC_LIDER','1.1.1'),
('1.1.1.09','CTA_VISTA_INSTITUCION_FINANCIERA6','1.1.1'),
('1.1.1.10','CTA_VISTA_INSTITUCION_FINANCIERA7','1.1.1'),
('1.1.1.11','CAI_INSTITUCION_FINANCIERA1','1.1.1'),
('1.1.1.12','CAI_INSTITUCION_FINANCIERA2','1.1.1'),
('1.1.1.13','CTA_TDC_INSTITUCION_FINANCIERA6','1.1.1'),
('1.1.2.01','CXC AMIGO1','1.1.2'),
('1.1.2.02','CXC AMIGO2','1.1.2'),
('1.1.2.03','CXC AMIGO3','1.1.2');

-- pasivos
INSERT INTO `account`(`id`,`name`,`category_3`) VALUES
('2.1.1.01','CXP AMIGO1','2.1.1'),
('2.1.1.02','CXP AMIGO2','2.1.1'),
('2.1.1.03','CXP AMIGO3','2.1.1'),
('2.1.1.04','CXP INSTITUCION_FINANCIERA8','2.1.1'),
('2.1.1.05','CXP TDC LIDER','2.1.1');

-- populate `currency` --
INSERT INTO currency(name) VALUES
('USD'),
('CLP'),
('BTC');

-- populate cost_center --

SELECT DISTINCT `CENTRO DE COSTO`
FROM finance_transactions

INSERT INTO cost_center(name) VALUES
('PERSONAL'),
('CAI LARGO PLAZO'),
('CAI CORTO PLAZO');


-- populate counterpart --

SELECT DISTINCT `CONTRAPARTE`
FROM finance_transactions

INSERT INTO counterpart(name) VALUES
('AMIGO1'),
('AMIGO2'),
('INSTITUCION_FINANCIERA8'),
('AMIGO3');

---------------------------------------------
/* REPLACE NAME VALUES WITH FK ID VALUES */
--------------------------------------------

-- CUENTA

-- update
START TRANSACTION;

UPDATE finance_transactions, account
SET finance_transactions.CUENTA = account.id
WHERE finance_transactions.CUENTA = account.name

-- check if the operation went well
SELECT ft.CUENTA, acn.name
FROM finance_transactions AS ft INNER JOIN account AS acn
ON ft.CUENTA = acn.id
GROUP BY acn.id

ROLLBACK;

COMMIT;

SELECT * FROM finance_transactions

-- MONEDA
START TRANSACTION;

UPDATE finance_transactions, currency
SET finance_transactions.MONEDA = currency.id
WHERE finance_transactions.MONEDA = currency.name

-- check if the operation went well
SELECT ft.MONEDA, c.name
FROM finance_transactions AS ft INNER JOIN currency AS c
ON ft.MONEDA = c.id
GROUP BY c.id

SELECT MONEDA, COUNT(MONEDA)
FROM finance_transactions
GROUP BY MONEDA
WHERE finance_transactions.MONEDA = currency.name

ROLLBACK;

COMMIT;


-- CENTRO DE COSTO
START TRANSACTION;

UPDATE finance_transactions, cost_center
SET finance_transactions.`CENTRO DE COSTO` = cost_center.id
WHERE finance_transactions.`CENTRO DE COSTO` = cost_center.name

-- check if the operation went well
SELECT ft.`CENTRO DE COSTO`, c.name
FROM finance_transactions AS ft INNER JOIN cost_center AS c
ON ft.`CENTRO DE COSTO` = c.id
GROUP BY c.id

SELECT * FROM finance_transactions

ROLLBACK;

COMMIT;


-- modify counterpart.name data length and values
ALTER TABLE counterpart  CHANGE name name varchar(50) NOT NULL;

-- update a value to match with FK
UPDATE `counterpart` SET `name` = 'INSTITUCION_FINANCIERA8' WHERE `counterpart`.`id` = 3


-- CONTRAPARTE
START TRANSACTION;

UPDATE finance_transactions, counterpart
SET finance_transactions.`CONTRAPARTE` = counterpart.id
WHERE finance_transactions.`CONTRAPARTE` = counterpart.name

-- check if the operation went well
SELECT ft.`CONTRAPARTE`, c.name
FROM finance_transactions AS ft INNER JOIN counterpart AS c
ON ft.`CONTRAPARTE` = c.id
GROUP BY c.id

SELECT CONTRAPARTE FROM finance_transactions
GROUP BY CONTRAPARTE

ROLLBACK;

COMMIT;


--------------------------------------
/* CREATING RELATIONSHIPS */
-------------------------------------

-- Stablish relationship between finance_transactions and other tables
--    Considerations: 
--      1. Referencing column has to be indexed
--      2. Referenced and referencing column must have the same data type, data lenght and collation.
--      3. All records must match, there can't exist null values, empty strings, etc.


-- CENTRO DE COSTO
SELECT DISTINCT finance_transactions.CONTRAPARTE
FROM finance_transactions;

SELECT DISTINCT counterpart.id
FROM counterpart

-- check for empty string values
SELECT * FROM finance_transactions
WHERE `CENTRO DE COSTO` = ""

-- update empty string values
START TRANSACTION;

UPDATE finance_transactions
SET finance_transactions.`CENTRO DE COSTO` = '1'
WHERE `CENTRO DE COSTO` = ""

COMMIT;

-- Add FK
ALTER TABLE finance_transactions
  ADD CONSTRAINT 
    FOREIGN KEY (`CENTRO DE COSTO`) REFERENCES `cost_center`(`id`)
      ON UPDATE CASCADE 
      ON DELETE NO ACTION;



-- CONTRAPARTE

-- check for 0 values
SELECT COUNT(ft.CONTRAPARTE) 
FROM finance_transactions AS ft
WHERE ft.CONTRAPARTE = 0

-- update 0 values to null to be able to create the FK
START TRANSACTION;

UPDATE finance_transactions
SET finance_transactions.CONTRAPARTE = NULL
WHERE CONTRAPARTE = 0

COMMIT;

-- Add foreign key constraint finance_transactions.`CENTRO DE COSTO` - cost_center.id
ALTER TABLE finance_transactions
  ADD CONSTRAINT 
    FOREIGN KEY (`CONTRAPARTE`) REFERENCES `counterpart`(`id`)
      ON UPDATE CASCADE
      ON DELETE NO ACTION;


-- MONEDA

-- check 
SELECT COUNT(ft.MONEDA) 
FROM finance_transactions AS ft
WHERE ft.MONEDA = 0


SELECT * 
FROM finance_transactions AS ft
WHERE ft.MONEDA = 0

-- update 0 values to null to be able to create the FK
START TRANSACTION;

UPDATE finance_transactions
SET finance_transactions.MONEDA = 2
WHERE MONEDA = 0

ROLLBACK;

COMMIT;

-- Add foreign key constraint finance_transactions.`CENTRO DE COSTO` - cost_center.id
ALTER TABLE finance_transactions
  ADD CONSTRAINT 
    FOREIGN KEY (`MONEDA`) REFERENCES `currency`(`id`)
      ON UPDATE CASCADE
      ON DELETE NO ACTION;


-- CUENTA

-- check 
SELECT COUNT(ft.CUENTA) 
FROM finance_transactions AS ft
WHERE ft.CUENTA = ""

SELECT * 
FROM finance_transactions AS ft
WHERE ft.CUENTA = 0


-- Add foreign key constraint finance_transactions.`CENTRO DE COSTO` - cost_center.id
ALTER TABLE finance_transactions
  ADD CONSTRAINT 
    FOREIGN KEY (`CUENTA`) REFERENCES `account`(`id`)
      ON UPDATE CASCADE
      ON DELETE NO ACTION;


SELECT * FROM finance_transactions
WHERE CUENTA LIKE '1.3.1%'


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


