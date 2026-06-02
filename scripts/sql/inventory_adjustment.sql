/*
  ERP inventory adjustment template (SQL Server).

  Scene:
  A product has an abnormal stock quantity after reconciliation. The actual
  stock has been confirmed by business users and warehouse records.

  Safety rules:
  1. Confirm product identity and current stock before adjustment.
  2. Back up the original row.
  3. Use an explicit transaction.
  4. Check affected rows before COMMIT.
*/

SET XACT_ABORT ON;

DECLARE @GoodsId NVARCHAR(50) = N'G100';
DECLARE @TargetStock INT = 15;

-- 1. Confirm current inventory.
SELECT goods_id, stock_count, updated_at
FROM inventory
WHERE goods_id = @GoodsId;

-- 2. Back up current inventory row.
SELECT *
INTO backup_inventory_G100
FROM inventory
WHERE goods_id = @GoodsId;

BEGIN TRANSACTION;

UPDATE inventory
SET stock_count = @TargetStock,
    updated_at = GETDATE()
WHERE goods_id = @GoodsId;

IF @@ROWCOUNT = 1
BEGIN
    COMMIT TRANSACTION;
    PRINT 'Inventory adjustment committed successfully.';
END
ELSE
BEGIN
    ROLLBACK TRANSACTION;
    PRINT 'Inventory adjustment rolled back. Please check goods_id condition.';
END;

-- 3. Review result after execution.
SELECT goods_id, stock_count, updated_at
FROM inventory
WHERE goods_id = @GoodsId;
