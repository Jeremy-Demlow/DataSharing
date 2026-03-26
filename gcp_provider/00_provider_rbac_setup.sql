-- ============================================================================
-- 00_provider_rbac_setup.sql
-- Run on: GCP Provider Account (<YOUR_ORG>.<GCP_ACCOUNT_NAME>)
-- Connection: snow sql -c gcp_central -f 00_provider_rbac_setup.sql
-- Prerequisites: Service user JD_SERVICE_ACCOUNT_ADMIN must have ACCOUNTADMIN
-- Purpose: Create a dedicated DATA_SHARING_ADMIN role with the minimum
--          privileges required to set up declarative data sharing.
--
-- RBAC best practices applied:
--   - Least-privilege: only the grants needed for sharing
--   - Custom role: avoids using ACCOUNTADMIN for day-to-day operations
--   - Role hierarchy: DATA_SHARING_ADMIN → SYSADMIN → ACCOUNTADMIN
--
-- Findings captured:
--   - SECURITYADMIN not always available to service users; use ACCOUNTADMIN
--   - Account-level grants (CREATE APPLICATION PACKAGE, CREATE LISTING)
--     require ACCOUNTADMIN
--   - Cross-cloud auto_fulfillment on listings requires ACCOUNTADMIN at
--     listing creation time (DATA_SHARING_ADMIN alone is insufficient)
--   - Warehouse must be created before any DML scripts run
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- STEP 1: Create the sharing role
-- ============================================================================

CREATE ROLE IF NOT EXISTS DATA_SHARING_ADMIN
    COMMENT = 'Role for managing declarative data sharing: app packages, listings, and source databases';

GRANT ROLE DATA_SHARING_ADMIN TO ROLE SYSADMIN;

-- ============================================================================
-- STEP 2: Grant account-level privileges
-- ============================================================================

GRANT CREATE APPLICATION PACKAGE ON ACCOUNT TO ROLE DATA_SHARING_ADMIN;

GRANT CREATE LISTING ON ACCOUNT TO ROLE DATA_SHARING_ADMIN;

GRANT CREATE DATABASE ON ACCOUNT TO ROLE DATA_SHARING_ADMIN;

GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE DATA_SHARING_ADMIN;

-- ============================================================================
-- STEP 3: Grant the role to the service user
-- ============================================================================

GRANT ROLE DATA_SHARING_ADMIN TO USER JD_SERVICE_ACCOUNT_ADMIN;

-- ============================================================================
-- STEP 4: Create a warehouse for the sharing workflow
-- Must be done under DATA_SHARING_ADMIN (which owns the warehouse)
-- ============================================================================

USE ROLE DATA_SHARING_ADMIN;

CREATE WAREHOUSE IF NOT EXISTS SHARING_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

-- ============================================================================
-- STEP 5: Verify
-- ============================================================================

USE ROLE ACCOUNTADMIN;

SHOW GRANTS TO ROLE DATA_SHARING_ADMIN;
SHOW GRANTS TO USER JD_SERVICE_ACCOUNT_ADMIN;

USE ROLE DATA_SHARING_ADMIN;
SELECT CURRENT_ROLE();
USE WAREHOUSE SHARING_WH;
SELECT CURRENT_WAREHOUSE();
