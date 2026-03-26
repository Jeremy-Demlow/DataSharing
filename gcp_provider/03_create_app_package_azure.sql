-- ============================================================================
-- 03_create_app_package_azure.sql
-- Run on: GCP Provider Account (<YOUR_ORG>.<GCP_ACCOUNT_NAME>)
-- Connection: snow sql -c gcp_central -f 03_create_app_package_azure.sql
-- Purpose: Create Application Package for operations data, upload manifest,
--          and release LIVE version for sharing with Azure consumer
-- ============================================================================
-- PREREQUISITE: Run 01_create_databases.sql first
--
-- Findings captured:
--   - Same idempotency pattern as 02: DROP IF EXISTS + CREATE
--   - LIVE version is auto-created; NEVER use BUILD or ADD LIVE VERSION
--   - PUT preserves source filename; manifest must be named manifest.yml locally
-- ============================================================================

USE ROLE DATA_SHARING_ADMIN;

DROP APPLICATION PACKAGE IF EXISTS OPERATIONS_DATA_PKG;

CREATE APPLICATION PACKAGE OPERATIONS_DATA_PKG TYPE = DATA;

PUT file://<LOCAL_PATH>/gcp_provider/manifests/operations_data_pkg/manifest.yml
    snow://package/OPERATIONS_DATA_PKG/versions/LIVE/
    OVERWRITE=TRUE AUTO_COMPRESS=false;

ALTER APPLICATION PACKAGE OPERATIONS_DATA_PKG RELEASE LIVE VERSION;

SHOW APPLICATION PACKAGES LIKE 'OPERATIONS_DATA_PKG';
DESCRIBE APPLICATION PACKAGE OPERATIONS_DATA_PKG;
