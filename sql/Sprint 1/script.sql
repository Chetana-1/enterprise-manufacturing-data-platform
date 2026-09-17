-- ============================================================
-- ENTERPRISE MANUFACTURING DATA PLATFORM (EMDP)
-- SPRINT 0 & SPRINT 1 - SQL QUERIES
-- ============================================================


-- ============================================================
-- SPRINT 0: DATABASE & BRONZE SCHEMA SETUP
-- ============================================================

-- 1. Check the current database
SELECT current_database();


-- 2. Create Bronze schema
CREATE SCHEMA IF NOT EXISTS bronze;


-- 3. Verify Bronze schema exists
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name = 'bronze';


-- 4. List all tables in Bronze schema
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'bronze'
ORDER BY table_name;


-- 5. Check columns and data types of a Bronze table
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'bronze'
  AND table_name = 'sales_pipeline'
ORDER BY ordinal_position;


-- 6. Check columns and data types of all Bronze tables
SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'bronze'
ORDER BY table_name, ordinal_position;


-- ============================================================
-- SPRINT 1: RECORD COUNT VALIDATION
-- ============================================================

-- 7. Count IoT records
SELECT COUNT(*) AS records
FROM bronze.iot_manufacturing;


-- 8. Count Manufacturing records
SELECT COUNT(*) AS records
FROM bronze.manufacturing;


-- 9. Count ERP Inventory records
SELECT COUNT(*) AS records
FROM bronze.erp_inventory;


-- 10. Count ERP Purchase Order records
SELECT COUNT(*) AS records
FROM bronze.erp_purchase_orders;


-- 11. Count Sales Pipeline records
SELECT COUNT(*) AS records
FROM bronze.sales_pipeline;


-- 12. Check record count of all Bronze tables together
SELECT 'iot_manufacturing' AS table_name, COUNT(*) AS records
FROM bronze.iot_manufacturing

UNION ALL

SELECT 'manufacturing', COUNT(*)
FROM bronze.manufacturing

UNION ALL

SELECT 'erp_inventory', COUNT(*)
FROM bronze.erp_inventory

UNION ALL

SELECT 'erp_purchase_orders', COUNT(*)
FROM bronze.erp_purchase_orders

UNION ALL

SELECT 'sales_pipeline', COUNT(*)
FROM bronze.sales_pipeline;


-- 13. Calculate total Bronze records
SELECT
    (SELECT COUNT(*) FROM bronze.iot_manufacturing) +
    (SELECT COUNT(*) FROM bronze.manufacturing) +
    (SELECT COUNT(*) FROM bronze.erp_inventory) +
    (SELECT COUNT(*) FROM bronze.erp_purchase_orders) +
    (SELECT COUNT(*) FROM bronze.sales_pipeline)
    AS total_bronze_records;


-- Expected total:
-- 100000 + 3000 + 1000 + 1000 + 8800 = 113800


-- ============================================================
-- SPRINT 1: VIEW SAMPLE DATA
-- ============================================================

-- 14. View Sales Pipeline data
SELECT *
FROM bronze.sales_pipeline
LIMIT 10;


-- 15. View IoT Manufacturing data
SELECT *
FROM bronze.iot_manufacturing
LIMIT 10;


-- 16. View Manufacturing data
SELECT *
FROM bronze.manufacturing
LIMIT 10;


-- 17. View ERP Inventory data
SELECT *
FROM bronze.erp_inventory
LIMIT 10;


-- 18. View ERP Purchase Order data
SELECT *
FROM bronze.erp_purchase_orders
LIMIT 10;


-- ============================================================
-- SPRINT 1: METADATA / DATA LINEAGE VALIDATION
-- ============================================================

-- 19. Check Sales Pipeline metadata
SELECT
    source_file,
    batch_id,
    load_timestamp,
    COUNT(*) AS records
FROM bronze.sales_pipeline
GROUP BY
    source_file,
    batch_id,
    load_timestamp;


-- 20. Check ERP Inventory metadata
SELECT
    source_file,
    batch_id,
    load_timestamp,
    COUNT(*) AS records
FROM bronze.erp_inventory
GROUP BY
    source_file,
    batch_id,
    load_timestamp;


-- 21. Check ERP Purchase Orders metadata
SELECT
    source_file,
    batch_id,
    load_timestamp,
    COUNT(*) AS records
FROM bronze.erp_purchase_orders
GROUP BY
    source_file,
    batch_id,
    load_timestamp;


-- 22. Check IoT Manufacturing metadata
SELECT
    source_file,
    batch_id,
    load_timestamp,
    COUNT(*) AS records
FROM bronze.iot_manufacturing
GROUP BY
    source_file,
    batch_id,
    load_timestamp;


-- 23. Check Manufacturing metadata
SELECT
    source_file,
    batch_id,
    load_timestamp,
    COUNT(*) AS records
FROM bronze.manufacturing
GROUP BY
    source_file,
    batch_id,
    load_timestamp;


-- ============================================================
-- SPRINT 1: DATA QUALITY VALIDATION
-- ============================================================

-- 24. Check NULL values in important Sales Pipeline fields
SELECT
    COUNT(*) FILTER (WHERE account IS NULL) AS null_account,
    COUNT(*) FILTER (WHERE engage_date IS NULL) AS null_engage_date,
    COUNT(*) FILTER (WHERE close_date IS NULL) AS null_close_date,
    COUNT(*) FILTER (WHERE close_value IS NULL) AS null_close_value
FROM bronze.sales_pipeline;


-- 25. Check duplicate Opportunity IDs
SELECT
    opportunity_id,
    COUNT(*) AS occurrence_count
FROM bronze.sales_pipeline
GROUP BY opportunity_id
HAVING COUNT(*) > 1;


-- 26. Check exact duplicate Sales Pipeline records
SELECT
    opportunity_id,
    sales_agent,
    product,
    account,
    deal_stage,
    engage_date,
    close_date,
    close_value,
    COUNT(*) AS occurrence_count
FROM bronze.sales_pipeline
GROUP BY
    opportunity_id,
    sales_agent,
    product,
    account,
    deal_stage,
    engage_date,
    close_date,
    close_value
HAVING COUNT(*) > 1;


-- ============================================================
-- SPRINT 1: DATE VALIDATION
-- ============================================================

-- 27. Check Sales Pipeline dates
SELECT
    opportunity_id,
    engage_date,
    close_date
FROM bronze.sales_pipeline
LIMIT 10;


-- 28. Check date range
SELECT
    MIN(engage_date) AS earliest_engage_date,
    MAX(engage_date) AS latest_engage_date,
    MIN(close_date) AS earliest_close_date,
    MAX(close_date) AS latest_close_date
FROM bronze.sales_pipeline;


-- ============================================================
-- SPRINT 1: DUPLICATE PREVENTION / FULL REFRESH
-- ============================================================

-- 29. Clear Bronze tables before a fresh reload
TRUNCATE TABLE
    bronze.iot_manufacturing,
    bronze.manufacturing,
    bronze.erp_inventory,
    bronze.erp_purchase_orders,
    bronze.sales_pipeline;


-- 30. Verify Bronze tables are empty after TRUNCATE
SELECT COUNT(*) AS records
FROM bronze.iot_manufacturing;

SELECT COUNT(*) AS records
FROM bronze.manufacturing;

SELECT COUNT(*) AS records
FROM bronze.erp_inventory;

SELECT COUNT(*) AS records
FROM bronze.erp_purchase_orders;

SELECT COUNT(*) AS records
FROM bronze.sales_pipeline;


-- ============================================================
-- END OF SPRINT 0 & SPRINT 1 SQL
-- ============================================================