-- ============================================================================
-- 00_org_enable_auto_fulfillment.sql
-- Run on: GCP Provider Account (<YOUR_ORG>.<GCP_ACCOUNT_NAME>)
--         Must have ORGADMIN enabled on this account
-- Purpose: Grant MANAGE LISTING AUTO FULFILLMENT to ACCOUNTADMIN on this account
--
-- This is required ONCE per provider account for cross-cloud data sharing.
-- ORGADMIN must grant this before listings with auto_fulfillment can be created.
--
-- Findings captured:
--   - Cross-cloud listings require auto_fulfillment in the listing YAML
--   - auto_fulfillment requires MANAGE LISTING AUTO FULFILLMENT privilege
--   - Only ORGADMIN can grant this privilege to ACCOUNTADMIN
--   - The grant is ON ACCOUNT (current account), NOT ON ACCOUNT <name>
--   - SYSTEM$ENABLE_GLOBAL_DATA_SHARING_FOR_ACCOUNT must be called first
--     to enable cross-cloud sharing for the account
--   - If ORGADMIN is not enabled on this account, enable it first from
--     an account that already has ORGADMIN:
--       USE ROLE ORGADMIN;
--       ALTER ACCOUNT <GCP_ACCOUNT_NAME> SET IS_ORG_ADMIN = TRUE;
-- ============================================================================

USE ROLE ORGADMIN;

SELECT SYSTEM$ENABLE_GLOBAL_DATA_SHARING_FOR_ACCOUNT('<GCP_ACCOUNT_NAME>');

GRANT MANAGE LISTING AUTO FULFILLMENT ON ACCOUNT TO ROLE ACCOUNTADMIN;

SHOW GRANTS TO ROLE ACCOUNTADMIN;
