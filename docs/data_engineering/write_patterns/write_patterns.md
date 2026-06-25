# Patrones de Escritura en Silver

Esta guía explica los diferentes patrones para escribir datos en la capa Silver de un pipeline de datos.

## Archivos por Patrón

| Patrón | Archivo | Descripción |
|--------|---------|-------------|
| Full Refresh | `full_refresh.md` | Recarga completa (recrea la tabla) |
| Full Reload | `full_reload.md` | Reemplazo completo manteniendo estructura |
| Incremental Append | `incremental_append.md` | Solo añade nuevos registros |
| Upsert / Merge | `upsert.md` | Inserta o actualiza según exista |
| Incremental Update | `incremental_update.md` | Elimina y reinserta por ventana de tiempo |

---

## Guía de Decisión: ¿Qué Patrón Usar?

> **Principio KISS:** Empezá por el patrón más simple y solo agregá complejidad cuando el rendimiento lo requiera.
> 
> **Default = Full Refresh / Full Reload** porque:
> - Es el más simple de implementar y mantener
> - Garantiza consistencia y corrección de datos
> - Facilita debugging (si falla, simplemente rerun)
> - Menos código = menos bugs potenciales
> 
> Solo pasar a patrones incrementales cuando el volumen o tiempo de procesamiento lo justifique.

```
Default → Full Refresh / Full Reload (más simple, más seguro)
         ↓
¿Hay problema de rendimiento o volumen? → Pasar a incremental
```

## Por Tipo de Datos

| Tipo de dato | Patrón recomendado | Razón |
|--------------|-------------------|-------|
| **Facts** (ventas, transacciones) | Incremental Update | Volumen masivo, cambios retroactivos (devoluciones, cancelaciones) |
| **Dimensiones** (clientes, productos) | Upsert / Merge | SCD Type 1, cambios pocos pero frecuentes |
| **Tablas pequeñas/estáticas** | Full Refresh | Overhead de lógica incremental no justifica |
| **Logs, eventos, clickstream** | Incremental Append | Datos inmutables, solo se añaden |
| **Agregaciones mensuales/históricas** | Full Reload | Se regenera desde cero por período |

## Comparativa rápida

```
┌─────────────────────┬────────────────────────────────────────────────────────┐
│ ¿Cuánto dato cambia?│ Patrón                                                 │
├─────────────────────┼────────────────────────────────────────────────────────┤
│ Todo (recargar todo)│ Full Refresh / Full Reload                            │
│ Solo lo nuevo       │ Incremental Append (si es inmutable)                  │
│ Solo lo nuevo       │ Upsert / Merge (si puede cambiar lo existente)        │
│ Solo ventana tiempo │ Incremental Update (ej: últimos 7 días)               │
└─────────────────────┴────────────────────────────────────────────────────────┘
```

## Consideraciones de Enterprise

En entornos enterprise con grandes volúmenes de datos:

- **Full Refresh y Full Reload** suelen ser impracticables para facts (millones/billones de filas)
- **Incremental Append** aplica solo cuando los datos son realmente inmutables
- **Upsert** es ideal para dimensiones (SCD Type 1)
- **Incremental Update** es el más común para facts en producción

> **Nota:** La elección también depende del motor (Snowflake, BigQuery, Spark, etc.) y sus capacidades específicas de escritura incremental.

---
