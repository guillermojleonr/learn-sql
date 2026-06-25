# Validación y Filtrado

Patrones para filtrar registros válidos y marcar datos con problemas de calidad.

## Filtrar Registros Válidos

Define registros "buenos" y excluye todo lo demás.

### Antes (Bronze)

| transaction_id | amount | transaction_date | customer_id | email |
|----------------|--------|------------------|-------------|-------|
| TXN001 | -50.00 | 2024-01-15 | 101 | john@example.com |
| TXN002 | 150.00 | NULL | 102 | maria@test.com |
| TXN003 | 200.00 | 2024-01-16 | NULL | invalid-email |
| TXN004 | 75.50 | 2024-01-17 | 104 | pedro@test.com |
| TXN005 | 0.00 | 2024-01-18 | 105 | ana@example.com |

### Después (Silver)

| transaction_id | amount | transaction_date | customer_id | email |
|----------------|--------|------------------|-------------|-------|
| TXN004 | 75.50 | 2024-01-17 | 104 | pedro@test.com |

### SQL

```sql
SELECT *
FROM bronze.transactions
WHERE amount > 0
  AND transaction_date IS NOT NULL
  AND customer_id IS NOT NULL
  AND email LIKE '%@%.%';
```

---

## Marcar Registros con Problemas de Calidad

En lugar de eliminar registros inválidos, los marcamos con un flag para auditoría.

### Antes (Bronze)

| order_id | email | amount | created_at |
|----------|-------|--------|------------|
| 1001 | john@example.com | 150.00 | 2024-01-15 |
| 1002 | invalid-email | 200.00 | 2024-01-16 |
| 1003 | maria@test.com | -50.00 | 2024-01-17 |
| 1004 | pedro@test.com | 75.00 | 2025-12-31 |
| 1005 | ana@company.com | 300.00 | 2024-01-18 |

### Después (Silver)

| order_id | email | amount | created_at | data_quality_flag |
|----------|-------|--------|------------|-------------------|
| 1001 | john@example.com | 150.00 | 2024-01-15 | valid |
| 1002 | invalid-email | 200.00 | 2024-01-16 | invalid_email |
| 1003 | maria@test.com | -50.00 | 2024-01-17 | negative_amount |
| 1004 | pedro@test.com | 75.00 | 2025-12-31 | future_date |
| 1005 | ana@company.com | 300.00 | 2024-01-18 | valid |

### SQL

```sql
SELECT *,
    CASE 
        WHEN email NOT LIKE '%@%' THEN 'invalid_email'
        WHEN amount < 0 THEN 'negative_amount'
        WHEN created_at > CURRENT_DATE THEN 'future_date'
        ELSE 'valid'
    END as data_quality_flag
FROM bronze.orders;
```

---

## Resumen

### Técnicas de Filtrado

| Técnica | Descripción | Cuándo usarla |
|---------|-------------|---------------|
| **WHERE** | Elimina registros no válidos | Cuando los datos inválidos no tienen valor |
| **CASE + Flag** | Marca sin eliminar | Cuando necesitas auditar o reprocesar |

### Validaciones Comunes

| Validación | SQL | Problema Detectado |
|------------|-----|-------------------|
| No nulo | `column IS NOT NULL` | Valores faltantes |
| Positivo | `column > 0` | Valores negativos inválidos |
| Email válido | `email LIKE '%@%.%'` | Formato de email incorrecto |
| Rango válido | `column BETWEEN 0 AND 100` | Valores fuera de rango |
| Fecha no futura | `date <= CURRENT_DATE` | Fechas futuras inválidas |