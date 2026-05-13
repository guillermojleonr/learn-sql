# Data Profiling

Antes de escribir transformaciones, es necesario explorar los datos para identificar qué campos tienen problemas. Este proceso se llama **data profiling** y es incremental.

## Query básica de profiling

```sql
SELECT 
    COUNT(*) as total_rows,
    COUNT(columna) as non_null_count,
    COUNT(*) - COUNT(columna) as null_count,
    ROUND((COUNT(*) - COUNT(columna)) * 100.0 / COUNT(*), 2) as null_percentage
FROM bronze.tabla_raw;
```

## Profiling completo por columna

```sql
SELECT 
    'nombre_columna' as column_name,
    COUNT(*) as total,
    COUNT(columna) as non_null,
    COUNT(*) - COUNT(columna) as null_count,
    COUNT(DISTINCT columna) as distinct_values,
    MIN(columna) as min_value,
    MAX(columna) as max_value
FROM bronze.tabla_raw;
```

## Detectar valores problemáticos

```sql
-- Valores vacíos que no son NULL
SELECT COUNT(*) 
FROM bronze.tabla 
WHERE columna = '' OR TRIM(columna) = '';

-- Valores que parecen inválidos
SELECT 
    columna,
    COUNT(*) as count
FROM bronze.tabla
WHERE columna NOT LIKE '%@%'  -- emails sin @
GROUP BY columna;
```

---

## Proceso Real en Producción

1. **Exploración inicial** - Ejecutar queries de profiling en la capa bronze
2. **Documentar hallazgos** - Registrar qué campos tienen nulls, vacíos, o valores inválidos
3. **Aplicar transformaciones** - Usar COALESCE solo donde realmente hace falta
4. **Monitoreo continuo** - Cada vez que el pipeline falla o produce resultados inesperados, investigar y actualizar las queries
5. **Iteración** - El proceso es continuo; nuevos datos revelan nuevos edge cases

> **Nota:** En equipos maduros, esto se automatiza con herramientas como Great Expectations, dbt-utils, o DataHub para hacer profiling automático y detectar drifts en los datos.