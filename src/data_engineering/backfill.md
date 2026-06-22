# Backfill y Fix Histórico

Cuando se descubre un problema en datos históricos de la capa silver, hay varias estrategias para corregirlo sin afectar el pipeline actual.

---

## El Patrón Híbrido: La Approación Más Común

1. **Corrige el pipeline** para que datos futuros no tengan el problema
2. **Aplica un fix histórico** solo a los datos afectados (una sola vez)

---

## Estrategias de Fix

### 1. UPDATE Puntual (más común)

Cuando sabes exactamente qué registros están mal.

```sql
-- Fix específico para registros con NULL en amount
UPDATE silver.orders
SET 
    amount = COALESCE(amount, 0),
    corrected_at = CURRENT_TIMESTAMP,
    quality_flag = 'fixed'
WHERE amount IS NULL
  AND order_date >= '2024-01-01';
```

**Cuándo usarlo:**
- Conoces el problema específico (campo X tiene valor Y que es incorrecto)
- Puedes identificar los registros afectados con un WHERE preciso
- El volumen de datos a corregir es manejable

---

### 2. UPDATE con Batch Processing (para tablas muy grandes)

Si la tabla es enorme y el UPDATE afecta millones de filas, hazlo en lotes.

```sql
-- Fix en lotes de 50,000 registros
DO $$
DECLARE
    batch_size INTEGER := 50000;
    affected_rows INTEGER := 1;
BEGIN
    WHILE affected_rows > 0 LOOP
        UPDATE silver.orders
        SET amount = COALESCE(amount, 0)
        WHERE amount IS NULL
        AND order_id IN (
            SELECT order_id 
            FROM silver.orders 
            WHERE amount IS NULL 
            LIMIT batch_size
        );
        
        GET DIAGNOSTICS affected_rows = ROW_COUNT;
        RAISE NOTICE 'Processed % rows', affected_rows;
        
        -- Commit explícito entre lotes (si tu DB lo requiere)
        COMMIT;
    END LOOP;
END $$;
```

---

### 3. Reconstrucción Parcial (ventana de tiempo)

Si sospechas que el problema abarca un período específico.

```sql
-- Eliminar y reprocesar solo los últimos 30 días
DELETE FROM silver.orders
WHERE order_date >= CURRENT_DATE - INTERVAL '30 days';

INSERT INTO silver.orders
SELECT 
    order_id,
    customer_id,
    status,
    COALESCE(amount, 0) as amount,  -- nueva lógica
    order_date,
    CURRENT_TIMESTAMP as reprocessed_at
FROM bronze.orders_raw
WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY updated_at DESC) = 1;
```

---

### 4. INSERT OVERWRITE / CTAS Temporal (reprocesamiento completo)

Cuando necesitas reaplicar toda la lógica de transformación a toda la tabla.

```sql
-- IMPORTANTE: Solo si tienes acceso completo a bronze
-- Esto reemplaza toda la tabla

INSERT OVERWRITE TABLE silver.orders
SELECT 
    CAST(order_id AS INTEGER) as order_id,
    CAST(customer_id AS INTEGER) as customer_id,
    COALESCE(amount, 0) as amount,  -- nueva lógica
    UPPER(TRIM(status)) as status,
    TO_DATE(order_date, 'YYYY-MM-DD') as order_date,
    CURRENT_TIMESTAMP as reprocessed_at
FROM bronze.orders_raw
WHERE order_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY updated_at DESC) = 1;
```

**Cuándo usarlo:**
- El problema afecta a toda la tabla de forma generalizada
- Tienesbronze disponible y la tabla no es excesivamente grande
- Necesitas reaplicar múltiples correcciones a la vez

---

## Matriz de Decisión

| Escenario | Estrategia Recomendada |
|-----------|------------------------|
| Conoces registros específicos | UPDATE puntual |
| Tabla > 10M filas | UPDATE en lotes |
| Problema en período específico | Reconstrucción parcial |
| Problema generalizado + bronze disponible | INSERT OVERWRITE |
|Pipeline roto por el problema | Primero fix, luego sigue |

---

## Consideraciones de Seguridad

```sql
-- Siempre hacer backup antes de un fix grande
-- Opción 1: Tabla backup
CREATE TABLE silver.orders_backup AS
SELECT * FROM silver.orders;

-- Opción 2: Snapshot (si tu DB lo soporta)
CREATE TABLE silver.orders_backup_20240101
SELECT * FROM silver.orders
WHERE 1=1;  -- copia completa (WHERE 1=1 always true)

-- Opción 3: Agregar columnas de auditoría antes del fix
ALTER TABLE silver.orders 
ADD COLUMN IF NOT EXISTS corrected_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS original_value DECIMAL(10,2);
```

---

## Validación Post-Fix

```sql
-- Verificar que el fix fue exitoso
SELECT 
    COUNT(*) as total,
    COUNT(amount) as non_null_amount,
    COUNT(*) - COUNT(amount) as remaining_nulls
FROM silver.orders;

-- Comparar antes vs después (si tienes metrics previas)
SELECT 
    'before' as period,
    MIN(processed_at) as min_date,
    MAX(processed_at) as max_date,
    COUNT(*) as total_rows
FROM silver.orders
WHERE quality_flag = 'invalid'

UNION ALL

SELECT 
    'after' as period,
    MIN(processed_at) as min_date,
    MAX(processed_at) as max_date,
    COUNT(*) as total_rows
FROM silver.orders
WHERE quality_flag = 'fixed';
```

---

## Recomendación Final

> **80% de los casos se resuelven con UPDATE puntual.**
> 
> No necesitas reprocesar toda la tabla si solo tienes un problema específico. Solo cambia el pipeline para que no vuelva a ocurrir y hace un fix histórico una sola vez.

Usa reprocesamiento completo (INSERT OVERWRITE) solo cuando:
- Hay múltiples campos afectados
- La lógica de transformación cambió significativamente
- El equipo tiene recursos para hacerlo de forma segura