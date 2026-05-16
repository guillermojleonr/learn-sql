-- Active: 1775008209648@@savingl.cl@3306
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

## Remover Tildes y Caracteres Especiales

Normaliza el texto eliminando acentos y caracteres no deseados para facilitar búsquedas, comparaciones y compatibilidad de sistemas.

### Antes (Bronze)

| name | slug | description |
|------|------|-------------|
| "Sebastián" | "producto-n°1" | "Oferta - $100!!" |
| "Mónica García" | "categoría/viva" | "¡Excelente estado!" |

### Después (Silver)

| name | slug | description |
|------|------|-------------|
| Sebastian | producto-n1 | Oferta - 100 |
| Monica Garcia | categoriaviva | Excelente estado |

### SQL

Utilizando `TRANSLATE` para tildes y `REGEXP_REPLACE` para caracteres especiales.

```sql
SELECT 
    TRANSLATE(name, 'áéíóúÁÉÍÓÚ', 'aeiouAEIOU') as name,
    REGEXP_REPLACE(slug, '[^a-zA-Z0-9-]', '', 'g') as slug,
    REGEXP_REPLACE(description, '[^a-zA-Z0-9 ]', '', 'g') as description
FROM bronze.catalog;
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
| `INITCAP()` | Capitaliza la primera letra de cada palabra | `"juan pérez"` → `"Juan Pérez"` |
| `TRANSLATE()` | Sustitución de caracteres (limpieza de tildes) | `TRANSLATE('á', 'á', 'a')` → `"a"` |
| `REGEXP_REPLACE()` | Limpieza avanzada mediante expresiones regulares | `REGEXP_REPLACE('A#1', '[^A-Z0-9]', '')` → `"A1"` |
| `COALESCE()` | Gestiona valores nulos asignando un valor por defecto | `COALESCE(NULL, 'N/A')` → `"N/A"` |