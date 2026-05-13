# Upsert / Merge

**También conocido como:** Merge, Insert-or-Update, Merge Into

## Descripción

Patrón que combina INSERT y UPDATE en una operación atómica. Si el registro existe (basado en clave única), se actualiza; si no existe, se inserta. Esencial para dimensiones slowly changing y datos que requieren actualizaciones.

## Cuándo usar

- Tablas de dimensiones (clientes, productos, ubicaciones)
- Datos maestro que cambian con el tiempo
- SCD Type 1 (sobrescribir valores)
- Datos de usuario/perfil
- Inventario de productos

## Cuando NO usar

- Datos append-only (usar Incremental Append)
- Cuando se necesita mantener historial de cambios (usar SCD Type 2)
- Para tablas de hechos grandes con muchas métricas (usar Incremental Update)

## Implementaciones por motor

### Snowflake

```sql
MERGE INTO silver.customers AS target
USING (
    SELECT 
        customer_id,
        LOWER(TRIM(email)) AS email,
        INITCAP(TRIM(name)) AS name,
        phone,
        updated_at
    FROM bronze.customers_raw
    WHERE updated_at >= CURRENT_DATE - INTERVAL '1 day'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY updated_at DESC) = 1
) AS source
ON target.customer_id = source.customer_id

WHEN MATCHED AND source.updated_at > target.updated_at THEN
    UPDATE SET
        email = source.email,
        name = source.name,
        phone = source.phone,
        updated_at = source.updated_at,
        processed_at = CURRENT_TIMESTAMP

WHEN NOT MATCHED THEN
    INSERT (customer_id, email, name, phone, updated_at, processed_at)
    VALUES (source.customer_id, source.email, source.name, source.phone, 
            source.updated_at, CURRENT_TIMESTAMP);
```

### BigQuery

```sql
MERGE INTO silver.customers AS target
USING (
    SELECT 
        customer_id,
        LOWER(TRIM(email)) AS email,
        INITCAP(TRIM(name)) AS name,
        phone,
        updated_at
    FROM bronze.customers_raw
    WHERE updated_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY updated_at DESC) = 1
) AS source
ON target.customer_id = source.customer_id

WHEN MATCHED AND source.updated_at > target.updated_at THEN
    UPDATE SET
        email = source.email,
        name = source.name,
        phone = source.phone,
        updated_at = source.updated_at,
        processed_at = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN
    INSERT (customer_id, email, name, phone, updated_at, processed_at)
    VALUES (source.customer_id, source.email, source.name, source.phone, 
            source.updated_at, CURRENT_TIMESTAMP());
```

### PostgreSQL

```sql
-- Upsert con ON CONFLICT (PostgreSQL 9.5+)
INSERT INTO silver.customers (customer_id, email, name, phone, updated_at, processed_at)
SELECT 
    customer_id,
    LOWER(TRIM(email)) AS email,
    INITCAP(TRIM(name)) AS name,
    phone,
    updated_at,
    CURRENT_TIMESTAMP AS processed_at
FROM bronze.customers_raw
WHERE updated_at >= CURRENT_DATE - INTERVAL '1 day'
ON CONFLICT (customer_id) DO UPDATE SET
    email = EXCLUDED.email,
    name = EXCLUDED.name,
    phone = EXCLUDED.phone,
    updated_at = EXCLUDED.updated_at,
    processed_at = CURRENT_TIMESTAMP
WHERE silver.customers.updated_at < EXCLUDED.updated_at;
```

### MySQL / MariaDB

```sql
-- UPSERT con ON DUPLICATE KEY UPDATE
INSERT INTO silver.customers (customer_id, email, name, phone, updated_at, processed_at)
SELECT 
    customer_id,
    LOWER(TRIM(email)) AS email,
    INITCAP(TRIM(name)) AS name,
    phone,
    updated_at,
    CURRENT_TIMESTAMP AS processed_at
FROM bronze.customers_raw
WHERE updated_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)
ON DUPLICATE KEY UPDATE
    email = VALUES(email),
    name = VALUES(name),
    phone = VALUES(phone),
    updated_at = VALUES(updated_at),
    processed_at = CURRENT_TIMESTAMP;
```

### SQL Server

```sql
MERGE INTO silver.customers AS target
USING (
    SELECT 
        customer_id,
        LOWER(TRIM(email)) AS email,
        INITCAP(TRIM(name)) AS name,
        phone,
        updated_at
    FROM bronze.customers_raw
    WHERE updated_at >= DATEADD(DAY, -1, GETDATE())
) AS source
ON target.customer_id = source.customer_id

WHEN MATCHED THEN
    UPDATE SET
        email = source.email,
        name = source.name,
        phone = source.phone,
        updated_at = source.updated_at,
        processed_at = GETDATE()

WHEN NOT MATCHED THEN
    INSERT (customer_id, email, name, phone, updated_at, processed_at)
    VALUES (source.customer_id, source.email, source.name, source.phone, 
            source.updated_at, GETDATE());
```

### Spark / Databricks (Delta Lake)

```python
# PySpark con Delta Lake
from delta.tables import DeltaTable

# Leer datos fuente
new_data = spark.read.format("delta").load("s3://bronze/customers_raw") \
    .filter(col("updated_at") >= current_date() - expr("INTERVAL 1 day")) \
    .dropDuplicates(["customer_id"])

# Upsert
delta_table = DeltaTable.forName(spark, "silver.customers")

delta_table.alias("target").merge(
    new_data.alias("source"),
    "target.customer_id = source.customer_id"
).whenMatchedUpdate(
    condition="source.updated_at > target.updated_at",
    set={
        "email": "source.email",
        "name": "source.name",
        "phone": "source.phone",
        "updated_at": "source.updated_at",
        "processed_at": "current_timestamp()"
    }
).whenNotMatchedInsert(
    values={
        "customer_id": "source.customer_id",
        "email": "source.email",
        "name": "source.name",
        "phone": "source.phone",
        "updated_at": "source.updated_at",
        "processed_at": "current_timestamp()"
    }
).execute()
```

### dbt

```sql
-- models/silver/customers.sql
{{ config(
    materialized='incremental',
    unique_key='customer_id',
    on_schema_change='fail'
) }}

WITH source_data AS (
    SELECT 
        customer_id,
        LOWER(TRIM(email)) AS email,
        INITCAP(TRIM(name)) AS name,
        phone,
        updated_at,
        CURRENT_TIMESTAMP AS processed_at
    FROM {{ source('bronze', 'customers_raw') }}
    {% if is_incremental() %}
        WHERE updated_at > (SELECT MAX(updated_at) FROM {{ this }})
    {% endif %}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY updated_at DESC) = 1
)

SELECT * FROM source_data
```

### Python (con SQLAlchemy)

```python
from sqlalchemy import create_engine, text
import pandas as pd

engine = create_engine("postgresql://user:pass@localhost/db")

# Obtener datos actualizados
new_data = pd.read_sql("""
    SELECT 
        customer_id,
        LOWER(TRIM(email)) AS email,
        INITCAP(TRIM(name)) AS name,
        phone,
        updated_at
    FROM bronze.customers_raw
    WHERE updated_at >= CURRENT_DATE - INTERVAL '1 day'
""", engine)

# Upsert con PostgreSQL
with engine.begin() as conn:
    for _, row in new_data.iterrows():
        conn.execute(text("""
            INSERT INTO silver.customers (customer_id, email, name, phone, updated_at, processed_at)
            VALUES (:customer_id, :email, :name, :phone, :updated_at, CURRENT_TIMESTAMP)
            ON CONFLICT (customer_id) DO UPDATE SET
                email = EXCLUDED.email,
                name = EXCLUDED.name,
                phone = EXCLUDED.phone,
                updated_at = EXCLUDED.updated_at,
                processed_at = CURRENT_TIMESTAMP
            WHERE silver.customers.updated_at < EXCLUDED.updated_at
        """), row.to_dict())
```

## Consideraciones

- **Idempotencia:** La operación puede ejecutarse múltiples veces sin efectos adversos
- **Condiciones de carrera:** En algunos motores puede haber condiciones de carrera; usar transacciones
- **Histórico:** Sobrescribe valores anteriores (SCD Type 1). Para mantener histórico usar SCD Type 2
- **Rendimiento:** El MERGE puede ser costoso en tablas muy grandes

## Metadata

- **Patrón:** Upsert / Merge
- **Otros nombres:** Insert-or-Update, Merge Into, Upsert
- **Caso de uso típico:** Dimensiones, datos maestros, SCD Type 1