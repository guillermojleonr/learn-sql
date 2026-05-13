# Full Refresh

**También conocido como:** CTAS (Create Table As Select), Truncate + Insert

## Descripción

Estrategy de recarga completa donde se elimina toda la tabla y se vuelve a cargar desde cero. Adecuada para tablas pequeñas o cuando se necesita un snapshot completo.

## Cuándo usar

- **Tablas pequeñas (< 1M rows):** El tiempo de procesar toda la tabla es aceptable (minutos, no horas).

- **Snapshots diarios completos:** Cuando necesitas una foto completa del estado de los datos cada día, por ejemplo:
  - Reportes diarios que requieren el estado exacto a cierre del día anterior
  - Auditorías que necesitan ver todos los registros en un momento dado
  - backups lógicos diarios de tablas pequeñas (no toda la base de datos)

- **Catálogos de productos:** Donde el volumen de productos es manejable y cambian poco:
  - Catálogo de e-commerce con 50,000 productos (no millones)
  - Lista de categorías, marcas, proveedores
  - Tablas que cambian varias veces al día pero no constantemente
  - El costo de recalcular todo es menor que el costo de mantener lógica de cambios

- **Tablas de referencia/dimensiones estáticas:** Datos que cambian poco o nunca:
  - Tablas de países, monedas, idiomas (datos geográficos)
  - Códigos postales o estados (cambian eventualmente)
  - Listas de permisos, roles de usuario
  - Cualquier dato que se actualiza manualmente y no viene de un sistema transaccional

- **Cuando la complejidad de lógica incremental no justifica el esfuerzo:** Si vas a dedicar más tiempo desarrollando y manteniendo código incremental que el tiempo que ahorrarías en ejecución, simpler es mejor.

## Cuando NO usar

- Tablas grandes (horas de procesamiento)
- Datos históricos que no cambian
- Cuando hay otras alternativas más eficientes

## Implementaciones por motor

### Snowflake

```sql
-- CTAS
CREATE OR REPLACE TABLE silver.orders AS
SELECT 
    CAST(order_id AS INTEGER) AS order_id,
    CAST(customer_id AS INTEGER) AS customer_id,
    UPPER(TRIM(status)) AS status,
    COALESCE(amount, 0) AS amount,
    TO_DATE(order_date, 'YYYY-MM-DD') AS order_date,
    CURRENT_TIMESTAMP AS processed_at
FROM bronze.orders_raw
WHERE order_id IS NOT NULL;

-- Truncate + Insert (para mantener estructura existente)
TRUNCATE TABLE silver.orders;

INSERT INTO silver.orders
SELECT 
    CAST(order_id AS INTEGER) AS order_id,
    CAST(customer_id AS INTEGER) AS customer_id,
    UPPER(TRIM(status)) AS status,
    COALESCE(amount, 0) AS amount,
    TO_DATE(order_date, 'YYYY-MM-DD') AS order_date,
    CURRENT_TIMESTAMP AS processed_at
FROM bronze.orders_raw
WHERE order_id IS NOT NULL;
```

### BigQuery

```sql
-- CREATE OR REPLACE (CTAS)
CREATE OR REPLACE TABLE silver.orders AS
SELECT 
    CAST(order_id AS INT64) AS order_id,
    CAST(customer_id AS INT64) AS customer_id,
    UPPER(TRIM(status)) AS status,
    COALESCE(amount, 0) AS amount,
    PARSE_DATE('%Y-%m-%d', order_date) AS order_date,
    CURRENT_TIMESTAMP() AS processed_at
FROM bronze.orders_raw
WHERE order_id IS NOT NULL;
```

### Spark / Databricks

```sql
-- Scala
spark.read.format("delta")
  .load("s3://bronze/orders_raw")
  .filter(col("order_id").isNotNull)
  .select(
    col("order_id").cast("int"),
    col("customer_id").cast("int"),
    upper(trim(col("status"))).alias("status"),
    coalesce(col("amount"), lit(0)).alias("amount"),
    to_date(col("order_date"), "yyyy-MM-dd").alias("order_date"),
    current_timestamp().alias("processed_at")
  )
  .write
  .mode("overwrite")
  .saveAsTable("silver.orders")
```

### PostgreSQL

```sql
-- Full refresh con transacción
BEGIN;

DROP TABLE IF EXISTS silver.orders;

CREATE TABLE silver.orders AS
SELECT 
    order_id::INTEGER AS order_id,
    customer_id::INTEGER AS customer_id,
    UPPER(TRIM(status))::VARCHAR(20) AS status,
    COALESCE(amount, 0)::DECIMAL(10,2) AS amount,
    order_date::DATE AS order_date,
    CURRENT_TIMESTAMP AS processed_at
FROM bronze.orders_raw
WHERE order_id IS NOT NULL;

-- O con TRUNCATE para mantener estructura
TRUNCATE TABLE silver.orders RESTART IDENTITY;

INSERT INTO silver.orders (order_id, customer_id, status, amount, order_date, processed_at)
SELECT 
    order_id::INTEGER,
    customer_id::INTEGER,
    UPPER(TRIM(status))::VARCHAR(20),
    COALESCE(amount, 0)::DECIMAL(10,2),
    order_date::DATE,
    CURRENT_TIMESTAMP
FROM bronze.orders_raw
WHERE order_id IS NOT NULL;

COMMIT;
```

### dbt

```sql
-- models/silver/orders_full_refresh.sql
{{ config(materialized='table') }}

SELECT 
    CAST(order_id AS INTEGER) AS order_id,
    CAST(customer_id AS INTEGER) AS customer_id,
    UPPER(TRIM(status)) AS status,
    COALESCE(amount, 0) AS amount,
    TO_DATE(order_date, 'YYYY-MM-DD') AS order_date,
    CURRENT_TIMESTAMP AS processed_at
FROM {{ source('bronze', 'orders_raw') }}
WHERE order_id IS NOT NULL
```

### Python (con Pandas / SQLAlchemy)

```python
import pandas as pd
from sqlalchemy import create_engine

engine = create_engine("snowflake://user:pass@account/db")

# Cargar datos
df = pd.read_sql("""
    SELECT 
        CAST(order_id AS INTEGER) AS order_id,
        CAST(customer_id AS INTEGER) AS customer_id,
        UPPER(TRIM(status)) AS status,
        COALESCE(amount, 0) AS amount,
        TO_DATE(order_date, 'YYYY-MM-DD') AS order_date,
        CURRENT_TIMESTAMP AS processed_at
    FROM bronze.orders_raw
    WHERE order_id IS NOT NULL
""", engine)

# Escribir con reemplazo completo
df.to_sql(
    'orders',
    schema='silver',
    con=engine,
    if_exists='replace',
    index=False
)
```

### Apache Airflow (TaskFlow)

```python
from airflow.decorators import task
from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook

@task
def full_refresh_orders():
    hook = SnowflakeHook(snowflake_conn_id='snowflake_default')
    
    # Usar CTAS para full refresh
    hook.run("""
        CREATE OR REPLACE TABLE silver.orders AS
        SELECT 
            CAST(order_id AS INTEGER) AS order_id,
            CAST(customer_id AS INTEGER) AS customer_id,
            UPPER(TRIM(status)) AS status,
            COALESCE(amount, 0) AS amount,
            TO_DATE(order_date, 'YYYY-MM-DD') AS order_date,
            CURRENT_TIMESTAMP AS processed_at
        FROM bronze.orders_raw
        WHERE order_id IS NOT NULL
    """)
```

## Consideraciones

- **Idempotencia:** La operación es idempotente si se usa `CREATE OR REPLACE` o `TRUNCATE + INSERT`
- **Tiempo de ejecución:** Proporcional al volumen total de datos
- **Bloqueo:** Puede requerir locks exclusivos según el motor
- **Costos:** En cloud warehouses, factura por datos procesados

## Metadata

- **Patrón:** Full Refresh
- **Otros nombres:** Complete Reload, Full Reload, Snapshot
- **Caso de uso típico:** Dimensiones pequeñas, tablas de referencia