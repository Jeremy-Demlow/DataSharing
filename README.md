# Cross-Cloud Declarative Data Sharing

**BlackLine + Snowflake | March 2026**

100% SQL-based, programmatic cross-cloud data sharing using Snowflake's Declarative Sharing (`TYPE=DATA` application packages). No UI clicks, no Terraform, no ETL pipelines.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                          <YOUR_ORG> (Organization)                                 │
│                                                                                         │
│  ┌──────────────────────────┐    Snowflake Global    ┌─────────────────────────────┐    │
│  │   GCP PROVIDER           │    Services Layer      │   AWS CONSUMER              │    │
│  │   (us-central1)          │                        │   (us-west-2)               │    │
│  │   <GCP_LOCATOR>                │                        │   <AWS_LOCATOR>                  │    │
│  │                          │    ┌──────────────┐    │                             │    │
│  │  ┌────────────────────┐  │    │  Private      │    │  ┌───────────────────────┐  │    │
│  │  │ SHARED_FINANCIAL_  │──┼───>│  Listing      │───>│  │ FINANCIAL_DATA_APP    │  │    │
│  │  │ DATA               │  │    │  <AWS_LISTING_GLOBAL_NAME> │    │  │  (installed from      │  │    │
│  │  │                    │  │    └──────────────┘    │  │   listing)             │  │    │
│  │  │  CORE Schema:      │  │                        │  │                       │  │    │
│  │  │  - JOURNAL_ENTRIES │  │    Auto-Fulfillment    │  │  CORE Schema:          │  │    │
│  │  │  - ACCOUNT_BALANCES│  │    ┌──────────────┐    │  │  - JOURNAL_ENTRIES     │  │    │
│  │  │  - RECONCILIATIONS │  │    │ SUB_DATABASE_ │    │  │  - ACCOUNT_BALANCES   │  │    │
│  │  │  - CLOSE_TASKS     │  │    │ WITH_REFERENCE│    │  │  - RECONCILIATIONS    │  │    │
│  │  │  - INTERCOMPANY_   │  │    │ _USAGE        │    │  │  - CLOSE_TASKS        │  │    │
│  │  │    TRANSACTIONS    │  │    └──────────────┘    │  │  - INTERCOMPANY_TXNS   │  │    │
│  │  └────────────────────┘  │                        │  └───────────────────────┘  │    │
│  │                          │                        │                             │    │
│  │  ┌────────────────────┐  │    ┌──────────────┐    └─────────────────────────────┘    │
│  │  │ SHARED_OPERATIONS_ │──┼───>│  Private      │                                      │
│  │  │ DATA               │  │    │  Listing      │    ┌─────────────────────────────┐    │
│  │  │                    │  │    │  <AZURE_LISTING_GLOBAL_NAME> │───>│   AZURE CONSUMER            │    │
│  │  │  CORE Schema:      │  │    └──────────────┘    │   (centralus)               │    │
│  │  │  - CUSTOMERS       │  │                        │   <AZURE_LOCATOR>                    │    │
│  │  │  - ORDERS          │  │    Auto-Fulfillment    │                             │    │
│  │  │  - PRODUCTS        │  │    ┌──────────────┐    │  ┌───────────────────────┐  │    │
│  │  │  - SUPPORT_TICKETS │  │    │ SUB_DATABASE_ │    │  │ OPERATIONS_DATA_APP   │  │    │
│  │  │  - USAGE_METRICS   │  │    │ WITH_REFERENCE│    │  │  (installed from      │  │    │
│  │  └────────────────────┘  │    │ _USAGE        │    │  │   listing)             │  │    │
│  │                          │    └──────────────┘    │  │                       │  │    │
│  │  App Packages:           │                        │  │  CORE Schema:          │  │    │
│  │  - FINANCIAL_DATA_PKG    │    ┌──────────────┐    │  │  - CUSTOMERS           │  │    │
│  │  - OPERATIONS_DATA_PKG   │    │ manifest.yml  │    │  │  - ORDERS             │  │    │
│  │    (TYPE=DATA, LIVE)     │    │ Roles:        │    │  │  - PRODUCTS           │  │    │
│  │                          │    │ - app_admin   │    │  │  - SUPPORT_TICKETS    │  │    │
│  │  Roles:                  │    │ - app_user    │    │  │  - USAGE_METRICS      │  │    │
│  │  - DATA_SHARING_ADMIN    │    └──────────────┘    │  └───────────────────────┘  │    │
│  │  - ACCOUNTADMIN          │                        │                             │    │
│  └──────────────────────────┘                        └─────────────────────────────┘    │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

## RBAC Model

```
Provider (GCP):                              Consumer (AWS/Azure):
┌──────────────┐                             ┌──────────────┐
│  ORGADMIN    │ ── MANAGE LISTING           │ ACCOUNTADMIN │ ── CREATE APPLICATION
│              │    AUTO FULFILLMENT         │              │    FROM LISTING
└──────┬───────┘                             └──────┬───────┘
       │                                            │
┌──────┴───────┐                             ┌──────┴───────┐
│ ACCOUNTADMIN │ ── Listing creation          │  app_admin   │ ── Full shared object access
│              │    (auto_fulfillment)        │ (from YAML)  │
└──────┬───────┘                             └──────┬───────┘
       │                                            │
┌──────┴──────────────┐                      ┌──────┴───────┐
│ DATA_SHARING_ADMIN  │ ── App packages      │  app_user    │ ── Read-only access
│ (custom role)       │    Databases          │ (from YAML)  │
│                     │    Day-to-day ops     └──────────────┘
└─────────────────────┘

Authentication: RSA Key-Pair (SNOWFLAKE_JWT) via TYPE=SERVICE users
```

---

## Prerequisites

1. **Three Snowflake accounts** in the same organization, on different clouds:
   - GCP Provider: `<YOUR_ORG>.<GCP_ACCOUNT_NAME>` (GCP_US_CENTRAL1)
   - AWS Consumer: `<YOUR_ORG>.<AWS_ACCOUNT_NAME>` (AWS_US_WEST_2)
   - Azure Consumer: `<YOUR_ORG>.<AZURE_ACCOUNT_NAME>` (AZURE_CENTRALUS)

2. **Snowflake CLI** (`snow`) installed with connections configured:
   ```
   snow sql -c gcp_central       # GCP provider
   snow sql -c myconnection      # AWS consumer
   snow sql -c azure_central     # Azure consumer
   ```

3. **ORGADMIN** enabled on the GCP provider account

4. **ACCOUNTADMIN** access on all three accounts

---

## Quick Start

### One-Time Org Setup (run once per provider account)

```bash
snow sql -c gcp_central -f setup/00_org_enable_auto_fulfillment.sql
```

### Provider Setup (GCP)

```bash
# 1. Create RBAC role and warehouse
snow sql -c gcp_central -f gcp_provider/00_provider_rbac_setup.sql

# 2. Create source databases and sample data (2 DBs, 10 tables)
snow sql -c gcp_central -f gcp_provider/01_create_databases.sql

# 3. Create app package for AWS consumer
snow sql -c gcp_central -f gcp_provider/02_create_app_package_aws.sql

# 4. Create app package for Azure consumer
snow sql -c gcp_central -f gcp_provider/03_create_app_package_azure.sql

# 5. Create and publish private listings
snow sql -c gcp_central -f gcp_provider/04_create_listings.sql
```

### Wait for Cross-Cloud Replication (30-90 minutes)

```bash
# Check readiness on AWS consumer
snow sql -c myconnection -q "SHOW AVAILABLE LISTINGS; SELECT \"global_name\", \"is_ready_for_import\" FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) WHERE \"global_name\" = '<AWS_LISTING_GLOBAL_NAME>';"

# Check readiness on Azure consumer
snow sql -c azure_central -q "SHOW AVAILABLE LISTINGS; SELECT \"global_name\", \"is_ready_for_import\" FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) WHERE \"global_name\" = '<AZURE_LISTING_GLOBAL_NAME>';"
```

### Consumer Install

```bash
# AWS consumer - install financial data
snow sql -c myconnection -f aws_consumer/01_install_app.sql

# Azure consumer - install operations data
snow sql -c azure_central -f azure_consumer/01_install_app.sql
```

---

## Project Structure

```
DataSharing/
├── setup/                                        # One-time org-level setup
│   ├── 00_org_enable_auto_fulfillment.sql        # ORGADMIN grants for cross-cloud
│   ├── 01_gcp_service_user.sql                   # GCP service user + RSA key
│   └── 02_azure_service_user.sql                 # Azure service user
│
├── gcp_provider/                                 # Provider-side scripts (run in order)
│   ├── 00_provider_rbac_setup.sql                # DATA_SHARING_ADMIN role + warehouse
│   ├── 01_create_databases.sql                   # 2 databases, 10 tables, sample data
│   ├── 02_create_app_package_aws.sql             # FINANCIAL_DATA_PKG (TYPE=DATA)
│   ├── 03_create_app_package_azure.sql           # OPERATIONS_DATA_PKG (TYPE=DATA)
│   ├── 04_create_listings.sql                    # Private listings + publish
│   └── manifests/
│       ├── financial_data_pkg/manifest.yml       # Roles & shared objects definition
│       └── operations_data_pkg/manifest.yml
│
├── aws_consumer/                                 # AWS consumer account
│   └── 01_install_app.sql                        # Install app + verify data
│
├── azure_consumer/                               # Azure consumer account
│   └── 01_install_app.sql                        # Install app + verify data
│
├── Cross-Cloud_Declarative_Data_Sharing.pptx     # Customer presentation
├── README.md                                     # This file
└── ARCHITECTURE.md                               # Detailed architecture document
```

---

## Execution Flow

```
 ┌─────────┐   ┌─────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
 │ Step 0  │──>│ Step 1  │──>│ Step 2   │──>│ Step 3   │──>│ Step 4   │──>│ Step 5   │
 │ Org     │   │ RBAC    │   │ Source   │   │ App      │   │ Listings │   │ Consumer │
 │ Setup   │   │ Setup   │   │ Data     │   │ Packages │   │ Publish  │   │ Install  │
 └─────────┘   └─────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
  ORGADMIN      ACCOUNTADMIN   DATA_SHARING   DATA_SHARING   ACCOUNTADMIN   ACCOUNTADMIN
  (once)        + custom role  _ADMIN          _ADMIN                       (consumer)
```

---

## Data Model

### SHARED_FINANCIAL_DATA (shared with AWS)

| Table | Description | Rows | Key Columns |
|---|---|---|---|
| JOURNAL_ENTRIES | GL journal entries | 26 | ENTRY_DATE, ACCOUNT_CODE, DEBIT/CREDIT, ENTITY |
| ACCOUNT_BALANCES | Period-end balances | 25 | ACCOUNT_CODE, PERIOD_END_DATE, BALANCE_AMOUNT |
| RECONCILIATIONS | Account recon records | 16 | GL_BALANCE vs SUB_LEDGER_BALANCE, STATUS |
| CLOSE_TASKS | Period close tracking | 15 | TASK_NAME, PERIOD, STATUS, PRIORITY |
| INTERCOMPANY_TRANSACTIONS | IC eliminations | 16 | FROM_ENTITY, TO_ENTITY, TXN_TYPE, STATUS |

### SHARED_OPERATIONS_DATA (shared with Azure)

| Table | Description | Rows | Key Columns |
|---|---|---|---|
| CUSTOMERS | Customer master | 15 | INDUSTRY, REGION, TIER, ARR |
| ORDERS | Sales orders | 17 | PRODUCT, TOTAL_AMOUNT, STATUS |
| PRODUCTS | Product catalog | 10 | CATEGORY, UNIT_PRICE, MARGIN_PCT |
| SUPPORT_TICKETS | Customer support | 15 | CATEGORY, PRIORITY, SLA_MET |
| USAGE_METRICS | Monthly telemetry | 30 | ACTIVE_USERS, API_CALLS, STORAGE_GB |

---

## Key Technical Decisions & Findings

### Declarative Sharing (TYPE=DATA) vs Native Apps

| Feature | TYPE=DATA (this project) | Native App (TYPE=FULL) |
|---|---|---|
| Setup script | None | Required |
| Code execution | None | Stored procs, UDFs |
| Consumer effort | 1 SQL statement | Setup + install |
| Best for | Data distribution | Data + logic |

### Findings Captured During Development

1. **Listing syntax**: `CREATE OR REPLACE` is NOT valid for listings. Must use `DROP IF EXISTS` + `CREATE EXTERNAL LISTING` pattern.

2. **Auto-fulfillment prerequisites**: ORGADMIN must call `SYSTEM$ENABLE_GLOBAL_DATA_SHARING_FOR_ACCOUNT('account')` BEFORE granting `MANAGE LISTING AUTO FULFILLMENT ON ACCOUNT`.

3. **LIVE version**: Never use `BUILD` or `ADD LIVE VERSION`. The correct syntax is `ALTER APPLICATION PACKAGE ... RELEASE LIVE VERSION`.

4. **Cross-cloud timing**: Initial replication takes 30-90 minutes. Monitor with `SHOW AVAILABLE LISTINGS` and check `is_ready_for_import` flag on consumer side.

5. **BCR 2025_03**: Use `CREATE LISTING` (not `CREATE DATA EXCHANGE LISTING`) on accounts with this BCR bundle released.

6. **Manifest rules**: File MUST be named `manifest.yml`. PUT command must include `AUTO_COMPRESS=false`.

7. **Connection management**: `snowflake_sql_execute` tool does NOT switch connections. Always use `snow sql -c <connection>` CLI for multi-account workflows.

8. **Grant syntax**: `MANAGE LISTING AUTO FULFILLMENT ON ACCOUNT` — no account name after `ACCOUNT`. It always refers to the current account.

---

## Connections Reference

| Connection | Account | Cloud/Region | Role | Auth |
|---|---|---|---|---|
| `gcp_central` | <GCP_ACCOUNT_NAME> | GCP US-Central1 | DATA_SHARING_ADMIN | SNOWFLAKE_JWT |
| `myconnection` | <AWS_ACCOUNT_NAME> (<AWS_LOCATOR>) | AWS US-West-2 | ACCOUNTADMIN | SNOWFLAKE_JWT |
| `azure_central` | <AZURE_ACCOUNT_NAME> | Azure CentralUS | ACCOUNTADMIN | SNOWFLAKE_JWT |

---

## Listing Reference

| Listing | Global Name | App Package | Target Consumer |
|---|---|---|---|
| FINANCIAL_DATA_LISTING | <AWS_LISTING_GLOBAL_NAME> | FINANCIAL_DATA_PKG | AWS (<AWS_ACCOUNT_NAME>) |
| OPERATIONS_DATA_LISTING | <AZURE_LISTING_GLOBAL_NAME> | OPERATIONS_DATA_PKG | Azure (<AZURE_ACCOUNT_NAME>) |

---

## Future Roadmap

### Phase 2: Security Hardening
- Column-level masking policies on sensitive fields
- Row-access policies for multi-tenant isolation
- Secure views for computed/aggregated datasets
- Event tables for audit trail and lineage

### Phase 3: Advanced Patterns
- Bi-directional sharing (consumer -> provider feedback)
- Snowflake Streams + Tasks for real-time CDC
- Dynamic Tables for derived/aggregated datasets
- Cortex AI for data quality monitoring
- Marketplace public listings for monetization
