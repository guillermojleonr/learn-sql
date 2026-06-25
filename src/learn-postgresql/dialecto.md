# Diferencias entre MySQL y PostgreSQL

## Tipos de Datos

### Numéricos

#### Enteros

| MySQL | PostgreSQL |
|-------|------------|
| `TINYINT` | No existe, usar `SMALLINT` |
| `INT UNSIGNED` | No soportado, usar `BIGINT` o `CHECK (valor >= 0)` |

#### Decimales

- **Moneda**: PostgreSQL tiene `MONEY`, MySQL no tiene tipo específico.

#### Serial / Auto-increment

| MySQL | PostgreSQL |
|-------|------------|
| `INT AUTO_INCREMENT` | `SERIAL` |
| `BIGINT AUTO_INCREMENT` | `BIGSERIAL` |
| `SMALLINT AUTO_INCREMENT` | `SMALLSERIAL` |

### Cadenas de Texto

| MySQL | PostgreSQL |
|-------|------------|
| `VARCHAR(n)` | `VARCHAR(n)` o `CHARACTER VARYING(n)` |
| `TEXT` (límite 65,535 bytes) | `TEXT` (ilimitado) |
| `BINARY(n)` | No existe, usar `BYTEA` |
| `BLOB` | `BYTEA` |
| `CHAR(n)` | `CHAR(n)` o `BPCHAR(n)` (blank-padded char) |

- **VARCHAR(n)**: Igual en ambos. PostgreSQL internally lo llama `CHARACTER VARYING(n)`.
- **CHAR(n)**: Igual en ambos. PostgreSQL tiene `BPCHAR(n)` como alias interno.

### Fechas y Tiempos

| MySQL | PostgreSQL |
|-------|------------|
| `DATETIME` | `TIMESTAMP` |
| `TIMESTAMP` (sin timezone) | `TIMESTAMPTZ` o `TIMESTAMP WITH TIME ZONE` |
| `YEAR` | No existe, usar `INT` o `DATE` |
| No soportado | `INTERVAL` |

```sql
-- PostgreSQL: Intervalos
SELECT '1 year 2 months 3 days'::INTERVAL;
SELECT fecha + INTERVAL '1 year' FROM tabla;
```

### Booleanos

| MySQL | PostgreSQL |
|-------|------------|
| `BOOLEAN` alias de `TINYINT(1)` | `BOOLEAN` tipo nativo (`TRUE`, `FALSE`, `NULL`) |

### JSON

| MySQL | PostgreSQL |
|-------|------------|
| `JSON` (único tipo) | `JSON` (texto) y `JSONB` (binario, indexable) |

### Arrays

| MySQL | PostgreSQL |
|-------|------------|
| No soportado | `TIPO[]` (arrays nativos) |

### UUID

| MySQL | PostgreSQL |
|-------|------------|
| No tiene tipo nativo | `UUID` nativo |

---

## Funciones

### Concatenación

| MySQL | PostgreSQL |
|-------|------------|
| `CONCAT(a, b)` (ignora NULL) | `a \|\| b` (propaga NULL) o `CONCAT(a, b)` |

### Subcadenas

| MySQL | PostgreSQL |
|-------|------------|
| `INSTR(cad, sub)` o `LOCATE(sub, cad)` | `POSITION(sub IN cad)` o `STRPOS(cad, sub)` |

### Mayúsculas y Minúsculas

| MySQL | PostgreSQL |
|-------|------------|
| `UPPER()`, `LOWER()` | `UPPER()`, `LOWER()`, `INITCAP()` |

### Expresiones Regulares

| MySQL | PostgreSQL |
|-------|------------|
| `REGEXP`, `NOT REGEXP`, `REGEXP_REPLACE()`, `REGEXP_SUBSTR()` | `~`, `!~`, `~*`, `!~*`, `REGEXP_REPLACE()` |

```sql
-- PostgreSQL
SELECT * FROM t WHERE col ~ '^[a-z]+$';      -- Sensible
SELECT * FROM t WHERE col ~* '^[a-z]+$';     -- Insensible
```

### Potencias y Logaritmos

| MySQL | PostgreSQL |
|-------|------------|
| `POWER(b, e)`, `SQRT()` | `POWER(b, e)` o `b ^ e`, `\|/` o `SQRT()` |

```sql
-- PostgreSQL
SELECT 2 ^ 10;       -- 1024
SELECT \|/ 16;        -- 4
SELECT \|\|/ 27;       -- 3
```

### Fechas

#### Funciones

| MySQL | PostgreSQL |
|-------|------------|
| `NOW()`, `CURDATE()`, `CURTIME()`, `YEAR()`, `MONTH()`, `DAY()`, `HOUR()`, `MINUTE()`, `SECOND()`, `DAYOFWEEK()`, `DAYOFYEAR()`, `WEEK()` | `NOW()`, `CURRENT_DATE`, `CURRENT_TIME`, `EXTRACT()` |

#### Diferencia entre Fechas

| MySQL | PostgreSQL |
|-------|------------|
| `DATEDIFF()`, `TIMEDIFF()`, `TIMESTAMPDIFF()` | `fecha1 - fecha2` (INTERVAL), `AGE()` |

#### Aritmética

| MySQL | PostgreSQL |
|-------|------------|
| `DATE_ADD(fecha, INTERVAL n)`, `DATE_SUB()` | `fecha + INTERVAL 'n unidad'` |

```sql
-- PostgreSQL
SELECT NOW() + INTERVAL '1 year 2 months 3 days';
```

#### Formateo

| MySQL | PostgreSQL |
|-------|------------|
| `DATE_FORMAT(fecha, formato)` | `TO_CHAR(fecha, formato)` |

Especificadores:
- `%Y` → `YYYY`
- `%m` → `MM`
- `%d` → `DD`
- `%H` → `HH24`
- `%i` → `MI`
- `%s` → `SS`

### Agregación

| MySQL | PostgreSQL |
|-------|------------|
| `GROUP_CONCAT(col SEPARATOR sep)` | `STRING_AGG(col, sep)` |
| - | `MODE() WITHIN GROUP`, `PERCENTILE_CONT()`, `PERCENTILE_DISC()` |

### Condicionales

| MySQL | PostgreSQL |
|-------|------------|
| `IF(cond, true_val, false_val)` | `CASE WHEN` |
| `GREATEST()` / `LEAST()` devuelve NULL si hay NULL | `GREATEST()` / `LEAST()` ignora NULL |

### Window Functions

| MySQL | PostgreSQL |
|-------|------------|
| `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `LAG()`, `LEAD()`, etc. | Lo anterior + `PERCENT_RANK()`, `CUME_DIST()` |

---

## DDL

### CREATE TABLE

#### Auto-increment

```sql
-- MySQL
id INT AUTO_INCREMENT PRIMARY KEY

-- PostgreSQL
id SERIAL PRIMARY KEY

-- PostgreSQL: Alternativa
id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
```

#### Valores por Defecto

| MySQL | PostgreSQL |
|-------|------------|
| `DEFAULT CURRENT_TIMESTAMP` | `DEFAULT NOW()` |

### ALTER TABLE

| MySQL | PostgreSQL |
|-------|------------|
| `MODIFY COLUMN`, `CHANGE COLUMN` | `ALTER COLUMN ... TYPE`, `RENAME COLUMN` |

### CREATE INDEX

| MySQL | PostgreSQL |
|-------|------------|
| `FULLTEXT INDEX`, `SPATIAL INDEX` | `USING HASH`, `USING GIN`, `USING GIST`, `USING BRIN` |

```sql
-- PostgreSQL
CREATE INDEX idx ON t USING GIN (col);      -- JSONB, arrays
CREATE INDEX idx ON t USING GIST (col);     -- Geométricos
CREATE INDEX idx ON t USING BRIN (col);     -- Tablas grandes
```

### DROP

| MySQL | PostgreSQL |
|-------|------------|
| `DROP TABLE IF EXISTS t` | `DROP TABLE IF EXISTS t CASCADE` |

---

## DML

### INSERT

#### RETURNING

- **MySQL**: No soporta `RETURNING`.
- **PostgreSQL**: Soporta `RETURNING`.

```sql
-- PostgreSQL
INSERT INTO t (col) VALUES ('val')
RETURNING id, col;
```

#### ON DUPLICATE KEY vs ON CONFLICT

| MySQL | PostgreSQL |
|-------|------------|
| `ON DUPLICATE KEY UPDATE col = VALUES(col)` | `ON CONFLICT (col) DO UPDATE SET col = EXCLUDED.col` |
| - | `ON CONFLICT DO NOTHING` |

```sql
-- PostgreSQL
INSERT INTO t (id, col) VALUES (1, 'val')
ON CONFLICT (id) DO UPDATE SET col = EXCLUDED.col;
```

### UPDATE

#### Con JOIN

| MySQL | PostgreSQL |
|-------|------------|
| `UPDATE t1 JOIN t2 ON ... SET ...` | `UPDATE t1 SET ... FROM t2 WHERE ...` |

#### RETURNING

- **MySQL**: No soporta.
- **PostgreSQL**: Soporta `RETURNING`.

### DELETE

#### Con JOIN

| MySQL | PostgreSQL |
|-------|------------|
| `DELETE t1 FROM t1 LEFT JOIN t2 ON ... WHERE ...` | `DELETE FROM t1 USING t2 WHERE ...` |

#### RETURNING

- **MySQL**: No soporta.
- **PostgreSQL**: Soporta `RETURNING`.

### MERGE

- **MySQL**: No tiene. Usar `INSERT ... ON DUPLICATE KEY`.
- **PostgreSQL**: Tiene `MERGE` (desde v15).

---

## SELECT

### DISTINCT

- **PostgreSQL**: Tiene `DISTINCT ON (col)`.

```sql
-- PostgreSQL
SELECT DISTINCT ON (departamento) *
FROM empleados
ORDER BY departamento, salario DESC;
```

### CTE

- Ambos soportan `WITH RECURSIVE` desde MySQL 8.0+.

### LATERAL Joins

- Ambos soportan desde MySQL 8.0.14+.

---

## JSON

### Creación

| MySQL | PostgreSQL |
|-------|------------|
| `JSON_OBJECT()`, `JSON_ARRAY()` | `JSON_BUILD_OBJECT()`, `JSON_BUILD_ARRAY()` |

### Extracción

| MySQL | PostgreSQL |
|-------|------------|
| `datos->'$.path'`, `datos->>'$.path'`, `JSON_EXTRACT()` | `datos->'path'`, `datos->>'path'`, `datos#>'{path,elements}'` |

### Modificación

| MySQL | PostgreSQL |
|-------|------------|
| `JSON_SET()`, `JSON_REMOVE()` | `datos \|\| '{"clave": valor}'::JSONB`, `datos - 'clave'` |

### Consultas

| MySQL | PostgreSQL |
|-------|------------|
| `JSON_CONTAINS()`, `JSON_SEARCH()` | `@>`, `?`, `?&`, `?|` |

### Índices

| MySQL | PostgreSQL |
|-------|------------|
| `CREATE INDEX ... ON (CAST(json_col AS CHAR(255)))` | `CREATE INDEX ... USING GIN (json_col)` |

---

## Control de Flujo

### Bloques IF

| MySQL | PostgreSQL |
|-------|------------|
| `IF ... THEN ... ELSEIF ... END IF;` | `IF ... THEN ... ELSIF ... END IF;` |

### Bucles

| MySQL | PostgreSQL |
|-------|------------|
| `WHILE ... DO ... END WHILE;`, `REPEAT ... UNTIL ... END REPEAT;`, `LOOP ... LEAVE ... END LOOP;` | `WHILE ... LOOP ... END LOOP;`, `LOOP ... EXIT WHEN ... END LOOP;`, `FOR ... LOOP ... END LOOP;`, `FOREACH ... LOOP ... END LOOP;` |

---

## Transacciones

### Niveles de Aislamiento

| MySQL | PostgreSQL |
|-------|------------|
| No soporta `READ UNCOMMITTED` en InnoDB | `READ UNCOMMITTED` se mapea a `READ COMMITTED` |

### Locking Explícito

- Ambos soportan `SELECT ... FOR UPDATE` y `SELECT ...W LOCK IN SHARE MODE` / `FOR SHARE`.
