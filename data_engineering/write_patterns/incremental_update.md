# Incremental Update

**También conocido como:** Delete + Insert, Windowed Refresh, Time-Based Refresh

## Descripción

Patrón híbrido que elimina un subconjunto de datos (típicamente por fecha o ventana de tiempo) y luego reinserta los datos actualizados. Es eficiente para datos particionados donde solo se procesa una ventana de tiempo.

## Cuándo usar

- Datos particionados por fecha
- Métricas diarias que se recalculan
- Transacciones por fecha
- Datos con late arrivals (llegada tardía de datos)
- Cuando se necesita actualizar datos en rangos específicos

## Cuando NO usar

- Para datos append-only (usar Incremental Append)
- Para dimensiones que cambian (usar Upsert)
- Cuando no hay una clave de partición clara
- Para tablas pequeñas donde Full Refresh es más simple

## Implementaciones por motor

### Snowflake

```sql
-- Paso 1: Eliminar particiones a reprocesar (últimos 7 días)
DELETE FROM silver.orders
WHERE order_date >= CURRENT_DATE - INTERVAL '7 days';

-- Paso 2: Insertar datos transformados
INSERT INTO silver.orders
SELECT 
    CAST(order_id AS INTEGER) AS order_id,
    CAST(customer_id AS INTEGER) AS customer_id,
    UPPER(TRIM(status)) AS status,
    COALESCE(amount, 0) AS amount,
    TO_DATE(order_date, 'YYYY-MM-DD') AS order_date,
    CURRENT_TIMESTAMP AS processed_at
FROM bronze.orders_raw
WHERE order_date >= CURRENT_DATE - INTERVAL '7 days'
  AND order_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY updated_at DESC) = 1;
```

### Snowflake (en transacción)

```sql
BEGIN TRANSACTION;

-- Eliminar ventana de tiempo
DELETE FROM silver.orders
WHERE order_date >= DATE_TRUNC('DAY', CURRENT_DATE - INTERVAL '7 days');

-- Insertar datos recalculados
INSERT INTO silver.orders
SELECT 
    CAST(order_id AS INTEGER) AS order_id,
    CAST(customer_id AS INTEGER) AS customer_id,
    UPPER(TRIM(status)) AS status,
    COALESCE(amount, 0) AS amount,
    TO_DATE(order_date, 'YYYY-MM-DD') AS order_date,
    CURRENT_TIMESTAMP AS processed_at
FROM bronze.orders_raw
WHERE order_date >= CURRENT_DATE - INTERVAL '7 days'
  AND order_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY updated_at DESC) = 1;

COMMIT;
```

### BigQuery

```sql
-- BigQuery no permite DELETE, se usa MERGE con ventana de tiempo
MERGE INTO silver.orders AS target
USING (
    SELECT 
        order_id,
        customer_id,
        status,
        amount,
        order_date,
        CURRENT_TIMESTAMP() AS processed_at
    FROM bronze.orders_raw
    WHERE order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY updated_at DESC) = 1
) AS source
ON target.order_id = source.order_id

WHEN MATCHED THEN
    UPDATE SET
        customer_id = source.customer_id,
        status = source.status,
        amount = source.amount,
        order_date = source.order_date,
        processed_at = source.processed_at

WHEN NOT MATCHED THEN
    INSERT ROW;
```

### PostgreSQL

```sql
-- Delete + Insert en transacción
BEGIN;

-- Eliminar registros de la ventana de tiempo
DELETE FROM silver.orders
WHERE order_date >= CURRENT_DATE - INTERVAL '7 days';

-- Insertar datos recalculados
INSERT INTO silver.orders (order_id, customer_id, status, amount, order_date, processed_at)
SELECT 
    order_id::INTEGER,
    customer_id::INTEGER,
    UPPER(TRIM(status))::VARCHAR(20),
    COALESCE(amount, 0)::DECIMAL(10,2),
    order_date::DATE,
    CURRENT_TIMESTAMP
FROM bronze.orders_raw
WHERE order_date >= CURRENT_DATE - INTERVAL '7 days'
  AND order_id IS NOT NULL;

-- Manejar duplicados con ON CONFLICT
ON CONFLICT (order_id) DO UPDATE SET
    customer_id = EXCLUDED.customer_id,
    status = EXCLUDED.status,
    amount = EXCLUDED.amount,
    order_date = EXCLUDED.order_date,
    processed_at = EXCLUDED.processed_at;

COMMIT;
```

### Spark / Databricks (Delta Lake)

```python
# PySpark con Delta Lake - usando merge con condición de tiempo
from delta.tables import DeltaTable
from pyspark.sql.functions import current_date, expr

# Definir ventana de tiempo a reprocesar
window_days = 7
window_start = current_date() - expr(f"INTERVAL {window_days} DAYS")

# Leer datos fuente
new_data = spark.read.format("delta").load("s3://bronze/orders_raw") \
    .filter(col("order_date") >= window_start) \
    .dropDuplicates(["order_id"])

# Obtener la tabla Delta
delta_table = DeltaTable.forName(spark, "silver.orders")

# Merge con condición de tiempo
delta_table.alias("target").merge(
    new_data.alias("source"),
    "target.order_id = source.order_date >= date '{}'".format(window_start)
).whenMatchedUpdate(
    set={
        "customer_id": "source.customer_id",
        "status": "source.status",
        "amount": "source.amount",
        "order_date": "source.order_date",
        "processed_at": "current_timestamp()"
    }
).whenNotMatchedInsert(
    values={
        "order_id": "source.order_id",
        "customer_id": "source.customer_id",
        "status": "source.status",
        "amount": "source.amount",
        "order_date": "source.order_date",
        "processed_at": "current_timestamp()"
    }
).execute()
```

### SQL Server

```sql
-- Delete + Insert
BEGIN TRANSACTION;

-- Eliminar datos de la ventana
DELETE FROM silver.orders
WHERE order_date >= DATEADD(DAY, -7, CAST(GETDATE() AS DATE));

-- Insertar datos recalculados
INSERT INTO silver.orders (order_id, customer_id, status, amount, order_date, processed_at)
SELECT 
    CAST(order_id AS INT),
    CAST(customer_id AS INT),
    UPPER(TRIM(status)),
    COALESCE(amount, 0),
    CAST(order_date AS DATE),
    GETDATE()
FROM bronze.orders_raw
WHERE order_date >= DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
  AND order_id IS NOT NULL;

COMMIT;
```

### dbt

```sql
-- models/silver/orders_incremental.sql
{{ config(
    materialized='incremental',
    unique_key='order_id',
    incremental_strategy='delete+insert'
) }}

SELECT 
    CAST(order_id AS INTEGER) AS order_id,
    CAST(customer_id AS INTEGER) AS customer_id,
    UPPER(TRIM(status)) AS status,
    COALESCE(amount, 0) AS amount,
    TO_DATE(order_date, 'YYYY-MM-DD') AS order_date,
    CURRENT_TIMESTAMP AS processed_at
FROM {{ source('bronze', 'orders_raw') }}

{% if is_incremental() %}
    WHERE order_date >= DATE_TRUNC('DAY', DATEADD('DAY', -7, CURRENT_DATE()))
{% endif %}

{% if is_incremental() %}
    -- dbt usa delete+insert automáticamente con esta estrategia
{% endif %}
```

### Python (con Apache Airflow)

```python
from airflow.providers.snowflake.operators.snowflake import SnowflakeOperator
from datetime import datetime, timedelta

# DAG para incremental update
with DAG('incremental_update_orders', start_date=datetime(2024, 1, 1)) as dag:
    
    delete_window = SnowflakeOperator(
        task_id='delete_window',
        snowflake_conn_id='snowflake_default',
        sql="""
            DELETE FROM silver.orders
            WHERE order_date >= CURRENT_DATE - INTERVAL '7 days'
        """
    )
    
    insert_data = SnowflakeOperator(
        task_id='insert_data',
        snowflake_conn_id='snowflake_default',
        sql="""
            INSERT INTO silver.orders
            SELECT 
                CAST(order_id AS INTEGER) AS order_id,
                CAST(customer_id AS INTEGER) AS customer_id,
                UPPER(TRIM(status)) AS status,
                COALESCE(amount, 0) AS amount,
                TO_DATE(order_date, 'YYYY-MM-DD') AS order_date,
                CURRENT_TIMESTAMP AS processed_at
            FROM bronze.orders_raw
            WHERE order_date >= CURRENT_DATE - INTERVAL '7 days'
              AND order_id IS NOT NULL
            QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY updated_at DESC) = 1
        """
    )
    
    delete_window >> insert_data
```

### Apache Iceberg

```sql
-- Iceberg soporta write incremental con MERGE INTO
MERGE INTO silver.orders AS target
USING (
    SELECT 
        order_id,
        customer_id,
        status,
        amount,
        order_date,
        updated_at
    FROM bronze.orders_raw
    WHERE order_date >= CURRENT_DATE - INTERVAL '7 days'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY updated_at DESC) = 1
) AS source
ON target.order_id = source.order_id

WHEN MATCHED THEN
    UPDATE SET
        customer_id = source.customer_id,
        status = source.status,
        amount = source.amount,
        order_date = source.order_date,
        processed_at = CURRENT_TIMESTAMP

WHEN NOT MATCHED THEN
    INSERT (order_id, customer_id, status, amount, order_date, processed_at)
    VALUES (source.order_id, source.customer_id, source.status, source.amount, 
            source.order_date, CURRENT_TIMESTAMP);
```

## Consideraciones

- **Ventana de tiempo:** Elegir una ventana suficientemente amplia para capturar late arrivals
- **Late arrivals:** Datos que llegan con retraso y deben incorporarse a días anteriores
- **Rendimiento:** Más eficiente que Full Refresh para tablas grandes
- **Transacciones:** Usar transacciones para保证 consistencia atómica

## Metadata

- **Patrón:** Incremental Update
- **Otros nombres:** Delete + Insert, Windowed Refresh, Time-Based Refresh
- **Caso de uso típico:** Métricas diarias, transacciones por fecha, datos con late arrivals