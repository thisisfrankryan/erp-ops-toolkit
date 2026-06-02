/*
  ERP report query performance diagnosis template (SQL Server).

  Scene:
  A customer reports that a project cost report, reimbursement list or inventory
  ledger loads slowly. Support should first identify slow SQL, scan behavior
  and missing index hints before changing code or data.

  Safety rules:
  1. This template is read-only.
  2. Do not create indexes directly in production without testing.
  3. Use the result to discuss optimization scope with development or DBA.
*/

SET NOCOUNT ON;

DECLARE @Keyword NVARCHAR(100) = N'erp_contracts';

-- 1. Recent heavy queries containing the target table or module keyword.
SELECT TOP (30)
    query_stats.total_elapsed_time / 1000 AS total_elapsed_ms,
    query_stats.total_worker_time / 1000 AS total_cpu_ms,
    query_stats.total_logical_reads,
    query_stats.execution_count,
    query_stats.last_execution_time,
    query_text.text AS sql_text
FROM sys.dm_exec_query_stats AS query_stats
CROSS APPLY sys.dm_exec_sql_text(query_stats.sql_handle) AS query_text
WHERE query_text.text LIKE N'%' + @Keyword + N'%'
ORDER BY query_stats.total_elapsed_time DESC;

-- 2. Missing index suggestions from SQL Server DMVs.
SELECT TOP (30)
    DB_NAME(index_details.database_id) AS database_name,
    OBJECT_NAME(index_details.object_id, index_details.database_id) AS table_name,
    index_details.equality_columns,
    index_details.inequality_columns,
    index_details.included_columns,
    index_group_stats.user_seeks,
    index_group_stats.avg_total_user_cost,
    index_group_stats.avg_user_impact,
    'CREATE INDEX IX_' + OBJECT_NAME(index_details.object_id, index_details.database_id)
        + '_AUTO_CHECK ON ' + index_details.statement
        + ' (' + ISNULL(index_details.equality_columns, '')
        + CASE
            WHEN index_details.equality_columns IS NOT NULL
                 AND index_details.inequality_columns IS NOT NULL
            THEN ', '
            ELSE ''
          END
        + ISNULL(index_details.inequality_columns, '') + ')'
        + CASE
            WHEN index_details.included_columns IS NOT NULL
            THEN ' INCLUDE (' + index_details.included_columns + ')'
            ELSE ''
          END AS suggested_index_sql
FROM sys.dm_db_missing_index_group_stats AS index_group_stats
INNER JOIN sys.dm_db_missing_index_groups AS index_groups
    ON index_group_stats.group_handle = index_groups.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS index_details
    ON index_groups.index_handle = index_details.index_handle
WHERE index_details.database_id = DB_ID()
ORDER BY index_group_stats.avg_user_impact DESC, index_group_stats.user_seeks DESC;

-- 3. Existing indexes of the suspected table.
SELECT
    table_info.name AS table_name,
    index_info.name AS index_name,
    index_info.type_desc,
    index_info.is_unique,
    column_info.name AS column_name,
    index_column.key_ordinal,
    index_column.is_included_column
FROM sys.indexes AS index_info
INNER JOIN sys.tables AS table_info
    ON index_info.object_id = table_info.object_id
INNER JOIN sys.index_columns AS index_column
    ON index_info.object_id = index_column.object_id
   AND index_info.index_id = index_column.index_id
INNER JOIN sys.columns AS column_info
    ON index_column.object_id = column_info.object_id
   AND index_column.column_id = column_info.column_id
WHERE table_info.name LIKE N'%' + @Keyword + N'%'
ORDER BY table_info.name, index_info.name, index_column.key_ordinal;

/*
  Follow-up rule:
  If a report is slow, first narrow the business condition: organization,
  project, date range and status. Then verify whether the WHERE condition can
  use existing indexes. Avoid wrapping indexed date columns with functions.
*/
