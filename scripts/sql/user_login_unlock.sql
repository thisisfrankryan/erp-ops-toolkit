/*
  ERP user login unlock template (SQL Server).

  Scene:
  A customer cannot log in because the account is locked by repeated password
  attempts or disabled by mistake. Support should confirm user identity and
  reset only the lock-related fields.
*/

SET XACT_ABORT ON;

DECLARE @LoginName NVARCHAR(80) = N'zhangsan';
DECLARE @Operator NVARCHAR(50) = N'OPS_SUPPORT';

-- 1. Confirm the target account and current lock status.
SELECT
    user_id,
    login_name,
    display_name,
    user_status,
    is_locked,
    failed_login_count,
    lock_time,
    updated_at
FROM sys_users
WHERE login_name = @LoginName;

-- 2. Back up the account row before modification.
SELECT *
INTO backup_sys_users_unlock_20260603
FROM sys_users
WHERE login_name = @LoginName;

BEGIN TRANSACTION;

UPDATE sys_users
SET
    is_locked = 0,
    failed_login_count = 0,
    lock_time = NULL,
    updated_by = @Operator,
    updated_at = GETDATE(),
    remark = CONCAT(ISNULL(remark, N''), N' | Account unlocked by ops support.')
WHERE login_name = @LoginName
  AND is_locked = 1;

IF @@ROWCOUNT = 1
BEGIN
    COMMIT TRANSACTION;
    PRINT N'User account unlocked successfully.';
END
ELSE
BEGIN
    ROLLBACK TRANSACTION;
    PRINT N'Unlock rolled back. Please check login name and current lock status.';
END;

-- 3. Review result after execution.
SELECT
    user_id,
    login_name,
    user_status,
    is_locked,
    failed_login_count,
    lock_time,
    updated_by,
    updated_at
FROM sys_users
WHERE login_name = @LoginName;
