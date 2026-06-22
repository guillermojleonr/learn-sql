# QUALIFY ROW_NUMBER() - Explicación para Principiantes

## ¿Qué son las Window Functions?

Antes de entender `QUALIFY`, necesitas saber qué es una **window function** (función de ventana).

Una window function realiza un cálculo sobre un conjunto de filas relacionadas con la fila actual, **sin agruparlas en una sola**. Es como si cada fila pudiera "ver" a sus vecinas.

Ejemplos comunes de window functions:
- `ROW_NUMBER()` - número de fila dentro de una partición
- `RANK()` - posición (con duplicados)
- `DENSE_RANK()` - posición sin saltos
- `SUM()`, `AVG()`, `COUNT()` - agregados acumulativos

---

## ROW_NUMBER() básico

`ROW_NUMBER()` asigna un número secuencial a cada fila:

```sql
SELECT 
    nombre,
    ciudad,
    ROW_NUMBER() OVER (ORDER BY nombre) AS numero_fila
FROM usuarios;
```

**Resultado:**
| nombre | ciudad | numero_fila |
|--------|--------|-------------|
| Ana    | Madrid | 1           |
| Luis   | Barcelona | 2       |
| María  | Sevilla | 3          |

La magia está en `OVER (ORDER BY nombre)` que define el orden de la numeración.

---

## Particiones con PARTITION BY

Puedes reiniciar la numeración para cada grupo usando `PARTITION BY`:

```sql
SELECT 
    nombre,
    ciudad,
    ROW_NUMBER() OVER (PARTITION BY ciudad ORDER BY nombre) AS posicion
FROM usuarios;
```

**Resultado:**
| nombre | ciudad | posicion |
|--------|--------|----------|
| Ana    | Madrid | 1        |
| Carlos | Madrid | 2        |
| Luis   | Barcelona | 1    |
| María  | Barcelona | 2    |

Cada ciudad tiene su propia secuencia 1, 2, 3...

---

## El Problema que resuelve QUALIFY

Históricamente, si querías filtrar por el resultado de una window function, necesitabas un subquery o CTE:

```sql
-- Método antiguo (sin QUALIFY)
SELECT * FROM (
    SELECT 
        nombre,
        ciudad,
        ROW_NUMBER() OVER (PARTITION BY ciudad ORDER BY nombre) AS posicion
    FROM usuarios
) AS subquery
WHERE posicion = 1;
```

**Problemas:**
- Código verboso (subquery o CTE requerido)
- Difícil de leer
- Más líneas de código

---

## QUALIFY al rescate

`QUALIFY` te permite filtrar directamente por window functions en el mismo SELECT:

```sql
-- Método moderno (con QUALIFY)
SELECT 
    nombre,
    ciudad,
    ROW_NUMBER() OVER (PARTITION BY ciudad ORDER BY nombre) AS posicion
FROM usuarios
QUALIFY posicion = 1;
```

**Resultado:**
| nombre | ciudad | posicion |
|--------|--------|----------|
| Ana    | Madrid | 1        |
| Luis   | Barcelona | 1    |

¡Mucho más limpio!

---

## Ejemplos prácticos

### 1. Obtener el primer pedido de cada cliente

```sql
SELECT 
    cliente_id,
    pedido_id,
    fecha,
    total
FROM pedidos
QUALIFY ROW_NUMBER() OVER (PARTITION BY cliente_id ORDER BY fecha) = 1;
```

### 2. Top 3 productos por categoría

```sql
SELECT 
    categoria,
    producto,
    ventas
FROM ventas_productos
QUALIFY ROW_NUMBER() OVER (PARTITION BY categoria ORDER BY ventas DESC) <= 3;
```

### Orden descendente (DESC)

```sql
SELECT 
    producto,
    ventas,
    ROW_NUMBER() OVER (ORDER BY ventas DESC) AS ranking_mayor_menor
FROM ventas;
```

El producto con más ventas será el #1.

### 3. Encontrar duplicados

```sql
SELECT pedido_id, cliente_id
FROM pedidos
QUALIFY COUNT(*) OVER (PARTITION BY pedido_id, cliente_id) > 1;
```

---

## Compatibilidad

**Bases de datos que soportan QUALIFY:**
- Snowflake ✅
- BigQuery ✅
- Databricks ✅
- DuckDB ✅

**Bases de datos que NO soportan QUALIFY:**
- PostgreSQL ❌
- MySQL ❌
- SQL Server ❌

Para estas últimas, debes usar el método del subquery/CTE.

---

## Resumen

| Concepto | Descripción |
|----------|-------------|
| `ROW_NUMBER()` | Asigna número secuencial a cada fila |
| `OVER()` | Define la "ventana" de filas a considerar |
| `ORDER BY` | Define el orden de la numeración |
| `PARTITION BY` | Reinicia el conteo para cada grupo |
| `QUALIFY` | Filtra por el resultado de la window function |

`QUALIFY` es simplemente un atajo de sintaxis que hace el código más legible y directo cuando quieres filtrar usando window functions.