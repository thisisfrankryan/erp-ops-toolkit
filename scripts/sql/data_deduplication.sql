/*
  ERP master data deduplication template (SQL Server).

  Scene:
  During ERP initialization, vendor or material master data imported from Excel
  may contain duplicate rows caused by spaces, inconsistent punctuation or
  repeated submissions.

  Safety rules:
  1. Preview duplicate groups before writing.
  2. Do not DELETE duplicate master data directly.
  3. Back up affected rows.
  4. Mark duplicate rows inactive in a transaction and keep the earliest row.
*/

SET XACT_ABORT ON;

DECLARE @Operator NVARCHAR(50) = N'DATA_INIT_OPS';
DECLARE @ExpectedDuplicateRows INT;
DECLARE @UpdatedRows INT;

IF OBJECT_ID('tempdb..#DuplicateVendorRows') IS NOT NULL
BEGIN
    DROP TABLE #DuplicateVendorRows;
END;

;WITH normalized_vendor AS (
    SELECT
        id,
        vendor_name,
        tax_no,
        is_active,
        UPPER(REPLACE(REPLACE(LTRIM(RTRIM(vendor_name)), N' ', N''), N'　', N'')) AS normalized_vendor_name,
        UPPER(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(tax_no, N''))), N' ', N''), N'　', N'')) AS normalized_tax_no
    FROM init_vendor_staging
    WHERE is_active = 1
),
ranked_vendor AS (
    SELECT
        id,
        vendor_name,
        tax_no,
        normalized_vendor_name,
        normalized_tax_no,
        ROW_NUMBER() OVER (
            PARTITION BY normalized_vendor_name, normalized_tax_no
            ORDER BY id ASC
        ) AS row_rank,
        MIN(id) OVER (
            PARTITION BY normalized_vendor_name, normalized_tax_no
        ) AS keep_id,
        COUNT(1) OVER (
            PARTITION BY normalized_vendor_name, normalized_tax_no
        ) AS group_count
    FROM normalized_vendor
)
SELECT
    id,
    vendor_name,
    tax_no,
    normalized_vendor_name,
    normalized_tax_no,
    keep_id,
    group_count
INTO #DuplicateVendorRows
FROM ranked_vendor
WHERE group_count > 1
  AND row_rank > 1;

-- 1. Preview duplicate rows that will be marked inactive.
SELECT *
FROM #DuplicateVendorRows
ORDER BY normalized_vendor_name, normalized_tax_no, id;

SELECT @ExpectedDuplicateRows = COUNT(1)
FROM #DuplicateVendorRows;

IF @ExpectedDuplicateRows = 0
BEGIN
    PRINT N'No duplicate vendor rows found.';
    RETURN;
END;

-- 2. Back up affected rows before update.
-- Change the backup table suffix before each execution to avoid name conflict.
SELECT source_data.*
INTO backup_vendor_staging_duplicates_20260602
FROM init_vendor_staging AS source_data
INNER JOIN #DuplicateVendorRows AS duplicate_rows
    ON source_data.id = duplicate_rows.id;

BEGIN TRANSACTION;

UPDATE target
SET
    target.is_active = 0,
    target.duplicate_flag = 1,
    target.duplicate_keep_id = duplicate_rows.keep_id,
    target.remark = N'Data initialization duplicate. Kept row id: ' + CAST(duplicate_rows.keep_id AS NVARCHAR(20)),
    target.updated_by = @Operator,
    target.updated_at = GETDATE()
FROM init_vendor_staging AS target
INNER JOIN #DuplicateVendorRows AS duplicate_rows
    ON target.id = duplicate_rows.id
WHERE target.is_active = 1;

SET @UpdatedRows = @@ROWCOUNT;

IF @UpdatedRows = @ExpectedDuplicateRows
BEGIN
    COMMIT TRANSACTION;
    PRINT N'Deduplication committed successfully.';
END
ELSE
BEGIN
    ROLLBACK TRANSACTION;
    PRINT N'Deduplication rolled back. Updated rows do not match expected duplicate rows.';
END;

-- 3. Review inactive duplicate rows after execution.
SELECT target.id,
       target.vendor_name,
       target.tax_no,
       target.is_active,
       target.duplicate_flag,
       target.duplicate_keep_id,
       target.updated_by,
       target.updated_at
FROM init_vendor_staging AS target
INNER JOIN #DuplicateVendorRows AS duplicate_rows
    ON target.id = duplicate_rows.id
ORDER BY duplicate_rows.normalized_vendor_name, duplicate_rows.normalized_tax_no, target.id;
