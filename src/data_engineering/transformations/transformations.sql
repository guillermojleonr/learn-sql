-- ============================================================================
-- CONSULTAS SQL PARA PROCESOS ETL/ELT - TRANSFORMACIÓN BRONZE → SILVER
-- ============================================================================
-- Este archivo contiene patrones y ejemplos de consultas típicas utilizadas
-- en pipelines de datos para transformar datos crudos (bronze) en datos
-- limpios y validados (silver).
--
-- NOTA: Ver archivos .md en esta carpeta para ejemplos visuales con datos
--       antes y después de cada transformación.
--
-- Archivos de referencia:
--   - cleaning_standardization.md  → Ejemplos visuales de limpieza de texto
--   - validation_filtering.md      → Ejemplos visuales de validación
--   - data_type_conversions.md     → Ejemplos visuales de conversiones
--   - pivot_unpivot.md             → Ejemplos visuales de pivot/unpivot
--   - complete_etl_pattern.md      → Ejemplo completo de pipeline
-- ============================================================================

-- Ejemplo completo de transformación, usando un write pattern full refresh (CTAs)
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
    'etl_pipeline_v1' as processed_by,
    MD5(CONCAT_WS('|', order_id, customer_id, amount)) as row_hash,

    -- Deduplicación
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY order_id 
        ORDER BY updated_at DESC
    ) = 1;

FROM bronze.orders_raw
WHERE order_date >= CURRENT_DATE - INTERVAL '90 days'  -- Ventana de procesamiento
  AND order_id IS NOT NULL  -- Validación básica
  


