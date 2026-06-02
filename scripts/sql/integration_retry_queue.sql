/*
  ERP integration retry queue template (SQL Server).

  Scene:
  Mobile approval, OA, finance or third-party interface messages fail because of
  temporary network errors. Support should identify safe retry candidates and
  reset only those messages that meet the retry conditions.
*/

SET XACT_ABORT ON;

DECLARE @InterfaceCode NVARCHAR(80) = N'OA_APPROVAL_CALLBACK';
DECLARE @MaxRetryCount INT = 3;
DECLARE @Operator NVARCHAR(50) = N'OPS_SUPPORT';
DECLARE @ExpectedRows INT;
DECLARE @UpdatedRows INT;

-- 1. Preview failed messages that can be retried.
SELECT
    message_id,
    interface_code,
    business_no,
    message_status,
    retry_count,
    last_error,
    updated_at
FROM interface_message_queue
WHERE interface_code = @InterfaceCode
  AND message_status = N'FAILED'
  AND retry_count < @MaxRetryCount
ORDER BY updated_at ASC;

SELECT @ExpectedRows = COUNT(1)
FROM interface_message_queue
WHERE interface_code = @InterfaceCode
  AND message_status = N'FAILED'
  AND retry_count < @MaxRetryCount;

IF @ExpectedRows = 0
BEGIN
    PRINT N'No retryable interface messages found.';
    RETURN;
END;

-- 2. Back up retry candidates.
SELECT *
INTO backup_interface_retry_20260603
FROM interface_message_queue
WHERE interface_code = @InterfaceCode
  AND message_status = N'FAILED'
  AND retry_count < @MaxRetryCount;

BEGIN TRANSACTION;

UPDATE interface_message_queue
SET
    message_status = N'PENDING',
    next_retry_time = DATEADD(MINUTE, 5, GETDATE()),
    updated_by = @Operator,
    updated_at = GETDATE(),
    remark = CONCAT(ISNULL(remark, N''), N' | Reset to pending for controlled retry.')
WHERE interface_code = @InterfaceCode
  AND message_status = N'FAILED'
  AND retry_count < @MaxRetryCount;

SET @UpdatedRows = @@ROWCOUNT;

IF @UpdatedRows = @ExpectedRows
BEGIN
    COMMIT TRANSACTION;
    PRINT N'Integration retry reset committed successfully.';
END
ELSE
BEGIN
    ROLLBACK TRANSACTION;
    PRINT N'Integration retry reset rolled back. Updated rows do not match preview count.';
END;

-- 3. Review reset messages.
SELECT
    message_id,
    interface_code,
    business_no,
    message_status,
    retry_count,
    next_retry_time,
    updated_by,
    updated_at
FROM interface_message_queue
WHERE interface_code = @InterfaceCode
  AND updated_by = @Operator
ORDER BY updated_at DESC;
