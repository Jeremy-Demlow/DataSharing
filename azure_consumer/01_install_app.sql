-- ============================================================================
-- 01_install_app.sql
-- Run on: Azure Consumer Account (<YOUR_ORG>.<AZURE_ACCOUNT_NAME>)
-- Connection: snow sql -c azure_central -f 01_install_app.sql
-- Purpose: Install the Operations Data app from the private listing and verify
-- ============================================================================
-- PREREQUISITE: Provider must have created and published the listing first
--               (gcp_provider/04_create_listings.sql)
--
-- Findings captured:
--   - Listing global name <AZURE_LISTING_GLOBAL_NAME> from SHOW LISTINGS on GCP provider
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

SHOW AVAILABLE LISTINGS LIKE '%OPERATIONS%';

SELECT "global_name", "title", "is_ready_for_import", "is_imported"
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "global_name" = '<AZURE_LISTING_GLOBAL_NAME>';

CREATE APPLICATION OPERATIONS_DATA_APP FROM LISTING '<AZURE_LISTING_GLOBAL_NAME>';

SHOW SCHEMAS IN APPLICATION OPERATIONS_DATA_APP;

SHOW TABLES IN OPERATIONS_DATA_APP.CORE;

SELECT COUNT(*) AS ROW_COUNT FROM OPERATIONS_DATA_APP.CORE.CUSTOMERS;
SELECT COUNT(*) AS ROW_COUNT FROM OPERATIONS_DATA_APP.CORE.ORDERS;
SELECT COUNT(*) AS ROW_COUNT FROM OPERATIONS_DATA_APP.CORE.PRODUCTS;
SELECT COUNT(*) AS ROW_COUNT FROM OPERATIONS_DATA_APP.CORE.SUPPORT_TICKETS;
SELECT COUNT(*) AS ROW_COUNT FROM OPERATIONS_DATA_APP.CORE.USAGE_METRICS;

SELECT * FROM OPERATIONS_DATA_APP.CORE.CUSTOMERS LIMIT 5;

SHOW APPLICATION ROLES IN APPLICATION OPERATIONS_DATA_APP;
