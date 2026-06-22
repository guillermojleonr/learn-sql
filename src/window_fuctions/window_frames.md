# Window Frames (Marcos de Ventana)

Los window frames definen qué filas específicas se incluyen en el cálculo de la window function.

## Sintaxis general

```sql
OVER (
    ORDER BY columna
    ROWS BETWEEN <inicio> AND <fin>
)
```

## Opciones de marco

| Frame | Descripción |
|-------|-------------|
| `UNBOUNDED PRECEDING` | Desde el inicio de la partición |
| `UNBOUNDED FOLLOWING` | Hasta el final de la partición |
| `CURRENT ROW` | Solo la fila actual |
| `n PRECEDING` | n filas antes |
| `n FOLLOWING` | n filas después |

## Ejemplo: Promedio móvil de 3 meses

```sql
SELECT 
    mes,
    ventas,
    AVG(ventas) OVER (
        ORDER BY mes 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS promedio_movil_3
FROM ventas_mensuales;
```

**Resultado:**
| mes | ventas | promedio_movil_3 |
|-----|--------|------------------|
| 1   | 100    | 100.0            |
| 2   | 150    | 125.0            |
| 3   | 200    | 150.0            |
| 4   | 180    | 176.6            |

- Mes 1: solo 100 (no hay 2 anteriores)
- Mes 2: (100 + 150) / 2 = 125
- Mes 3: (100 + 150 + 200) / 3 = 150
- Mes 4: (150 + 200 + 180) / 3 = 176.6

## RANGE vs ROWS

### ROWS (basado en filas)

Cuenta filas físicas:

```sql
ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
-- Fila anterior + actual + siguiente
```

### RANGE (basado en valores)

Agrupa valores idénticos:

```sql
RANGE BETWEEN 1 PRECEDING AND 1 FOLLOWING
-- Todas las filas con valores dentro del rango
```

## Ejemplo completo: Totales acumulativos

```sql
-- Suma acumulativa (típico)
SUM(ventas) OVER (ORDER BY mes)

-- Equivalente a:
SUM(ventas) OVER (
    ORDER BY mes 
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
```

## Ejemplo: Suma de la ventana completa

```sql
-- Suma de TODA la partición (mismo valor en todas las filas)
SUM(ventas) OVER (
    ORDER BY mes
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
)
```

## GROUPS (agrupación por valores)

```sql
-- Todas las filas con el mismo valor que la fila actual
GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING
```

Útil cuando tienes muchos valores duplicados.

## Resumen de casos de uso

| Caso | Window Frame |
|------|--------------|
| Total acumulativo | `ROWS UNBOUNDED PRECEDING AND CURRENT ROW` |
| Promedio móvil | `ROWS BETWEEN n PRECEDING AND CURRENT ROW` |
| Comparar con primer valor | `ROWS UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` |
| Suma de ventana completa | `ROWS UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` |