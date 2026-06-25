# Deduplicación en SQL

La deduplicación es una de las tareas más frecuentes en pipelines de datos. Los datos duplicados pueden ingresar por errores en la fuente, problemas de captura, o lógica de integración incompleta. Esta guía cubre técnicas desde las más simples hasta las más avanzadas.

## 1. Deduplicación Básica

### Usando DISTINCT

La forma más simple para eliminar valores duplicados en el resultado:

```sql
-- Eliminar emails duplicados
SELECT DISTINCT email
FROM bronze.customers;
```

**Limitación**: Solo funciona a nivel de fila completa. No puedes decidir qué duplicado mantener.
Si usas mas de un campo, se consideran todos como clave de deduplicación

### Usando GROUP BY con Aggregates

```sql
-- Obtener una fila por cliente, sumando o contando
SELECT 
    customer_id,
    COUNT(*) as occurrence_count,
    MAX(created_at) as latest_created,
    STRING_AGG(order_id, ',') as all_orders
FROM bronze.orders
GROUP BY customer_id
HAVING COUNT(*) > 1;
```

## 2. Deduplicación con Window Functions

Las window functions son la herramienta más poderosa para deduplicación avanzada.

### ROW_NUMBER - Mantener solo una fila por clave

```sql
-- Mantener el registro más reciente por customer_id (usando QUALIFY)
SELECT *
FROM bronze.customers
QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY created_at DESC) = 1;
```

También se puede escribir con subquery (sintaxis más compatible):

```sql
-- Mantener el registro más reciente por customer_id
SELECT *
FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY created_at DESC
        ) as rn
    FROM bronze.customers
) ranked
WHERE rn = 1;
```

### ROW_NUMBER es la función para deduplicar

`RANK` y `DENSE_RANK` **no** se usan para deduplicar. Se usan para otros casos:

```sql
-- Ejemplo con empates en created_at
SELECT 
    customer_id,
    created_at,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY created_at DESC) as row_num,
    RANK() OVER (PARTITION BY customer_id ORDER BY created_at DESC) as rank_num,
    DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY created_at DESC) as dense_rank_num
FROM orders;

-- Resultado:
-- customer_id | created_at         | row_num | rank_num | dense_rank_num
-- ------------|--------------------|---------|----------|----------------
-- 101         | 2024-01-03 10:00   | 1       | 1        | 1
-- 101         | 2024-01-03 10:00   | 2       | 1        | 1    ← empato!
-- 101         | 2024-01-02 15:00   | 3       | 3        | 2
```

**Diferencia**:
- `ROW_NUMBER()`: 1, 2, 3... siempre números únicos (ideal para deduplicar)
- `RANK()`: 1, 1, 3... salta posiciones cuando hay empates
- `DENSE_RANK()`: 1, 1, 2... sin saltos

**Cuándo usar cada uno para otros propósitos**:
- `ROW_NUMBER()`: Deduplicar, top N exacto por grupo
- `RANK()`: Top N incluyendo todos los empatados (ej: "top 10" pero si hay empatados en posición 10, incluirlos a todos)
- `DENSE_RANK()`: Rankings sin saltos (ej: posiciones en una competencia)

## 3. Escenarios Comunes de Deduplicación

### Por múltiples columnas

```sql
-- Deduplicar por combinación de columnas (usando QUALIFY)
SELECT *
FROM bronze.customers
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id, email, phone 
    ORDER BY updated_at DESC
) = 1;
```

### Mantener el registro más antiguo

```sql
-- Mantener la primera versión (más antigua) usando QUALIFY
SELECT *
FROM bronze.customers
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id 
    ORDER BY created_at ASC
) = 1;
```

### Deduplicación con criterios de calidad

```sql
-- Preferir registros con más información completa usando QUALIFY
SELECT *
FROM bronze.customers
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY email 
    ORDER BY 
        -- Primero: registros con teléfono no nulo
        CASE WHEN phone IS NOT NULL THEN 0 ELSE 1 END,
        -- Segundo: el más reciente
        updated_at DESC
) = 1;
```

### Por fecha o período

```sql
-- Deduplicar dentro de cada día, mantener el último del día usando QUALIFY
SELECT *
FROM bronze.events
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id, DATE(created_at) 
    ORDER BY created_at DESC
) = 1;
```

## 4. Deduplicación en Procesos Incrementales

### Identificar qué es "nuevo" vs "duplicado"

```sql
-- Encontrar registros que ya existen en la tabla destino
SELECT b.*
FROM bronze.new_customers b
INNER JOIN silver.customers s 
    ON b.customer_id = s.customer_id;

-- Encontrar registros completamente nuevos
SELECT b.*
FROM bronze.new_customers b
LEFT JOIN silver.customers s 
    ON b.customer_id = s.customer_id
WHERE s.customer_id IS NULL;
```

### Insertar solo unique records

```sql
-- Insertar sin duplicados, usando NOT EXISTS
INSERT INTO silver.customers
SELECT b.*
FROM bronze.customers b
WHERE NOT EXISTS (
    SELECT 1 
    FROM silver.customers s 
    WHERE s.customer_id = b.customer_id
);
```

## 5. Deduplicación Avanzada

### SCD Type 2 - Deduplicación con historial

```sql
-- Cuando quieres mantener todas las versiones pero marcar la actual
INSERT INTO silver.customers_scd
SELECT 
    customer_id,
    name,
    email,
    address,
    CURRENT_TIMESTAMP as valid_from,
    NULL as valid_to,
    TRUE as is_current,
    MD5(CONCAT(name, email, address)) as row_hash
FROM bronze.customers b
WHERE NOT EXISTS (
    SELECT 1 
    FROM silver.customers_scd s
    WHERE s.customer_id = b.customer_id
      AND s.is_current = TRUE
      AND MD5(CONCAT(b.name, b.email, b.address)) = s.row_hash
);

-- Cerrar versiones anteriores cuando hay cambio
UPDATE silver.customers_scd
SET 
    valid_to = CURRENT_TIMESTAMP,
    is_current = FALSE
WHERE is_current = TRUE
AND customer_id IN (SELECT customer_id FROM bronze.customers);
```
```

### Deduplicación con múltiples matches

```sql
-- Cuando hay múltiples candidatos, usar lógica compleja
WITH ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY 
                -- Prioridad 1: registros verificados
                CASE WHEN verified = TRUE THEN 0 ELSE 1 END,
                -- Prioridad 2: más campos llenos
                (CASE WHEN name IS NOT NULL THEN 1 ELSE 0 END +
                 CASE WHEN phone IS NOT NULL THEN 1 ELSE 0 END +
                 CASE WHEN address IS NOT NULL THEN 1 ELSE 0 END) DESC,
                -- Prioridad 3: más reciente
                updated_at DESC
        ) as rn
    FROM bronze.customers
)
SELECT * FROM ranked WHERE rn = 1;
```

### Deduplicación con MERGE

```sql
MERGE INTO silver.customers AS target
USING bronze.customers AS source
ON target.customer_id = source.customer_id
WHEN MATCHED AND target.row_hash <> MD5(CONCAT(source.name, source.email)) THEN
    UPDATE SET
        name = source.name,
        email = source.email,
        address = source.address,
        updated_at = CURRENT_TIMESTAMP,
        row_hash = MD5(CONCAT(source.name, source.email, source.address))
WHEN NOT MATCHED THEN
    INSERT (customer_id, name, email, address, created_at, row_hash)
    VALUES (source.customer_id, source.name, source.email, source.address, 
            CURRENT_TIMESTAMP, MD5(CONCAT(source.name, source.email, source.address)));
```

## 6. Patrones de Deduplicación por Tipo de Datos

### Emails

```sql
-- Normalizar antes de deduplicar
SELECT DISTINCT 
    LOWER(TRIM(email)) as email
FROM bronze.customers
WHERE email IS NOT NULL;
```

### Números de teléfono

```sql
-- Estandarizar formato antes de deduplicar
SELECT DISTINCT
    REGEXP_REPLACE(phone, '[^0-9]', '') as phone_clean
FROM bronze.customers;
```

### Strings con variaciones

```sql
-- Normalizar texto para comparación
SELECT DISTINCT
    UPPER(TRIM(name)) as name_normalized
FROM bronze.customers;
```

## 7. Ejemplo Completo: Pipeline de Deduplicación

```sql
-- Paso 1: Identificar duplicados usando QUALIFY
SELECT 
    customer_id,
    email,
    COUNT(*) OVER (PARTITION BY customer_id, email) as duplicate_count,
    CASE 
        WHEN COUNT(*) OVER (PARTITION BY customer_id, email) > 1 THEN 'duplicate'
        ELSE 'unique'
    END as status
FROM bronze.customers_raw
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id, email
    ORDER BY updated_at DESC, created_at DESC
) = 1;

-- Paso 2: Eliminar y mantener el mejor registro usando QUALIFY
CREATE TABLE silver.customers_dedup AS
SELECT 
    customer_id,
    name,
    email,
    phone,
    address,
    verified,
    CURRENT_TIMESTAMP as deduped_at,
    'silver_pipeline_v1' as source
FROM bronze.customers_raw
WHERE customer_id IS NOT NULL  -- Filtrar registros válidos
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id 
    ORDER BY 
        CASE WHEN verified = TRUE THEN 0 ELSE 1 END,
        updated_at DESC,
        LENGTH(CONCAT(name, phone, address)) DESC
) = 1;
```

## Resumen de Técnicas

| Escenario | Técnica |
|-----------|---------|
| Valores únicos simples | `DISTINCT` |
| Una fila por clave | `ROW_NUMBER() OVER (PARTITION BY key ORDER BY ...)` |
| Mantener más reciente | `ORDER BY created_at DESC` |
| Mantener más antiguo | `ORDER BY created_at ASC` |
| Múltiples claves | `PARTITION BY col1, col2` |
| Por criterio de calidad | `ORDER BY CASE WHEN condition THEN 0 ELSE 1 END` |
| Con historial (SCD2) | `INSERT + UPDATE` con `is_current` |
| Solo inserts nuevos | `NOT EXISTS` o `MERGE` |

## Consideraciones de Rendimiento

1. **Índices**: Asegúrate de tener índices en las columnas de partición
2. **Volumen**: Para datasets muy grandes, considera procesar en lotes
3. **CTEs**: Las CTEs son legibles pero pueden materializar datos grandes; para casos extremos considera crear tablas temporales
4. **Particiones**: Si tu base de datos soporta particiones, úsalas para limitar el escaneo