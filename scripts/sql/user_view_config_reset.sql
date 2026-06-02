/*
  ERP user view configuration reset template (SQL Server).

  Scene:
  A user reports that list columns disappear, search conditions are strange or a
  page layout is broken. The root cause may be a corrupted personal view config.
*/

SET XACT_ABORT ON;

DECLARE @UserId BIGINT = 9527;
DECLARE @PageCode NVARCHAR(80) = N'reimbursement_list';
DECLARE @Operator NVARCHAR(50) = N'OPS_SUPPORT';
DECLARE @ExpectedRows INT;
DECLARE @UpdatedRows INT;

-- 1. Preview personal view configuration.
SELECT
    config_id,
    user_id,
    page_code,
    config_type,
    config_json,
    is_active,
    updated_at
FROM sys_user_view_config
WHERE user_id = @UserId
  AND page_code = @PageCode
  AND is_active = 1;

SELECT @ExpectedRows = COUNT(1)
FROM sys_user_view_config
WHERE user_id = @UserId
  AND page_code = @PageCode
  AND is_active = 1;

IF @ExpectedRows = 0
BEGIN
    PRINT N'No active personal view config found. System default may already be used.';
    RETURN;
END;

-- 2. Back up the personal config before reset.
SELECT *
INTO backup_user_view_config_20260603
FROM sys_user_view_config
WHERE user_id = @UserId
  AND page_code = @PageCode
  AND is_active = 1;

BEGIN TRANSACTION;

UPDATE sys_user_view_config
SET
    is_active = 0,
    updated_by = @Operator,
    updated_at = GETDATE(),
    remark = CONCAT(ISNULL(remark, N''), N' | Disabled to restore system default view.')
WHERE user_id = @UserId
  AND page_code = @PageCode
  AND is_active = 1;

SET @UpdatedRows = @@ROWCOUNT;

IF @UpdatedRows = @ExpectedRows
BEGIN
    COMMIT TRANSACTION;
    PRINT N'User view config reset committed successfully.';
END
ELSE
BEGIN
    ROLLBACK TRANSACTION;
    PRINT N'User view config reset rolled back. Updated rows do not match preview count.';
END;

-- 3. Review reset result.
SELECT
    config_id,
    user_id,
    page_code,
    config_type,
    is_active,
    updated_by,
    updated_at
FROM sys_user_view_config
WHERE user_id = @UserId
  AND page_code = @PageCode
ORDER BY updated_at DESC;
