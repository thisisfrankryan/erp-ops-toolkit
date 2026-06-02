/*
  ERP attachment orphan audit template (SQL Server).

  Scene:
  A document page shows no attachment after upload, or old attachments appear in
  the wrong document. The usual cause is inconsistent metadata between business
  document id and attachment table.
*/

SET XACT_ABORT ON;

DECLARE @BusinessType NVARCHAR(50) = N'REIMBURSEMENT';
DECLARE @BusinessId BIGINT = 1001001;
DECLARE @Operator NVARCHAR(50) = N'OPS_SUPPORT';
DECLARE @ExpectedRows INT;
DECLARE @UpdatedRows INT;

-- 1. Preview attachment metadata of the target document.
SELECT
    attachment_id,
    business_type,
    business_id,
    file_name,
    file_path,
    file_status,
    created_at,
    updated_at
FROM sys_attachments
WHERE business_type = @BusinessType
  AND business_id = @BusinessId
ORDER BY created_at DESC;

-- 2. Find active attachments whose business document no longer exists.
SELECT
    attachment.attachment_id,
    attachment.business_type,
    attachment.business_id,
    attachment.file_name,
    attachment.file_status
FROM sys_attachments AS attachment
LEFT JOIN erp_reimbursement AS reimbursement
    ON attachment.business_type = N'REIMBURSEMENT'
   AND attachment.business_id = reimbursement.reimbursement_id
WHERE attachment.business_type = @BusinessType
  AND attachment.file_status = N'ACTIVE'
  AND reimbursement.reimbursement_id IS NULL;

SELECT @ExpectedRows = COUNT(1)
FROM sys_attachments AS attachment
LEFT JOIN erp_reimbursement AS reimbursement
    ON attachment.business_type = N'REIMBURSEMENT'
   AND attachment.business_id = reimbursement.reimbursement_id
WHERE attachment.business_type = @BusinessType
  AND attachment.file_status = N'ACTIVE'
  AND reimbursement.reimbursement_id IS NULL;

IF @ExpectedRows = 0
BEGIN
    PRINT N'No orphan attachments found.';
    RETURN;
END;

-- 3. Back up orphan attachment rows before marking inactive.
SELECT attachment.*
INTO backup_orphan_attachments_20260603
FROM sys_attachments AS attachment
LEFT JOIN erp_reimbursement AS reimbursement
    ON attachment.business_type = N'REIMBURSEMENT'
   AND attachment.business_id = reimbursement.reimbursement_id
WHERE attachment.business_type = @BusinessType
  AND attachment.file_status = N'ACTIVE'
  AND reimbursement.reimbursement_id IS NULL;

BEGIN TRANSACTION;

UPDATE attachment
SET
    attachment.file_status = N'ORPHAN',
    attachment.updated_by = @Operator,
    attachment.updated_at = GETDATE(),
    attachment.remark = CONCAT(ISNULL(attachment.remark, N''), N' | Marked orphan after business document audit.')
FROM sys_attachments AS attachment
LEFT JOIN erp_reimbursement AS reimbursement
    ON attachment.business_type = N'REIMBURSEMENT'
   AND attachment.business_id = reimbursement.reimbursement_id
WHERE attachment.business_type = @BusinessType
  AND attachment.file_status = N'ACTIVE'
  AND reimbursement.reimbursement_id IS NULL;

SET @UpdatedRows = @@ROWCOUNT;

IF @UpdatedRows = @ExpectedRows
BEGIN
    COMMIT TRANSACTION;
    PRINT N'Orphan attachment audit committed successfully.';
END
ELSE
BEGIN
    ROLLBACK TRANSACTION;
    PRINT N'Orphan attachment audit rolled back. Updated rows do not match preview count.';
END;

-- 4. Review result after execution.
SELECT attachment_id, business_type, business_id, file_name, file_status, updated_by, updated_at
FROM sys_attachments
WHERE business_type = @BusinessType
  AND file_status = N'ORPHAN'
ORDER BY updated_at DESC;
