-- ============================================================
-- ENTERPRISE MANUFACTURING DATA PLATFORM
-- SPRINT 2 – SQL SCRIPTS
-- ============================================================


-- ============================================================
-- 1. CREATE GOLD SCHEMA
-- ============================================================

CREATE SCHEMA IF NOT EXISTS gold;


-- ============================================================
-- 2. CREATE DATE DIMENSION
-- ============================================================

CREATE TABLE IF NOT EXISTS gold.dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE UNIQUE NOT NULL,
    day_of_month INTEGER,
    day_name VARCHAR(20),
    day_of_week INTEGER,
    week_of_year INTEGER,
    month_number INTEGER,
    month_name VARCHAR(20),
    quarter_number INTEGER,
    year_number INTEGER,
    is_weekend BOOLEAN
);


-- ============================================================
-- 3. POPULATE DATE DIMENSION
-- ============================================================

INSERT INTO gold.dim_date
(
    date_key,
    full_date,
    day_of_month,
    day_name,
    day_of_week,
    week_of_year,
    month_number,
    month_name,
    quarter_number,
    year_number,
    is_weekend
)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INTEGER,
    d::DATE,
    EXTRACT(DAY FROM d)::INTEGER,
    TRIM(TO_CHAR(d, 'Day')),
    EXTRACT(ISODOW FROM d)::INTEGER,
    EXTRACT(WEEK FROM d)::INTEGER,
    EXTRACT(MONTH FROM d)::INTEGER,
    TRIM(TO_CHAR(d, 'Month')),
    EXTRACT(QUARTER FROM d)::INTEGER,
    EXTRACT(YEAR FROM d)::INTEGER,
    EXTRACT(ISODOW FROM d) IN (6,7)
FROM generate_series(
    DATE '2016-10-20',
    DATE '2028-03-18',
    INTERVAL '1 day'
) AS d
ON CONFLICT (date_key) DO NOTHING;


-- ============================================================
-- 4. CREATE PRODUCT DIMENSION
-- ============================================================

CREATE TABLE IF NOT EXISTS gold.dim_product (
    product_key SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    product_category VARCHAR(100),
    product_source VARCHAR(30) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_name, product_source)
);


-- Populate Manufacturing products
INSERT INTO gold.dim_product
(product_name, product_category, product_source)
SELECT DISTINCT
    product_type,
    NULL,
    'MANUFACTURING'
FROM silver.manufacturing
WHERE product_type IS NOT NULL
ON CONFLICT (product_name, product_source) DO NOTHING;


-- Populate Sales products
INSERT INTO gold.dim_product
(product_name, product_category, product_source)
SELECT DISTINCT
    product,
    NULL,
    'SALES'
FROM silver.sales_pipeline
WHERE product IS NOT NULL
ON CONFLICT (product_name, product_source) DO NOTHING;


-- ============================================================
-- 5. CREATE MACHINE DIMENSION
-- ============================================================

CREATE TABLE IF NOT EXISTS gold.dim_machine (
    machine_key SERIAL PRIMARY KEY,
    machine_id INTEGER NOT NULL UNIQUE,
    machine_name VARCHAR(100),
    machine_type VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


INSERT INTO gold.dim_machine
(machine_id, machine_name, machine_type)
SELECT DISTINCT
    machine_id::INTEGER,
    'Machine ' || machine_id,
    NULL
FROM silver.iot_manufacturing
WHERE machine_id IS NOT NULL
ON CONFLICT (machine_id) DO NOTHING;


-- ============================================================
-- 6. CREATE WAREHOUSE DIMENSION
-- ============================================================

CREATE TABLE IF NOT EXISTS gold.dim_warehouse (
    warehouse_key SERIAL PRIMARY KEY,
    warehouse_id VARCHAR(100) NOT NULL UNIQUE,
    warehouse_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


INSERT INTO gold.dim_warehouse
(warehouse_id, warehouse_name)
SELECT DISTINCT
    warehouse_id,
    warehouse_id
FROM silver.erp_inventory
WHERE warehouse_id IS NOT NULL
ON CONFLICT (warehouse_id) DO NOTHING;


-- ============================================================
-- 7. CREATE SUPPLIER DIMENSION
-- ============================================================

CREATE TABLE IF NOT EXISTS gold.dim_supplier (
    supplier_key SERIAL PRIMARY KEY,
    supplier_id VARCHAR(100) NOT NULL UNIQUE,
    supplier_name VARCHAR(200) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


INSERT INTO gold.dim_supplier
(supplier_id, supplier_name)
SELECT DISTINCT
    supplier_id,
    supplier_name
FROM silver.erp_purchase_orders
WHERE supplier_id IS NOT NULL
ON CONFLICT (supplier_id) DO NOTHING;


-- ============================================================
-- 8. CREATE ACCOUNT DIMENSION
-- ============================================================

CREATE TABLE IF NOT EXISTS gold.dim_account (
    account_key SERIAL PRIMARY KEY,
    account_name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Unknown Account member
INSERT INTO gold.dim_account
(account_key, account_name)
VALUES (0, 'Unknown Account')
ON CONFLICT (account_key) DO NOTHING;


-- Actual accounts
INSERT INTO gold.dim_account
(account_name)
SELECT DISTINCT
    account
FROM silver.sales_pipeline
WHERE account IS NOT NULL
  AND TRIM(account) <> ''
ON CONFLICT (account_name) DO NOTHING;


-- ============================================================
-- 9. CREATE SALES AGENT DIMENSION
-- ============================================================

CREATE TABLE IF NOT EXISTS gold.dim_sales_agent (
    sales_agent_key SERIAL PRIMARY KEY,
    sales_agent_name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


INSERT INTO gold.dim_sales_agent
(sales_agent_name)
SELECT DISTINCT
    sales_agent
FROM silver.sales_pipeline
WHERE sales_agent IS NOT NULL
  AND TRIM(sales_agent) <> ''
ON CONFLICT (sales_agent_name) DO NOTHING;


-- ============================================================
-- 10. CREATE PRODUCTION FACT
-- ============================================================

CREATE TABLE IF NOT EXISTS gold.fact_production (
    production_key BIGSERIAL PRIMARY KEY,
    production_id BIGINT NOT NULL,
    date_key INTEGER NOT NULL,
    product_key INTEGER NOT NULL,
    machine_key INTEGER NOT NULL,
    shift VARCHAR(50),
    units_produced NUMERIC,
    defects NUMERIC,
    production_time_hours NUMERIC,
    material_cost_per_unit NUMERIC,
    labour_cost_per_hour NUMERIC,
    total_material_cost NUMERIC,
    total_labour_cost NUMERIC,
    energy_consumption_kwh NUMERIC,
    operator_count INTEGER,
    maintenance_hours NUMERIC,
    downtime_hours NUMERIC,
    production_volume_cubic_meters NUMERIC,
    scrap_rate NUMERIC,
    rework_hours NUMERIC,
    quality_checks_failed INTEGER,
    average_temperature_c NUMERIC,
    average_humidity_percent NUMERIC,
    data_quality_flag VARCHAR(30),
    load_timestamp TIMESTAMP,
    source_file VARCHAR(255),
    batch_id VARCHAR(100),

    FOREIGN KEY (date_key)
        REFERENCES gold.dim_date(date_key),

    FOREIGN KEY (product_key)
        REFERENCES gold.dim_product(product_key),

    FOREIGN KEY (machine_key)
        REFERENCES gold.dim_machine(machine_key)
);


-- ============================================================
-- 11. LOAD PRODUCTION FACT
-- ============================================================

INSERT INTO gold.fact_production
(
    production_id,
    date_key,
    product_key,
    machine_key,
    shift,
    units_produced,
    defects,
    production_time_hours,
    material_cost_per_unit,
    labour_cost_per_hour,
    total_material_cost,
    total_labour_cost,
    energy_consumption_kwh,
    operator_count,
    maintenance_hours,
    downtime_hours,
    production_volume_cubic_meters,
    scrap_rate,
    rework_hours,
    quality_checks_failed,
    average_temperature_c,
    average_humidity_percent,
    data_quality_flag,
    load_timestamp,
    source_file,
    batch_id
)
SELECT
    s.production_id,
    TO_CHAR(s.production_date, 'YYYYMMDD')::INTEGER,
    p.product_key,
    m.machine_key,
    s.shift,
    s.units_produced,
    s.defects,
    s.production_time_hours,
    s.material_cost_per_unit,
    s.labour_cost_per_hour,

    s.units_produced *
        s.material_cost_per_unit,

    s.production_time_hours *
        s.labour_cost_per_hour,

    s.energy_consumption_kwh,
    s.operator_count,
    s.maintenance_hours,
    s.downtime_hours,
    s.production_volume_cubic_meters,
    s.scrap_rate,
    s.rework_hours,
    s.quality_checks_failed,
    s.average_temperature_c,
    s.average_humidity_percent,
    s.data_quality_flag,
    s.load_timestamp,
    s.source_file,
    s.batch_id

FROM silver.manufacturing s

JOIN gold.dim_product p
    ON p.product_name = s.product_type
   AND p.product_source = 'MANUFACTURING'

JOIN gold.dim_machine m
    ON m.machine_id = s.machine_id::INTEGER;


-- ============================================================
-- 12. CREATE SALES FACT
-- ============================================================

CREATE TABLE IF NOT EXISTS gold.fact_sales (
    sales_key BIGSERIAL PRIMARY KEY,
    opportunity_id VARCHAR(100) NOT NULL,
    product_key INTEGER NOT NULL,
    account_key INTEGER NOT NULL,
    sales_agent_key INTEGER NOT NULL,
    engage_date DATE,
    close_date DATE,
    close_value NUMERIC,
    deal_stage VARCHAR(50),
    load_timestamp TIMESTAMP,
    source_file VARCHAR(255),
    batch_id VARCHAR(100),

    FOREIGN KEY (product_key)
        REFERENCES gold.dim_product(product_key),

    FOREIGN KEY (account_key)
        REFERENCES gold.dim_account(account_key),

    FOREIGN KEY (sales_agent_key)
        REFERENCES gold.dim_sales_agent(sales_agent_key)
);


-- ============================================================
-- 13. LOAD SALES FACT
-- ============================================================

INSERT INTO gold.fact_sales
(
    opportunity_id,
    product_key,
    account_key,
    sales_agent_key,
    engage_date,
    close_date,
    close_value,
    deal_stage,
    load_timestamp,
    source_file,
    batch_id
)
SELECT
    s.opportunity_id,
    p.product_key,
    COALESCE(a.account_key, 0),
    sa.sales_agent_key,
    s.engage_date,
    s.close_date,
    s.close_value,
    s.deal_stage,
    s.load_timestamp,
    s.source_file,
    s.batch_id

FROM silver.sales_pipeline s

JOIN gold.dim_product p
    ON p.product_name = s.product
   AND p.product_source = 'SALES'

JOIN gold.dim_sales_agent sa
    ON sa.sales_agent_name = s.sales_agent

LEFT JOIN gold.dim_account a
    ON a.account_name = s.account;


-- ============================================================
-- 14. CREATE INVENTORY FACT
-- ============================================================

CREATE TABLE IF NOT EXISTS gold.fact_inventory (
    inventory_key BIGSERIAL PRIMARY KEY,
    inventory_id VARCHAR(100) NOT NULL,
    date_key INTEGER NOT NULL,
    warehouse_key INTEGER NOT NULL,
    material_id VARCHAR(100),
    material_name VARCHAR(200),
    material_category VARCHAR(100),
    stock_quantity NUMERIC,
    reorder_level NUMERIC,
    unit_cost NUMERIC,
    inventory_value NUMERIC,
    last_updated DATE,
    stock_status VARCHAR(50),
    load_timestamp TIMESTAMP,
    source_file VARCHAR(255),
    batch_id VARCHAR(100),

    FOREIGN KEY (date_key)
        REFERENCES gold.dim_date(date_key),

    FOREIGN KEY (warehouse_key)
        REFERENCES gold.dim_warehouse(warehouse_key)
);


-- ============================================================
-- 15. LOAD INVENTORY FACT
-- ============================================================

INSERT INTO gold.fact_inventory
(
    inventory_id,
    date_key,
    warehouse_key,
    material_id,
    material_name,
    material_category,
    stock_quantity,
    reorder_level,
    unit_cost,
    inventory_value,
    last_updated,
    stock_status,
    load_timestamp,
    source_file,
    batch_id
)
SELECT
    s.inventory_id,
    TO_CHAR(s.last_updated, 'YYYYMMDD')::INTEGER,
    w.warehouse_key,
    s.material_id,
    s.material_name,
    s.material_category,
    s.stock_quantity,
    s.reorder_level,
    s.unit_cost,
    s.stock_quantity * s.unit_cost,
    s.last_updated,
    s.stock_status,
    s.load_timestamp,
    s.source_file,
    s.batch_id

FROM silver.erp_inventory s

JOIN gold.dim_warehouse w
    ON w.warehouse_id = s.warehouse_id;


-- ============================================================
-- 16. CREATE PURCHASE ORDER FACT
-- ============================================================

CREATE TABLE IF NOT EXISTS gold.fact_purchase_orders (
    purchase_order_key BIGSERIAL PRIMARY KEY,
    purchase_order_id VARCHAR(100) NOT NULL,
    date_key INTEGER NOT NULL,
    supplier_key INTEGER NOT NULL,
    warehouse_key INTEGER NOT NULL,
    material_id VARCHAR(100),
    material_name VARCHAR(200),
    quantity NUMERIC,
    unit_price NUMERIC,
    total_order_value NUMERIC,
    order_date DATE,
    delivery_date DATE,
    order_status VARCHAR(50),
    load_timestamp TIMESTAMP,
    source_file VARCHAR(255),
    batch_id VARCHAR(100),

    FOREIGN KEY (date_key)
        REFERENCES gold.dim_date(date_key),

    FOREIGN KEY (supplier_key)
        REFERENCES gold.dim_supplier(supplier_key),

    FOREIGN KEY (warehouse_key)
        REFERENCES gold.dim_warehouse(warehouse_key)
);


-- ============================================================
-- 17. LOAD PURCHASE ORDER FACT
-- ============================================================

INSERT INTO gold.fact_purchase_orders
(
    purchase_order_id,
    date_key,
    supplier_key,
    warehouse_key,
    material_id,
    material_name,
    quantity,
    unit_price,
    total_order_value,
    order_date,
    delivery_date,
    order_status,
    load_timestamp,
    source_file,
    batch_id
)
SELECT
    s.purchase_order_id,
    TO_CHAR(s.order_date, 'YYYYMMDD')::INTEGER,
    sp.supplier_key,
    w.warehouse_key,
    s.material_id,
    s.material_name,
    s.quantity,
    s.unit_price,
    s.quantity * s.unit_price,
    s.order_date,
    s.delivery_date,
    s.status,
    s.load_timestamp,
    s.source_file,
    s.batch_id

FROM silver.erp_purchase_orders s

JOIN gold.dim_supplier sp
    ON sp.supplier_id = s.supplier_id

JOIN gold.dim_warehouse w
    ON w.warehouse_id = s.warehouse_id;


-- ============================================================
-- 18. CREATE IoT FACT
-- ============================================================

CREATE TABLE IF NOT EXISTS gold.fact_iot (
    iot_key BIGSERIAL PRIMARY KEY,
    machine_key INTEGER NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    temperature NUMERIC,
    vibration NUMERIC,
    humidity NUMERIC,
    pressure NUMERIC,
    energy_consumption NUMERIC,
    machine_status INTEGER,
    anomaly_flag INTEGER,
    predicted_remaining_life NUMERIC,
    failure_type VARCHAR(100),
    downtime_risk NUMERIC,
    maintenance_required BOOLEAN,
    load_timestamp TIMESTAMP,
    source_file VARCHAR(255),
    batch_id VARCHAR(100),

    FOREIGN KEY (machine_key)
        REFERENCES gold.dim_machine(machine_key)
);


-- ============================================================
-- 19. LOAD IoT FACT
-- ============================================================

INSERT INTO gold.fact_iot
(
    machine_key,
    timestamp,
    temperature,
    vibration,
    humidity,
    pressure,
    energy_consumption,
    machine_status,
    anomaly_flag,
    predicted_remaining_life,
    failure_type,
    downtime_risk,
    maintenance_required,
    load_timestamp,
    source_file,
    batch_id
)
SELECT
    m.machine_key,
    s.timestamp,
    s.temperature,
    s.vibration,
    s.humidity,
    s.pressure,
    s.energy_consumption,
    s.machine_status::INTEGER,

    CASE
        WHEN s.anomaly_flag = TRUE THEN 1
        ELSE 0
    END,

    s.predicted_remaining_life,
    s.failure_type,
    s.downtime_risk,
    s.maintenance_required,
    s.load_timestamp,
    s.source_file,
    s.batch_id

FROM silver.iot_manufacturing s

JOIN gold.dim_machine m
    ON m.machine_id = s.machine_id::INTEGER;


-- ============================================================
-- 20. VALIDATION – DIMENSION COUNTS
-- ============================================================

SELECT 'dim_date' AS table_name, COUNT(*) AS records
FROM gold.dim_date

UNION ALL

SELECT 'dim_product', COUNT(*)
FROM gold.dim_product

UNION ALL

SELECT 'dim_machine', COUNT(*)
FROM gold.dim_machine

UNION ALL

SELECT 'dim_warehouse', COUNT(*)
FROM gold.dim_warehouse

UNION ALL

SELECT 'dim_supplier', COUNT(*)
FROM gold.dim_supplier

UNION ALL

SELECT 'dim_account', COUNT(*)
FROM gold.dim_account

UNION ALL

SELECT 'dim_sales_agent', COUNT(*)
FROM gold.dim_sales_agent;


-- ============================================================
-- 21. VALIDATION – FACT COUNTS
-- ============================================================

SELECT 'fact_production' AS table_name, COUNT(*) AS records
FROM gold.fact_production

UNION ALL

SELECT 'fact_sales', COUNT(*)
FROM gold.fact_sales

UNION ALL

SELECT 'fact_inventory', COUNT(*)
FROM gold.fact_inventory

UNION ALL

SELECT 'fact_purchase_orders', COUNT(*)
FROM gold.fact_purchase_orders

UNION ALL

SELECT 'fact_iot', COUNT(*)
FROM gold.fact_iot;


-- ============================================================
-- 22. BUSINESS QUERY – PRODUCTION PERFORMANCE
-- ============================================================

SELECT
    p.product_name,
    SUM(f.units_produced) AS total_units_produced,
    SUM(f.defects) AS total_defects,

    ROUND(
        SUM(f.defects) * 100.0 /
        NULLIF(SUM(f.units_produced), 0),
        2
    ) AS defect_rate_percent,

    ROUND(SUM(f.scrap_rate), 2) AS total_scrap_rate,

    ROUND(SUM(f.downtime_hours), 2)
        AS total_downtime_hours

FROM gold.fact_production f

JOIN gold.dim_product p
    ON f.product_key = p.product_key

WHERE p.product_source = 'MANUFACTURING'

GROUP BY p.product_name

ORDER BY total_units_produced DESC;


-- ============================================================
-- 23. BUSINESS QUERY – SALES PIPELINE
-- ============================================================

SELECT
    deal_stage,
    COUNT(*) AS opportunity_count,
    COUNT(close_date) AS closed_opportunities,
    SUM(close_value) AS total_close_value

FROM gold.fact_sales

GROUP BY deal_stage

ORDER BY opportunity_count DESC;


-- ============================================================
-- 24. BUSINESS QUERY – INVENTORY & REORDER
-- ============================================================

SELECT
    w.warehouse_id,
    f.stock_status,
    COUNT(*) AS record_count,
    SUM(f.stock_quantity) AS total_stock_quantity,
    ROUND(SUM(f.inventory_value), 2)
        AS total_inventory_value

FROM gold.fact_inventory f

JOIN gold.dim_warehouse w
    ON f.warehouse_key = w.warehouse_key

GROUP BY
    w.warehouse_id,
    f.stock_status

ORDER BY
    w.warehouse_id,
    f.stock_status;


-- ============================================================
-- 25. BUSINESS QUERY – PURCHASE ORDER & SUPPLIER
-- ============================================================

SELECT
    s.supplier_id,
    s.supplier_name,
    COUNT(*) AS purchase_order_count,
    SUM(f.quantity) AS total_quantity,
    ROUND(SUM(f.total_order_value), 2)
        AS total_purchase_value

FROM gold.fact_purchase_orders f

JOIN gold.dim_supplier s
    ON f.supplier_key = s.supplier_key

GROUP BY
    s.supplier_id,
    s.supplier_name

ORDER BY total_purchase_value DESC;


-- ============================================================
-- 26. BUSINESS QUERY – IoT / MACHINE MONITORING
-- ============================================================

SELECT
    m.machine_id,

    COUNT(*) AS sensor_observations,

    SUM(f.anomaly_flag) AS anomaly_count,

    SUM(
        CASE
            WHEN f.maintenance_required = TRUE
            THEN 1
            ELSE 0
        END
    ) AS maintenance_required_count,

    ROUND(AVG(f.temperature), 2)
        AS average_temperature,

    ROUND(AVG(f.vibration), 2)
        AS average_vibration,

    ROUND(AVG(f.energy_consumption), 2)
        AS average_energy_consumption,

    ROUND(AVG(f.downtime_risk), 2)
        AS average_downtime_risk,

    ROUND(AVG(f.predicted_remaining_life), 2)
        AS average_remaining_life

FROM gold.fact_iot f

JOIN gold.dim_machine m
    ON f.machine_key = m.machine_key

GROUP BY m.machine_id

ORDER BY m.machine_id;


-- ============================================================
-- 27. NULL AUDIT – SALES
-- ============================================================

SELECT
    COUNT(*) AS total_sales_records,

    COUNT(*) FILTER (
        WHERE opportunity_id IS NULL
    ) AS null_opportunity_id,

    COUNT(*) FILTER (
        WHERE product_key IS NULL
    ) AS null_product_key,

    COUNT(*) FILTER (
        WHERE sales_agent_key IS NULL
    ) AS null_sales_agent_key,

    COUNT(*) FILTER (
        WHERE close_value IS NULL
    ) AS null_close_value

FROM gold.fact_sales;


-- ============================================================
-- 28. DUPLICATE CHECK – PRODUCTION
-- ============================================================

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT production_id)
        AS distinct_production_ids
FROM gold.fact_production;


-- ============================================================
-- 29. DUPLICATE CHECK – SALES
-- ============================================================

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT opportunity_id)
        AS distinct_opportunity_ids
FROM gold.fact_sales;


-- ============================================================
-- 30. MACHINE / IoT VALIDATION
-- ============================================================

SELECT
    COUNT(*) AS total_iot_records,
    COUNT(DISTINCT machine_key) AS machines_present,
    COUNT(DISTINCT (timestamp, machine_key))
        AS unique_machine_observations
FROM gold.fact_iot;


-- ============================================================
-- END OF SPRINT 2 SQL SCRIPT
-- ============================================================