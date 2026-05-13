# Incremental Append

**También conocido como:** Append-Only, Append, Insert Only

## Descripción

Patrón donde solo se añaden nuevos registros sin modificar los existentes. Los datos son inmutables y nunca se actualizan o eliminan después de ser insertados.

## Cuándo usar

- Logs de aplicación
- Eventos de clickstream
- Datos de sensores IoT
- Historial de transacciones inmutables
- Cualquier dato donde el pasado no debe cambiar

## Cuando NO usar

- Cuando los datos pueden ser corregidos retroactivamente
- Para dimensiones que requieren actualizaciones (usar Upsert)
- Cuando hay requisitos de GDPR/derecho al olvido

## Implementaciones por motor

### Snowflake

```sql
-- Solo insertar registros nuevos basados en timestamp
INSERT INTO silver.events
SELECT 
    event_id,
    user_id,
    event_type,
    TO_TIMESTAMP(event_timestamp) AS event_timestamp,
    PARSE_JSON(event_data) AS event_data,
    CURRENT_TIMESTAMP AS processed_at
FROM bronze.events_raw
WHERE event_timestamp > (
    SELECT COALESCE(MAX(event_timestamp), '1900-01-01')
    FROM silver.events
);
```

### BigQuery

```sql
-- Append solo registros nuevos
INSERT INTO silver.events (event_id, user_id, event_type, event_timestamp, event_data, processed_at)
SELECT 
    event_id,
    user_id,
    event_type,
    TIMESTAMP(event_timestamp),
    PARSE_JSON(event_data),
    CURRENT_TIMESTAMP()
FROM bronze.events_raw
WHERE event_timestamp > (
    SELECT COALESCE(MAX(event_timestamp), TIMESTAMP('1900-01-01'))
    FROM silver.events
);
```

### PostgreSQL

```sql
-- Insertar solo registros nuevos
INSERT INTO silver.events
SELECT 
    event_id,
    user_id,
    event_type,
    event_timestamp::TIMESTAMP,
    event_data::JSONB,
    CURRENT_TIMESTAMP AS processed_at
FROM bronze.events_raw
WHERE event_timestamp > (
    SELECT COALESCE(MAX(event_timestamp), '-infinity'::TIMESTAMP)
    FROM silver.events
)
ON CONFLICT DO NOTHING;  -- Si hay constraint de unicidad
```

### Spark / Databricks

```python
# PySpark - Append mode
df = spark.read.format("delta").load("s3://bronze/events_raw")

# Filtrar solo registros nuevos
max_timestamp = spark.sql("SELECT MAX(event_timestamp) FROM silver.events").collect()[0][0]

if max_timestamp:
    new_events = df.filter(col("event_timestamp") > lit(max_timestamp))
else:
    new_events = df

new_events.write \
    .mode("append") \
    .saveAsTable("silver.events")
```

### MySQL / MariaDB

```sql
-- Insert solo registros nuevos
INSERT INTO silver.events
SELECT 
    event_id,
    user_id,
    event_type,
    event_timestamp,
    event_data,
    NOW() AS processed_at
FROM bronze.events_raw AS src
WHERE NOT EXISTS (
    SELECT 1 FROM silver.events AS target
    WHERE target.event_id = src.event_id
);

-- O usando LEFT JOIN
INSERT INTO silver.events
SELECT src.*
FROM bronze_events_raw AS src
LEFT JOIN silver.events AS target ON src.event_id = target.event_id
WHERE target.event_id IS NULL;
```

### dbt

```sql
-- models/silver/events.sql
{{ config(
    materialized='incremental',
    unique_key='event_id'
) }}

SELECT 
    event_id,
    user_id,
    event_type,
    event_timestamp,
    event_data,
    CURRENT_TIMESTAMP AS processed_at
FROM {{ source('bronze', 'events_raw') }}

{% if is_incremental() %}
    WHERE event_timestamp > (SELECT MAX(event_timestamp) FROM {{ this }})
{% endif %}
```

### Python (with SQLAlchemy)

```python
from sqlalchemy import create_engine, text
import pandas as pd

engine = create_engine("postgresql://user:pass@localhost/db")

# Obtener el máximo timestamp existente
with engine.connect() as conn:
    result = conn.execute(text("SELECT MAX(event_timestamp) FROM silver.events"))
    max_ts = result.scalar() or '1900-01-01'

# Cargar solo registros nuevos
new_data = pd.read_sql(f"""
    SELECT * FROM bronze.events_raw
    WHERE event_timestamp > '{max_ts}'
""", engine)

# Append
new_data.to_sql(
    'events',
    schema='silver',
    con=engine,
    if_exists='append',
    index=False
)
```

### Apache Kafka + Spark Streaming

```python
# Consumir de Kafka y hacer append a Delta Lake
from pyspark.sql import SparkSession
from pyspark.sql.functions import from_json, col

spark = SparkSession.builder.getOrCreate()

# Schema del evento
schema = StructType([
    StructField("event_id", StringType(), True),
    StructField("user_id", StringType(), True),
    StructField("event_type", StringType(), True),
    StructField("event_timestamp", TimestampType(), True),
    StructField("event_data", StringType(), True)
])

# Leer de Kafka
events = spark \
    .readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("subscribe", "user_events") \
    .load() \
    .select(from_json(col("value").cast("string"), schema).alias("data")) \
    .select("data.*")

# Append a Delta Lake
events.writeStream \
    .format("delta") \
    .outputMode("append") \
    .option("checkpointLocation", "/delta/events/_checkpoints") \
    .start("s3://silver/events")
```

## Consideraciones

- **Inmutabilidad:** Los datos nunca se modifican después de insertados
- ** deduplicación:** Puede ser necesario manejar duplicados (usar QUALIFY o DISTINCT)
- **Escala:** Excelente para escalar horizontalmente
- **Consistencia:** Fácil de mantener consistencia eventual

## Metadata

- **Patrón:** Incremental Append
- **Otros nombres:** Append-Only, Insert Only, Log Append
- **Caso de uso típico:** Logs, eventos, IoT, clickstream