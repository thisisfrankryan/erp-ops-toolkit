/*
  ERP user data scope audit and repair template (SQL Server).

  Scene:
  A user can log in and see menus, but cannot see project / department data.
  This is often caused by missing organization data scope or inconsistent role
  bindings.
*/

SET XACT_ABORT ON;

DECLARE @UserId BIGINT = 9527;
DECLARE @ReferenceUserId BIGINT = 8012;
DECLARE @Operator NVARCHAR(50) = N'OPS_SUPPORT';
DECLARE @ReferenceScopeCount INT;
DECLARE @TargetScopeCount INT;
DECLARE @InsertedRows INT;

-- 1. Audit target user role and organization scope.
SELECT user_id, role_id, is_active
FROM sys_user_roles
WHERE user_id = @UserId
ORDER BY role_id;

SELECT user_id, org_id, data_scope_type, is_active
FROM sys_user_data_scope
WHERE user_id = @UserId
ORDER BY org_id;

-- 2. Compare with a confirmed reference user in the same position.
SELECT user_id, org_id, data_scope_type, is_active
FROM sys_user_data_scope
WHERE user_id = @ReferenceUserId
  AND is_active = 1
ORDER BY org_id;

SELECT @ReferenceScopeCount = COUNT(1)
FROM sys_user_data_scope
WHERE user_id = @ReferenceUserId
  AND is_active = 1;

SELECT @TargetScopeCount = COUNT(1)
FROM sys_user_data_scope
WHERE user_id = @UserId
  AND is_active = 1;

IF @ReferenceScopeCount = 0
BEGIN
    RAISERROR(N'Reference user has no active data scope. Repair stopped.', 16, 1);
    RETURN;
END;

IF @TargetScopeCount > 0
BEGIN
    RAISERROR(N'Target user already has active data scope. Audit manually before repair.', 16, 1);
    RETURN;
END;

-- 3. Back up both users' scope rows before repair.
SELECT *
INTO backup_user_data_scope_20260603
FROM sys_user_data_scope
WHERE user_id IN (@UserId, @ReferenceUserId);

BEGIN TRANSACTION;

INSERT INTO sys_user_data_scope (
    user_id,
    org_id,
    data_scope_type,
    is_active,
    created_by,
    created_at,
    remark
)
SELECT
    @UserId,
    org_id,
    data_scope_type,
    1,
    @Operator,
    GETDATE(),
    N'Copied data scope from user ' + CAST(@ReferenceUserId AS NVARCHAR(20))
FROM sys_user_data_scope
WHERE user_id = @ReferenceUserId
  AND is_active = 1;

SET @InsertedRows = @@ROWCOUNT;

IF @InsertedRows = @ReferenceScopeCount
BEGIN
    COMMIT TRANSACTION;
    PRINT N'User data scope repair committed successfully.';
END
ELSE
BEGIN
    ROLLBACK TRANSACTION;
    PRINT N'User data scope repair rolled back. Inserted rows do not match reference count.';
END;

-- 4. Review repaired scope.
SELECT user_id, org_id, data_scope_type, is_active, created_by, created_at
FROM sys_user_data_scope
WHERE user_id = @UserId
ORDER BY org_id;
