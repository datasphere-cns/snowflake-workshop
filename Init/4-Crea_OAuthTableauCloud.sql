-- ============================================================================
-- SCRIPT DE CONFIGURACIÓN DE OAUTH SECURITY INTEGRATION PARA TABLEAU CLOUD
-- Proyecto: Conexión Segura entre Tableau Cloud y Snowflake
--
--   Este script crea una integración de seguridad (`SECURITY INTEGRATION`) en
--   Snowflake para habilitar la autenticación OAuth con Tableau Cloud.
--
--   ¿Qué es una SECURITY INTEGRATION?
--   Es una configuración de seguridad que permite a Snowflake delegar la
--   autenticación de usuarios a aplicaciones externas como Tableau usando el
--   protocolo OAuth 2.0. Este flujo es moderno, seguro y auditable.
--
--   ¿Para qué sirve?
--   Permite que Tableau Cloud se conecte a Snowflake sin necesidad de guardar
--   usuarios y contraseñas, utilizando tokens de acceso autorizados.
--   Esta conexión se puede usar para refrescar extractos, mostrar dashboards,
--   o consultar datos en tiempo real.
--
--   ¿Qué configuración incluye?
--   - `OAUTH_CLIENT = EXTERNAL`: indica que el cliente (Tableau) es externo.
--   - `OAUTH_CLIENT_TYPE = 'TABLEAU'`: tipo de cliente permitido.
--   - `OAUTH_REDIRECT_URI = 'https://online.tableau.com'`: URI de retorno segura.
--   - `OAUTH_ISSUE_REFRESH_TOKENS = TRUE`: permite mantener la sesión activa.
--   - `OAUTH_REFRESH_TOKEN_VALIDITY = 7776000`: duración del refresh token (90 días).
--
--   Requisitos:
--   - Snowflake en edición Enterprise o superior.
--   - Tableau Cloud configurado como cliente OAuth.
--   - Rol con privilegios de seguridad (como ACCOUNTADMIN).
--
--   Después de ejecutar este script:
--   1. Ejecuta `SELECT SYSTEM$SHOW_OAUTH_CLIENT_SECRETS(...)` para obtener
--      la URL de autorización y el client_id/client_secret.
--   2. Ingresa esos datos en Tableau Cloud al configurar la conexión OAuth.
--   3. Asocia esta integración con un rol que tenga acceso a los datos deseados.
--
-- Autor: Nelson Zepeda
-- Email: nelson.zepeda@datasphere.tech
-- Fecha de creación: 2025-05-01
-- Log de Cambios:
--
--
--
-- ============================================================================


-- ============================================================================
-- CREACIÓN DE LA INTEGRACIÓN OAUTH PARA TABLEAU CLOUD
-- ============================================================================

CREATE OR REPLACE SECURITY INTEGRATION tableau_oauth_integration
    TYPE = OAUTH
    ENABLED = TRUE
    OAUTH_CLIENT = 'CUSTOM'
    OAUTH_CLIENT_TYPE = 'CONFIDENTIAL' -- puede ser PUBLIC o CONFIDENTIAL
    OAUTH_REDIRECT_URI = 'https://online.tableau.com'
    OAUTH_ISSUE_REFRESH_TOKENS = TRUE
    OAUTH_REFRESH_TOKEN_VALIDITY = 7776000  -- 90 días
    COMMENT = 'Integración OAuth genérica para conectar Tableau Cloud con Snowflake usando cliente personalizado';



-- ============================================================================
-- VALIDACIÓN Y DATOS PARA TABLEAU CLOUD
-- ============================================================================


	SHOW SECURITY INTEGRATIONS;

