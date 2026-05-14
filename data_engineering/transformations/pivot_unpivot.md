# Pivoting y Unpivoting

Transformaciones para reorganizar datos entre formato ancho y largo.

## Unpivot: Columnas → Filas

Convierte múltiples columnas en filas, útil para normalizar datos.

### Ejemplo: Contactos

Convierte email y phone (que están como columnas) en filas con tipo.

### Antes (Bronze)

| customer_id | name | email | phone |
|-------------|------|-------|-------|
| 101 | Juan Pérez | juan@example.com | 555-1234 |
| 102 | María García | maria@example.com | NULL |
| 103 | Pedro López | NULL | 555-5678 |

### Después (Silver)

| customer_id | name | contact_type | contact_value |
|-------------|------|--------------|---------------|
| 101 | Juan Pérez | email | juan@example.com |
| 101 | Juan Pérez | phone | 555-1234 |
| 102 | María García | email | maria@example.com |
| 103 | Pedro López | phone | 555-5678 |

### SQL

```sql
SELECT customer_id, 'email' as contact_type, email as contact_value
FROM bronze.customers
WHERE email IS NOT NULL
UNION ALL
SELECT customer_id, 'phone' as contact_type, phone as contact_value
FROM bronze.customers
WHERE phone IS NOT NULL;
```

---

## Pivot: Filas → Columnas

Convierte filas en columnas, útil para crear reportes resumidos.

### Ejemplo: Métricas de Cliente

Convierte diferentes métricas (que están como filas) en columnas.

### Antes (Bronze)

| customer_id | metric_name | metric_value |
|-------------|-------------|--------------|
| 101 | total_orders | 25 |
| 101 | total_spent | 1500.00 |
| 102 | total_orders | 10 |
| 102 | total_spent | 450.00 |
| 103 | total_orders | 50 |
| 103 | total_spent | 3200.00 |

### Después (Silver)

| customer_id | total_orders | total_spent |
|-------------|--------------|-------------|
| 101 | 25 | 1500.00 |
| 102 | 10 | 450.00 |
| 103 | 50 | 3200.00 |

### SQL

```sql
SELECT 
    customer_id,
    MAX(CASE WHEN metric_name = 'total_orders' THEN metric_value END) as total_orders,
    MAX(CASE WHEN metric_name = 'total_spent' THEN metric_value END) as total_spent
FROM bronze.customer_metrics
GROUP BY customer_id;
```

### ⚠️ Consideración Importante: Duplicados

Usar `MAX()` (o cualquier agregación) **no elimina el riesgo de duplicados** — solo lo oculta. Si tienes:

| customer_id | metric_name | metric_value |
|-------------|-------------|--------------|
| 101 | total_orders | 25 |
| 101 | total_orders | **30** | ← duplicado

El resultado sería `25` (el máximo), perdiendo el valor real.

**Solución: Deduplicar antes de pivotar**

```sql
-- Primero deduplicar, luego pivotar
WITH deduplicated AS (
    SELECT customer_id, metric_name, metric_value
    FROM bronze.customer_metrics
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY customer_id, metric_name 
        ORDER BY updated_at DESC
    ) = 1
)
SELECT 
    customer_id,
    MAX(CASE WHEN metric_name = 'total_orders' THEN metric_value END) as total_orders,
    MAX(CASE WHEN metric_name = 'total_spent' THEN metric_value END) as total_spent
FROM deduplicated
GROUP BY customer_id;
```

**Alternativa: Detectar duplicados antes de procesar**

```sql
SELECT customer_id, metric_name, COUNT(*) as duplicates
FROM bronze.customer_metrics
GROUP BY customer_id, metric_name
HAVING COUNT(*) > 1;
```

---

## Ejemplo Visual: Transformación Completa

### Bronze (Formato Largo - Multiple Filas por Producto)

| product_id | attribute | value |
|------------|-----------|-------|
| P001 | color | rojo |
| P001 | tamaño | grande |
| P001 | peso | 5kg |
| P002 | color | azul |
| P002 | tamaño | pequeño |
| P002 | peso | 2kg |

### Silver (Formato Ancho - Una Fila por Producto)

| product_id | color | tamaño | peso |
|------------|-------|--------|------|
| P001 | rojo | grande | 5kg |
| P002 | azul | pequeño | 2kg |

### SQL (Pivot)

```sql
SELECT 
    product_id,
    MAX(CASE WHEN attribute = 'color' THEN value END) as color,
    MAX(CASE WHEN attribute = 'tamaño' THEN value END) as tamaño,
    MAX(CASE WHEN attribute = 'peso' THEN value END) as peso
FROM bronze.product_attributes
GROUP BY product_id;
```

---

## Resumen

| Operación | Dirección | Uso Común |
|-----------|-----------|-----------|
| **UNPIVOT** | Columnas → Filas | Normalizar, datos relacionales |
| **PIVOT** | Filas → Columnas | Reportes, dashboards, agregaciones |

### Cuándo Usar Cada Uno

| Escenario | Transformación |
|-----------|----------------|
| Datos de sensores en columnas por fecha | Unpivot |
| Métricas en filas que quieres como columnas | Pivot |
| Normalizar para almacenamiento relacional | Unpivot |
| Preparar datos para visualización | Pivot |