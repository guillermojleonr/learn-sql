# Limpieza y Estandarización

Transformaciones básicas para normalizar y limpiar datos en pipelines ETL/ELT.

## Normalizar Texto (Mayúsculas, Minúsculas, Trim)

Convierte texto a mayúsculas/minúsculas y elimina espacios en blanco.

### Antes (Bronze)

| country | email | name |
|---------|-------|------|
| " españa " | "JOHN@EXAMPLE.COM" | "juan pérez" |
| "MEXICO " | "maria@test.com" | "MARIA GARCIA" |
| "  argentina  " | "PEPE@DOMAIN.ORG" | "luis martinez" |

### Después (Silver)

| country | email | name |
|---------|-------|------|
| ESPAÑA | john@example.com | Juan Pérez |
| MEXICO | maria@test.com | Maria Garcia |
| ARGENTINA | pepe@domain.org | Luis Martinez |

### SQL

```sql
SELECT 
    UPPER(TRIM(country)) as country,
    LOWER(TRIM(email)) as email,
    INITCAP(TRIM(name)) as name
FROM bronze.customers;
```

---

## Reemplazar Valores Nulos con Defaults

Maneja valores nulos asignando valores por defecto.

### Antes (Bronze)

| order_id | phone | address | status |
|----------|-------|---------|--------|
| 1001 | NULL | NULL | "shipped" |
| 1002 | "555-1234" | NULL | NULL |
| 1003 | NULL | "Calle Main 123" | "pending" |

### Después (Silver)

| order_id | phone | address | status |
|----------|-------|---------|--------|
| 1001 | N/A | Unknown | shipped |
| 1002 | 555-1234 | Unknown | pending |
| 1003 | N/A | Calle Main 123 | pending |

### SQL

```sql
SELECT 
    COALESCE(phone, 'N/A') as phone,
    COALESCE(address, 'Unknown') as address,
    COALESCE(status, 'pending') as status
FROM bronze.orders;
```

---

## Resumen

| Función | Propósito | Ejemplo |
|---------|-----------|---------|
| `TRIM()` | Elimina espacios en blanco | `"  hola  "` → `"hola"` |
| `UPPER()` | Convierte a mayúsculas | `"hola"` → `"HOLA"` |
| `LOWER()` | Convierte a minúsculas | `"HOLA"` → `"hola"` |
| `INITCAP()` | Capitaliza palabras | `"juan García"` → `"Juan García"` |
| `COALESCE()` | Reemplaza nulos | `COALESCE(NULL, 'default')` → `"default"` |