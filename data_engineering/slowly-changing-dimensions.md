# Slowly Changing Dimensions (SCD)

Las **SCD** (*Slowly Changing Dimensions* o Dimensiones de Cambio Lento) son técnicas en *data warehousing* para gestionar datos cualitativos que cambian con el tiempo, rastreando su evolución. Los tipos más comunes, como **Tipo 1** (sobrescribir) o **Tipo 2** (historial completo), deciden cómo actualizar registros para mantener la precisión histórica.

Es una decisión de diseño temprana que depende de:

Requerimientos de negocio: ¿necesitas historial? ¿cuánto?
Volumen de datos: SCD2 puede duplicar/triplicar registros
Complexidad de queries: más joins, más tamaño = queries más lentas
Costo de almacenamiento: contrapeso entre detalle y eficiencia
Una vez en producción, migrar de SCD1 a SCD2 es painful (hay que recrear histórico). Por eso se planifica desde el inicio.

Lo que sí puede evolucionar es que una dimensión pase de SCD1 a SCD2 si el negocio luego decide que necesita追踪 cambios.

---

## Tipos Principales de SCD

| Tipo | Nombre | Descripción |
|------|--------|-------------|
| 0 | Fija | No se permiten cambios; los datos originales se mantienen inmutables |
| 1 | Sobrescribir | La información nueva reemplaza a la antigua; no se mantiene historial |
| 2 | Histórico | Crea un registro nuevo para cada cambio, marcando el anterior como inactivo y permitiendo ver el valor en cualquier momento histórico |
| 3 | Histórico Limitado | Añade una columna para mostrar solo el valor actual y el anterior |
| 4 | Historial separado | Usa una tabla adicional para mantener el histórico de cambios |

---

## Aplicación e Importancia
queo
- Se utilizan en entornos de **SQL Server Integration Services** y bases de datos estrella para analizar tendencias pasadas.
- Esencial para seguimiento de datos maestros, como la dirección de un cliente, que cambian de manera impredecible.