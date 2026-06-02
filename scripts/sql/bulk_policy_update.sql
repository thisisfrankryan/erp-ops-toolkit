/*
  ERP bulk policy update template (SQL Server).

  Scene:
  Tax policy or internal business policy changes require updating a batch of
  unclosed contracts or reimbursement documents. The operation must be scoped,
  backed up and reviewed before commit.

  Safety rules:
  1. Preview affected rows before writing.
  2. Back up all affected rows.
  3. Use an explicit transaction.
  4. Check affected rows before COMMIT.
*/

SET XACT_ABORT ON;

DECLARE @OldTaxRate DECIMAL(6, 4) = 0.0900;
DECLARE @NewTaxRate DECIMAL(6, 4) = 0.0600;
DECLARE @EffectiveDate DATE = '2026-06-01';
DECLARE @Operator NVARCHAR(50) = N'POLICY_UPDATE_OPS';
DECLARE @ExpectedRows INT;
DECLARE @UpdatedRows INT;

-- 1. Preview affected contracts. Replace table and status values with the
-- actual ERP dictionary before execution.
SELECT
    contract_id,
    contract_no,
    project_no,
    supplier_id,
    tax_rate,
    contract_status,
    updated_at
FROM erp_contracts
WHERE tax_rate = @OldTaxRate
  AND contract_status IN (N'DRAFT', N'APPROVING', N'ACTIVE')
  AND created_at < @EffectiveDate;

SELECT @ExpectedRows = COUNT(1)
FROM erp_contracts
WHERE tax_rate = @OldTaxRate
  AND contract_status IN (N'DRAFT', N'APPROVING', N'ACTIVE')
  AND created_at < @EffectiveDate;

IF @ExpectedRows = 0
BEGIN
    PRINT N'No contracts matched the policy update scope.';
    RETURN;
END;

-- 2. Back up affected rows before update.
-- Change the backup table suffix before each execution to avoid name conflict.
SELECT *
INTO backup_contract_tax_policy_20260603
FROM erp_contracts
WHERE tax_rate = @OldTaxRate
  AND contract_status IN (N'DRAFT', N'APPROVING', N'ACTIVE')
  AND created_at < @EffectiveDate;

BEGIN TRANSACTION;

UPDATE erp_contracts
SET
    tax_rate = @NewTaxRate,
    policy_effective_date = @EffectiveDate,
    updated_by = @Operator,
    updated_at = GETDATE(),
    remark = CONCAT(
        ISNULL(remark, N''),
        N' | Tax rate adjusted from ',
        CAST(@OldTaxRate AS NVARCHAR(20)),
        N' to ',
        CAST(@NewTaxRate AS NVARCHAR(20)),
        N' by policy update.'
    )
WHERE tax_rate = @OldTaxRate
  AND contract_status IN (N'DRAFT', N'APPROVING', N'ACTIVE')
  AND created_at < @EffectiveDate;

SET @UpdatedRows = @@ROWCOUNT;

IF @UpdatedRows = @ExpectedRows
BEGIN
    COMMIT TRANSACTION;
    PRINT N'Bulk policy update committed successfully.';
END
ELSE
BEGIN
    ROLLBACK TRANSACTION;
    PRINT N'Bulk policy update rolled back. Updated rows do not match preview count.';
END;

-- 3. Review affected rows after execution.
SELECT
    contract_id,
    contract_no,
    project_no,
    supplier_id,
    tax_rate,
    policy_effective_date,
    contract_status,
    updated_by,
    updated_at
FROM erp_contracts
WHERE updated_by = @Operator
  AND policy_effective_date = @EffectiveDate
ORDER BY updated_at DESC;
