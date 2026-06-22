# LAG() y LEAD()

Estas funciones permiten acceder a filas anteriores o posteriores sin self-join.

## LAG() - Valor anterior

`LAG()` devuelve el valor de la fila **anterior**:

```sql
SELECT 
    mes,
    ventas,
    LAG(ventas) OVER (ORDER BY mes) AS ventas_mes_anterior
FROM ventas_mensuales;
```

**Resultado:**
| mes | ventas | ventas_mes_anterior |
|-----|--------|---------------------|
| 1   | 100    | NULL                |
| 2   | 150    | 100                 |
| 3   | 200    | 150                 |

## LAG() con offset

Por defecto trae la fila anterior, pero puedes especificar cuántas filas atrás:

```sql
LAG(ventas, 2)  -- 2 filas atrás
LAG(ventas, 3)  -- 3 filas atrás
```

```sql
SELECT 
    mes,
    ventas,
    LAG(ventas, 2) OVER (ORDER BY mes) AS ventas_2_meses_atras
FROM ventas_mensuales;
```

## LAG() con valor por defecto

Si no hay fila anterior, devuelve NULL. Puedes especificar un valor por defecto:

```sql
LAG(ventas, 1, 0)  -- si es NULL, devuelve 0
```

## LEAD() - Valor siguiente

`LEAD()` devuelve el valor de la fila **siguiente**:

```sql
SELECT 
    mes,
    ventas,
    LEAD(ventas) OVER (ORDER BY mes) AS ventas_mes_siguiente
FROM ventas_mensuales;
```

**Resultado:**
| mes | ventas | ventas_mes_siguiente |
|-----|--------|----------------------|
| 1   | 100    | 150                  |
| 2   | 150    | 200                  |
| 3   | 200    | NULL                 |

## Uso con PARTITION BY

```sql
SELECT 
    categoria,
    mes,
    ventas,
    LAG(ventas) OVER (PARTITION BY categoria ORDER BY mes) AS anterior
FROM ventas;
```

Funciona igual, pero reinicia para cada categoría.

## Ejemplo práctico: Variación intermensual

```sql
SELECT 
    mes,
    ventas,
    LAG(ventas) OVER (ORDER BY mes) AS anterior,
    ventas - LAG(ventas) OVER (ORDER BY mes) AS variacion
FROM ventas_mensuales;
```

| mes | ventas | anterior | variacion |
|-----|--------|----------|-----------|
| 1   | 100    | NULL     | NULL      |
| 2   | 150    | 100      | 50        |
| 3   | 200    | 150      | 50        |