/*
  ERP user permission clone template (SQL Server).

  Scene:
  A new employee needs the same permissions as an existing employee in the same
  role. The target user must be checked before inserting any permission records.

  Safety rules:
  1. Confirm source permissions before cloning.
  2. Confirm target user has no residual permissions.
  3. Back up source and target permission records.
  4. Use an explicit transaction and check affected rows.
*/

SET XACT_ABORT ON;

DECLARE @SourceUserId BIGINT = 8012;
DECLARE @TargetUserId BIGINT = 9527;
DECLARE @Operator NVARCHAR(50) = N'SYS_ADMIN_OPS';
DECLARE @SourcePermissionCount INT;
DECLARE @TargetPermissionCount INT;
DECLARE @InsertedRows INT;

-- 1. Preview source permissions.
SELECT user_id, permission_code, permission_type, is_active
FROM erp_user_permissions
WHERE user_id = @SourceUserId
  AND is_active = 1
ORDER BY permission_type, permission_code;

SELECT @SourcePermissionCount = COUNT(1)
FROM erp_user_permissions
WHERE user_id = @SourceUserId
  AND is_active = 1;

-- 2. Confirm target user has no active residual permissions.
SELECT user_id, permission_code, permission_type, is_active
FROM erp_user_permissions
WHERE user_id = @TargetUserId
  AND is_active = 1
ORDER BY permission_type, permission_code;

SELECT @TargetPermissionCount = COUNT(1)
FROM erp_user_permissions
WHERE user_id = @TargetUserId
  AND is_active = 1;

IF @SourcePermissionCount = 0
BEGIN
    RAISERROR(N'Source user has no active permissions. Clone stopped.', 16, 1);
    RETURN;
END;

IF @TargetPermissionCount > 0
BEGIN
    RAISERROR(N'Target user already has active permissions. Clean or confirm before clone.', 16, 1);
    RETURN;
END;

-- 3. Back up related permission rows before insert.
-- Change the backup table suffix before each execution to avoid name conflict.
SELECT *
INTO backup_user_permissions_20260602
FROM erp_user_permissions
WHERE user_id IN (@SourceUserId, @TargetUserId);

BEGIN TRANSACTION;

INSERT INTO erp_user_permissions (
    user_id,
    permission_code,
    permission_type,
    is_active,
    created_by,
    created_at,
    remark
)
SELECT
    @TargetUserId,
    permission_code,
    permission_type,
    1,
    @Operator,
    GETDATE(),
    N'Cloned from user ' + CAST(@SourceUserId AS NVARCHAR(20))
FROM erp_user_permissions
WHERE user_id = @SourceUserId
  AND is_active = 1;

SET @InsertedRows = @@ROWCOUNT;

IF @InsertedRows = @SourcePermissionCount
BEGIN
    COMMIT TRANSACTION;
    PRINT N'Permission clone committed successfully.';
END
ELSE
BEGIN
    ROLLBACK TRANSACTION;
    PRINT N'Permission clone rolled back. Inserted rows do not match source permission count.';
END;

-- 4. Review target permissions after execution.
SELECT user_id, permission_code, permission_type, is_active, created_by, created_at
FROM erp_user_permissions
WHERE user_id = @TargetUserId
ORDER BY permission_type, permission_code;
