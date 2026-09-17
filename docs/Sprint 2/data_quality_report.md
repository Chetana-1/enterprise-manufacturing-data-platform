# Sprint 2 — Data Quality Report

## Enterprise Manufacturing Data Platform (EMDP)

### 1. Purpose

This report documents the data-quality assessment, cleansing, standardization, validation, and business-rule treatment performed during Sprint 2.

The objective was to identify quality issues in the Bronze datasets and produce trusted, standardized data in the Silver layer.

---

## 2. Data Quality Checks

The following checks were performed:

- Missing-value analysis
- Duplicate-record detection
- Data-type validation
- Date validation
- Identifier validation
- Categorical-value validation
- Business-rule validation
- Outlier flagging
- Silver-layer record-count validation

---

## 3. Data Quality Summary

| Dataset | Bronze Records | Silver Records | Quality Result |
|---|---:|---:|---|
| Manufacturing | 3,000 | 3,000 | Validated |
| Sales Pipeline | 8,800 | 8,800 | Validated |
| ERP Inventory | 1,000 | 1,000 | Validated |
| ERP Purchase Orders | 1,000 | 1,000 | Validated |
| IoT Manufacturing | 100,000 | 100,000 | Validated |

Total records processed:

**113,800**

---

## 4. Missing-Value Treatment

### Manufacturing

The Manufacturing dataset was processed using business-rule-based quality checks.

The Silver layer contains:

- `data_quality_flag`
- `missing_fields_count`

Records requiring attention were retained and classified rather than silently discarded.

Final Silver result:

- GOOD: 1,975
- WARNING: 1,025

---

### Sales Pipeline

The Sales Pipeline contained missing values in fields such as:

- `account`
- `engage_date`
- `close_date`
- `close_value`

The missing values were handled according to their business meaning.

Open opportunities can legitimately have no close date or close value. Therefore, these values were retained as NULL instead of inserting artificial dates or zero values.

The missing account information was handled in the Gold layer through an Unknown Account dimension member.

Final Silver result:

- GOOD: 7,212
- WARNING: 1,588

---

### ERP Inventory

No missing values were identified in the validated inventory fields.

Final Silver record count:

**1,000**

---

### ERP Purchase Orders

Required purchase-order fields were validated and the dataset was successfully loaded into Silver.

Final Silver record count:

**1,000**

All validated records were classified as GOOD.

---

### IoT Manufacturing

No missing values were identified in the validated IoT fields.

Final Silver result:

- GOOD: 100,000
- WARNING: 0

---

## 5. Duplicate Validation

Duplicate validation was performed on the datasets.

The final validated datasets contained no duplicate records requiring removal.

For Sales Pipeline, the 8,800 opportunity records were also validated against unique opportunity identifiers.

---

## 6. Standardization

The following standardization activities were performed during Silver processing:

- Source data types were converted to appropriate PostgreSQL-compatible types.
- Date fields were validated and standardized.
- Required identifiers were validated.
- Categorical fields were checked against observed source values.
- Missing-field counts were generated where applicable.
- Data-quality flags were assigned using transformation rules.
- Source metadata was preserved.

The Silver layer therefore provides a validated and standardized representation of the Bronze data.

---

## 7. Data Quality Flags

The Silver transformations use data-quality flags to distinguish records requiring attention.

The Manufacturing dataset produced:

| Quality Flag | Records |
|---|---:|
| GOOD | 1,975 |
| WARNING | 1,025 |
| **Total** | **3,000** |

The Sales Pipeline produced:

| Quality Flag | Records |
|---|---:|
| GOOD | 7,212 |
| WARNING | 1,588 |
| **Total** | **8,800** |

The ERP Inventory dataset produced:

| Quality Flag | Records |
|---|---:|
| GOOD | 1,000 |
| WARNING | 0 |
| **Total** | **1,000** |

The ERP Purchase Orders dataset produced:

| Quality Flag | Records |
|---|---:|
| GOOD | 1,000 |
| WARNING | 0 |
| **Total** | **1,000** |

The IoT Manufacturing dataset produced:

| Quality Flag | Records |
|---|---:|
| GOOD | 100,000 |
| WARNING | 0 |
| **Total** | **100,000** |

---

## 8. Outlier Flagging

Outlier checks were performed for important numerical variables including:

- PM2.5
- PM10
- NO2
- SO2
- CO
- O3
- AQI

The profiling and quality process identified records requiring attention through outlier flagging.

Outlier records were flagged rather than automatically deleted so that potentially important operational observations were preserved for further analysis.

---

## 9. IoT Data-Type Compatibility

During warehouse loading, source and target data types were validated.

The IoT dataset contains:

- `machine_status` as VARCHAR in Silver
- `anomaly_flag` as BOOLEAN in Silver
- `maintenance_required` as BOOLEAN in Silver

The Gold fact table stores `machine_status` as INTEGER and Boolean fields as INTEGER-compatible values according to the Gold table design.

The source machine-status codes `0`, `1`, and `2` were preserved without assigning undocumented business meanings.

---

## 10. Validation Results

Final Silver validation confirmed:

| Dataset | Records | Key-ID NULLs | Result |
|---|---:|---:|---|
| Manufacturing | 3,000 | 0 | PASS |
| Sales Pipeline | 8,800 | 0 | PASS |
| ERP Inventory | 1,000 | 0 | PASS |
| ERP Purchase Orders | 1,000 | 0 | PASS |
| IoT Manufacturing | 100,000 | 0 | PASS |

The Sales Pipeline contains business-valid NULL values in fields such as `close_date` and `close_value`; these were intentionally preserved.

---

## 11. Conclusion

The Sprint 2 data-quality process successfully identified, treated, and validated quality issues across the five enterprise datasets.

The cleansing and validation rules produced standardized Silver-layer datasets while preserving legitimate missing information and operational observations.

The validated Silver layer was subsequently used to populate the PostgreSQL Gold data warehouse.