# Guía para Cargar Datos a la Capa Bronze en Snowflake

Esta guía describe paso a paso cómo cargar un archivo CSV (ej. `products.csv`) a la capa Bronze de Mercadeo utilizando un stage en Snowflake.

## Requisitos

- Acceso a Snowflake con rol `ROLE_ADMIN_FULL` o `ROLE_DEVELOPER`
- Warehouse activo (ej. `WH_SMALL`)
- Archivo CSV limpio y delimitado por comas
...

## Pasos

1. Crear el stage
2. Subir el archivo
3. Crear la tabla destino
4. Ejecutar `COPY INTO`
5. Validar resultados
