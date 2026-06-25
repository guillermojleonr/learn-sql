# Transformaciones de Tipos de Datos

Conversiones entre tipos de datos para asegurar compatibilidad y precisión.

## Conversión de Tipos

Convierte datos de un tipo a otro (CAST o funciones específicas).

### Antes (Bronze)

| order_id | amount | order_date | created_at |
|----------|--------|------------|------------|
| "1001" | "150.75" | "2024-01-15" | "2024-01-15 14:30:00" |
| "1002" | "200.50" | "2024-01-16" | "2024-01-16 09:15:00" |
| "1003" | "75.25" | "2024-01-17" | "2024-01-17 18:45:00" |

> **Nota:** Los datos en bronze pueden venir como texto (VARCHAR) desde archivos JSON, CSV, o APIs.

### Después (Silver)

| order_id | amount | order_date | created_at |
|----------|--------|------------|------------|
| 1001 | 150.75 | 2024-01-15 | 2024-01-15 14:30:00 |
| 1002 | 200.50 | 2024-01-16 | 2024-01-16 09:15:00 |
| 1003 | 75.25 | 2024-01-17 | 2024-01-17 18:45:00 |

| Campo | Tipo Original | Tipo Destino |
|-------|---------------|--------------|
| order_id | VARCHAR | INTEGER |
| amount | VARCHAR | DECIMAL(10,2) |
| order_date | VARCHAR | DATE |
| created_at | VARCHAR | TIMESTAMP |

### SQL

```sql
SELECT 
    CAST(order_id AS INTEGER) as order_id,
    CAST(amount AS DECIMAL(10,2)) as amount,
    TO_DATE(order_date, 'YYYY-MM-DD') as order_date,
    TO_TIMESTAMP(created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at
FROM bronze.orders;
```

---

## Funciones de Conversión por Base de Datos

### SQL Server

```sql
SELECT 
    CAST(order_id AS INT) as order_id,
    CAST(amount AS DECIMAL(10,2)) as amount,
    CONVERT(DATE, order_date, 'YYYY-MM-DD') as order_date,
    CONVERT(DATETIME, created_at, 'YYYY-MM-DD HH:MI:SS') as created_at
FROM bronze.orders;
```

### PostgreSQL

```sql
SELECT 
    order_id::INTEGER as order_id,
    amount::DECIMAL(10,2) as amount,
    order_date::DATE as order_date,
    created_at::TIMESTAMP as created_at
FROM bronze.orders;
```

### BigQuery

```sql
SELECT 
    CAST(order_id AS INT64) as order_id,
    CAST(amount AS NUMERIC(10,2)) as amount,
    PARSE_DATE('%Y-%m-%d', order_date) as order_date,
    CAST(created_at AS TIMESTAMP) as created_at
FROM bronze.orders;
```

---

## Resumen

| Función | Base de Datos | Propósito |
|---------|---------------|-----------|
| `CAST(x AS tipo)` | Universal | Conversión genérica |
| `CONVERT(tipo, x)` | SQL Server | Conversión con formato |
| `TO_DATE(x, formato)` | PostgreSQL/Oracle | Texto a fecha |
| `TO_TIMESTAMP(x, formato)` | PostgreSQL/Oracle | Texto a timestamp |
| `PARSE_DATE(formato, x)` | BigQuery | Texto a fecha |

### Tipos Numéricos Comunes

| Tipo | Precisión | Uso |
|------|-----------|-----|
| `INTEGER` / `INT` | Entero | IDs, conteos |
| `DECIMAL(p,s)` | Decimal exacto | Montos, coordenadas |
| `NUMERIC(p,s)` | Decimal exacto | Equivalente a DECIMAL |
| `FLOAT` / `REAL` | Aproximado | Mediciones científicas |
| `DOUBLE` | Aproximado | Precisión extendida |