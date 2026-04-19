# Resumen de Dominio SQL

En base a un scan de este repo, para mayor info ver el proyecto "jobs" que puede estar más actualizado y optimizado para jobs offerings.

## Áreas de Dominio

### 1. Diseño de Bases de Datos
- Modelado relacional completo con múltiples niveles de jerarquía
- Normalización de datos (categorías multinivel, relaciones muchos-a-muchos)
- Diseño de esquemas para diferentes dominios: finanzas personales, logística/envíos, academia, ubicaciones geográficas

### 2. Gestión de Usuarios y Seguridad
- Administración de privilegios (GRANT, SHOW GRANTS)
- Control de acceso a nivel de base de datos y servidor
- Gestión de usuarios con restricciones de host

## Cláusulas y Comandos SQL

### DDL (Data Definition Language)
- `CREATE TABLE`, `DROP TABLE`
- `ALTER TABLE` (ADD, DROP, CHANGE)
- `CREATE DATABASE`, `USE`
- `CREATE FUNCTION`, `DROP FUNCTION`
- `CREATE TRIGGER`
- `CREATE VIEW`
- Definición de constraints: `PRIMARY KEY`, `FOREIGN KEY`, `UNIQUE`, `CHECK`, `DEFAULT`

### DML (Data Manipulation Language)
- `SELECT` (simple y complejo)
- `INSERT INTO` (individual y masivo)
- `UPDATE` (con y sin JOIN)
- `DELETE`
- `START TRANSACTION`, `COMMIT`, `ROLLBACK`

### Consultas Avanzadas
- `INNER JOIN` (múltiples tablas)
- `UNION`, `UNION ALL`
- Subconsultas (escalares, de lista, correlacionadas)
- `GROUP BY`, `HAVING`
- Funciones de agregación: `SUM`, `COUNT`, `AVG`
- `ORDER BY`
- `BETWEEN`, `IN`, `NOT IN`, `ALL`, `ANY`
- `EXISTS`

### DCL (Data Control Language)
- `GRANT` (privilegios globales y específicos)
- `SHOW GRANTS FOR`

### Funciones y Operadores
- `CHAR_LENGTH`, `LEN`
- `DATEDIFF`, `BETWEEN` (fechas)
- Operadores aritméticos y de comparación
- `CASE WHEN`
- Funciones de cadena y numéricas

### Características Avanzadas
- `AUTO_INCREMENT`
- Triggers (`INSERT`, `UPDATE`, `DELETE`)
- Funciones definidas por usuario (UDF)
- Tablas temporales (`DELETED`, `INSERTED` en triggers)
- Campos calculados (`AS`)
- Transacciones con control de errores
- Vistas (`CREATE VIEW`)
- Constraints con acciones referenciales (`ON UPDATE CASCADE`, `ON DELETE CASCADE/SET NULL/NO ACTION`)

### Tipos de Datos
- **Numéricos**: `INT`, `TINYINT`, `SMALLINT`, `BIGINT`, `DECIMAL`, `MONEY`
- **Cadenas**: `VARCHAR`, `CHAR`
- **Fechas**: `DATE`, `TIME`
- **Booleanos**: `BIT`
- **Modificadores**: `UNSIGNED`, `NOT NULL`

### Metadatos y Administración
- `INFORMATION_SCHEMA.COLUMNS`
- `INFORMATION_SCHEMA.TABLE_CONSTRAINTS`
- `SHOW VARIABLES`

## Nivel de Dominio

**Nivel: Intermedio-Avanzado**

Capacidades demostradas:
- Diseño completo de bases de datos relacionales
- Implementación de integridad referencial compleja
- Consultas complejas con múltiples JOINs y subconsultas
- Programación de lógica de negocio (triggers, funciones)
- Gestión de transacciones
- Administración de seguridad y privilegios
- Trabajo con diferentes dialectos SQL (MariaDB/MySQL, T-SQL)
