# Calidad de Datos

Parece que la calidad de datos es más amplia que solo el perfilado de datos.

## Diferencia entre Calidad de Datos y Perfilado de Datos
- **Calidad de datos** se refiere al grado en que los datos cumplen con los requisitos de precisión, completitud, consistencia, validez y actualidad. Implica medidas y reglas para evaluar y mejorar los datos, así como procesos de limpieza, validación y monitorización.
- **Perfilado de datos** es una técnica que explora y describe las características de los datos (tipo, distribución, valores nulos, patrones) para comprender su estructura y contenido. Es una fase inicial que ayuda a identificar problemas de calidad, pero no incluye acciones correctivas ni políticas de calidad.

## Plataformas de Calidad de Datos
Muchas plataformas intentan aportar “usabilidad”, ofreciendo interfaces visuales y flujos de trabajo con pocos clics para crear suites extensas de pruebas de datos. Como usuario técnico, a veces rechazo SaaS porque prefiero el control y el versionado que me brinda desarrollar mis propias soluciones en código. Sin embargo, cuando la cantidad de código necesario es enorme, valoro la capacidad de generar rápidamente pruebas de datos robustas con plataformas, por lo que actualmente tengo una visión favorable hacia ellas.

- **Databricks**: No olvidar que en Data Bricks hay una sintaxis EXPECT que permite integrar data quality en los procesos
- **Great Expectations Cloud**: Se cerró el 1 de junio de 2026, adquirido por otra compañía.
- **Qualitics.ai**: Se solicita el precio a través de LinkedIn; no es transparente y solo ofrece una demo.
- **Monte Carlo**: Plataforma líder en observabilidad de datos que utiliza machine learning para detectar anomalías automáticamente sin necesidad de configurar reglas manuales constantemente. No tiene free tier, solo get a demo
- **Datafold**: Enfocada en la validación de datos mediante "data diffs", permitiendo comparar conjuntos de datos entre entornos (por ejemplo, desarrollo vs producción) de manera automatizada.
- **Anomalo**: Plataforma de calidad de datos que se integra en el almacén de datos (warehouse) para detectar, comprender y resolver problemas de datos mediante inteligencia artificial.
- **Atlan**: Plataforma de catálogo y gobernanza de datos que incorpora activamente métricas de calidad de datos para democratizar el conocimiento sobre el estado de los activos dentro de la organización.

## Bibliotecas - Código
En contraposición a las plataformas, tenemos las tecnologías que requieren definir y mantener esto como una capa extra en el pipeline

### Great Expectations Core (biblioteca Python)
- **Qué es**: Great Expectations (GX) Core es una librería de Python que permite definir *expectativas* (expectations) sobre los datos, generar perfiles automáticos y validar la calidad de los datos durante la ejecución de pipelines.
- **Data profiling**: Con `gx expect_suite` puedes generar automáticamente un *expectation suite* basada en el análisis estadístico de los datasets (tipo de columnas, valores nulos, distribuciones, etc.).
- **Data quality**: Además del profiling, puedes declarar expectativas de calidad como `expect_column_values_to_be_unique`, `expect_column_values_to_not_be_null`, `expect_column_values_to_be_in_set`, entre otras. Estas expectativas forman parte de un *pipeline* y, al fallar, pueden disparar alertas o pasos correctivos.
- **Integración en pipelines**: En un flujo ETL típico, añades una fase de validación con GX:
  ```python
  import great_expectations as gx
  from great_expectations.checkpoint import SimpleCheckpoint

  # Crear un DataContext local (sin GX Cloud)
  context = gx.get_context()

  # Definir un suite de expectativas (profiling automático o manual)
  suite = context.create_expectation_suite("mi_suite", overwrite=True)
  batch = context.get_batch({
      "datasource": "my_datasource",
      "data_connector_name": "default_runtime_data_connector_name",
      "data_asset_name": "mis_datos.csv",
      "runtime_parameters": {"path": "data/mis_datos.csv"},
      "batch_identifiers": {"default_identifier_name": "default_identifier"},
  })

  # Ejecutar profiling (auto‑generar expectativas básicas)
  from great_expectations.validator.validator import Validator
  validator = context.get_validator(batch=batch, expectation_suite_name="mi_suite")
  validator.expect_table_row_count_to_be_between(min_value=1, max_value=1_000_000)
  # ...más expectativas de calidad según tu política

  # Checkpoint: valida y reporta
  checkpoint = SimpleCheckpoint(name="mi_checkpoint", 
                                 context=context,
                                 validator=validator)
  result = checkpoint.run()
  print(result)
  ```
- **Ventajas**: No dependes de GX Cloud; todo el procesamiento ocurre localmente o en tu propia infraestructura (Docker, Airflow, Prefect, etc.). El código es versionable con Git y se puede probar unitariamente.
- **Limitaciones**: Necesitas definir y mantener las expectativas manualmente o mediante scripts de profiling; la UI de GX Cloud ya no está disponible, pero existen UI de código abierto (Great Expectations UI) que puedes desplegar si lo deseas.

### Soda Core (biblioteca Python)
- **Qué es**: Soda Core es una herramienta de código abierto que usa una sintaxis declarativa llamada SodaCL para definir tests de calidad de datos (expectativas) de forma sencilla.
- **Data profiling**: Con `soda scan` puedes generar automáticamente un perfil del dataset y crear expectativas basadas en estadísticas (valores nulos, rangos, patrones).
- **Data quality**: Permite expresar reglas como `expect_column_values_to_be_unique` o `expect_column_values_to_match_regex` en archivos `.sodaql` que se versionan con Git.
- **Integración en pipelines**: Se puede ejecutar como paso en Airflow, dbt, Prefect o cualquier workflow de CI/CD, y los resultados se pueden exportar como JSON para decisiones automáticas.

### Corrección de problemas de calidad dentro de los pipelines
Los propios pipelines son el lugar natural donde se aplican correcciones basadas en los resultados de validación de GX:
- **Bloque de detección**: GX valida los datos y genera un reporte de errores.
- **Bloque de corrección**: Según el tipo de fallo (valores nulos, duplicados, rango fuera de límites), puedes añadir transformaciones de limpieza (e.g., `fillna`, `drop_duplicates`, `clip`).
- **Bloque de re‑validación**: Después de aplicar la corrección, vuelve a ejecutar GX para asegurar que el dataset cumple con las expectativas.

De esta forma, el *profiling* sirve para descubrir problemas, las *expectativas* definen la calidad deseada y el *pipeline* orquesta la corrección automática o manual.

### dbt-utils
dbt naturalmente ya tiene tests como unique, not_null relationships accepted_values, pero dbt-utils agrega macros extra: sequential values,recency,cardinalidad,surrogate keys,equality entre tablas,etc

````yaml
tests:
  - dbt_utils.unique_combination_of_columns:
      combination_of_columns:
        - order_id
        - line_number
````

Acá el profiling/calidad vive directamente en SQL warehouse.

Muy usado en stacks: Snowflake,BigQuery,Databricks,Redshift

Fortalezas: Muy simple, Todo SQL, Versionado Git, Corre en el warehouse, Excelente para analytics engineering
Debilidad: Menos flexible que Python para lógica compleja.
