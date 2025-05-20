# Llaves Primarias, Foráneas y Constraints en Snowflake: ¿Realmente se Enforzan?

En Snowflake, puedes declarar restricciones como `PRIMARY KEY`, `UNIQUE`, `FOREIGN KEY` y `NOT NULL`, pero su comportamiento **depende del tipo de tabla que estás utilizando**.

---

## 1. Tablas Estándar (`CREATE TABLE`)

Snowflake **permite declarar** constraints en tablas estándar, pero **NO las enforza**. Esto significa que no validará la unicidad ni impedirá inserciones que violen las reglas definidas.

### Ejemplo:

```sql
CREATE TABLE clientes (
  id_cliente STRING PRIMARY KEY,
  nombre STRING,
  correo STRING
);

INSERT INTO clientes VALUES ('C001', 'Ana', 'ana@dominio.com');
INSERT INTO clientes VALUES ('C001', 'Ana', 'duplicado@dominio.com');

SELECT * FROM clientes;
```

En este ejemplo:
- Snowflake permite insertar dos veces `id_cliente = 'C001'`, **aunque se haya declarado como PRIMARY KEY**.
- La restricción **no es validada** ni usada para optimización.
- La declaración sirve solo como **documentación semántica** o para herramientas externas como dbt o ERD.

---

## 2. Tablas Híbridas (`CREATE HYBRID TABLE`)

Las **Hybrid Tables** son un nuevo tipo de tabla en Snowflake que **sí enforza constraints**, permitiendo workloads **OLTP reales** dentro de Snowflake.

### Ejemplo:

```sql
CREATE HYBRID TABLE clientes_hybrid (
  id_cliente STRING PRIMARY KEY,
  nombre STRING,
  correo STRING
);
```

En este caso:
- Snowflake **no permitirá duplicados** en `id_cliente`.
- También puedes declarar `UNIQUE`, `FOREIGN KEY`, y serán **validadas** al insertar o actualizar datos.
- Se comporta como una base de datos transaccional tradicional (PostgreSQL, SQL Server, etc.).

---

## 3. Comparación entre Tablas Estándar y Hybrid Tables

| Característica        | Tabla Estándar     | Hybrid Table         |
|-----------------------|--------------------|-----------------------|
| `PRIMARY KEY`         | Declarativa        | ✅ Enforced           |
| `UNIQUE`              | Declarativa        | ✅ Enforced           |
| `FOREIGN KEY`         | Declarativa        | ✅ Enforced           |
| `NOT NULL`            | ✅ Enforced         | ✅ Enforced           |
| Soporta OLTP real     | ❌ No               | ✅ Sí                 |
| Requiere habilitación | ❌ No               | ✅ Sí (por Snowflake) |

---

## 4. ¿Cómo obtener acceso a las Hybrid Tables?

Para usar `CREATE HYBRID TABLE`, necesitas:

- Tener una cuenta **Enterprise Edition** o superior.
- Estar en una región donde las Hybrid Tables están disponibles.
- Tener habilitado el **feature flag** por parte de Snowflake.

Puedes verificar si están disponibles con:

```sql
SELECT SYSTEM$FEATURE_SUPPORT('HYBRID_TABLE');
```

Si el resultado es `'NOT_SUPPORTED'` o `'NOT_ENABLED'`, debes solicitar acceso al soporte o a tu Sales Engineer de Snowflake.

---

## 5. Recomendación

- Si solo necesitas **documentar relaciones y claves**, puedes usar constraints en tablas estándar.
- Si necesitas **enforcement real** (por ejemplo, validar claves primarias y foráneas automáticamente), solicita acceso a **Hybrid Tables**.
- Para workloads OLAP (analíticos), las restricciones no son necesarias para performance. Para workloads OLTP (transaccionales), **Hybrid Tables son el camino**.

