# FIRST_VALUE() y LAST_VALUE()

Estas funciones devuelven el primer o último valor de una ventana.

## FIRST_VALUE() - Primer valor

```sql
SELECT 
    mes,
    ventas,
    FIRST_VALUE(ventas) OVER (ORDER BY mes) AS primera_venta
FROM ventas_mensuales;
```

**Resultado:**
| mes | ventas | primera_venta |
|-----|--------|---------------|
| 1   | 100    | 100           |
| 2   | 150    | 100           |
| 3   | 200    | 100           |

Todas las filas muestran el valor del primer mes.

## LAST_VALUE() - Último valor

```sql
SELECT 
    mes,
    ventas,
    LAST_VALUE(ventas) OVER (ORDER BY mes) AS ultima_venta
FROM ventas_mensuales;
```

**Resultado:**
| mes | ventas | ultima_venta |
|-----|--------|--------------|
| 1   | 100    | 100          |
| 2   | 150    | 150          |
| 3   | 200    | 200          |

**Nota:** Por defecto, LAST_VALUE() considera la ventana hasta la fila actual. Para obtener el último de toda la partición, usa:

```sql
LAST_VALUE(ventas) OVER (
    ORDER BY mes 
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
)
```

## Con PARTITION BY

```sql
SELECT 
    categoria,
    producto,
    ventas,
    FIRST_VALUE(producto) OVER (PARTITION BY categoria ORDER BY ventas DESC) AS producto_mas_vendido
FROM ventas;
```

Muestra el producto más vendido de cada categoría en todas las filas.

## nth_value() - Valor n-ésimo

```sql
SELECT 
    producto,
    ventas,
    NTH_VALUE(ventas, 2) OVER (ORDER BY ventas DESC) AS segunda_venta
FROM ventas;
```

Devuelve el segundo valor más alto.