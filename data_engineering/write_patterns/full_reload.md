# Full Reload

**También conocido como:** Complete Reload, Full Overwrite

## Descripción

Estrategia de recarga completa donde se reemplazan todos los datos existentes con los datos actuales. A diferencia de Full Refresh (que recrea la tabla), esta mantiene la estructura DDL existente.

## Cuándo usar

- **Reportes históricos completos:** Cuando necesitas regenerar un reporte desde cero:
  - Reportes mensuales de finanzas que deben reflejar el estado exacto de hace un mes
  - Dashboards ejecutivos que se construyen sobre múltiples fuentes y necesitan consistencia
  - Cuando el reporte combina datos de varias tablas que pueden cambiar independientemente, y necesitas una foto consistente

- **Agregaciones mensuales/anuales:** Cuando recalcular métricas tiene más sentido que actualizar incrementally:
  - Ventas mensuales por región (se recalcula todo el mes, no solo el último día)
  - Métricas de NPS o satisfacción por trimestre
  - KPIs agregados que dependen de muchas tablas fuentes
  - Ejemplo: si tienes 10 millones de transacciones y quieres el total por día del mes, es más simple regenerar todo el mes que mantener lógica de "qué días cambiaron"

- **Reprocesamiento de datos (reprocessing):** Cuando hay cambios en la lógica de transformación:
  - Se descubrió un bug en la transformación y hay que corregir datos históricos
  - Cambió la definición de un indicador (ej: cambió cómo se calcula "ingreso")
  - Migración de sistema fuente que afecta datos pasados
  - Se incorporan datos históricos que antes no estaban disponibles

- **Cuando se necesita consistencia atómica en todo el conjunto de datos:** Situaciones donde un cálculo parcial es peor que nada:
  - Modelos predictivos que se entrenan con datos consistentes
  - Reportes regulatorios que no pueden tener inconsistencias
  - Cuando los datos tiene dependencias circulares o se alimentan entre sí
  - Ejemplo: tienes tabla A → tabla B → tabla C y cualquier cambio puede afectar cualquier nivel, es más fácil regenerar todo

- **Datos que se regeneran completamente desde la fuente:** Cuando la fuente es la única verdad:
  - Datos extraídos de sistemas externos que cambian retroactivamente
  - APIs que pueden devolver datos diferentes para la misma query
  - Cuando no hay log de cambios en la fuente (no hay CDC)
  - Ejemplo: datos de un API de tasas de cambio que pueden actualizar valores anteriores

## Cuando NO usar

- Cuando solo hay cambios incrementales
- Para tablas con gran volumen de datos históricos
- Cuando el tiempo de procesamiento es crítico

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

### Hive

```sql
INSERT OVERWRITE TABLE silver.monthly_sales
SELECT 
    TRUNC(order_date, 'MM') AS month,
    COUNT(*) AS total_orders,
    SUM(amount) AS total_amount,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM bronze.orders_raw
WHERE order_date >= ADD_MONTHS(CURRENT_DATE, -1)
GROUP BY TRUNC(order_date, 'MM');
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

## Consideraciones

- ** atomicidad:** La operación es atómica (todos los datos se reemplazan o ninguno)
- **Particiones:** En sistemas que soportan particiones, puede especificarse qué particiones reemplazar
- **Tiempo:** Puede tomar tiempo significativo para tablas grandes
- **Histórico:** Generalmente se pierde el histórico anterior (se reemplaza completamente)

## Metadata

- **Patrón:** Full Reload
- **Otros nombres:** Complete Overwrite, Full Replacement
- **Caso de uso típico:** Agregaciones mensuales, reportes históricos