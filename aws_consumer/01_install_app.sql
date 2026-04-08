-- ============================================================================
-- 01_install_app.sql
-- Run on: AWS Consumer Account (<YOUR_ORG>.<AWS_ACCOUNT_NAME>)
-- Connection: snow sql -c myconnection -f 01_install_app.sql
-- Purpose: Install the Financial Data app from the private listing and verify
-- ============================================================================
-- PREREQUISITE: Provider must have created and published the listing first
--               (gcp_provider/04_create_listings.sql)
--
-- Findings captured:
--   - Listing global name <AWS_LISTING_GLOBAL_NAME> from SHOW LISTINGS on GCP provider
--   - Cross-cloud auto-fulfillment takes time for initial replication
--   - SHOW AVAILABLE LISTINGS shows is_ready_for_import = true when ready
--   - If CREATE APPLICATION fails with "listing does not exist", wait and retry
--   - ACCOUNTADMIN required to install applications from listings
-- ============================================================================

USE ROLE ACCOUNTADMIN;

CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

SHOW AVAILABLE LISTINGS LIKE '%FINANCIAL%';

SELECT "global_name", "title", "is_ready_for_import", "is_imported"
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "global_name" = '<AWS_LISTING_GLOBAL_NAME>';

CREATE APPLICATION FINANCIAL_DATA_APP FROM LISTING '<AWS_LISTING_GLOBAL_NAME>';

SHOW SCHEMAS IN APPLICATION FINANCIAL_DATA_APP;

SHOW TABLES IN FINANCIAL_DATA_APP.CORE;

SELECT COUNT(*) AS ROW_COUNT FROM FINANCIAL_DATA_APP.CORE.JOURNAL_ENTRIES;
SELECT COUNT(*) AS ROW_COUNT FROM FINANCIAL_DATA_APP.CORE.ACCOUNT_BALANCES;
SELECT COUNT(*) AS ROW_COUNT FROM FINANCIAL_DATA_APP.CORE.RECONCILIATIONS;
SELECT COUNT(*) AS ROW_COUNT FROM FINANCIAL_DATA_APP.CORE.CLOSE_TASKS;
SELECT COUNT(*) AS ROW_COUNT FROM FINANCIAL_DATA_APP.CORE.INTERCOMPANY_TRANSACTIONS;

SELECT * FROM FINANCIAL_DATA_APP.CORE.JOURNAL_ENTRIES LIMIT 5;

SHOW APPLICATION ROLES IN APPLICATION FINANCIAL_DATA_APP;
