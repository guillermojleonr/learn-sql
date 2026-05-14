# Patrón Completo: Bronze → Silver

Ejemplo integral de transformación de datos crudos a datos listos para consumo.

## Descripción del Pipeline

Este patrón combina múltiples técnicas de transformación:
- Limpieza de texto
- Conversión de tipos
- Validación y defaults
- Flags de calidad
- Metadatos de auditoría
- Deduplicación

---

## Datos de Entrada (Bronze)

### Tabla: bronze.orders_raw

| order_id | customer_id | status | amount | order_date | updated_at | created_at |
|----------|-------------|--------|--------|------------|------------|------------|
| "1001" | "501" | "  Shipped  " | "150.00" | "2024-01-15" | 2024-01-15 10:30:00 | 2024-01-14 09:00:00 |
| "1002" | NULL | "pending" | NULL | "2024-01-16" | 2024-01-16 11:00:00 | 2024-01-15 14:00:00 |
| "1003" | "503" | "cancelled" | "200.50" | "2024-01-17" | 2024-01-17 16:00:00 | 2024-01-16 10:00:00 |
| "1001" | "501" | "  Shipped  " | "150.00" | "2024-01-15" | 2024-01-16 08:00:00 | 2024-01-14 09:00:00 |
| "1004" | "504" | "delivered" | "75.25" | "2024-10-20" | 2024-10-20 12:00:00 | 2024-10-19 11:00:00 |
| "1005" | "505" | "PENDING" | "0" | "2024-01-18" | 2024-01-18 09:00:00 | 2024-01-17 15:00:00 |

### Problemas en los datos:
- order_id y customer_id son texto (deben ser integer)
- status tiene espacios extra y está en minúsculas
- amount tiene valores nulos
- order_date viene como texto
- Hay duplicados (order_id 1001 aparece dos veces)
- order_id 1002 tiene customer_id nulo
- order_id 1005 tiene amount = 0 (inválido)
- order_id 1004 está fuera de la ventana de 90 días

---

## Datos de Salida (Silver)

### Tabla: silver.orders

| order_id | customer_id | status | amount | order_date | quality_flag | silver_created_at | processed_by | row_hash |
|----------|-------------|--------|--------|------------|--------------|-------------------|--------------|----------|
| 1001 | 501 | SHIPPED | 150.00 | 2024-01-15 | valid | 2024-01-20 10:00:00 | etl_pipeline_v1 | a1b2c3... |
| 1003 | 503 | CANCELLED | 200.50 | 2024-01-17 | valid | 2024-01-20 10:00:00 | etl_pipeline_v1 | d4e5f6... |

### Explicación:
- **order_id 1001**: Deduplicado (quedó el registro con updated_at más reciente)
- **order_id 1002**: Excluido (customer_id es nulo)
- **order_id 1003**: Incluido con status normalizado
- **order_id 1004**: Excluido (fuera de ventana de 90 días)
- **order_id 1005**: Excluido (amount = 0 no pasa validación amount > 0)

---

## SQL del Pipeline

```sql
CREATE TABLE silver.orders AS
SELECT 
    -- IDs limpios (conversión de texto a integer)
    CAST(order_id AS INTEGER) as order_id,
    CAST(customer_id AS INTEGER) as customer_id,
    
    -- Limpieza de texto (mayúsculas + trim)
    UPPER(TRIM(status)) as status,
    
    -- Validación y defaults (nulos a 0)
    COALESCE(amount, 0) as amount,
    
    -- Conversión de tipos (texto a fecha)
    TO_DATE(order_date, 'YYYY-MM-DD') as order_date,
    
    -- Flags de calidad (reglas de validación)
    CASE 
        WHEN amount > 0 AND customer_id IS NOT NULL THEN 'valid'
        ELSE 'invalid'
    END as quality_flag,
    
    -- Metadatos de auditoría
    CURRENT_TIMESTAMP as silver_created_at,
    'etl_pipeline_v1' as processed_by,
    MD5(CONCAT_WS('|', order_id, customer_id, amount)) as row_hash,

    -- Deduplicación (QUALIFY mantiene solo el registro más reciente)
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY order_id 
        ORDER BY updated_at DESC
    ) = 1

FROM bronze.orders_raw
WHERE order_date >= CURRENT_DATE - INTERVAL '90 days'  -- Ventana de procesamiento
  AND order_id IS NOT NULL  -- Validación básica
```

---

## Diagrama del Flujo

```
┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│   BRONZE (Raw)      │     │   TRANSFORMACIÓN    │     │   SILVER (Clean)    │
│                     │     │                     │     │                     │
│  • Datos crudos     │     │  1. CAST tipos      │     │  • Tipos correctos  │
│  • Formato texto    │ ──▶ │  2. UPPER/TRIM      │ ──▶ │  • Texto normalizado│
│  • Espacios extra   │     │  3. COALESCE nulos  │     │  • Nulos tratados   │
│  • Duplicados       │     │  4. WHERE filtrado  │     │  • Deduplicado      │
│  • Nulos            │     │  5. QUALIFY dedup   │     │  • Validaciones     │
│  • Sin metadatos    │     │  6. Auditoría MD5   │     │  • Con metadatos    │
└─────────────────────┘     └─────────────────────┘     └─────────────────────┘
```

---

## Componentes del Pipeline

### 1. Conversión de Tipos
```sql
CAST(order_id AS INTEGER) as order_id
```
Convierte texto a número para operaciones matemáticas y joins.

### 2. Limpieza de Texto
```sql
UPPER(TRIM(status)) as status
```
Elimina espacios y normaliza a mayúsculas.

### 3. Manejo de Nulos
```sql
COALESCE(amount, 0) as amount
```
Reemplaza nulos con valores seguros.

### 4. Filtrado
```sql
WHERE order_date >= CURRENT_DATE - INTERVAL '90 days'
  AND order_id IS NOT NULL
```
Limita el procesamiento a datos relevantes.

### 5. Flags de Calidad
```sql
CASE 
    WHEN amount > 0 AND customer_id IS NOT NULL THEN 'valid'
    ELSE 'invalid'
END as quality_flag
```
Marca la calidad de cada registro.

### 6. Deduplicación
```sql
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY order_id 
    ORDER BY updated_at DESC
) = 1
```
Mantiene solo el registro más reciente por clave.

### 7. Auditoría
```sql
MD5(CONCAT_WS('|', order_id, customer_id, amount)) as row_hash
```
Crea un identificador único para tracking de cambios.

---

## Mejores Prácticas

| Práctica | Descripción |
|----------|-------------|
| **Ventana de procesamiento** | Limita los datos a procesar (90 días) |
| **Validación temprana** | Filtra nulos en el WHERE antes de procesar |
| **Deduplicación** | Usa QUALIFY para evitar duplicados |
| **Flags de calidad** | No elimines datos; márcalos para auditoría |
| **Metadatos** | Agrega timestamps y hashes para tracking |
| **Nombre de pipeline** | Versiona el código ('etl_pipeline_v1') |