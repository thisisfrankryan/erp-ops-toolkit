/*
  ERP approval status correction template (SQL Server).

  Scene:
  A purchase order is stuck in an intermediate approval status. Business users
  confirmed that the approval process has completed, but the database status
  was not synchronized.

  Safety rules:
  1. Confirm the target row with SELECT before UPDATE.
  2. Back up the original row before changing data.
  3. Use an explicit transaction.
  4. Check affected rows before COMMIT.
*/

SET XACT_ABORT ON;

DECLARE @OrderNo NVARCHAR(50) = N'PO20260602';
DECLARE @ExpectedOldStatus INT = 2; -- 2 = approving
DECLARE @TargetNewStatus INT = 3;   -- 3 = completed

-- 1. Confirm target data before update.
SELECT order_no, status, updated_at
FROM purchase_orders
WHERE order_no = @OrderNo;

-- 2. Back up the row before modification.
SELECT *
INTO backup_purchase_orders_PO20260602
FROM purchase_orders
WHERE order_no = @OrderNo;

BEGIN TRANSACTION;

UPDATE purchase_orders
SET status = @TargetNewStatus,
    updated_at = GETDATE()
WHERE order_no = @OrderNo
  AND status = @ExpectedOldStatus;

IF @@ROWCOUNT = 1
BEGIN
    COMMIT TRANSACTION;
    PRINT 'Status correction committed successfully.';
END
ELSE
BEGIN
    ROLLBACK TRANSACTION;
    PRINT 'Status correction rolled back. Please check target row and status.';
END;

-- 3. Review result after execution.
SELECT order_no, status, updated_at
FROM purchase_orders
WHERE order_no = @OrderNo;
