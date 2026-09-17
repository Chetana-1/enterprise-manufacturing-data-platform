# Sprint 2 — Data Profiling Report

## Enterprise Manufacturing Data Platform (EMDP)

### 1. Purpose

The purpose of this report is to document the profiling performed on the Bronze-layer datasets as part of Sprint 2. Python was used to examine dataset structure, record counts, data types, missing values, duplicates, categorical values, and numerical characteristics.

The profiling activity supports the Sprint 2 objective of transforming raw operational data into trusted and analytics-ready datasets.

---

## 2. Profiling Tool and Method

The Bronze datasets were profiled using Python with Pandas and PostgreSQL connectivity.

The profiling script is:

```text
python/profiling/profile_bronze.py