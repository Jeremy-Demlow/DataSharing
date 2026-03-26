-- ============================================================================
-- 04_create_listings.sql
-- Run on: GCP Provider Account (<YOUR_ORG>.<GCP_ACCOUNT_NAME>)
-- Connection: snow sql -c gcp_central -f 04_create_listings.sql
-- Purpose: Create private listings to share app packages with specific
--          consumer accounts (AWS and Azure)
-- ============================================================================
-- PREREQUISITES:
--   1. Run 02_create_app_package_aws.sql and 03_create_app_package_azure.sql
--   2. ORGADMIN must have granted MANAGE LISTING AUTO FULFILLMENT on this
--      account (see setup/00_org_enable_auto_fulfillment.sql)
--
-- Findings captured:
--   - CREATE OR REPLACE is NOT valid syntax for listings; must DROP + CREATE
--   - Cross-cloud listings require auto_fulfillment section in YAML
--   - For app packages: refresh_type must be SUB_DATABASE_WITH_REFERENCE_USAGE
--   - Do NOT specify refresh_schedule for app packages (set at account level)
--   - ACCOUNTADMIN required for listings with auto_fulfillment configuration
--   - MANAGE LISTING AUTO FULFILLMENT is an org-level grant from ORGADMIN;
--     cannot be self-granted by ACCOUNTADMIN
-- ============================================================================

USE ROLE ACCOUNTADMIN;

SELECT CURRENT_ORGANIZATION_NAME() AS ORG_NAME;

-- ============================================================================
-- LISTING 1: Financial Data -> AWS Consumer
-- Target: <YOUR_ORG>.<AWS_ACCOUNT_NAME> (AWS US_WEST_2)
-- ============================================================================

DROP LISTING IF EXISTS FINANCIAL_DATA_LISTING;

CREATE EXTERNAL LISTING FINANCIAL_DATA_LISTING
APPLICATION PACKAGE FINANCIAL_DATA_PKG AS
$$
title: "Shared Financial Data"
subtitle: "Journal entries, balances, reconciliations, close tasks, and intercompany transactions"
description: |
  Cross-cloud shared financial and accounting data from GCP provider.
  Contains 5 tables: JOURNAL_ENTRIES, ACCOUNT_BALANCES, RECONCILIATIONS,
  CLOSE_TASKS, and INTERCOMPANY_TRANSACTIONS.
  All data is in the CORE schema.
listing_terms:
  type: "OFFLINE"
targets:
  accounts: ["<YOUR_ORG>.<AWS_ACCOUNT_NAME>"]
auto_fulfillment:
  refresh_type: SUB_DATABASE_WITH_REFERENCE_USAGE
$$
PUBLISH = FALSE
REVIEW = FALSE;

ALTER LISTING FINANCIAL_DATA_LISTING PUBLISH;

-- ============================================================================
-- LISTING 2: Operations Data -> Azure Consumer
-- Target: <YOUR_ORG>.<AZURE_ACCOUNT_NAME> (Azure CENTRALUS)
-- ============================================================================

DROP LISTING IF EXISTS OPERATIONS_DATA_LISTING;

CREATE EXTERNAL LISTING OPERATIONS_DATA_LISTING
APPLICATION PACKAGE OPERATIONS_DATA_PKG AS
$$
title: "Shared Operations Data"
subtitle: "Customers, orders, products, support tickets, and usage metrics"
description: |
  Cross-cloud shared operational data from GCP provider.
  Contains 5 tables: CUSTOMERS, ORDERS, PRODUCTS, SUPPORT_TICKETS,
  and USAGE_METRICS.
  All data is in the CORE schema.
listing_terms:
  type: "OFFLINE"
targets:
  accounts: ["<YOUR_ORG>.<AZURE_ACCOUNT_NAME>"]
auto_fulfillment:
  refresh_type: SUB_DATABASE_WITH_REFERENCE_USAGE
$$
PUBLISH = FALSE
REVIEW = FALSE;

ALTER LISTING OPERATIONS_DATA_LISTING PUBLISH;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SHOW LISTINGS;
