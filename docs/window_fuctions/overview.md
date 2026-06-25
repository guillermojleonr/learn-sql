# Window Functions - Introducción y Fundamentos

## El Problema que dio origen a las Window Functions

Antes de las window functions, había un problema fundamental en SQL: **la tensión entre agregación y detalle**.

### Agregación vs. Detalle

Cuando usas `GROUP BY`, pierdes el detalle de las filas individuales:

```sql
-- Consulta agrupada: pierdes las filas individuales
SELECT ciudad, SUM(ventas) AS total
FROM pedidos
GROUP BY ciudad;
```

¿Qué pasa si necesitas **ambos** al mismo tiempo? Antes de las window functions, las opciones eran limitadas:

1. **Subqueries**: Consultas anidadas difíciles de leer
2. **JOINS con tablas agregadas**: Repetitivas y propensas a errores
3. **Tablas temporales**: Proceso manual en varios pasos

```sql
-- Solución ANTES de window functions (engorrosa)
SELECT 
    p.*,
    t.total_ciudad
FROM pedidos p
JOIN (
    SELECT ciudad, SUM(ventas) AS total_ciudad
    FROM pedidos
    GROUP BY ciudad
) t ON p.ciudad = t.ciudad;
```

## ¿Qué es una Window Function?

Una **window function** (función de ventana) es una función que realiza un cálculo sobre un conjunto de filas **relacionadas con la fila actual**, pero **sin agruparlas**.

La clave está en la palabra "ventana": define un conjunto de filas que la función puede "ver" para realizar su cálculo.

### Sintaxis básica

```sql
function_name() OVER (
    [PARTITION BY columna]   -- Opcional: divide en grupos
    [ORDER BY columna]       -- Opcional: define orden
    [ROWS/RANGE frame]       -- Opcional: define el marco de la ventana
)
```

- **`OVER()`**: Indica que es una window function
- **`PARTITION BY`**: Divide el resultado en particiones (como un GROUP BY pero sin perder filas)
- **`ORDER BY`**: Define el orden dentro de cada partición

## ¿Por qué se crearon?

Las window functions surgen para resolver **3 casos de uso principales**:

### 1. Cálculos acumulados sin perder detalle

Obtener el total acumulado manteniendo cada fila individual:

```sql
SELECT 
    mes,
    ventas,
    SUM(ventas) OVER (ORDER BY mes) AS total_acumulado
FROM ventas_mensuales;
```

### 2. Rankings y posiciones

Asignar posiciones sin necesidad de self-joins:

```sql
SELECT 
    producto,
    ventas,
    RANK() OVER (ORDER BY ventas DESC) AS posicion
FROM productos;
```

### 3. Comparaciones entre filas

Comparar cada fila con la anterior o siguiente:

```sql
SELECT 
    fecha,
    precio,
    LAG(precio) OVER (ORDER BY fecha) AS precio_anterior
FROM acciones;
```

## Evolución histórica

| Año | Momento histórico |
|-----|-------------------|
| 1992 | Primeras window functions en SQL estándar |
| 2005+ | PostgreSQL las introduce formalmente |
| 2010s | Snowflake, BigQuery las hacen populares |
| Actualidad | Soportadas en la mayoría de databases modernos |

Inicialmente eran complejas y poco usadas. Con el tiempo, se simplificó su sintaxis y más databases las incorporaron.

## Diferencia con GROUP BY

| Característica | GROUP BY | Window Functions |
|----------------|----------|------------------|
| Filas resultantes | Una por grupo | Una por cada fila |
| Pérdida de detalle | Sí | No |
| Múltiples cálculos | Varias agregaciones | Varias funciones en uno |
| Orden inherente | No | Sí (con ORDER BY) |

## Estructura de archivos en esta carpeta

Esta carpeta contiene material sobre window functions específicas:

- `row_number.md` - Numeración secuencial
- `rank.md` y `dense_rank.md` - Rankings
- `lag_lead.md` - Valores anteriores/siguientes
- `first_last_value.md` - Primeros y últimos valores
- `sum_avg_count.md` - Agregados acumulativos
- `ntile.md` - Distribución en cuantiles
- `window_frames.md` - Marcos de ventana específicos

## Resumen

Las window functions resuelven el problema de **tener que elegir entre agregación y detalle**. Permiten:

- Realizar cálculos sobre conjuntos de filas relacionados
- Mantener cada fila individual en el resultado
- Evitar subqueries y joins complejos
- Escribir código más claro y mantenible