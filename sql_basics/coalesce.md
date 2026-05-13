# COALESCE: Manejo de Valores Nulos

`COALESCE` es una función que retorna el primer valor no nulo de una lista de argumentos. Es fundamental para el manejo de datos incompletos en SQL.

## Sintaxis

```sql
COALESCE(valor1, valor2, valor3, ...)
```

Retorna el primer valor que no sea NULL.

---

## Casos de Uso

### 1. Valores por defecto para display

Cuando los resultados se muestran al usuario, es preferible mostrar un texto significativo en lugar de valores vacíos.

```sql
SELECT 
    COALESCE(phone, 'N/A') as phone,
    COALESCE(address, 'Unknown') as address,
    COALESCE(status, 'pending') as status
FROM orders;
```

**Por qué:** NULL no tiene significado para el usuario final. Un "N/A" o "Unknown" comunica que el dato no está disponible de forma clara.

---

### 2. Protección en cálculos y agregaciones

NULL en operaciones matemáticas produce NULL, lo cual puede romper cálculos.

```sql
-- Sin COALESCE: si amount tiene NULLs, el resultado puede ser NULL
SELECT SUM(amount) FROM orders;

-- Con COALESCE: los NULLs se tratan como 0
SELECT SUM(COALESCE(amount, 0)) FROM orders;
```

**Por qué:**
- `NULL + 10` → `NULL`
- `NULL * 5` → `NULL`
- `SUM` ignora NULLs, pero en otros contextos (CASE, operaciones directas) puede ser problemático

---

### 3. Comparaciones seguras con fechas/timestamps

Al obtener valores máximo/mínimo de tablas vacías, el resultado es NULL.

```sql
WHERE event_timestamp > (
    SELECT COALESCE(MAX(event_timestamp), '1900-01-01')
    FROM silver.events
)
```

**Por qué:** Si la tabla está vacía, `MAX()` retorna NULL. Sin COALESCE:
- La comparación fallaría
- Retornaría resultados inesperados
- El pipeline de datos podría romperse

---

### 4. Valores por defecto en inserciones

```sql
INSERT INTO silver.orders (order_id, amount, status)
SELECT 
    order_id,
    COALESCE(amount, 0),
    COALESCE(status, 'pending')
FROM bronze.orders_raw;
```

**Por qué:** Evita errores de constraints NOT NULL y mantiene consistencia en la capa silver.

---

## Casos donde NO usar COALESCE

| Situación | Razón |
|-----------|-------|
| WHERE con `IS NOT NULL` | El NULL es intencional, significa "no aplica" |
| JOINs | Quiere distinguir entre "no match" y "valor vacío" |
| Datos que legitimately pueden ser NULL | Ej: `phone` en customers puede no existir |

---

## Regla General

**Usar COALESCE cuando:**
- El NULL rompería un cálculo
- El resultado final necesita un valor concreto (display,插入, comparación)
- Hay un valor por defecto sensato

**No usar COALESCE cuando:**
- El NULL tiene significado semántico (dato no disponible vs dato vacío)
- Se quiere distinguir entre diferentes tipos de "ausencia de dato"

---

## Alternativas

### IFNULL (MySQL/MariaDB)
```sql
IFNULL(amount, 0)  -- Solo 2 argumentos
```

### NVL (Oracle)
```sql
NVL(amount, 0)  -- Solo 2 argumentos
```

### CASE (universal)
```sql
CASE WHEN amount IS NOT NULL THEN amount ELSE 0 END
```

COALESCE es preferible cuando hay múltiples valores por verificar o cuando se requiere portabilidad entre bases de datos.
---