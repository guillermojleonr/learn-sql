# Homogenización de Datos Categóricos

Este documento aborda el procesamiento de campos categóricos de alta cardinalidad (como **Comunas**, **Ciudades** o **Marcas**) que no han sido validados en el origen, resultando en datos ruidosos, inconsistentes y con errores ortográficos.

## El Problema: El Caos de los Datos no Validados

Cuando un sistema permite entrada de texto libre para una categoría con cientos de valores posibles, terminamos con situaciones como:
- **Abreviaciones**: "STGO", "SNTGO".
- **Errores de dedo**: "Santiaog", "Providnecia".
- **Variaciones válidas pero no estándar**: "Santiago de Chile" vs "Santiago".
- **Caracteres extraños**: "Santiago!!!", " Maipú ".

---

## Arquitectura de Capas y Dónde Vive Cada Etapa

> **Principio clave**: Silver no es "Bronze un poco más limpio". Silver es la primera capa donde los datos son confiables y homogéneos. Todo el trabajo sucio ocurre **antes** de escribir a Silver.

```
bronze.sucursales          ← datos crudos tal como llegaron del sistema origen
        │
        ├── Etapa 1 (SQL): Limpieza sintáctica
        ├── Etapa 2 (SQL): Homogenización por diccionario
        ├── Etapa 3 (SQL/Python): Fuzzy matching sobre el residuo
        │
        ▼
staging.sucursales_clean   ← tabla intermedia: todo lo resuelto hasta acá
        │
        ├── Etapa 4: Marcado de excepciones no resueltas
        │
        ▼
silver.sucursales          ← datos limpios + columna de calidad para lo no resuelto
```

Silver **sí** contiene registros con `comuna = 'DESCONOCIDO'` si no se pudo resolver, pero siempre con una **columna de calidad** (`comuna_quality_flag`) que permite filtrarlos o tratarlos por separado aguas abajo.

---

## Estrategia Secuencial de Homogenización

### Etapa 1: Limpieza Sintáctica (SQL sobre Bronze)
**Objetivo**: Normalizar el formato base. Sin tildes, sin espacios, en mayúsculas. Esta es la preparación mínima para que cualquier comparación posterior sea válida.

- **Entrada**: `bronze.sucursales`
- **Salida**: campo `comuna_clean` calculado en memoria (CTE o vista)

```sql
-- Genera comuna_clean como base para las etapas siguientes
SELECT 
    id,
    comuna_original,
    UPPER(
        TRIM(
            REGEXP_REPLACE(
                TRANSLATE(comuna_original, 'áéíóúÁÉÍÓÚñÑ', 'aeiouAEIOUnn'),
                '[^A-Z0-9 ]', '', 'g'
            )
        )
    ) as comuna_clean
FROM bronze.sucursales;
```

| id | comuna_original | comuna_clean |
|----|----------------|--------------|
| 1  | " Santiago " | SANTIAGO |
| 2  | "STGO" | STGO |
| 3  | "Santiaog" | SANTIAOG |
| 4  | "Santiago de Chile" | SANTIAGO DE CHILE |
| 5  | "Maipú!!" | MAIPU |

---

### Etapa 2: Homogenización por Diccionario de Mapeo (SQL)
**Objetivo**: Resolver sinónimos, abreviaciones y variaciones conocidas usando una tabla maestra `metadata.mapping_comunas`.

- **Entrada**: resultado de la Etapa 1 (`comuna_clean`)
- **Salida**: `comuna_homologada` + indicador de si fue resuelta o no

#### Tabla maestra: `metadata.mapping_comunas`

| valor_entrada | comuna_estandar |
|---------------|----------------|
| STGO | SANTIAGO |
| SANTIAGO DE CHILE | SANTIAGO |
| PROV | PROVIDENCIA |
| PROVIDENCIA CHILE | PROVIDENCIA |
| NUNOA | NUNOA |

#### SQL de la Etapa 2

```sql
-- Aplica el diccionario de mapeo sobre el resultado de Etapa 1
SELECT 
    s.id,
    s.comuna_original,
    s.comuna_clean,
    m.comuna_estandar,
    -- Si hay match en el diccionario, se usa. Si no, queda NULL (residuo para Etapa 3)
    CASE 
        WHEN m.comuna_estandar IS NOT NULL THEN m.comuna_estandar
        ELSE NULL  -- pendiente de resolución en Etapa 3
    END as comuna_homologada
FROM etapa1 s  -- CTE o vista con el resultado de Etapa 1
LEFT JOIN metadata.mapping_comunas m ON s.comuna_clean = m.valor_entrada;
```

#### Resultado después de Etapa 2

| id | comuna_original | comuna_clean | comuna_estandar | comuna_homologada |
|----|----------------|--------------|-----------------|-------------------|
| 1  | " Santiago " | SANTIAGO | SANTIAGO | SANTIAGO ✅ |
| 2  | "STGO" | STGO | SANTIAGO | SANTIAGO ✅ |
| 3  | "Santiaog" | SANTIAOG | NULL | NULL ⏳ |
| 4  | "Santiago de Chile" | SANTIAGO DE CHILE | SANTIAGO | SANTIAGO ✅ |
| 5  | "Maipú!!" | MAIPU | NULL | NULL ⏳ |

Los registros con `NULL` en `comuna_homologada` son el **residuo** que alimenta la Etapa 3.

---

### Etapa 3: Fuzzy Matching sobre el Residuo (SQL/Python)
**Objetivo**: Corregir errores ortográficos en los registros que **no pudieron ser resueltos por el diccionario** en la Etapa 2.

La tabla `sucursales_unmapped` **no existe previamente**: se genera como un subconjunto filtrado del resultado de la Etapa 2, tomando únicamente los registros donde `comuna_homologada IS NULL`.

```sql
-- sucursales_unmapped: subconjunto del residuo de Etapa 2
-- Se crea como CTE, tabla temporal o tabla staging
CREATE TABLE staging.sucursales_unmapped AS
SELECT id, comuna_original, comuna_clean
FROM staging.etapa2_result
WHERE comuna_homologada IS NULL;
```

| id | comuna_original | comuna_clean |
|----|----------------|--------------|
| 3  | "Santiaog" | SANTIAOG |
| 5  | "Maipú!!" | MAIPU |

#### Catálogo oficial de comunas

```sql
-- Catálogo de referencia: la lista oficial de comunas válidas
-- Ej: tabla con las 346 comunas de Chile
SELECT comuna_oficial FROM metadata.catalogo_comunas;
-- SANTIAGO, PROVIDENCIA, NUNOA, MAIPU, ...
```

#### SQL con Levenshtein (PostgreSQL / Databricks SQL)

```sql
-- Para cada registro no resuelto, encontrar la comuna oficial más cercana
SELECT DISTINCT ON (u.id)
    u.id,
    u.comuna_clean,
    c.comuna_oficial as comuna_sugerida,
    levenshtein(u.comuna_clean, c.comuna_oficial) as distancia
FROM staging.sucursales_unmapped u
CROSS JOIN metadata.catalogo_comunas c
WHERE levenshtein(u.comuna_clean, c.comuna_oficial) <= 3
ORDER BY u.id, distancia ASC;
```

| id | comuna_clean | comuna_sugerida | distancia |
|----|-------------|-----------------|-----------|
| 3  | SANTIAOG | SANTIAGO | 2 |
| 5  | MAIPU | MAIPU | 0 ✅ |

> **Nota**: "MAIPU" ya venía limpio desde Etapa 1 pero no estaba en el diccionario. Levenshtein distancia 0 lo resuelve trivialmente. El diccionario de Etapa 2 debería enriquecerse con este caso.

#### Python (cuando SQL no es suficiente)

En plataformas como **Databricks**, se puede orquestar SQL y Python en el mismo pipeline. Python es preferible cuando el catálogo es grande y se necesitan algoritmos más sofisticados (Jaro-Winkler, fonético):

```python
# Ejemplo Python (Databricks / PySpark UDF)
from fuzzywuzzy import process
import pandas as pd

catalogo = ["SANTIAGO", "PROVIDENCIA", "NUNOA", "MAIPU"]

def get_best_match(query: str, min_score: int = 85):
    """Retorna el mejor match si supera el umbral de confianza, sino None."""
    match, score = process.extractOne(query, catalogo)
    return match if score >= min_score else None

# Aplicar sobre el DataFrame del residuo
df_unmapped["comuna_sugerida"] = df_unmapped["comuna_clean"].apply(get_best_match)
```

---

### Etapa 4: Gestión de Excepciones y Enriquecimiento del Diccionario
**Objetivo**: Registros que no pudieron resolverse ni por diccionario ni por fuzzy matching llegan a Silver **marcados explícitamente** como no resueltos. Esto permite:
1. Que los consumidores de Silver los excluyan o traten diferente.
2. Que el equipo de datos los priorice para enriquecer el diccionario de Etapa 2.

#### Escritura a Silver con flag de calidad

```sql
-- Vista o tabla final que se escribe en silver.sucursales
SELECT 
    b.id,
    b.nombre,
    b.fecha_apertura,
    -- Tomar el mejor valor disponible en cascada
    COALESCE(
        e3.comuna_sugerida,  -- resultado fuzzy matching
        e2.comuna_homologada, -- resultado diccionario
        'DESCONOCIDO'        -- fallback explícito
    ) as comuna,
    -- Columna de calidad: indica cómo se resolvió el valor
    CASE
        WHEN e2.comuna_homologada IS NOT NULL THEN 'DICCIONARIO'
        WHEN e3.comuna_sugerida   IS NOT NULL THEN 'FUZZY'
        ELSE 'NO_RESUELTO'
    END as comuna_quality_flag
FROM bronze.sucursales b
LEFT JOIN staging.etapa2_result e2 ON b.id = e2.id
LEFT JOIN staging.etapa3_result e3 ON b.id = e3.id;
```

#### Resultado en `silver.sucursales`

| id | nombre | comuna | comuna_quality_flag |
|----|--------|--------|---------------------|
| 1  | Sucursal A | SANTIAGO | DICCIONARIO |
| 2  | Sucursal B | SANTIAGO | DICCIONARIO |
| 3  | Sucursal C | SANTIAGO | FUZZY |
| 4  | Sucursal D | SANTIAGO | DICCIONARIO |
| 5  | Sucursal E | MAIPU | FUZZY |
| 6  | Sucursal F | DESCONOCIDO | NO_RESUELTO |

#### Query de auditoría: ¿qué queda sin resolver?

```sql
-- Priorizar por frecuencia para alimentar el diccionario
SELECT 
    comuna_original,
    COUNT(*) as ocurrencias
FROM silver.sucursales s
JOIN bronze.sucursales b ON s.id = b.id
WHERE s.comuna_quality_flag = 'NO_RESUELTO'
GROUP BY comuna_original
ORDER BY ocurrencias DESC;
```

| comuna_original | ocurrencias |
|----------------|-------------|
| "Stgo Norte" | 87 |
| "SNGO" | 34 |
| "Sn Miguel" | 12 |

> Estos valores se insertan manualmente en `metadata.mapping_comunas`, cerrando el ciclo y mejorando las siguientes ejecuciones del pipeline.

---

## Comparativa: SQL vs Python

| Criterio | SQL | Python (Pandas/PySpark) |
|----------|-----|-------------------------|
| **Etapas cubiertas** | 1, 2 y parcialmente 3 | 3 (fuzzy complejo) y 4 (auditoría) |
| **Fuzzy Matching** | Levenshtein básico (distancia de edición). | Superior: FuzzyWuzzy, Jaro-Winkler, fonético. |
| **Compatibilidad** | Universal (cualquier motor SQL). | Requiere Python runtime (Databricks, Glue, etc). |
| **Mantenibilidad** | El diccionario es auditable y versionable. | Lógica dispersa en scripts; más difícil de auditar. |

## Conclusión

La clave no es usar una sola técnica, sino respetar la **secuencia y la capa**:
1. **Bronze → Etapa 1**: Limpia el formato (SQL).
2. **Bronze → Etapa 2**: Aplica el diccionario (SQL). Resuelve la mayoría.
3. **Staging → Etapa 3**: Fuzzy matching sobre el residuo (SQL/Python).
4. **Silver**: Escribe con `quality_flag`. Audita y retroalimenta el diccionario.
