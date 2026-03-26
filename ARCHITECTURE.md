# Architecture: Cross-Cloud Declarative Data Sharing

## System Overview

```
                            ┌─────────────────────────────────┐
                            │     <YOUR_ORG> (Org)       │
                            │     Snowflake Organization       │
                            └──────────────┬──────────────────┘
                                           │
              ┌────────────────────────────┼────────────────────────────┐
              │                            │                            │
              ▼                            ▼                            ▼
┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐
│  GCP US-CENTRAL1     │  │  AWS US-WEST-2       │  │  AZURE CENTRALUS     │
│  ──────────────────  │  │  ──────────────────  │  │  ──────────────────  │
│  <GCP_ACCOUNT_      │  │  <AWS_ACCOUNT_NAME>        │  │  <AZURE_ACCOUNT_      │
│  CENTRAL (<GCP_LOCATOR>)   │  │  (<AWS_LOCATOR>)          │  │  CENTRAL (<AZURE_LOCATOR>)   │
│                      │  │                      │  │                      │
│  Role: PROVIDER      │  │  Role: CONSUMER      │  │  Role: CONSUMER      │
│  Connection:         │  │  Connection:         │  │  Connection:         │
│    gcp_central       │  │    myconnection      │  │    azure_central     │
└──────────────────────┘  └──────────────────────┘  └──────────────────────┘
```

---

## Provider-Side Architecture (GCP)

```
GCP Account: <GCP_ACCOUNT_NAME>
═══════════════════════════════════

┌─ RBAC Hierarchy ─────────────────────────────────────────────────────────┐
│                                                                          │
│  ORGADMIN ──────────────────────────────────────────────────────────┐    │
│  │  SYSTEM$ENABLE_GLOBAL_DATA_SHARING_FOR_ACCOUNT                  │    │
│  │  GRANT MANAGE LISTING AUTO FULFILLMENT ON ACCOUNT               │    │
│  │                                                                  │    │
│  └─> ACCOUNTADMIN ─────────────────────────────────────────────┐   │    │
│      │  CREATE EXTERNAL LISTING (with auto_fulfillment)        │   │    │
│      │  ALTER LISTING ... PUBLISH                              │   │    │
│      │                                                         │   │    │
│      └─> SYSADMIN                                              │   │    │
│          │                                                     │   │    │
│          └─> DATA_SHARING_ADMIN (custom role)                  │   │    │
│              │  CREATE APPLICATION PACKAGE ON ACCOUNT           │   │    │
│              │  CREATE LISTING ON ACCOUNT                       │   │    │
│              │  CREATE DATABASE ON ACCOUNT                      │   │    │
│              │  CREATE WAREHOUSE ON ACCOUNT                     │   │    │
│              │  Owns: SHARING_WH, SHARED_FINANCIAL_DATA,       │   │    │
│              │        SHARED_OPERATIONS_DATA                    │   │    │
│              │                                                  │   │    │
│              Assigned to: JD_SERVICE_ACCOUNT_ADMIN              │   │    │
│              Auth: RSA Key-Pair (SNOWFLAKE_JWT)                 │   │    │
└──────────────────────────────────────────────────────────────────────────┘

┌─ Data Layer ─────────────────────────────────────────────────────────────┐
│                                                                          │
│  ┌─ SHARED_FINANCIAL_DATA ─────────────────────────────────────────┐    │
│  │  Schema: CORE                                                    │    │
│  │  ┌──────────────────────────┬────────┬─────────────────────┐    │    │
│  │  │ Table                    │ Rows   │ Key Purpose          │    │    │
│  │  ├──────────────────────────┼────────┼─────────────────────┤    │    │
│  │  │ JOURNAL_ENTRIES          │   26   │ GL debit/credit      │    │    │
│  │  │ ACCOUNT_BALANCES         │   25   │ Period-end balances  │    │    │
│  │  │ RECONCILIATIONS          │   16   │ GL vs sub-ledger     │    │    │
│  │  │ CLOSE_TASKS              │   15   │ Period close tasks   │    │    │
│  │  │ INTERCOMPANY_TRANSACTIONS│   16   │ IC eliminations      │    │    │
│  │  └──────────────────────────┴────────┴─────────────────────┘    │    │
│  └──────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌─ SHARED_OPERATIONS_DATA ────────────────────────────────────────┐    │
│  │  Schema: CORE                                                    │    │
│  │  ┌──────────────────────────┬────────┬─────────────────────┐    │    │
│  │  │ Table                    │ Rows   │ Key Purpose          │    │    │
│  │  ├──────────────────────────┼────────┼─────────────────────┤    │    │
│  │  │ CUSTOMERS                │   15   │ Customer master      │    │    │
│  │  │ ORDERS                   │   17   │ Sales orders         │    │    │
│  │  │ PRODUCTS                 │   10   │ Product catalog      │    │    │
│  │  │ SUPPORT_TICKETS          │   15   │ Support tracking     │    │    │
│  │  │ USAGE_METRICS            │   30   │ Usage telemetry      │    │    │
│  │  └──────────────────────────┴────────┴─────────────────────┘    │    │
│  └──────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────┘

┌─ Sharing Layer ──────────────────────────────────────────────────────────┐
│                                                                          │
│  ┌─ FINANCIAL_DATA_PKG (TYPE=DATA) ─────────────────────────────┐       │
│  │  manifest.yml:                                                │       │
│  │    roles: [app_user, app_admin]                               │       │
│  │    shared_content:                                            │       │
│  │      databases: SHARED_FINANCIAL_DATA                         │       │
│  │        schemas: CORE                                          │       │
│  │          tables: [5 tables]                                   │       │
│  │  Version: LIVE (released)                                     │       │
│  └───────────────────────┬───────────────────────────────────────┘       │
│                          │                                               │
│                          ▼                                               │
│  ┌─ FINANCIAL_DATA_LISTING ─────────────────────────────────────┐       │
│  │  Global Name: <AWS_LISTING_GLOBAL_NAME>                                    │       │
│  │  Target: <YOUR_ORG>.<AWS_ACCOUNT_NAME> (AWS)                  │       │
│  │  Auto-Fulfillment: SUB_DATABASE_WITH_REFERENCE_USAGE          │       │
│  │  Status: PUBLISHED                                            │       │
│  └───────────────────────────────────────────────────────────────┘       │
│                                                                          │
│  ┌─ OPERATIONS_DATA_PKG (TYPE=DATA) ────────────────────────────┐       │
│  │  manifest.yml:                                                │       │
│  │    roles: [app_user, app_admin]                               │       │
│  │    shared_content:                                            │       │
│  │      databases: SHARED_OPERATIONS_DATA                        │       │
│  │        schemas: CORE                                          │       │
│  │          tables: [5 tables]                                   │       │
│  │  Version: LIVE (released)                                     │       │
│  └───────────────────────┬───────────────────────────────────────┘       │
│                          │                                               │
│                          ▼                                               │
│  ┌─ OPERATIONS_DATA_LISTING ────────────────────────────────────┐       │
│  │  Global Name: <AZURE_LISTING_GLOBAL_NAME>                                    │       │
│  │  Target: <YOUR_ORG>.<AZURE_ACCOUNT_NAME> (Azure)       │       │
│  │  Auto-Fulfillment: SUB_DATABASE_WITH_REFERENCE_USAGE          │       │
│  │  Status: PUBLISHED                                            │       │
│  └───────────────────────────────────────────────────────────────┘       │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Cross-Cloud Replication Flow

```
 PROVIDER (GCP)                    SNOWFLAKE GLOBAL                 CONSUMER (AWS/Azure)
 ═══════════════                   ═══════════════                  ════════════════════

 ┌──────────────┐
 │ Source DBs   │
 │ (10 tables)  │
 └──────┬───────┘
        │
        ▼
 ┌──────────────┐
 │ App Package  │──── PUT manifest.yml ───┐
 │ TYPE=DATA    │                         │
 └──────┬───────┘                         │
        │                                 │
        ▼                                 ▼
 ┌──────────────┐              ┌──────────────────┐
 │ RELEASE LIVE │              │ manifest.yml      │
 │ VERSION      │              │ snow://package/   │
 └──────┬───────┘              │ .../LIVE/         │
        │                      └──────────────────┘
        ▼
 ┌──────────────┐
 │ CREATE       │
 │ EXTERNAL     │
 │ LISTING      │
 └──────┬───────┘
        │
        ▼
 ┌──────────────┐              ┌──────────────────┐       ┌──────────────────┐
 │ ALTER        │──────────────│ Auto-Fulfillment │──────>│ Listing appears  │
 │ LISTING      │              │ Engine           │       │ in SHOW          │
 │ PUBLISH      │              │                  │       │ AVAILABLE        │
 └──────────────┘              │ Replicates:      │       │ LISTINGS         │
                               │ - App package    │       │                  │
                               │ - Database data  │       │ is_ready_for_    │
                               │ - manifest/roles │       │ import = false   │
                               │                  │       └────────┬─────────┘
                               │ (30-90 min       │                │
                               │  initial sync)   │                │ (wait...)
                               │                  │                │
                               └──────────────────┘       ┌────────▼─────────┐
                                                          │ is_ready_for_    │
                                                          │ import = true    │
                                                          └────────┬─────────┘
                                                                   │
                                                                   ▼
                                                          ┌──────────────────┐
                                                          │ CREATE           │
                                                          │ APPLICATION      │
                                                          │ FROM LISTING     │
                                                          │ '<global_name>'  │
                                                          └────────┬─────────┘
                                                                   │
                                                                   ▼
                                                          ┌──────────────────┐
                                                          │ Query shared     │
                                                          │ data via app:    │
                                                          │ SELECT * FROM    │
                                                          │ APP.CORE.TABLE   │
                                                          └──────────────────┘
```

---

## Script Execution Order

```
                    ┌──────────────────────────────────┐
                    │         ONE-TIME SETUP            │
                    │  (Run once per provider account)  │
                    └──────────────┬───────────────────┘
                                   │
                    ┌──────────────▼───────────────────┐
                    │ setup/00_org_enable_              │
                    │   auto_fulfillment.sql            │
                    │ ─────────────────────             │
                    │ USE ROLE ORGADMIN                 │
                    │ SYSTEM$ENABLE_GLOBAL_DATA_...     │
                    │ GRANT MANAGE LISTING AUTO ...     │
                    └──────────────┬───────────────────┘
                                   │
         ┌─────────────────────────┼─────────────────────────┐
         │                         │                         │
         ▼                         ▼                         ▼
┌────────────────┐  ┌───────────────────┐  ┌────────────────────┐
│ setup/01_gcp_  │  │ setup/02_azure_   │  │  PROVIDER SETUP    │
│ service_user   │  │ service_user      │  │  (run in order)    │
│ .sql           │  │ .sql              │  │                    │
└────────────────┘  └───────────────────┘  └────────┬───────────┘
                                                     │
                                   ┌─────────────────▼────────────────┐
                                   │ gcp_provider/00_provider_         │
                                   │   rbac_setup.sql                  │
                                   │ ──────────────────────            │
                                   │ CREATE ROLE DATA_SHARING_ADMIN    │
                                   │ GRANT CREATE APPLICATION PACKAGE  │
                                   │ GRANT CREATE LISTING              │
                                   │ CREATE WAREHOUSE SHARING_WH       │
                                   └─────────────────┬────────────────┘
                                                     │
                                   ┌─────────────────▼────────────────┐
                                   │ gcp_provider/01_create_           │
                                   │   databases.sql                   │
                                   │ ──────────────────────            │
                                   │ CREATE DB SHARED_FINANCIAL_DATA   │
                                   │ CREATE DB SHARED_OPERATIONS_DATA  │
                                   │ 10 tables + sample data           │
                                   └─────────────────┬────────────────┘
                                                     │
                              ┌───────────────────────┼───────────────────────┐
                              │                                               │
                ┌─────────────▼──────────────┐             ┌─────────────────▼──────────┐
                │ gcp_provider/02_create_    │             │ gcp_provider/03_create_    │
                │   app_package_aws.sql      │             │   app_package_azure.sql    │
                │ ────────────────────       │             │ ────────────────────       │
                │ FINANCIAL_DATA_PKG         │             │ OPERATIONS_DATA_PKG        │
                │ TYPE=DATA                  │             │ TYPE=DATA                  │
                │ PUT manifest.yml           │             │ PUT manifest.yml           │
                │ RELEASE LIVE VERSION       │             │ RELEASE LIVE VERSION       │
                └─────────────┬──────────────┘             └─────────────────┬──────────┘
                              │                                               │
                              └───────────────────────┬───────────────────────┘
                                                      │
                                   ┌──────────────────▼───────────────────┐
                                   │ gcp_provider/04_create_              │
                                   │   listings.sql                       │
                                   │ ──────────────────────               │
                                   │ FINANCIAL_DATA_LISTING  -> AWS       │
                                   │ OPERATIONS_DATA_LISTING -> Azure     │
                                   │ auto_fulfillment + PUBLISH           │
                                   └──────────────────┬───────────────────┘
                                                      │
                                            ┌─────────▼──────────┐
                                            │ WAIT 30-90 min     │
                                            │ for replication     │
                                            └─────────┬──────────┘
                                                      │
                              ┌────────────────────────┼────────────────────────┐
                              │                                                 │
                ┌─────────────▼──────────────┐             ┌───────────────────▼──────────┐
                │ aws_consumer/01_install_   │             │ azure_consumer/01_install_   │
                │   app.sql                  │             │   app.sql                    │
                │ ────────────────────       │             │ ────────────────────         │
                │ CREATE APPLICATION         │             │ CREATE APPLICATION           │
                │   FINANCIAL_DATA_APP       │             │   OPERATIONS_DATA_APP        │
                │   FROM LISTING             │             │   FROM LISTING               │
                │   '<AWS_LISTING_GLOBAL_NAME>'            │             │   '<AZURE_LISTING_GLOBAL_NAME>'              │
                │ Query + verify data        │             │ Query + verify data          │
                └────────────────────────────┘             └──────────────────────────────┘
```

---

## Manifest Structure

```yaml
# manifest.yml (identical structure for both packages)
#
# Location: snow://package/<PKG_NAME>/versions/LIVE/manifest.yml
# Upload:   PUT file://<local_path>/manifest.yml
#               snow://package/<PKG>/versions/LIVE/
#               OVERWRITE=TRUE AUTO_COMPRESS=false;

roles:
  - app_user:
      comment: "Read-only access to shared data"
  - app_admin:
      comment: "Full access to all shared objects"

shared_content:
  databases:
    - <DATABASE_NAME>:           # e.g., SHARED_FINANCIAL_DATA
        schemas:
          - CORE:
              roles: [app_user, app_admin]
              tables:
                - <TABLE_1>:
                    roles: [app_user, app_admin]
                - <TABLE_2>:
                    roles: [app_user, app_admin]
                # ... (all tables listed)
```

---

## Listing YAML Structure

```yaml
# Embedded in CREATE EXTERNAL LISTING ... AS $$ ... $$

title: "Human-readable listing title"
subtitle: "Short subtitle"
description: |
  Multi-line description of the shared data.
listing_terms:
  type: "OFFLINE"                    # No click-through terms
targets:
  accounts: ["ORG.ACCOUNT_NAME"]     # Private listing targets
auto_fulfillment:
  refresh_type: SUB_DATABASE_WITH_REFERENCE_USAGE  # Required for cross-cloud
```

---

## Security Model

```
┌─────────────────────────────────────────────────────────────────────┐
│                        SECURITY LAYERS                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. AUTHENTICATION                                                  │
│     ├── RSA Key-Pair (2048-bit)                                    │
│     ├── SNOWFLAKE_JWT authenticator                                │
│     ├── TYPE=SERVICE users (no interactive login)                  │
│     └── No passwords stored anywhere                               │
│                                                                     │
│  2. AUTHORIZATION (Provider)                                        │
│     ├── ORGADMIN: org-level auto-fulfillment grants (one-time)     │
│     ├── ACCOUNTADMIN: listing creation + publishing                │
│     ├── DATA_SHARING_ADMIN: app packages, databases (day-to-day)   │
│     └── Least-privilege: custom role for sharing operations         │
│                                                                     │
│  3. AUTHORIZATION (Consumer)                                        │
│     ├── ACCOUNTADMIN: application install from listing              │
│     ├── app_admin: full access to shared objects (from manifest)    │
│     └── app_user: read-only access (from manifest)                 │
│                                                                     │
│  4. DATA PROTECTION                                                 │
│     ├── Zero-copy: data never leaves provider storage              │
│     ├── Read-only: consumers cannot modify source data             │
│     ├── Private listings: only targeted accounts can see/install   │
│     └── No ETL = no data in transit to secure                      │
│                                                                     │
│  5. NETWORK                                                         │
│     ├── All traffic over Snowflake's internal backbone             │
│     ├── No public internet exposure for data transfer              │
│     └── Cross-cloud replication handled by Snowflake               │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Troubleshooting

### Listing not visible on consumer

```sql
-- Run on consumer account
SHOW AVAILABLE LISTINGS;
-- If listing not shown: wait for replication or verify target account name
```

### is_ready_for_import = false

Cross-cloud auto-fulfillment initial replication takes 30-90 minutes. Monitor:

```sql
SHOW AVAILABLE LISTINGS;
SELECT "global_name", "title", "is_ready_for_import"
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "global_name" = '<LISTING_GLOBAL_NAME>';
```

### CREATE APPLICATION fails with "listing does not exist"

The listing data has not finished replicating. Wait until `is_ready_for_import = true`.

### Auto-fulfillment privilege errors

```sql
-- Must run as ORGADMIN on the provider account
USE ROLE ORGADMIN;
SELECT SYSTEM$ENABLE_GLOBAL_DATA_SHARING_FOR_ACCOUNT('<ACCOUNT_NAME>');
GRANT MANAGE LISTING AUTO FULFILLMENT ON ACCOUNT TO ROLE ACCOUNTADMIN;
```
