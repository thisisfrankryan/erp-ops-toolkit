/*
  ERP SQL Server blocking and deadlock diagnosis template.

  Scene:
  During month-end cost calculation or voucher generation, finance pages keep
  loading because long-running report jobs block each other or hold locks for a
  long time.

  Safety rules:
  1. This template is read-only by default.
  2. Confirm database, module, business window and affected users first.
  3. Do not KILL sessions until business owner and DBA confirm the impact.
*/

SET NOCOUNT ON;

DECLARE @DatabaseName SYSNAME = DB_NAME();

-- 1. Current blocking chain and waiting SQL.
SELECT
    waiting_request.session_id AS waiting_session_id,
    waiting_request.blocking_session_id,
    waiting_session.login_name AS waiting_login,
    waiting_session.host_name AS waiting_host,
    waiting_session.program_name AS waiting_program,
    waiting_request.status,
    waiting_request.command,
    waiting_request.wait_type,
    waiting_request.wait_time,
    waiting_request.wait_resource,
    DB_NAME(waiting_request.database_id) AS database_name,
    waiting_text.text AS waiting_sql_text,
    blocking_text.text AS blocking_sql_text
FROM sys.dm_exec_requests AS waiting_request
INNER JOIN sys.dm_exec_sessions AS waiting_session
    ON waiting_request.session_id = waiting_session.session_id
OUTER APPLY sys.dm_exec_sql_text(waiting_request.sql_handle) AS waiting_text
LEFT JOIN sys.dm_exec_requests AS blocking_request
    ON waiting_request.blocking_session_id = blocking_request.session_id
OUTER APPLY sys.dm_exec_sql_text(blocking_request.sql_handle) AS blocking_text
WHERE waiting_request.blocking_session_id <> 0
  AND waiting_request.database_id = DB_ID(@DatabaseName)
ORDER BY waiting_request.wait_time DESC;

-- 2. Long-running transactions in the current database.
SELECT
    session_info.session_id,
    session_info.login_name,
    session_info.host_name,
    session_info.program_name,
    transaction_info.transaction_begin_time,
    DATEDIFF(MINUTE, transaction_info.transaction_begin_time, GETDATE()) AS transaction_minutes,
    request_info.status,
    request_info.command,
    request_info.wait_type,
    request_info.wait_resource,
    sql_text.text AS running_sql_text
FROM sys.dm_tran_session_transactions AS session_transaction
INNER JOIN sys.dm_tran_active_transactions AS transaction_info
    ON session_transaction.transaction_id = transaction_info.transaction_id
INNER JOIN sys.dm_exec_sessions AS session_info
    ON session_transaction.session_id = session_info.session_id
LEFT JOIN sys.dm_exec_requests AS request_info
    ON session_transaction.session_id = request_info.session_id
OUTER APPLY sys.dm_exec_sql_text(request_info.sql_handle) AS sql_text
WHERE request_info.database_id = DB_ID(@DatabaseName)
ORDER BY transaction_info.transaction_begin_time ASC;

-- 3. Lock details for the current database.
SELECT
    lock_info.request_session_id,
    lock_info.resource_type,
    lock_info.request_mode,
    lock_info.request_status,
    OBJECT_NAME(partition_info.object_id, lock_info.resource_database_id) AS object_name,
    session_info.login_name,
    session_info.host_name,
    session_info.program_name
FROM sys.dm_tran_locks AS lock_info
LEFT JOIN sys.partitions AS partition_info
    ON lock_info.resource_associated_entity_id = partition_info.hobt_id
LEFT JOIN sys.dm_exec_sessions AS session_info
    ON lock_info.request_session_id = session_info.session_id
WHERE lock_info.resource_database_id = DB_ID(@DatabaseName)
ORDER BY lock_info.request_session_id, lock_info.resource_type, lock_info.request_mode;

-- 4. Recent deadlock graphs captured by the system_health session.
SELECT TOP (10)
    deadlock_event.value('@timestamp', 'DATETIME2') AS event_time,
    deadlock_event.query('.') AS deadlock_graph
FROM (
    SELECT CAST(target_data AS XML) AS target_data
    FROM sys.dm_xe_sessions AS xe_session
    INNER JOIN sys.dm_xe_session_targets AS xe_target
        ON xe_session.address = xe_target.event_session_address
    WHERE xe_session.name = N'system_health'
      AND xe_target.target_name = N'ring_buffer'
) AS source_data
CROSS APPLY source_data.target_data.nodes(
    N'RingBufferTarget/event[@name="xml_deadlock_report"]'
) AS deadlock_data(deadlock_event)
ORDER BY event_time DESC;

/*
  Optional handling after confirmation:

  1. Save screenshots or export the result sets above.
  2. Confirm whether the blocking session is a stuck report / batch job or an
     active business operation.
  3. If DBA and business owner both confirm that the session can be terminated,
     execute the generated command manually:

     -- KILL <blocking_session_id>;

  4. Re-run section 1 to confirm the blocking chain is cleared.
*/
