-- ============================================================================
-- CONSULTAS SQL PARA PROCESOS ETL/ELT - TRANSFORMACIÓN BRONZE → SILVER
-- ============================================================================
-- Este archivo contiene patrones y ejemplos de consultas típicas utilizadas
-- en pipelines de datos para transformar datos crudos (bronze) en datos
-- limpios y validados (silver).
-- ============================================================================

-- ============================================================================
-- 1. LIMPIEZA Y ESTANDARIZACIÓN
-- ============================================================================

-- Eliminar duplicados
SELECT DISTINCT 
    customer_id,
    email,
    first_name,
    last_name
FROM bronze.customers;

-- Normalizar texto (mayúsculas, minúsculas, trim)
SELECT 
    UPPER(TRIM(country)) as country,
    LOWER(TRIM(email)) as email,
    INITCAP(TRIM(name)) as name
FROM bronze.customers;

-- Reemplazar valores nulos con defaults
SELECT 
    COALESCE(phone, 'N/A') as phone,
    COALESCE(address, 'Unknown') as address,
    COALESCE(status, 'pending') as status
FROM bronze.orders;

-- ============================================================================
-- 2. VALIDACIÓN Y FILTRADO
-- ============================================================================

-- Filtrar registros válidos
SELECT *
FROM bronze.transactions
WHERE amount > 0
  AND transaction_date IS NOT NULL
  AND customer_id IS NOT NULL
  AND email LIKE '%@%.%';

-- Marcar registros con problemas de calidad
SELECT *,
    CASE 
        WHEN email NOT LIKE '%@%' THEN 'invalid_email'
        WHEN amount < 0 THEN 'negative_amount'
        WHEN created_at > CURRENT_DATE THEN 'future_date'
        ELSE 'valid'
    END as data_quality_flag
FROM bronze.orders;

-- ============================================================================
-- 3. TRANSFORMACIONES DE TIPOS DE DATOS
-- ============================================================================

-- Conversión de tipos
SELECT 
    CAST(order_id AS INTEGER) as order_id,
    CAST(amount AS DECIMAL(10,2)) as amount,
    TO_DATE(order_date, 'YYYY-MM-DD') as order_date,
    TO_TIMESTAMP(created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at
FROM bronze.orders;

-- Parsing de JSON (común en datos ingestados)
SELECT 
    id,
    JSON_EXTRACT_PATH_TEXT(metadata, 'source') as source,
    JSON_EXTRACT_PATH_TEXT(metadata, 'version') as version
FROM bronze.events;

-- ============================================================================
-- 4. ENRIQUECIMIENTO CON LOOKUPS
-- ============================================================================

-- Join con tablas de referencia
SELECT 
    o.order_id,
    o.customer_id,
    c.customer_name,
    c.customer_segment,
    p.product_name,
    p.category
FROM bronze.orders o
LEFT JOIN silver.customers c ON o.customer_id = c.customer_id
LEFT JOIN silver.products p ON o.product_id = p.product_id;

-- ============================================================================
-- 5. DEDUPLICACIÓN AVANZADA
-- ============================================================================

-- Mantener el registro más reciente por clave
SELECT *
FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY updated_at DESC
        ) as rn
    FROM bronze.customers
) ranked
WHERE rn = 1;

-- Deduplicación con criterios de calidad
SELECT *
FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY email 
            ORDER BY 
                CASE WHEN phone IS NOT NULL THEN 1 ELSE 0 END DESC,
                updated_at DESC
        ) as rn
    FROM bronze.customers
) ranked
WHERE rn = 1;

-- ============================================================================
-- 6. SLOWLY CHANGING DIMENSIONS (SCD TYPE 2)
-- ============================================================================

-- Detectar cambios y crear nuevas versiones
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
FROM bronze.customers_latest b
WHERE NOT EXISTS (
    SELECT 1 
    FROM silver.customers_scd s
    WHERE s.customer_id = b.customer_id
      AND s.is_current = TRUE
      AND MD5(CONCAT(b.name, b.email, b.address)) = s.row_hash
);

-- ============================================================================
-- 7. AGREGACIONES Y MÉTRICAS DERIVADAS
-- ============================================================================

-- Calcular métricas por cliente
SELECT 
    customer_id,
    COUNT(*) as total_orders,
    SUM(amount) as total_spent,
    AVG(amount) as avg_order_value,
    MIN(order_date) as first_order_date,
    MAX(order_date) as last_order_date,
    DATEDIFF(day, MIN(order_date), MAX(order_date)) as customer_lifetime_days
FROM bronze.orders
GROUP BY customer_id;

-- ============================================================================
-- 8. PIVOTING Y UNPIVOTING
-- ============================================================================

-- Unpivot: convertir columnas en filas
SELECT customer_id, 'email' as contact_type, email as contact_value
FROM bronze.customers
WHERE email IS NOT NULL
UNION ALL
SELECT customer_id, 'phone' as contact_type, phone as contact_value
FROM bronze.customers
WHERE phone IS NOT NULL;

-- Pivot: convertir filas en columnas
SELECT 
    customer_id,
    MAX(CASE WHEN metric_name = 'total_orders' THEN metric_value END) as total_orders,
    MAX(CASE WHEN metric_name = 'total_spent' THEN metric_value END) as total_spent
FROM bronze.customer_metrics
GROUP BY customer_id;

-- ============================================================================
-- 9. MANEJO DE TIMESTAMPS Y AUDITORÍA
-- ============================================================================

-- Agregar metadatos de procesamiento
SELECT 
    *,
    CURRENT_TIMESTAMP as processed_at,
    'etl_pipeline_v1' as processed_by,
    MD5(CONCAT_WS('|', column1, column2, column3)) as row_hash
FROM bronze.raw_data;

-- ============================================================================
-- 10. INCREMENTAL LOADS (DELTA PROCESSING)
-- ============================================================================

-- Procesar solo registros nuevos o modificados
SELECT *
FROM bronze.orders
WHERE updated_at > (
    SELECT COALESCE(MAX(last_processed_timestamp), '1900-01-01')
    FROM silver.etl_watermarks
    WHERE table_name = 'orders'
);

-- ============================================================================
-- PATRÓN COMPLETO: BRONZE → SILVER
-- ============================================================================

-- Ejemplo completo de transformación
CREATE TABLE silver.orders AS
SELECT 
    -- IDs limpios
    CAST(order_id AS INTEGER) as order_id,
    CAST(customer_id AS INTEGER) as customer_id,
    
    -- Limpieza de texto
    UPPER(TRIM(status)) as status,
    
    -- Validación y defaults
    COALESCE(amount, 0) as amount,
    
    -- Conversión de tipos
    TO_DATE(order_date, 'YYYY-MM-DD') as order_date,
    
    -- Flags de calidad
    CASE 
        WHEN amount > 0 AND customer_id IS NOT NULL THEN 'valid'
        ELSE 'invalid'
    END as quality_flag,
    
    -- Metadatos de auditoría
    CURRENT_TIMESTAMP as silver_created_at,
    MD5(CONCAT_WS('|', order_id, customer_id, amount)) as row_hash

FROM bronze.orders_raw
WHERE order_date >= CURRENT_DATE - INTERVAL '90 days'  -- Ventana de procesamiento
  AND order_id IS NOT NULL  -- Validación básica
  
-- Deduplicación
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY order_id 
    ORDER BY updated_at DESC
) = 1;

