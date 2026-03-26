-- ============================================================================
-- 02_create_app_package_aws.sql
-- Run on: GCP Provider Account (<YOUR_ORG>.<GCP_ACCOUNT_NAME>)
-- Connection: snow sql -c gcp_central -f 02_create_app_package_aws.sql
-- Purpose: Create Application Package for financial data, upload manifest,
--          and release LIVE version for sharing with AWS consumer
-- ============================================================================
-- PREREQUISITE: Run 01_create_databases.sql first
--
-- Findings captured:
--   - CREATE APPLICATION PACKAGE does not support OR REPLACE
--   - IF NOT EXISTS is supported but re-running with changed manifest needs
--     DROP + CREATE to reset the package cleanly
--   - LIVE version is auto-created; NEVER use BUILD or ADD LIVE VERSION
--   - PUT preserves source filename; manifest must be named manifest.yml locally
--   - OVERWRITE=TRUE + AUTO_COMPRESS=false are required PUT flags
-- ============================================================================

USE ROLE DATA_SHARING_ADMIN;

DROP APPLICATION PACKAGE IF EXISTS FINANCIAL_DATA_PKG;

CREATE APPLICATION PACKAGE FINANCIAL_DATA_PKG TYPE = DATA;

PUT file://<LOCAL_PATH>/gcp_provider/manifests/financial_data_pkg/manifest.yml
    snow://package/FINANCIAL_DATA_PKG/versions/LIVE/
    OVERWRITE=TRUE AUTO_COMPRESS=false;

ALTER APPLICATION PACKAGE FINANCIAL_DATA_PKG RELEASE LIVE VERSION;

SHOW APPLICATION PACKAGES LIKE 'FINANCIAL_DATA_PKG';
DESCRIBE APPLICATION PACKAGE FINANCIAL_DATA_PKG;
