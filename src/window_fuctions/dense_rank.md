# DENSE_RANK()

`DENSE_RANK()` es como `RANK()` pero **sin saltos** en las posiciones.

## Ejemplo

```sql
SELECT 
    producto,
    ventas,
    DENSE_RANK() OVER (ORDER BY ventas DESC) AS posicion
FROM ventas;
```

**Resultado:**
| producto | ventas | posicion |
|----------|--------|----------|
| A        | 100    | 1        |
| B        | 100    | 1        |
| C        | 50     | 2        |

A diferencia de RANK(), aquí C obtiene posición 2 (sin salto).

## Comparación completa

| producto | ventas | ROW_NUMBER() | RANK() | DENSE_RANK() |
|----------|--------|--------------|--------|--------------|
| A        | 100    | 1            | 1      | 1            |
| B        | 100    | 2            | 1      | 1            |
| C        | 50     | 3            | 3      | 2            |
| D        | 30     | 4            | 4      | 3            |

- **ROW_NUMBER()**: secuencial puro
- **RANK()**: con empates, salta posiciones
- **DENSE_RANK()**: con empates, sin saltos