SHOW PARAMETERS LIKE 'TIMEZONE' IN SESSION;

SELECT
    warehouse_name,
    DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time)) AS usage_date_central,
    HOUR(CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time)) AS usage_hour_central,
    DAYOFWEEK(CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time)) AS day_of_week_central,
    SUM(credits_used) AS total_credits_used
FROM
    SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE
    start_time >= DATEADD(day, -180, CURRENT_TIMESTAMP())
    --AND warehouse_name IN ('DBT_LARGE_WH')
GROUP BY
    warehouse_name, usage_date_central, usage_hour_central, day_of_week_central
ORDER BY
    warehouse_name, usage_date_central, usage_hour_central;



WITH CTE_QUERIES_WH AS (
SELECT
    query_id,
    query_text,
    query_type,
    user_name,
    role_name,
    warehouse_name,
    database_name,
    schema_name,
    total_elapsed_time / 1000 AS total_elapsed_time_seconds,
    execution_time / 1000 AS execution_time_seconds,
    credits_used_cloud_services,
    bytes_scanned,
    rows_produced,
    start_time AS start_time_utc,
    end_time AS end_time_utc,
    CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time) AS start_time_central,
    CONVERT_TIMEZONE('UTC', 'America/Chicago', end_time) AS end_time_central,
    DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time)) AS usage_date_central,
    HOUR(CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time)) AS usage_hour_central,
    DAYOFWEEK(CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time)) AS day_of_week_central,
    error_message
FROM
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE
    --warehouse_name IN ('DBT_LARGE_WH', 'ETL_WH')
    start_time >= DATEADD(day, -180, CURRENT_TIMESTAMP())
    AND query_type NOT IN ('SHOW', 'DESCRIBE', 'USE')
)
SELECT warehouse_name,COUNT(*) QUERIES_,
SUM(total_elapsed_time_seconds) total_elapsed_time_seconds,
SUM(execution_time_seconds) execution_time_seconds
FROM CTE_QUERIES_WH A
GROUP BY ALL





SELECT
    end_time AS "End Time",
    start_time AS "Start Time",
    warehouse_name AS "Warehouse Name",
    credits_used AS "Credits Used",
    credits_used_cloud_services AS "Credits Used Cloud Services",
    credits_used_compute AS "Credits Used Compute"
FROM
    TABLE(INFORMATION_SCHEMA.WAREHOUSE_METERING_HISTORY(
        DATE_RANGE_START => DATEADD(day, -7, CURRENT_DATE()),
        DATE_RANGE_END => CURRENT_DATE()
    ))
ORDER BY
    start_time, warehouse_name;



SELECT
    CONVERT_TIMEZONE('UTC', 'America/Chicago', usage_date::TIMESTAMP_NTZ)::DATE AS "UsageDate",
    SUM(credits_used) AS "TotalCreditsUsed"
FROM
    snowflake.account_usage.metering_daily_history
WHERE
    usage_date >= CONVERT_TIMEZONE('America/Chicago', 'UTC', DATE_TRUNC('month', DATEADD(month, -1, CURRENT_TIMESTAMP()))::TIMESTAMP_NTZ)::DATE
    AND usage_date < CONVERT_TIMEZONE('America/Chicago', 'UTC', DATE_TRUNC('month', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ)::DATE
GROUP BY
    1
ORDER BY
    1;




    SELECT
    CONVERT_TIMEZONE('UTC', 'America/Chicago', usage_date::TIMESTAMP_NTZ)::DATE AS "UsageDate",
    SUM(credits_used_compute) AS "ComputeCredits",
    SUM(credits_used_cloud_services) AS "CloudServicesCredits",
    SUM(credits_used_compute) + SUM(credits_used_cloud_services) AS "TotalCredits"
FROM
    snowflake.account_usage.metering_daily_history
WHERE
    usage_date >= CONVERT_TIMEZONE('America/Chicago', 'UTC', DATE_TRUNC('month', DATEADD(month, -1, CURRENT_TIMESTAMP()))::TIMESTAMP_NTZ)::DATE
    AND usage_date < CONVERT_TIMEZONE('America/Chicago', 'UTC', DATE_TRUNC('month', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ)::DATE
GROUP BY
    1
ORDER BY
    1;




 SELECT
    warehouse_name AS "WarehouseName",
    SUM(credits_used) AS "TotalCreditsUsed",
    SUM(credits_used_compute) AS "ComputeCredits",
    SUM(credits_used_cloud_services) AS "CloudServicesCredits"
FROM
    snowflake.account_usage.metering_warehouse_history
WHERE
    start_time >= CONVERT_TIMEZONE('America/Chicago', 'UTC', DATE_TRUNC('month', DATEADD(month, -1, CURRENT_TIMESTAMP()))::TIMESTAMP_NTZ)
    AND start_time < CONVERT_TIMEZONE('America/Chicago', 'UTC', DATE_TRUNC('month', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ)
GROUP BY
    1
ORDER BY
    "TotalCreditsUsed" DESC;   




SELECT
    table_catalog AS "DatabaseName",
    table_schema AS "SchemaName",
    table_name AS "TableName",
    retained_for_clone_bytes / (POWER(1024, 3)) AS "RetainedForCloneGB",
    active_bytes / (POWER(1024, 3)) AS "ActiveStorageGB"
 FROM
    INFORMATION_SCHEMA.TABLE_STORAGE_METRICS;





SELECT
    query_id AS "QueryId",
    query_text AS "QueryText",
    CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time) AS "StartTimeCST",
    CONVERT_TIMEZONE('UTC', 'America/Chicago', end_time) AS "EndTimeCST",
    total_elapsed_time / 1000 AS "ElapsedTimeSeconds",
    execution_status AS "ExecutionStatus",
    warehouse_name AS "WarehouseName",
    warehouse_size AS "WarehouseSize",
    bytes_scanned AS "BytesScanned",
    rows_produced AS "RowsProduced",
    credits_used_cloud_services AS "CloudServicesCreditsUsed",
    query_type AS "QueryType",
    user_name AS "UserName"
FROM
    snowflake.account_usage.query_history
WHERE
    start_time >= CONVERT_TIMEZONE('America/Chicago', 'UTC', DATE_TRUNC('month', DATEADD(month, -1, CURRENT_TIMESTAMP()))::TIMESTAMP_NTZ)
    AND start_time < CONVERT_TIMEZONE('America/Chicago', 'UTC', DATE_TRUNC('month', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ)
ORDER BY
    start_time DESC    


    SELECT
    warehouse_name AS "WarehouseName",
    created_on AS "CreatedOnCST",
    deleted_on AS "DeletedOnCST"
FROM
    snowflake.account_usage.warehouses
WHERE
    deleted_on IS NOT NULL
ORDER BY
    deleted_on DESC;



SELECT
    CONVERT_TIMEZONE('UTC', 'America/Chicago', DATE_TRUNC('day', start_time))::DATE AS "ReportDateCST",
    warehouse_name AS "WarehouseName",
    COUNT(query_id) AS "QueryCount",
    SUM(total_elapsed_time / 1000) AS "TotalDurationSeconds",
    AVG(total_elapsed_time / 1000) AS "AverageDurationSeconds",
    MAX(total_elapsed_time / 1000) AS "MaxDurationSeconds",
    MIN(total_elapsed_time / 1000) AS "MinDurationSeconds"
FROM
    snowflake.account_usage.query_history
WHERE
    start_time >= CONVERT_TIMEZONE('America/Chicago', 'UTC', DATE_TRUNC('month', DATEADD(month, -1, CURRENT_TIMESTAMP()))::TIMESTAMP_NTZ)
    AND start_time < CONVERT_TIMEZONE('America/Chicago', 'UTC', DATE_TRUNC('month', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ)
GROUP BY
    1, 2
ORDER BY
    1, 2;    



    SELECT
    DATE_TRUNC('hour', CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time)) AS "HourCST",
    warehouse_name AS "WarehouseName",
    MAX(avg_running) AS "MaxConcurrentQueries",
    AVG(avg_running) AS "AverageRunningQueries",
    MAX(avg_queued_load) AS "MaxQueuedQueries"
FROM
    snowflake.account_usage.warehouse_load_history
WHERE
    start_time >= CONVERT_TIMEZONE('America/Chicago', 'UTC', DATE_TRUNC('day', DATEADD(day, -1, CURRENT_TIMESTAMP()))::TIMESTAMP_NTZ)
    AND start_time < CONVERT_TIMEZONE('America/Chicago', 'UTC', DATE_TRUNC('day', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ)
GROUP BY
    1, 2
ORDER BY
    1, 2;




    SELECT
    DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time))::DATE AS "ReportDateCST",
    warehouse_name AS "WarehouseName",
    MAX(avg_running) AS "MaxAvgRunningQueries",
    AVG(avg_running) AS "AverageRunningQueries",
    MAX(avg_queued_load) AS "MaxQueuedQueries",
    AVG(avg_queued_load) AS "AverageQueuedQueries"
FROM
    snowflake.account_usage.warehouse_load_history
WHERE
    start_time >= CONVERT_TIMEZONE('America/Chicago', 'UTC', DATE_TRUNC('day', DATEADD(day, -1, CURRENT_TIMESTAMP()))::TIMESTAMP_NTZ)
    AND start_time < CONVERT_TIMEZONE('America/Chicago', 'UTC', DATE_TRUNC('day', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ)
GROUP BY
    1, 2
ORDER BY
    1, 2;



    SELECT
    CONVERT_TIMEZONE('UTC', 'America/Chicago', DATE_TRUNC('day', start_time))::DATE AS "QueryDateCST",
    warehouse_name AS "WarehouseName",
    COUNT(query_id) AS "QueryCount"
FROM
    snowflake.account_usage.query_history
WHERE
    start_time >= CONVERT_TIMEZONE('America/Chicago', 'UTC', DATE_TRUNC('day', DATEADD(day, -1, CURRENT_TIMESTAMP()))::TIMESTAMP_NTZ)
    AND start_time < CONVERT_TIMEZONE('America/Chicago', 'UTC', DATE_TRUNC('day', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ)
GROUP BY
    1, 2
ORDER BY
    1, 2;



    SELECT
    warehouse_name AS "WarehouseName",
    warehouse_id AS "WarehouseId",
    type AS "WarehouseType",
    size AS "Size",
    state AS "CurrentState",
    owner AS "Owner",
    CONVERT_TIMEZONE('UTC', 'America/Chicago', created_on) AS "CreatedOnCST"
SELECT * FROM
    snowflake.account_usage.WAREHOUSE_EVENTS_HISTORY
WHERE
    deleted_on IS NULL
ORDER BY
    "CreatedOnCST" DESC;



    SELECT
    COUNT(*) AS "QueryCountFromAccountUsage"
FROM
    snowflake.account_usage.query_history
WHERE
    start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP());




    SELECT
    end_time AS "EndTimeUTC", -- Keep original UTC time for reference
    start_time AS "StartTimeUTC", -- Keep original UTC time for reference
    CONVERT_TIMEZONE('UTC', 'America/Chicago', end_time) AS "EndTimeCST",
    CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time) AS "StartTimeCST",
    warehouse_id AS "WarehouseId",
    warehouse_name AS "WarehouseName",
    credits_used AS "CreditsUsed",
    credits_used_cloud_services AS "CreditsUsedCloudServices",
    credits_used_compute AS "CreditsUsedCompute"
FROM
    snowflake.account_usage.WAREHOUSE_METERING_HISTORY
WHERE
    start_time >= CONVERT_TIMEZONE('America/Chicago', 'UTC', DATE_TRUNC('month', DATEADD(month, -1, CURRENT_TIMESTAMP()))::TIMESTAMP_NTZ)
    AND start_time < CONVERT_TIMEZONE('America/Chicago', 'UTC', DATE_TRUNC('month', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ)
ORDER BY
    start_time, warehouse_name;







    SELECT
    query_id,
    query_text,
    query_type,
    user_name,
    role_name,
    warehouse_name,
    database_name,
    schema_name,
    total_elapsed_time / 1000 AS total_elapsed_time_seconds,
    execution_time / 1000 AS execution_time_seconds,
    credits_used_cloud_services,
    bytes_scanned,
    rows_produced,
    start_time AS start_time_utc,
    end_time AS end_time_utc,
    CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time) AS start_time_central,
    CONVERT_TIMEZONE('UTC', 'America/Chicago', end_time) AS end_time_central
FROM
    (
        SELECT
            *,
            ROW_NUMBER() OVER (PARTITION BY warehouse_name ORDER BY total_elapsed_time DESC) as rn
        FROM
            SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE
            DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time)) = DATEADD(day, -1, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'America/Chicago', CURRENT_TIMESTAMP())))
            AND query_type NOT IN ('SHOW', 'DESCRIBE', 'USE')
    )
WHERE
    rn <= 20
ORDER BY
    warehouse_name, total_elapsed_time_seconds DESC;




    SELECT
    query_id,
    query_text,
    query_type,
    user_name,
    role_name,
    warehouse_name,
    database_name,
    schema_name,
    total_elapsed_time / 1000 AS total_elapsed_time_seconds,
    execution_time / 1000 AS execution_time_seconds,
    credits_used_cloud_services,
    bytes_scanned,
    rows_produced,
    start_time AS start_time_utc,
    end_time AS end_time_utc,
    CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time) AS start_time_central,
    CONVERT_TIMEZONE('UTC', 'America/Chicago', end_time) AS end_time_central,
    DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time)) AS usage_date_central,
    HOUR(CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time)) AS usage_hour_central,
    DAYOFWEEK(CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time)) AS day_of_week_central,
    error_message
FROM
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE
    warehouse_name = 'DBT_LARGE_WH'
    AND DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time)) = DATEADD(day, -1, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'America/Chicago', CURRENT_TIMESTAMP()))) 
    AND query_type NOT IN ('SHOW', 'DESCRIBE', 'USE') 
ORDER BY
    total_elapsed_time_seconds DESC; 



SELECT
    query_id,
   -- REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(query_text, '\n', ' '), '\r', ' '), '"', ''), '''', ''), ',', ''), '/*', ''), '*/', '') AS query_text_cleaned, 
    query_type,
    user_name,
    role_name,
    warehouse_name,
    database_name,
    schema_name,
    total_elapsed_time / 1000 AS total_elapsed_time_seconds,
    execution_time / 1000 AS execution_time_seconds,
    credits_used_cloud_services,
    bytes_scanned,
    rows_produced,
    start_time AS start_time_utc,
    end_time AS end_time_utc,
    CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time) AS start_time_central,
    CONVERT_TIMEZONE('UTC', 'America/Chicago', end_time) AS end_time_central,
    DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time)) AS usage_date_central,
    HOUR(CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time)) AS usage_hour_central,
    DAYOFWEEK(CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time)) AS day_of_week_central,
    error_message
FROM
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE
    warehouse_name = 'DBT_LARGE_WH'
    AND DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time)) = DATEADD(day, -1, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'America/Chicago', CURRENT_TIMESTAMP())))
    AND query_type NOT IN ('SHOW', 'DESCRIBE', 'USE')
ORDER BY
    total_elapsed_time_seconds DESC;






SELECT
    query_id,
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(query_text, '\n', ' '), '\r', ' '), '"', ''), '''', ''), ',', ''), '/*', ''), '*/', '') AS query_text_cleaned
FROM
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE
    warehouse_name = 'DBT_LARGE_WH'
    AND DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'America/Chicago', start_time)) = DATEADD(day, -1, DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'America/Chicago', CURRENT_TIMESTAMP())))
    AND QUERY_TYPE='MERGE'
ORDER BY
    total_elapsed_time DESC; 
