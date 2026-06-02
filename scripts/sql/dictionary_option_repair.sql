/*
  ERP dictionary option repair template (SQL Server).

  Scene:
  A drop-down field is blank or shows an incorrect value because a dictionary
  item was disabled, renamed or missed during initialization.
*/

SET XACT_ABORT ON;

DECLARE @DictType NVARCHAR(80) = N'expense_type';
DECLARE @DictCode NVARCHAR(80) = N'RESEARCH';
DECLARE @DictLabel NVARCHAR(120) = N'科研经费';
DECLARE @Operator NVARCHAR(50) = N'OPS_SUPPORT';
DECLARE @AffectedRows INT;

-- 1. Preview current dictionary items.
SELECT
    dict_id,
    dict_type,
    dict_code,
    dict_label,
    sort_no,
    is_active,
    updated_at
FROM sys_dict_items
WHERE dict_type = @DictType
ORDER BY sort_no, dict_code;

-- 2. Back up related dictionary rows.
SELECT *
INTO backup_dict_items_20260603
FROM sys_dict_items
WHERE dict_type = @DictType;

BEGIN TRANSACTION;

IF EXISTS (
    SELECT 1
    FROM sys_dict_items
    WHERE dict_type = @DictType
      AND dict_code = @DictCode
)
BEGIN
    UPDATE sys_dict_items
    SET
        dict_label = @DictLabel,
        is_active = 1,
        updated_by = @Operator,
        updated_at = GETDATE()
    WHERE dict_type = @DictType
      AND dict_code = @DictCode;

    SET @AffectedRows = @@ROWCOUNT;
END
ELSE
BEGIN
    INSERT INTO sys_dict_items (
        dict_type,
        dict_code,
        dict_label,
        sort_no,
        is_active,
        created_by,
        created_at
    )
    VALUES (
        @DictType,
        @DictCode,
        @DictLabel,
        10,
        1,
        @Operator,
        GETDATE()
    );

    SET @AffectedRows = @@ROWCOUNT;
END;

IF @AffectedRows = 1
BEGIN
    COMMIT TRANSACTION;
    PRINT N'Dictionary option repair committed successfully.';
END
ELSE
BEGIN
    ROLLBACK TRANSACTION;
    PRINT N'Dictionary option repair rolled back. Please check dictionary key.';
END;

-- 3. Review result after execution.
SELECT
    dict_type,
    dict_code,
    dict_label,
    sort_no,
    is_active,
    updated_by,
    updated_at
FROM sys_dict_items
WHERE dict_type = @DictType
ORDER BY sort_no, dict_code;
