# JSON Parsing en SQL

Manipulación de JSON en diferentes warehouses.

## Snowflake

### Extracción de valores

```sql
-- Extraer un valor específico
SELECT 
    JSON_EXTRACT_PATH_TEXT(metadata, 'source') as source,
    JSON_EXTRACT_PATH_TEXT(metadata, 'version') as version,
    JSON_EXTRACT_PATH_TEXT(metadata, 'user', 'name') as user_name  -- nested
FROM bronze.events;

-- Extraer como VARIANT (para arrays)
SELECT 
    JSON_EXTRACT(metadata, '$.tags') as tags,
    JSON_EXTRACT(metadata, '$.items[0]') as first_item
FROM bronze.events;
```

### Parsear arrays

```sql
-- flatten: convertir array en filas
SELECT 
    e.id,
    f.value as tag
FROM bronze.events e,
     LATERAL FLATTEN(input => e.metadata:tags) f;
```

### JSON_TABLE (equivalente)

```sql
-- Usar lateral flatten para simular JSON_TABLE
SELECT 
    e.id,
    f.value:name::STRING as item_name,
    f.value:price::NUMBER as item_price
FROM bronze.events e,
     LATERAL FLATTEN(input => e.metadata:items) f;
```

---

## BigQuery

### Extracción con JSON_EXTRACT

```sql
SELECT 
    JSON_EXTRACT(metadata, '$.source') as source,
    JSON_EXTRACT(metadata, '$.version') as version,
    JSON_EXTRACT(metadata, '$.user.name') as user_name
FROM bronze.events;
```

### Extraer como tipo específico

```sql
SELECT 
    JSON_VALUE(metadata, '$.source') as source,           -- STRING
    JSON_QUERY(metadata, '$.tags') as tags,                -- STRING (JSON)
    CAST(JSON_VALUE(metadata, '$.count') AS INT64) as count
FROM bronze.events;
```

### JSON_TABLE (nativo)

```sql
SELECT *
FROM bronze.events,
UNNEST(JSON_EXTRACT_ARRAY(metadata, '$.items')) as item
```

### UNNEST con structs

```sql
SELECT 
    id,
    item.name,
    item.price
FROM bronze.events,
UNNEST(JSON_EXTRACT_ARRAY(metadata, '$.items')) as item
CROSS JOIN UNNEST([FROM JSON(item STRUCT<name STRING, price INT64>)]) as item
```

---

## PostgreSQL

### Extracción con -> y ->>

```sql
-- -> devuelve JSON, ->> devuelve TEXT
SELECT 
    metadata->>'source' as source,
    metadata->>'version' as version,
    metadata->'user'->>'name' as user_name
FROM bronze.events;
```

### Extraer de arrays

```sql
-- Arrays: json_array_elements
SELECT 
    e.id,
    tag.value::TEXT as tag
FROM bronze.events e,
     JSON_ARRAY_ELEMENTS(e.metadata->'tags') as tag;
```

### JSON_TABLE (PostgreSQL 15+)

```sql
SELECT *
FROM JSON_TABLE(
    '[{"name": "item1", "price": 10}, {"name": "item2", "price": 20}]',
    '$[*]'
    COLUMNS (
        name TEXT PATH '$.name',
        price INT PATH '$.price'
    )
) AS jt;
```

---

## MySQL

### Extracción con JSON_EXTRACT y JSON_VALUE

```sql
-- JSON_EXTRACT devuelve el valor como JSON
-- JSON_VALUE devuelve el valor como STRING
SELECT 
    JSON_EXTRACT(metadata, '$.source') as source_json,    -- JSON
    JSON_VALUE(metadata, '$.source') as source,           -- STRING
    JSON_VALUE(metadata, '$.user.name') as user_name       -- nested
FROM bronze.events;
```

### Extraer de arrays

```sql
-- JSON_TABLE (MySQL 8.0+)
SELECT 
    id,
    jt.*
FROM bronze.events e,
JSON_TABLE(
    e.metadata, -- field
    '$.items[*]' -- array location
    COLUMNS ( -- unnesting
        name VARCHAR(100) PATH '$.name',
        price DECIMAL(10,2) PATH '$.price'
    )
) AS jt;
```

## Patrones Comunes

### Verificar si existe una clave

```sql
-- Snowflake
SELECT * FROM events 
WHERE JSON_EXTRACT_PATH_TEXT(metadata, 'source') IS NOT NULL;

-- BigQuery
SELECT * FROM events 
WHERE JSON_VALUE(metadata, '$.source') IS NOT NULL;

-- PostgreSQL
SELECT * FROM events 
WHERE metadata ? 'source';
```

### Manejo de nulls en JSON

```sql
-- Si la clave no existe, devuelve NULL
-- Para valores vacíos usar COALESCE

-- Snowflake
COALESCE(JSON_EXTRACT_PATH_TEXT(metadata, 'source'), 'unknown') as source

-- BigQuery
IFNULL(JSON_VALUE(metadata, '$.source'), 'unknown') as source
```

### Validar JSON válido

```sql
-- Snowflake
SELECT * FROM events 
WHERE metadata IS NOT NULL
  AND TRY_PARSE_JSON(metadata) IS NOT NULL;

-- PostgreSQL
SELECT * FROM events 
WHERE metadata::TEXT IS NOT NULL 
  AND JSON_TYPEOF(metadata) IS NOT NULL;
```

---


## Notas

- **Snowflake**: `JSON_EXTRACT_PATH_TEXT` es más práctico para valores simples. Usa FLATTEN para arrays.
- **BigQuery**: `JSON_VALUE` para strings, `JSON_QUERY` para objetos/arrays.
- **PostgreSQL**: `->>` es el más usado para extraer texto. `json_array_elements` para arrays.
- Siempre validar JSON con `TRY_PARSE_JSON` o similar antes de procesar en producción.