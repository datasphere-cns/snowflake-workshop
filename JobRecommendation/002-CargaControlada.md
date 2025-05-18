
# Ejercicio Adicional - Carga Controlada desde S3 en Snowflake

## Objetivo

Diseñar una solución en Snowflake que permita:

- Cargar archivos `.tsv` desde un stage externo en Amazon S3.
- Controlar **qué archivos se cargan** automáticamente sin duplicados.
- Verificar **cuáles archivos ya fueron cargados** usando vistas del sistema.
- Entender el uso correcto del comando `COPY INTO`.

---

## Introducción

Snowflake tiene la capacidad de registrar automáticamente qué archivos han sido cargados exitosamente en una tabla desde un `STAGE`, lo que le permite evitar duplicados **por defecto**.

Este comportamiento es fundamental para flujos de datos en los que se cargan archivos recurrentes desde S3, sin necesidad de renombrarlos o llevar control manual.

---

## 1. Ver archivos disponibles en el STAGE

```sql
LIST @job_stage;
```

Esto muestra todos los archivos presentes en el bucket S3 apuntado por el stage `job_stage`.

---

## 2. Cargar archivos automáticamente (sin duplicados)

```sql
COPY INTO apps
FROM @job_stage
FILE_FORMAT = (FORMAT_NAME = job_tsv_format);
```

### ¿Qué hace este comando?

- Intenta cargar todos los archivos disponibles en el stage.
- **Solo se cargan archivos que no han sido cargados antes** hacia la tabla `apps`.
- Snowflake ignora automáticamente archivos ya procesados, **salvo que se use `FORCE = TRUE`**.

---

## 3. Ver qué archivos ya fueron cargados

Usa la vista `INFORMATION_SCHEMA.LOAD_HISTORY`:

```sql
SELECT table_name,
       filename,
       last_load_time,
       row_count,
       status
FROM workshop.INFORMATION_SCHEMA.LOAD_HISTORY
WHERE table_name = 'APPS'
ORDER BY last_load_time DESC;
```

Esto permite auditar la carga y evitar duplicados manuales.

---

## 4. Diferencias entre formas de uso del COPY

### Específico (archivo único)

```sql
COPY INTO apps
FROM @job_stage/apps.tsv
FILE_FORMAT = (FORMAT_NAME = job_tsv_format);
```

- Carga solo `apps.tsv`.
- Snowflake aún evita duplicados si ya fue cargado.

### General (todos los archivos)

```sql
COPY INTO apps
FROM @job_stage
FILE_FORMAT = (FORMAT_NAME = job_tsv_format);
```

- Carga todos los archivos que coincidan con la estructura de la tabla.
- Snowflake compara automáticamente contra su historial de carga.

---

## 5. ¿Qué pasa si uso `FORCE = TRUE`?

```sql
COPY INTO apps
FROM @job_stage
FILE_FORMAT = (FORMAT_NAME = job_tsv_format)
FORCE = TRUE;
```

- Ignora el historial.
- **Todos los archivos serán cargados de nuevo**, incluso si ya se habían cargado.
- Puede causar duplicados si no hay controles de unicidad.

---

## 6. ¿Qué pasa si recreo la tabla o el stage?

Si borras y vuelves a crear la **tabla** o el **stage**, Snowflake pierde la referencia a los archivos ya cargados.

| Acción                     | ¿Se conserva historial? | ¿Puede duplicar? |
|----------------------------|--------------------------|------------------|
| Mantienes tabla + stage    | ✅ Sí                    | ❌ No            |
| Recreas la tabla           | ❌ No                   | ✅ Sí            |
| Recreas el stage           | ❌ No                   | ✅ Sí            |
| Cambias nombre de archivo  | ❌ No                   | ✅ Sí            |
| Usas FORCE = TRUE          | ❌ No                   | ✅ Sí            |

---

## 7. Recomendación General

> **Para evitar duplicados en Snowflake:**
> - Mantén el mismo stage y la misma tabla.
> - No uses `FORCE = TRUE` a menos que necesites recargar datos intencionalmente.
> - Usa la vista `LOAD_HISTORY` para auditar qué se ha cargado.

---

## Pregunta Frecuente

### ¿Snowflake guarda el historial en el stage?

**No.**  
El historial se guarda asociado a la **tabla de destino** y al stage que se usó en la carga. El bucket en S3 no guarda ningún registro.

---

## Próximo paso

En ejercicios más avanzados, se puede:
- Filtrar archivos con `FILES = (...)` o `PATTERN = '.*'`
- Crear `TASKS` para automatizar cargas por horario
- Usar `Streams` para detectar cambios posteriores
