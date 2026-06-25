# NTILE()

`NTILE()` divide las filas en grupos (percentiles, квартили, etc.) y asigna el número de grupo a cada fila.

## Ejemplo básico

```sql
SELECT 
    producto,
    ventas,
    NTILE(4) OVER (ORDER BY ventas DESC) AS cuarto
FROM ventas;
```

**Resultado:**
| producto | ventas | cuarto |
|----------|--------|--------|
| A        | 100    | 1      |
| B        | 80     | 1      |
| C        | 60     | 2      |
| D        | 40     | 2      |
| E        | 20     | 3      |
| F        | 10     | 4      |

Las filas se dividen en 4 grupos lo más igual posible.

## Casos de uso

### Cuartiles (4 grupos)

```sql
NTILE(4) OVER (ORDER BY ventas DESC)
```

### Deciles (10 grupos)

```sql
NTILE(10) OVER (ORDER BY ventas DESC)
```

### Percentiles (100 grupos)

```sql
NTILE(100) OVER (ORDER BY ventas DESC)
```

## Con PARTITION BY

```sql
SELECT 
    categoria,
    producto,
    ventas,
    NTILE(3) OVER (PARTITION BY categoria ORDER BY ventas DESC) AS grupo
FROM ventas;
```

Crea terciles dentro de cada categoría.

## Comportamiento con números impares

Si tienes 10 filas y pides 4 grupos:
- Grupos 1, 2, 3 = 3 filas
- Grupo 4 = 1 fila

Los primeros grupos reciben las filas extra cuando no divide exactamente.

## Ejemplo práctico: Segmentación de clientes

```sql
SELECT 
    cliente_id,
    gasto_total,
    NTILE(5) OVER (ORDER BY gasto_total DESC) AS segmento
FROM clientes
QUALIFY segmento = 1;  -- top 20% de clientes
```