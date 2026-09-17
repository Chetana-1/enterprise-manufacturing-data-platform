# Sprint 2 — Star Schema Design

## Enterprise Manufacturing Data Platform (EMDP)

### 1. Purpose

The Gold layer of the Enterprise Manufacturing Data Platform is designed using a dimensional Star Schema.

The purpose of the Star Schema is to organize validated Silver-layer data into business-ready fact and dimension tables for reporting and analytics.

---

## 2. Star Schema Overview

The Gold warehouse contains reusable dimension tables connected to business-process fact tables.

### Dimensions

- `gold.dim_date`
- `gold.dim_product`
- `gold.dim_machine`
- `gold.dim_warehouse`
- `gold.dim_supplier`
- `gold.dim_account`
- `gold.dim_sales_agent`

### Fact Tables

- `gold.fact_production`
- `gold.fact_sales`
- `gold.fact_inventory`
- `gold.fact_purchase_orders`
- `gold.fact_iot`

---

## 3. Dimension Tables

### 3.1 Date Dimension

Table:

`gold.dim_date`

Purpose:

Provides calendar attributes for reporting and time-based analysis.

Important attributes:

- `date_key`
- `full_date`
- `day_of_month`
- `day_name`
- `day_of_week`
- `week_of_year`
- `month_number`
- `month_name`
- `quarter_number`
- `year_number`
- `is_weekend`

The dimension contains 4,168 dates.

---

### 3.2 Product Dimension

Table:

`gold.dim_product`

Purpose:

Provides product information for manufacturing and sales analysis.

Attributes:

- `product_key`
- `product_name`
- `product_category`
- `product_source`
- `created_at`

The dimension contains 12 records.

Manufacturing and Sales products are retained as separate source concepts using `product_source`.

---

### 3.3 Machine Dimension

Table:

`gold.dim_machine`

Purpose:

Provides a reusable machine reference for manufacturing and IoT analysis.

Attributes:

- `machine_key`
- `machine_id`
- `machine_name`
- `machine_type`
- `created_at`

The dimension contains 50 machines.

Changing sensor measurements and machine-status observations are stored in the IoT fact table rather than the machine dimension.

---

### 3.4 Warehouse Dimension

Table:

`gold.dim_warehouse`

Purpose:

Provides warehouse information for inventory and purchasing analysis.

Attributes:

- `warehouse_key`
- `warehouse_id`
- `warehouse_name`
- `created_at`

The dimension contains 4 warehouses.

---

### 3.5 Supplier Dimension

Table:

`gold.dim_supplier`

Purpose:

Provides supplier information for purchase-order analysis.

Attributes:

- `supplier_key`
- `supplier_id`
- `supplier_name`
- `created_at`

The dimension contains 8 suppliers.

---

### 3.6 Account Dimension

Table:

`gold.dim_account`

Purpose:

Provides customer/account information for Sales Pipeline analysis.

Attributes:

- `account_key`
- `account_name`
- `created_at`

The dimension contains 86 records, including the Gold-layer Unknown Account member used for missing account information.

---

### 3.7 Sales Agent Dimension

Table:

`gold.dim_sales_agent`

Purpose:

Provides sales-agent information for Sales Pipeline analysis.

Attributes:

- `sales_agent_key`
- `sales_agent_name`
- `created_at`

The dimension contains 30 sales agents.

---

## 4. Fact Tables

### 4.1 Production Fact

Table:

`gold.fact_production`

Grain:

One row per `production_id`.

Dimensions connected:

- Date
- Product
- Machine

Important measures:

- Units produced
- Defects
- Production time
- Material cost
- Labour cost
- Total material cost
- Total labour cost
- Energy consumption
- Maintenance hours
- Downtime hours
- Scrap rate
- Rework hours
- Quality checks failed

Derived measures include:

`total_material_cost = units_produced × material_cost_per_unit`

`total_labour_cost = production_time_hours × labour_cost_per_hour`

Final record count:

**3,000**

---

### 4.2 Sales Fact

Table:

`gold.fact_sales`

Grain:

One row per sales opportunity.

Dimensions connected:

- Date
- Product
- Account
- Sales Agent

Important business attributes/measures include:

- Deal stage
- Engage date
- Close date
- Close value
- Sales opportunity information

Legitimate NULL close dates and close values are preserved for opportunities that have not reached a closing stage.

Final record count:

**8,800**

---

### 4.3 Inventory Fact

Table:

`gold.fact_inventory`

Grain:

One row per inventory record.

Dimension connected:

- Warehouse

Important measures:

- Stock quantity
- Reorder level
- Unit cost
- Inventory value

Important business attributes:

- Material
- Stock status

Final record count:

**1,000**

---

### 4.4 Purchase Order Fact

Table:

`gold.fact_purchase_orders`

Grain:

One row per purchase order.

Dimensions connected:

- Supplier
- Warehouse
- Date

Important measures:

- Quantity
- Unit price
- Total order value

Important business attributes:

- Material
- Order status
- Order date
- Delivery date

Final record count:

**1,000**

---

### 4.5 IoT Fact

Table:

`gold.fact_iot`

Grain:

One row per machine sensor observation.

Dimension connected:

- Machine

Important measurements:

- Temperature
- Vibration
- Humidity
- Pressure
- Energy consumption
- Machine status
- Anomaly flag
- Predicted remaining life
- Downtime risk
- Maintenance required

Final record count:

**100,000**

The source machine-status codes 0, 1 and 2 are preserved without assigning undocumented business meanings.

---

## 5. Logical Star Schema Relationships

The overall Gold model can be represented as:

```text
                         dim_date
                            |
                            |
                     fact_production
                       /           \
                      /             \
              dim_product       dim_machine


                         dim_date
                            |
                            |
                       fact_sales
                    /      |       \
                   /       |        \
           dim_product  dim_account  dim_sales_agent


                    dim_warehouse
                          |
                          |
                    fact_inventory


              dim_supplier       dim_warehouse
                    \                 /
                     \               /
                  fact_purchase_orders
                          |
                       dim_date


                     dim_machine
                          |
                          |
                       fact_iot