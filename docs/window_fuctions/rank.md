# RANK()

`RANK()` asigna posiciones a las filas, **pero deja saltos** cuando hay empates.

## Ejemplo

```sql
SELECT 
    producto,
    ventas,
    RANK() OVER (ORDER BY ventas DESC) AS posicion
FROM ventas;
```

**Resultado:**
| producto | ventas | posicion |
|----------|--------|----------|
| A        | 100    | 1        |
| B        | 100    | 1        |
| C        | 50     | 3        |

¿Notas el salto? Los productos A y B empatan en 1° lugar, pero el siguiente (C) es 3°, no 2°.

## Diferencia con ROW_NUMBER()

| producto | ventas | ROW_NUMBER() | RANK() |
|----------|--------|--------------|--------|
| A        | 100    | 1            | 1      |
| B        | 100    | 2            | 1      |
| C        | 50     | 3            | 3      |

- **ROW_NUMBER()**: siempre secuencial (1, 2, 3...)
- **RANK()**: permite empates y salta posiciones (1, 1, 3...)

## Con PARTITION BY

```sql
SELECT 
    categoria,
    producto,
    ventas,
    RANK() OVER (PARTITION BY categoria ORDER BY ventas DESC) AS posicion
FROM ventas_productos;
```

Aplica el ranking dentro de cada categoría.