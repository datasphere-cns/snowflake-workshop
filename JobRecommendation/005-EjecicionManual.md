
# Ejecución Manual de Snowpipe y Stored Procedure en Snowflake

Este documento describe cómo ejecutar manualmente un Snowpipe y un procedimiento almacenado (Stored Procedure) para probar o forzar cargas en entornos de desarrollo o validación.

---

## 1. Ejecutar Snowpipe manualmente

Si estás usando un `PIPE` con `AUTO_INGEST = FALSE`, o quieres forzar una carga de archivos nuevos desde S3, puedes ejecutar:

```sql
ALTER PIPE workshop.bronze_recursos_humanos.apps_pipe REFRESH;
```

Esto indica a Snowflake que busque nuevos archivos en el `STAGE` y ejecute el `COPY INTO` que contiene el `PIPE`.

---

## 2. Ejecutar el Stored Procedure manualmente

El procedimiento `proc_enrich_apps_silver` realiza:

- Inserción de datos desde `apps_stage` hacia `apps_silver`.
- Registro en `carga_logs`.
- Limpieza de la tabla staging.

Para ejecutarlo:

```sql
CALL workshop.silver_recursos_humanos.proc_enrich_apps_silver();
```

Devolverá una cadena con el número de filas insertadas.

---

## 3. Flujo manual completo recomendado (para pruebas)

### Paso 1: Asegúrate que `apps_stage` esté limpia

```sql
TRUNCATE TABLE workshop.bronze_recursos_humanos.apps_stage;
```

---

### Paso 2: Ejecuta el Snowpipe

```sql
ALTER PIPE workshop.bronze_recursos_humanos.apps_pipe REFRESH;
```

---

### Paso 3: Verifica si se cargaron datos en staging

```sql
SELECT COUNT(*) FROM workshop.bronze_recursos_humanos.apps_stage;
```

---

### Paso 4: Ejecuta el procedimiento para mover datos a SILVER

```sql
CALL workshop.silver_recursos_humanos.proc_enrich_apps_silver();
```

---

### Paso 5: Validaciones posteriores

Verifica los datos insertados en `apps_silver`:

```sql
SELECT COUNT(*) FROM workshop.silver_recursos_humanos.apps_silver;
```

Verifica los logs registrados:

```sql
SELECT *
FROM workshop.bronze_recursos_humanos.carga_logs
ORDER BY FechaCarga DESC;
```

---

Este flujo permite realizar pruebas controladas y forzar cargas sin depender de automatismos o eventos S3.

---
