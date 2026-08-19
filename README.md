# Enterprise Manufacturing Data Platform (EMDP)

## UC1 – Enterprise Data Engineering Capstone Project

### Project Overview

The Enterprise Manufacturing Data Platform (EMDP) is designed to integrate manufacturing data from multiple heterogeneous enterprise systems and provide a unified platform for production intelligence.

The project focuses on data ingestion, data quality, transformation, storage, metadata management, data lineage, analytics, and reporting.

## Objectives

- Collect manufacturing data from multiple sources
- Clean and validate incoming data
- Store curated datasets in PostgreSQL
- Maintain metadata and data lineage
- Support analytics and reporting
- Use Git and GitHub for version control
- Produce enterprise-level project documentation

## Technology Stack

| Category | Technology |
|---|---|
| ETL | Pentaho Data Integration (Spoon) |
| Database | PostgreSQL |
| Programming | Python / Pandas |
| Version Control | Git / GitHub |
| Reporting | Power BI |
| Documentation | Markdown / MS Word |
| Project Management | Agile Scrum |

## Architecture

The project follows a Bronze–Silver–Gold Medallion Architecture.

### Bronze
Raw and staged data obtained from source systems.

### Silver
Cleansed, validated and transformed data.

### Gold
Analytics-ready warehouse, data marts and datasets.

## Project Sprints

### Sprint 0 – Project Initiation & Architecture
- Business requirements
- Stakeholder identification
- Data source identification
- Project scope
- Solution architecture
- Git repository
- Project backlog
- Project charter

### Sprint 1 – Data Discovery & Ingestion
- Source system analysis
- Data dictionary
- CSV ingestion
- Excel ingestion
- JSON ingestion
- XML ingestion
- SQL ingestion
- PostgreSQL staging
- Logging and exception handling

### Sprint 2 – Data Profiling & Data Warehouse
- Data profiling
- Data quality
- Data cleansing
- Star schema
- Fact and dimension tables
- PostgreSQL data warehouse

### Sprint 3 – Data Governance & Analytics
- Data lineage
- Metadata
- Business glossary
- ETL orchestration
- Validation
- Power BI dashboard
- Final project documentation