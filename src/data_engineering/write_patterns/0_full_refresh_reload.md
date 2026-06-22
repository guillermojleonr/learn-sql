# Full Refresh

CTAS (Create Table As Select), Truncate + Insert

Patrón de recarga completa donde se elimina toda la tabla y se vuelve a cargar desde cero.

- **Idempotencia:** La operación es idempotente si se usa `CREATE OR REPLACE` o `TRUNCATE + INSERT`
- **Tiempo de ejecución:** Proporcional al volumen total de datos
- **Bloqueo:** Puede requerir locks exclusivos según el motor
- **Costos:** En cloud warehouses, factura por datos procesados
- **Atomicidad:** La operación es atómica (todos los datos se reemplazan o ninguno)
- **Histórico:** Generalmente se pierde el histórico anterior (se reemplaza completamente)

## Cuándo usar

- **Reportes históricos completos:** Cuando necesitas regenerar un reporte desde cero:
  - Reportes mensuales de finanzas que deben reflejar el estado exacto de hace un mes
  - Dashboards ejecutivos que se construyen sobre múltiples fuentes y necesitan consistencia
  - Cuando el reporte combina datos de varias tablas que pueden cambiar independientemente, y necesitas una foto consistente

- **Reprocesamiento de datos (reprocessing):** Cuando hay cambios en la lógica de transformación:
  - Se descubrió un bug en la transformación y hay que corregir datos históricos
  - Cambió la definición de un indicador (ej: cambió cómo se calcula "ingreso")
  - Migración de sistema fuente que afecta datos pasados
  - Se incorporan datos históricos que antes no estaban disponibles

- **Cuando se necesita consistencia atómica en todo el conjunto de datos:** Situaciones donde un cálculo parcial es peor que nada:
  - Modelos predictivos que se entrenan con datos consistentes
  - Reportes regulatorios que no pueden tener inconsistencias
  - Cuando los datos tiene dependencias circulares o se alimentan entre sí. Ejemplo: tienes tabla A → tabla B → tabla C y cualquier cambio puede afectar cualquier nivel, es más fácil regenerar todo

- **Datos que se regeneran completamente desde la fuente:** Cuando la fuente es la única verdad:
  - Datos extraídos de sistemas externos que cambian retroactivamente
  - APIs que pueden devolver datos diferentes para la misma query
  - Cuando no hay log de cambios en la fuente (no hay CDC)
  - Ejemplo: datos de un API de tasas de cambio que pueden actualizar valores anteriores

  - **Costo de recalcular**: El costo monetarios de recalcular todo es menor que el costo de mantener lógica de cambios.

- **Tablas pequeñas (< 1M rows):** El tiempo de procesar toda la tabla es aceptable (minutos, no horas).

- Tablas que cambian varias veces al día pero no constantemente

- **Snapshots diarios completos:** Cuando necesitas una foto completa del estado de los datos cada día, por ejemplo:
  - Reportes diarios que requieren el estado exacto a cierre del día anterior
  - Auditorías que necesitan ver todos los registros en un momento dado
  - backups lógicos diarios de tablas pequeñas (no toda la base de datos)

- **Tablas de referencia/dimensiones estáticas:** Datos que cambian poco o nunca:
  - Tablas de países, monedas, idiomas (datos geográficos)
  - Códigos postales o estados (cambian eventualmente)
  - Listas de permisos, roles de usuario
  - Lista de categorías, marcas, proveedores
  - Catálogos de productos acotados (miles y no millones)
  - Cualquier dato que se actualiza manualmente y no viene de un sistema transaccional

## Cuando NO usar

- Tablas grandes (horas de procesamiento)
- Datos históricos que no cambian
- Cuando hay otras alternativas más eficientes
- Cuando solo hay cambios incrementales
- Cuando el tiempo de procesamiento es crítico

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

# Full Reload

También conocido como: Complete Reload, Full Overwrite

Patrón de recarga completa donde se reemplazan todos los datos existentes con los datos actuales pero manteniendo el DDL existente.

En sistemas que soportan particiones, puede especificarse qué particiones reemplazar

## Implementaciones por motor

### Snowflake

```sql
-- INSERT OVERWRITE (común en Spark/Hive, emulado en Snowflake)
INSERT OVERWRITE INTO silver.monthly_sales
SELECT 
    DATE_TRUNC('MONTH', order_date) AS month,
    COUNT(*) AS total_orders,
    SUM(amount) AS total_amount,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM bronze.orders_raw
WHERE order_date >= DATE_TRUNC('MONTH', DATE_ADD('MONTH', -1, CURRENT_DATE()))
GROUP BY DATE_TRUNC('MONTH', order_date);

-- Nota: Snowflake no tiene "INSERT OVERWRITE" nativo como Spark
-- Se emula con TRUNCATE + INSERT o CREATE OR REPLACE
```

### Spark / Databricks (Nativo)

```scala
// Scala
spark.read.format("delta")
  .load("s3://bronze/orders_raw")
  .filter(col("order_date") >= lit(current_date - 1))
  .groupBy(date_trunc("month", col("order_date")).alias("month"))
  .agg(
    count("*").alias("total_orders"),
    sum("amount").alias("total_amount"),
    countDistinct("customer_id").alias("unique_customers")
  )
  .write
  .mode("overwrite")
  .partitionBy("month")
  .saveAsTable("silver.monthly_sales")
```

```python
# PySpark
df = spark.read.format("delta").load("s3://bronze/orders_raw")

result = df.filter(col("order_date") >= lit(current_date - 1)) \
    .groupBy(date_trunc("month", col("order_date")).alias("month")) \
    .agg(
        count("*").alias("total_orders"),
        sum("amount").alias("total_amount"),
        countDistinct("customer_id").alias("unique_customers")
    )

result.write \
    .mode("overwrite") \
    .partitionBy("month") \
    .saveAsTable("silver.monthly_sales")
```

### BigQuery

```sql
-- BigQuery no tiene INSERT OVERWRITE, usa CREATE OR REPLACE
CREATE OR REPLACE TABLE silver.monthly_sales AS
SELECT 
    DATE_TRUNC(order_date, MONTH) AS month,
    COUNT(*) AS total_orders,
    SUM(amount) AS total_amount,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM bronze.orders_raw
WHERE order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH)
GROUP BY DATE_TRUNC(order_date, MONTH);
```

### dbt

```sql
-- models/silver/monthly_sales.sql
{{ config(materialized='table') }}

SELECT 
    DATE_TRUNC('MONTH', order_date) AS month,
    COUNT(*) AS total_orders,
    SUM(amount) AS total_amount,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM {{ source('bronze', 'orders_raw') }}
WHERE order_date >= DATE_TRUNC('MONTH', DATEADD('MONTH', -1, CURRENT_DATE()))
GROUP BY DATE_TRUNC('MONTH', order_date)
```

### Python (Delta Lake)

```python
from delta import DeltaTable

# Full reload usando Delta Lake
df = spark.read.format("delta").load("s3://bronze/orders_raw")

result = df.groupBy(date_trunc("month", col("order_date")).alias("month")) \
    .agg(
        count("*").alias("total_orders"),
        sum("amount").alias("total_amount")
    )

# Sobrescribir completamente la tabla
result.write \
    .mode("overwrite") \
    .saveAsTable("silver.monthly_sales")

# O con Delta Lake específico
DeltaTable.convertToDelta(spark, "parquet.`s3://silver/monthly_sales`")
```