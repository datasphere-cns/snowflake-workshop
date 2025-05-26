
# Data Sharing en Snowflake: Que es, Como Funciona y Cuando Usarlo

## Que es el Data Sharing?

El **Data Sharing** en Snowflake permite compartir datos en **tiempo real** con otras cuentas de Snowflake **sin necesidad de copiar, mover o exportar** los datos. Los consumidores acceden directamente al almacenamiento del proveedor.

---

## Caracteristicas clave

- Sin duplicacion de datos.
- Sin ETLs ni pipelines adicionales.
- Los datos compartidos se actualizan en tiempo real.
- Los consumidores solo tienen acceso de **lectura**.
- Comparticion entre cuentas Snowflake, regiones o incluso nubes (Cross-Cloud).

---

## Diferencia con Clonacion

| Clonacion (CLONE)                  | Data Sharing                            |
|------------------------------------|------------------------------------------|
| Copia logica del objeto            | Acceso en tiempo real a datos compartidos |
| Independiente del objeto original  | Vinculado a los datos del proveedor      |
| Puede modificarse                  | Solo lectura para el consumidor          |
| Ideal para desarrollo o respaldo   | Ideal para colaboracion interorganizacional |

---

## Casos de uso

- Compartir datos con otras areas de la empresa (finanzas, marketing, etc.)
- Colaborar con socios o clientes que tambien usan Snowflake.
- Crear productos de datos o modelos de datos como servicio.
- Ofrecer acceso a datos en **marketplaces privados o publicos**.
- Habilitar la estrategia de **Data Mesh**.

---

## Como se usa?

### 1. El proveedor crea un `SHARE`

```sql
-- Crear el objeto share
CREATE SHARE mi_share;

-- Conceder permisos de lectura
GRANT USAGE ON DATABASE mi_base TO SHARE mi_share;
GRANT USAGE ON SCHEMA mi_base.mi_esquema TO SHARE mi_share;
GRANT SELECT ON TABLE mi_base.mi_esquema.mi_tabla TO SHARE mi_share;

-- Especificar la cuenta Snowflake que puede consumirlo
ALTER SHARE mi_share ADD ACCOUNT = '123456789012.us-east-1';
```

### 2. El consumidor crea una base a partir del `SHARE`

```sql
-- Crear base virtual desde el share
CREATE DATABASE base_remota FROM SHARE proveedor_cuenta.mi_share;

-- Consultar los datos compartidos
SELECT * FROM base_remota.mi_esquema.mi_tabla;
```

---

## Tipos de Data Sharing

1. Directo entre cuentas Snowflake
2. Data Exchange privado (entre departamentos, unidades o partners)
3. Snowflake Marketplace publico (opcional con monetizacion)

---

## Seguridad y control

- Solo se comparte lo que se otorga explicitamente.
- Los consumidores no pueden ver otros objetos ni modificar los datos.
- El proveedor puede revocar el acceso en cualquier momento.
- Todas las actividades quedan auditadas.

---

## Conclusion

El Data Sharing en Snowflake es ideal para promover la colaboracion entre areas o empresas, optimizar el acceso a datos sin redundancia, y habilitar modelos de negocio basados en datos. Es rapido, seguro y no requiere replicacion fisica.
