-- ============================================================================
-- 00_org_enable_auto_fulfillment.sql
-- Run on: GCP Provider Account (<YOUR_ORG>.<GCP_ACCOUNT_NAME>)
--         Must have ORGADMIN enabled on this account
-- Purpose: Enable cross-cloud auto-fulfillment and delegate the privilege
--          to the DATA_SHARING_ADMIN custom role (least-privilege)
--
-- This is required ONCE per provider account for cross-cloud data sharing.
-- ORGADMIN must enable global data sharing before the privilege can be granted.
--
-- Best practices applied:
--   - Idempotency: checks if already enabled before calling enable
--   - Least-privilege: grants to DATA_SHARING_ADMIN, not ACCOUNTADMIN
--   - Verification: confirms enable succeeded and grant is in place
--   - If ORGADMIN is not enabled on this account, enable it first from
--     an account that already has ORGADMIN:
--       USE ROLE ORGADMIN;
--       ALTER ACCOUNT <GCP_ACCOUNT_NAME> SET IS_ORG_ADMIN = TRUE;
-- ============================================================================

USE ROLE ORGADMIN;

-- Step 1: Check if auto-fulfillment is already enabled (idempotency)
SELECT SYSTEM$IS_GLOBAL_DATA_SHARING_ENABLED_FOR_ACCOUNT('<GCP_ACCOUNT_NAME>') AS already_enabled;

-- Step 2: Enable cross-cloud data sharing for this account
SELECT SYSTEM$ENABLE_GLOBAL_DATA_SHARING_FOR_ACCOUNT('<GCP_ACCOUNT_NAME>');

-- Step 3: Verify it was enabled successfully
SELECT SYSTEM$IS_GLOBAL_DATA_SHARING_ENABLED_FOR_ACCOUNT('<GCP_ACCOUNT_NAME>') AS is_enabled;

-- Step 4: Grant auto-fulfillment privilege to DATA_SHARING_ADMIN (least-privilege)
-- Per Snowflake docs, ACCOUNTADMIN can delegate this to custom roles.
-- We grant to DATA_SHARING_ADMIN so day-to-day listing ops don't require ACCOUNTADMIN.
-- Note: DATA_SHARING_ADMIN must exist first (see gcp_provider/00_provider_rbac_setup.sql)
-- If running before RBAC setup, grant to ACCOUNTADMIN temporarily:
--   GRANT MANAGE LISTING AUTO FULFILLMENT ON ACCOUNT TO ROLE ACCOUNTADMIN;
GRANT MANAGE LISTING AUTO FULFILLMENT ON ACCOUNT TO ROLE ACCOUNTADMIN;

USE ROLE ACCOUNTADMIN;
GRANT MANAGE LISTING AUTO FULFILLMENT ON ACCOUNT TO ROLE DATA_SHARING_ADMIN;

-- Step 5: Verify the grant landed on DATA_SHARING_ADMIN
SHOW GRANTS TO ROLE DATA_SHARING_ADMIN;
