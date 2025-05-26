
# Introducción a Time Travel en Snowflake

**Time Travel** es una funcionalidad nativa de Snowflake que permite acceder a versiones anteriores de los datos en una tabla dentro de un período determinado. Es útil para recuperación de datos, auditoría, comparación de versiones y revertir operaciones accidentales como `DELETE`, `UPDATE` o `DROP`.

---

## ¿Para qué sirve Time Travel?

- Recuperar datos eliminados por error
- Auditar cambios en los datos
- Consultar el estado anterior de una tabla
- Comparar versiones históricas de los datos
- Restaurar una tabla eliminada
- Clonar una tabla como estaba en un momento anterior

---

## ¿Cuántos días conserva los datos Snowflake?

| Tipo de cuenta            | Retención por defecto | Retención máxima permitida |
|---------------------------|------------------------|-----------------------------|
| **Standard Edition**      | 1 día (24 horas)       | 1 día                       |
| **Enterprise Edition+**   | 1 día (24 horas)       | Hasta 90 días               |

### Cambiar el período de retención

```sql
ALTER TABLE nombre_tabla SET DATA_RETENTION_TIME_IN_DAYS = 7;
```

### Ver la retención actual de una tabla

```sql
SHOW TABLES LIKE 'nombre_tabla';
```

---

## Comandos para usar Time Travel

### 1. Consultar una versión específica (`AT`)

```sql
SELECT * FROM mi_tabla AT (TIMESTAMP => '2025-05-25 10:00:00');
```

### 2. Consultar antes de cierto punto (`BEFORE`)

```sql
SELECT * FROM mi_tabla BEFORE (TIMESTAMP => '2025-05-25 10:00:00');
```

### 3. Usar desplazamiento en segundos (`OFFSET`)

```sql
SELECT * FROM mi_tabla AT (OFFSET => -600); -- 10 minutos atrás
```

### 4. Consultar por ID de una instrucción (`STATEMENT`)

```sql
SELECT * FROM mi_tabla BEFORE (STATEMENT => '01a2b3c4-d5f6-7890-1234-abcdef987654');
```

---

## Operaciones avanzadas con Time Travel

### Restaurar una tabla eliminada

```sql
UNDROP TABLE mi_tabla;
```

### Clonar una tabla como estaba en un momento anterior

```sql
CREATE TABLE mi_tabla_clonada CLONE mi_tabla 
  AT (TIMESTAMP => '2025-05-25 10:00:00');
```

---

## Ejemplo práctico: recuperación de datos

Supón que alguien ejecutó este comando erróneamente:

```sql
DELETE FROM ventas WHERE fecha = '2025-05-20';
```

Puedes recuperar los datos así:

```sql
INSERT INTO ventas
SELECT * FROM ventas BEFORE (STATEMENT => 'ID_DEL_DELETE')
WHERE fecha = '2025-05-20';
```

---

## Consideraciones importantes

- El período de retención inicia desde la **última modificación** de la tabla.
- No se necesita configurar nada para usar Time Travel con 1 día de retención.
- Una vez superado el período de retención, los datos históricos **no pueden recuperarse** con Time Travel.
- Retenciones mayores a 1 día requieren **Enterprise Edition** o superior.

---

## Sección especial: ¿Qué es el Fail-safe?

**Fail-safe** es una capa adicional de recuperación que Snowflake ofrece **después de que ha expirado el Time Travel**, pero **no es accesible por el usuario**.

### Características de Fail-safe:

- Tiene una duración fija de **7 días adicionales** después del período de retención.
- Solo el equipo de soporte de Snowflake puede restaurar datos desde Fail-safe.
- Está diseñado para **recuperación ante fallos catastróficos** y **no para uso operativo diario**.
- No puedes consultar datos directamente con `SELECT ... AT` o `CLONE` durante el período de Fail-safe.
- Snowflake garantiza que los datos aún pueden ser recuperados internamente.

### Ejemplo de cronología:

- Supón que una tabla tiene `DATA_RETENTION_TIME_IN_DAYS = 3`.
- Puedes acceder al historial con Time Travel durante esos 3 días.
- Después de eso, tienes otros 7 días donde **solo Snowflake** puede ayudarte a recuperarlos bajo solicitud.

---

## Referencias adicionales

- [Documentación oficial de Time Travel](https://docs.snowflake.com/en/user-guide/data-time-travel)
- [Documentación oficial de Fail-safe](https://docs.snowflake.com/en/user-guide/data-fail-safe)
