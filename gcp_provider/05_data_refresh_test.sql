-- ============================================================================
-- 05_data_refresh_test.sql
-- Run on: GCP Provider Account (<YOUR_ORG>.<GCP_ACCOUNT_NAME>)
-- Connection: snow sql -c gcp_central -f gcp_provider/05_data_refresh_test.sql
-- Purpose: Insert new data into shared tables and trigger an on-demand
--          auto-fulfillment refresh to verify cross-cloud data pipeline
-- ============================================================================
-- PREREQUISITES:
--   1. All provider scripts (00-04) have been run
--   2. Consumer has installed the app (azure_consumer/01_install_app.sql)
--   3. Auto-fulfillment initial replication is complete
--
-- WHAT THIS PROVES:
--   - Provider can add new data to shared databases at any time
--   - SYSTEM$TRIGGER_LISTING_REFRESH pushes changes on-demand
--   - Consumer sees new rows without any action on their side
--   - Cross-cloud replication (GCP -> Azure) completes in ~30 seconds
--     for incremental changes (initial sync takes 30-90 min)
--
-- VERIFICATION:
--   After running this script, run the consumer verification:
--     snow sql -c azure_central -q "USE WAREHOUSE COMPUTE_WH;
--       SELECT NAME, INDUSTRY, ARR FROM SHARED_OPERATIONS_DATA.CORE.CUSTOMERS
--       WHERE NAME = 'PIPELINE_VERIFY_2026';"
-- ============================================================================

USE ROLE DATA_SHARING_ADMIN;
USE WAREHOUSE SHARING_WH;

-- ============================================================================
-- STEP 1: Capture pre-insert row counts
-- ============================================================================

SELECT 'PRE-INSERT COUNTS' AS PHASE,
       'CUSTOMERS' AS TBL, COUNT(*) AS CNT FROM SHARED_OPERATIONS_DATA.CORE.CUSTOMERS
UNION ALL SELECT 'PRE-INSERT COUNTS', 'ORDERS', COUNT(*) FROM SHARED_OPERATIONS_DATA.CORE.ORDERS
UNION ALL SELECT 'PRE-INSERT COUNTS', 'PRODUCTS', COUNT(*) FROM SHARED_OPERATIONS_DATA.CORE.PRODUCTS
UNION ALL SELECT 'PRE-INSERT COUNTS', 'SUPPORT_TICKETS', COUNT(*) FROM SHARED_OPERATIONS_DATA.CORE.SUPPORT_TICKETS
UNION ALL SELECT 'PRE-INSERT COUNTS', 'USAGE_METRICS', COUNT(*) FROM SHARED_OPERATIONS_DATA.CORE.USAGE_METRICS;

-- ============================================================================
-- STEP 2: Insert identifiable test data
-- ============================================================================

INSERT INTO SHARED_OPERATIONS_DATA.CORE.CUSTOMERS
    (NAME, INDUSTRY, REGION, COUNTRY, TIER, ARR, CREATED_DATE, ACCOUNT_MANAGER)
VALUES
    ('PIPELINE_VERIFY_2026', 'Cross-Cloud Verification', 'North America', 'United States', 'ENTERPRISE', 999999.00, CURRENT_DATE(), 'Auto-Fulfillment Engine');

INSERT INTO SHARED_OPERATIONS_DATA.CORE.ORDERS
    (CUSTOMER_ID, ORDER_DATE, PRODUCT, QUANTITY, UNIT_PRICE, TOTAL_AMOUNT, STATUS, SHIP_DATE)
SELECT MAX(CUSTOMER_ID), CURRENT_DATE(), 'PIPELINE_VERIFY - Cross-Cloud Refresh Test', 1, 999999.00, 999999.00, 'DELIVERED', CURRENT_DATE()
FROM SHARED_OPERATIONS_DATA.CORE.CUSTOMERS;

INSERT INTO SHARED_OPERATIONS_DATA.CORE.USAGE_METRICS
    (CUSTOMER_ID, METRIC_DATE, ACTIVE_USERS, API_CALLS, STORAGE_GB, FEATURE_FLAGS_USED)
SELECT MAX(CUSTOMER_ID), CURRENT_DATE(), 9999, 9999999, 999.99, 99
FROM SHARED_OPERATIONS_DATA.CORE.CUSTOMERS;

-- ============================================================================
-- STEP 3: Verify post-insert counts on provider
-- ============================================================================

SELECT 'POST-INSERT COUNTS' AS PHASE,
       'CUSTOMERS' AS TBL, COUNT(*) AS CNT FROM SHARED_OPERATIONS_DATA.CORE.CUSTOMERS
UNION ALL SELECT 'POST-INSERT COUNTS', 'ORDERS', COUNT(*) FROM SHARED_OPERATIONS_DATA.CORE.ORDERS
UNION ALL SELECT 'POST-INSERT COUNTS', 'PRODUCTS', COUNT(*) FROM SHARED_OPERATIONS_DATA.CORE.PRODUCTS
UNION ALL SELECT 'POST-INSERT COUNTS', 'SUPPORT_TICKETS', COUNT(*) FROM SHARED_OPERATIONS_DATA.CORE.SUPPORT_TICKETS
UNION ALL SELECT 'POST-INSERT COUNTS', 'USAGE_METRICS', COUNT(*) FROM SHARED_OPERATIONS_DATA.CORE.USAGE_METRICS;

-- ============================================================================
-- STEP 4: Trigger on-demand refresh (requires ACCOUNTADMIN or MANAGE LISTING
--         AUTO FULFILLMENT privilege)
--
-- SYSTEM$TRIGGER_LISTING_REFRESH triggers replication of the specified
-- database to all remote regions where listings reference it.
-- Args: ('DATABASE', '<database_name>')
-- ============================================================================

USE ROLE ACCOUNTADMIN;

SELECT SYSTEM$TRIGGER_LISTING_REFRESH('DATABASE', 'SHARED_OPERATIONS_DATA');

-- ============================================================================
-- STEP 5: Check current refresh schedule
-- ============================================================================

SHOW PARAMETERS LIKE 'LISTING_AUTO_FULFILLMENT%' IN ACCOUNT;

-- ============================================================================
-- EXPECTED RESULT:
--   "Successfully triggered refresh for DATABASE 'SHARED_OPERATIONS_DATA'
--    in 1 region(s)."
--
-- NEXT STEPS:
--   Wait ~30 seconds, then verify on the Azure consumer:
--
--   snow sql -c azure_central -q "
--     USE WAREHOUSE COMPUTE_WH;
--     SELECT NAME, INDUSTRY, ARR, CREATED_DATE
--     FROM SHARED_OPERATIONS_DATA.CORE.CUSTOMERS
--     WHERE NAME = 'PIPELINE_VERIFY_2026';
--   "
--
-- CLEANUP (optional - remove test data):
--   snow sql -c gcp_central -q "
--     USE ROLE DATA_SHARING_ADMIN; USE WAREHOUSE SHARING_WH;
--     DELETE FROM SHARED_OPERATIONS_DATA.CORE.CUSTOMERS WHERE NAME LIKE 'PIPELINE_VERIFY%' OR NAME LIKE 'TEST_REFRESH%';
--     DELETE FROM SHARED_OPERATIONS_DATA.CORE.ORDERS WHERE PRODUCT LIKE 'PIPELINE_VERIFY%' OR PRODUCT LIKE 'DATA REFRESH TEST%';
--     DELETE FROM SHARED_OPERATIONS_DATA.CORE.USAGE_METRICS WHERE ACTIVE_USERS = 9999;
--   "
--   Then trigger another refresh to propagate the deletes.
-- ============================================================================
