## pip install snowflake-connector-python

import snowflake.connector
import os

# Configuración de conexión
conn = snowflake.connector.connect(
    user='usuario_developer',
    password='*****',
    account='kixfvtu-oic64833',
    warehouse='WH_SMALL',
    database='WORKSHOP',
    schema='BRONZE_MERCADEO',
    role='ROLE_DEVELOPER'
)

# Ruta local del archivo CSV
local_file_path = 'C:/Snowflake/CargaDatos/dataset/products.csv'

# Nombre de archivo
file_name = os.path.basename(local_file_path)

# Ejecutar comandos
cs = conn.cursor()
try:
    # Comando PUT para subir archivo al STAGE interno
    put_command = f"PUT file://{local_file_path} @STG_PRODUCTS_DEV auto_compress=false;"
    cs.execute(put_command)
    print("Archivo cargado al STAGE exitosamente.")

    # COPY INTO desde el stage
    copy_command = f"""
    COPY INTO PRODUCTS_BRONZE
    FROM @STG_PRODUCTS_DEV/{file_name}
    FILE_FORMAT = (
        TYPE = 'CSV',
        FIELD_OPTIONALLY_ENCLOSED_BY = '"',
        SKIP_HEADER = 1
    )
    ON_ERROR = 'CONTINUE';
    """
    cs.execute(copy_command)
    print("Datos copiados a PRODUCTS_BRONZE.")
finally:
    cs.close()
    conn.close()
