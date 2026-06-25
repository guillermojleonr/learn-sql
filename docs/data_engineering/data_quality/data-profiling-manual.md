# Data Profiling

Antes de escribir transformaciones, es necesario explorar los datos para identificar qué campos tienen problemas. Este proceso se llama **data profiling** y es incremental: lo haces al principio pero luego lo sigues haciendo para depurar los procesos. Lo descrito acá es profiling manual, para mayor información sobre automatizaciones (profiling + quality) ver [data_quality.md]

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

### Validación y Flags de Calidad
Marcar registros con problemas detectados:

```sql
SELECT *,
    CASE 
        WHEN email NOT LIKE '%@%' THEN 'invalid_email' -- realmente requiere una validación más compleja, en python tengo una
        WHEN amount < 0 THEN 'negative_amount'
        WHEN created_at > CURRENT_DATE THEN 'future_date'
        ELSE 'valid'
    END as data_quality_flag
FROM bronze.orders;
```

---

## Proceso Real en Producción

1. **Exploración inicial** - Ejecutar queries cuando recién entras a conocer la data base
2. **Documentar hallazgos** - Registrar qué campos tienen nulls, vacíos, o valores inválidos
3. **Aplicar transformaciones en los pipelines** 
4. **Monitoreo continuo** - Cada vez que el pipeline falla o produce resultados inesperados, investigar y actualizar las queries
5. **Iteración** - El proceso es continuo; nuevos datos revelan nuevos edge cases