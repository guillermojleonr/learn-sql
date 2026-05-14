# Data Profiling

Antes de escribir transformaciones, es necesario explorar los datos para identificar qué campos tienen problemas. Este proceso se llama **data profiling** y es incremental: lo haces al principio pero luego lo sigues haciendo para depurar los procesos. Lo descrito acá es profiling manual, En equipos maduros, esto se automatiza con herramientas como Great Expectations, dbt-utils.

## Data profiling automático

### Great Expectations
Es una librería python que corre donde corre tu pipeline Python/Spark, la configuras y durante el proceso se ejecuta y devuelve resultados del profiling que aplicaste a los campos respectivos. Te sirve para saber que sucede en la capa silver/gold donde se supone que ya todo está limpio y al encontrar problemas en esas capas se realiza el ajuste de procesamiento.

### dbt-utils
dbt naturalmente ya tiene tests como unique, not_null relationships accepted_values, pero dbt-utils agrega macros extra: sequential values,recency,cardinalidad,surrogate keys,equality entre tablas,etc

Ejemplo:

````yaml
tests:
  - dbt_utils.unique_combination_of_columns:
      combination_of_columns:
        - order_id
        - line_number
````
Acá el profiling/calidad vive directamente en SQL warehouse.

Muy usado en stacks: Snowflake,BigQuery,Databricks,Redshift

Fortalezas: Muy simple, Todo SQL, Versionado Git, Corre en el warehouse, Excelente para analytics engineering
Debilidad: Menos flexible que Python para lógica compleja.

## Data profiling manual

Queries que se aplican columna a columna

### Query de Profiling Completa (Una sola consulta)
Incluye nulls, empty strings, valores únicos, min/max:

```sql
SELECT 
    'nombre_columna' as column_name,
    COUNT(*) as total,
    COUNT(columna) as non_null,
    COUNT(*) - COUNT(columna) as null_count,
    ROUND((COUNT(*) - COUNT(columna)) * 100.0 / COUNT(*), 2) as null_percentage,
    COUNT(DISTINCT columna) as distinct_values,
    MIN(columna) as min_value,
    MAX(columna) as max_value,
    -- Empty strings ( '', not NULL)
    SUM(CASE WHEN columna = '' OR TRIM(columna) = '' THEN 1 ELSE 0 END) as empty_count,
    ROUND(SUM(CASE WHEN columna = '' OR TRIM(columna) = '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as empty_percentage
FROM bronze.tabla_raw;
```

### Emails
Para esto tengo una query de validación mejor en Python que ve muchas más cosas

```sql
SELECT 
    columna,
    COUNT(*) as count
FROM bronze.tabla
WHERE columna NOT LIKE '%@%'  -- emails sin @
GROUP BY columna;
```

### Validación y Flags de Calidad
Marcar registros con problemas detectados:

```sql
SELECT *,
    CASE 
        WHEN email NOT LIKE '%@%' THEN 'invalid_email'
        WHEN amount < 0 THEN 'negative_amount'
        WHEN created_at > CURRENT_DATE THEN 'future_date'
        ELSE 'valid'
    END as data_quality_flag
FROM bronze.orders;
```

---

## Proceso Real en Producción

1. **Exploración inicial** - Ejecutar queries de profiling en la capa bronze
2. **Documentar hallazgos** - Registrar qué campos tienen nulls, vacíos, o valores inválidos
3. **Aplicar transformaciones** - Usar COALESCE solo donde realmente hace falta
4. **Monitoreo continuo** - Cada vez que el pipeline falla o produce resultados inesperados, investigar y actualizar las queries
5. **Iteración** - El proceso es continuo; nuevos datos revelan nuevos edge cases
