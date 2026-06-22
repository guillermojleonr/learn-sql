
# Guía de Optimización de Queries SQL

---

## Proceso de Optimización (Paso a Paso)

### Paso 1: Revisar el Plan de Ejecución

**Herramientas según motor:**
- PostgreSQL: `EXPLAIN ANALYZE`
- MySQL: `EXPLAIN` + `VISUAL EXPLAIN` (Workbench)
- SQL Server: Execution Plan (gráfico)

**Qué buscar en orden de importancia:**

1. **Full Table Scans** → "Seq Scan" (PostgreSQL) o "Table Scan" (SQL Server)
   - Indica que no hay índice aprovechable
   - Oportunidad de indexar

2. **Nested Loops costosos** → Operación N×M (NxM significa N veces M, que a su vez hace referencia a la cantidad de filas que se procesan en cada nivel del loop)
   - Muy cara cuando la tabla interna es grande
   - Buscar alternativas de JOIN

3. **Sort operations** → "Sort" en el plan
   - Especialmente grave si no hay índice en ORDER BY
   - Usa mucha memoria si el dataset es grande

4. **Memory/IO usage** → Porcentaje de buffer I/O
   - Si es muy alto, hay demasiados accesos a disco
   - Señal de falta de índices o dataset muy grande

**Red flags:**
- `Execution time: XXXms` significativamente alto
- `Rows: 1000000` cuando esperabas 100
- `Buffer I/O: >80%`

### Paso 2: Reescribir la Query

Hacer primero porque es gratis y resuelve muchos problemas sin crear índices nuevos.

**Técnicas de reescritura:**

1. **Mover filtros lo más "abajo" posible**
   - Filtrar antes de JOIN es más eficiente que después
   ```sql
   -- LENTO: JOIN primero, filtro después
   SELECT * FROM usuarios u 
   JOIN pedidos p ON u.id = p.usuario_id 
   WHERE u.pais = 'AR';
   
   -- RÁPIDO: Filtro primero
   SELECT * FROM usuarios u 
   WHERE u.pais = 'AR'
   JOIN pedidos p ON u.id = p.usuario_id;
   ```

2. **Evitar funciones en columnas filtradas**
   - Invalidan índices completamente
   ```sql
   -- LENTO: YEAR() invalida índice en fecha
   SELECT * FROM usuarios WHERE YEAR(fecha_registro) = 2024;
   
   -- RÁPIDO: Sin función
   SELECT * FROM usuarios 
   WHERE fecha_registro >= '2024-01-01' 
   AND fecha_registro < '2025-01-01';
   ```

3. **Preferir JOIN sobre subconsultas**
   - JOIN es casi siempre más optimizable que IN/EXISTS
   ```sql
   -- LENTO: Subconsulta
   SELECT * FROM pedidos WHERE usuario_id IN 
     (SELECT id FROM usuarios WHERE pais = 'AR');
   
   -- RÁPIDO: JOIN
   SELECT p.* FROM pedidos p 
   JOIN usuarios u ON p.usuario_id = u.id 
   WHERE u.pais = 'AR';
   ```

4. **Usar CTEs (WITH) con cuidado**
   - No se materializan por defecto: el optimizador no siempre los optimiza
   - Útiles para legibilidad, pero no garantizan mejor performance

5. **Eliminar columnas innecesarias en SELECT**
   - Traer solo lo que necesitas
   ```sql
   -- LENTO: Trae todo
   SELECT * FROM pedidos WHERE estado = 'completado';
   
   -- RÁPIDO: Solo columnas necesarias
   SELECT id, fecha, monto FROM pedidos WHERE estado = 'completado';
   ```

### Paso 3: Evaluar Índices

Si después de reescribir sigue siendo lento, entonces agregar índices.

**Columnas candidatas a indexar (en orden de prioridad):**

1. **Condiciones WHERE restrictivas** → Reducen el dataset rápido
   - Ejemplo: `WHERE estado = 'activo'` en tabla de 1M registros

2. **Ambos lados de JOIN** → Clave primaria + clave foránea
   - Ejemplo: `usuarios.id` y `pedidos.usuario_id`

3. **GROUP BY** → Si hay muchos grupos únicos
   - Evita full scan + sort

4. **ORDER BY** → Si la ordenación es frecuente
   - Evita operación costosa de sort en memoria

**Consideraciones prácticas:**

- **Índices compuestos**: Si hay múltiples condiciones en WHERE
  ```sql
  -- En lugar de dos índices separados:
  CREATE INDEX idx_composite ON usuarios(pais, estado, fecha);
  ```

- **No sobreindexar**: Cada índice ralentiza INSERT/UPDATE/DELETE
  - Solo indexar columnas que realmente se usan en filtros

- **Índices parciales** (PostgreSQL) o **filtrados** (SQL Server)
  - Si solo necesitas indexar un subset de datos
  ```sql
  CREATE INDEX idx_activos ON usuarios(id) WHERE estado = 'activo';
  ```

### Paso 4: Validar/Actualizar Estadísticas

El optimizador necesita estadísticas actuales para tomar decisiones correctas.

**Comandos por motor:**
```sql
-- PostgreSQL
ANALYZE tabla;

-- MySQL
ANALYZE TABLE tabla;

-- SQL Server
UPDATE STATISTICS tabla;
```

**Cuándo ejecutar:**
- Después de cambios grandes de datos
- Antes de optimizar queries importantes
- Regularmente en bases de datos activas

### Paso 5: Considerar Ajustes Adicionales

- **Particionamiento**: Para tablas muy grandes (millones de filas)
  - Mejora tiempo de queries en subconjuntos específicos

- **Materialized Views**: Para consultas complejas frecuentes
  - Precalcula y almacena resultados

- **Cache**: Para lecturas muy repetidas con pocos cambios
  - Evita ejecutar query completa cada vez

---

## Checklist de Optimización

- [ ] Ejecutar plan de ejecución (EXPLAIN/EXPLAIN ANALYZE)
- [ ] Identificar full table scans y nested loops costosos
- [ ] Crear índices en columnas de WHERE, JOIN, GROUP BY
- [ ] Reescribir query: mover filtros, eliminar funciones innecesarias
- [ ] Actualizar estadísticas (ANALYZE/UPDATE STATISTICS)
- [ ] Volver a ejecutar plan de ejecución para comparar
- [ ] Evaluar si es necesario particionamiento o materialized views