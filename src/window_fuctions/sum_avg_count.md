# Funciones de Agregado como Window Functions

Las funciones `SUM()`, `AVG()`, `COUNT()`, `MIN()`, `MAX()` pueden usarse como window functions.

## SUM() - Total acumulativo

```sql
SELECT 
    mes,
    ventas,
    SUM(ventas) OVER (ORDER BY mes) AS total_acumulado
FROM ventas_mensuales;
```

**Resultado:**
| mes | ventas | total_acumulado |
|-----|--------|-----------------|
| 1   | 100    | 100             |
| 2   | 150    | 250             |
| 3   | 200    | 450             |

Cada fila muestra la suma de todos los meses anteriores **incluyendo el actual**.

## SUM() con PARTITION BY

```sql
SELECT 
    categoria,
    mes,
    ventas,
    SUM(ventas) OVER (PARTITION BY categoria ORDER BY mes) AS total_categoria
FROM ventas;
```

Reinicia el acumulado para cada categoría.

## AVG() - Promedio acumulativo

```sql
SELECT 
    mes,
    ventas,
    AVG(ventas) OVER (ORDER BY mes) AS promedio_hasta_fecha
FROM ventas_mensuales;
```

Muestra el promedio de todos los meses hasta la fecha actual.

## COUNT() - Conteo acumulativo

```sql
SELECT 
    orden_id,
    fecha,
    COUNT(*) OVER (ORDER BY fecha) AS total_ordenes
FROM ordenes;
```

## Diferencia: ventana completa vs. acumulativa

```sql
-- Promedio de TODAS las ventas (misma ventana)
SELECT 
    producto,
    ventas,
    AVG(ventas) OVER () AS promedio_global
FROM ventas;

-- Promedio ACUMULATIVO (creciente)
SELECT 
    mes,
    ventas,
    AVG(ventas) OVER (ORDER BY mes) AS promedio_acumulativo
FROM ventas_mensuales;
```

La diferencia está en si incluyes `ORDER BY` o no:
- **Sin ORDER BY**: toda la partición como ventana
- **Con ORDER BY**: ventana móvil desde el inicio