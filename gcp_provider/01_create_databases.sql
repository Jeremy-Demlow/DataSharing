-- ============================================================================
-- 01_create_databases.sql
-- Run on: GCP Provider Account (<YOUR_ORG>.<GCP_ACCOUNT_NAME>)
-- Connection: snow sql -c gcp_central -f 01_create_databases.sql
-- Purpose: Create 2 source databases with 5 tables each + sample data
--
-- Findings captured:
--   - USE WAREHOUSE is required before any DML (INSERT) statements
--   - SHARING_WH must be created first (see 00_provider_rbac_setup.sql)
--   - CREATE OR REPLACE TABLE makes this idempotent for re-runs
-- ============================================================================

USE ROLE DATA_SHARING_ADMIN;
USE WAREHOUSE SHARING_WH;

-- ============================================================================
-- DATABASE 1: SHARED_FINANCIAL_DATA
-- Shared with AWS consumer (<YOUR_ORG>.<AWS_ACCOUNT_NAME>)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS SHARED_FINANCIAL_DATA;
CREATE SCHEMA IF NOT EXISTS SHARED_FINANCIAL_DATA.CORE;

-- --------------------------------------------------------------------------
-- Table 1: JOURNAL_ENTRIES - General Ledger journal entries
-- --------------------------------------------------------------------------
CREATE OR REPLACE TABLE SHARED_FINANCIAL_DATA.CORE.JOURNAL_ENTRIES (
    ENTRY_ID        NUMBER AUTOINCREMENT,
    ENTRY_DATE      DATE NOT NULL,
    ACCOUNT_CODE    VARCHAR(20) NOT NULL,
    DESCRIPTION     VARCHAR(500),
    DEBIT_AMOUNT    NUMBER(18,2) DEFAULT 0,
    CREDIT_AMOUNT   NUMBER(18,2) DEFAULT 0,
    CURRENCY        VARCHAR(3) DEFAULT 'USD',
    ENTITY          VARCHAR(50),
    POSTED_BY       VARCHAR(100),
    STATUS          VARCHAR(20) DEFAULT 'POSTED'
);

INSERT INTO SHARED_FINANCIAL_DATA.CORE.JOURNAL_ENTRIES
    (ENTRY_DATE, ACCOUNT_CODE, DESCRIPTION, DEBIT_AMOUNT, CREDIT_AMOUNT, CURRENCY, ENTITY, POSTED_BY, STATUS)
VALUES
    ('2025-01-15', '1010', 'Cash receipt from customer Alpha Corp', 150000.00, 0, 'USD', 'US-EAST', 'jsmith', 'POSTED'),
    ('2025-01-15', '4010', 'Revenue recognition - Alpha Corp Q1', 0, 150000.00, 'USD', 'US-EAST', 'jsmith', 'POSTED'),
    ('2025-01-20', '5010', 'COGS - Product delivery Alpha Corp', 45000.00, 0, 'USD', 'US-EAST', 'mwilson', 'POSTED'),
    ('2025-01-20', '2010', 'Inventory reduction - Alpha Corp order', 0, 45000.00, 'USD', 'US-EAST', 'mwilson', 'POSTED'),
    ('2025-02-01', '6010', 'Office lease payment - NYC HQ', 25000.00, 0, 'USD', 'US-EAST', 'agarcia', 'POSTED'),
    ('2025-02-01', '1010', 'Cash disbursement - lease', 0, 25000.00, 'USD', 'US-EAST', 'agarcia', 'POSTED'),
    ('2025-02-10', '1010', 'Cash receipt from Beta Industries', 220000.00, 0, 'EUR', 'EU-WEST', 'kmueller', 'POSTED'),
    ('2025-02-10', '4010', 'Revenue recognition - Beta Industries Q1', 0, 220000.00, 'EUR', 'EU-WEST', 'kmueller', 'POSTED'),
    ('2025-02-15', '6020', 'Payroll expense - February', 180000.00, 0, 'USD', 'US-EAST', 'hrteam', 'POSTED'),
    ('2025-02-15', '2020', 'Payroll liability - February', 0, 180000.00, 'USD', 'US-EAST', 'hrteam', 'POSTED'),
    ('2025-03-01', '1020', 'AR - Gamma LLC invoice #4421', 95000.00, 0, 'USD', 'US-WEST', 'tbrown', 'POSTED'),
    ('2025-03-01', '4010', 'Revenue recognition - Gamma LLC', 0, 95000.00, 'USD', 'US-WEST', 'tbrown', 'POSTED'),
    ('2025-03-05', '6030', 'Software subscription - Salesforce', 12000.00, 0, 'USD', 'GLOBAL', 'itteam', 'POSTED'),
    ('2025-03-05', '1010', 'Cash disbursement - Salesforce', 0, 12000.00, 'USD', 'GLOBAL', 'itteam', 'POSTED'),
    ('2025-03-10', '7010', 'Depreciation - IT equipment', 8500.00, 0, 'USD', 'GLOBAL', 'agarcia', 'POSTED'),
    ('2025-03-10', '1510', 'Accumulated depreciation', 0, 8500.00, 'USD', 'GLOBAL', 'agarcia', 'POSTED'),
    ('2025-03-15', '1010', 'Cash receipt - Delta Corp', 310000.00, 0, 'GBP', 'UK', 'lwright', 'POSTED'),
    ('2025-03-15', '4010', 'Revenue recognition - Delta Corp', 0, 310000.00, 'GBP', 'UK', 'lwright', 'POSTED'),
    ('2025-03-20', '6040', 'Travel expense - Sales team Q1', 18500.00, 0, 'USD', 'US-EAST', 'jsmith', 'PENDING'),
    ('2025-03-20', '2030', 'Accrued expenses - travel', 0, 18500.00, 'USD', 'US-EAST', 'jsmith', 'PENDING'),
    ('2025-03-25', '1010', 'Wire transfer - Epsilon SA', 175000.00, 0, 'EUR', 'EU-WEST', 'kmueller', 'POSTED'),
    ('2025-03-25', '4020', 'Service revenue - Epsilon SA', 0, 175000.00, 'EUR', 'EU-WEST', 'kmueller', 'POSTED'),
    ('2025-03-31', '8010', 'FX gain - EUR revaluation', 0, 4200.00, 'USD', 'GLOBAL', 'treasury', 'POSTED'),
    ('2025-03-31', '3010', 'Unrealized FX gain', 4200.00, 0, 'USD', 'GLOBAL', 'treasury', 'POSTED'),
    ('2025-03-31', '6050', 'Insurance premium - Q2 prepaid', 36000.00, 0, 'USD', 'GLOBAL', 'agarcia', 'POSTED'),
    ('2025-03-31', '1010', 'Cash disbursement - insurance', 0, 36000.00, 'USD', 'GLOBAL', 'agarcia', 'POSTED');

-- --------------------------------------------------------------------------
-- Table 2: ACCOUNT_BALANCES - Period-end account balances
-- --------------------------------------------------------------------------
CREATE OR REPLACE TABLE SHARED_FINANCIAL_DATA.CORE.ACCOUNT_BALANCES (
    BALANCE_ID      NUMBER AUTOINCREMENT,
    ACCOUNT_CODE    VARCHAR(20) NOT NULL,
    ACCOUNT_NAME    VARCHAR(200) NOT NULL,
    PERIOD_END_DATE DATE NOT NULL,
    BALANCE_AMOUNT  NUMBER(18,2),
    CURRENCY        VARCHAR(3) DEFAULT 'USD',
    ENTITY          VARCHAR(50),
    ACCOUNT_TYPE    VARCHAR(50)
);

INSERT INTO SHARED_FINANCIAL_DATA.CORE.ACCOUNT_BALANCES
    (ACCOUNT_CODE, ACCOUNT_NAME, PERIOD_END_DATE, BALANCE_AMOUNT, CURRENCY, ENTITY, ACCOUNT_TYPE)
VALUES
    ('1010', 'Cash and Cash Equivalents', '2025-03-31', 2450000.00, 'USD', 'US-EAST', 'ASSET'),
    ('1010', 'Cash and Cash Equivalents', '2025-03-31', 890000.00, 'EUR', 'EU-WEST', 'ASSET'),
    ('1010', 'Cash and Cash Equivalents', '2025-03-31', 520000.00, 'GBP', 'UK', 'ASSET'),
    ('1020', 'Accounts Receivable', '2025-03-31', 1850000.00, 'USD', 'US-EAST', 'ASSET'),
    ('1020', 'Accounts Receivable', '2025-03-31', 620000.00, 'EUR', 'EU-WEST', 'ASSET'),
    ('1510', 'Accumulated Depreciation', '2025-03-31', -340000.00, 'USD', 'GLOBAL', 'CONTRA-ASSET'),
    ('2010', 'Accounts Payable', '2025-03-31', -780000.00, 'USD', 'US-EAST', 'LIABILITY'),
    ('2020', 'Accrued Payroll', '2025-03-31', -540000.00, 'USD', 'US-EAST', 'LIABILITY'),
    ('2030', 'Accrued Expenses', '2025-03-31', -125000.00, 'USD', 'US-EAST', 'LIABILITY'),
    ('3010', 'Retained Earnings', '2025-03-31', -4500000.00, 'USD', 'GLOBAL', 'EQUITY'),
    ('4010', 'Product Revenue', '2025-03-31', -3200000.00, 'USD', 'US-EAST', 'REVENUE'),
    ('4010', 'Product Revenue', '2025-03-31', -1100000.00, 'EUR', 'EU-WEST', 'REVENUE'),
    ('4010', 'Product Revenue', '2025-03-31', -680000.00, 'GBP', 'UK', 'REVENUE'),
    ('4020', 'Service Revenue', '2025-03-31', -950000.00, 'USD', 'US-WEST', 'REVENUE'),
    ('5010', 'Cost of Goods Sold', '2025-03-31', 1450000.00, 'USD', 'US-EAST', 'EXPENSE'),
    ('6010', 'Rent Expense', '2025-03-31', 75000.00, 'USD', 'US-EAST', 'EXPENSE'),
    ('6020', 'Payroll Expense', '2025-03-31', 540000.00, 'USD', 'US-EAST', 'EXPENSE'),
    ('6030', 'Software & Subscriptions', '2025-03-31', 48000.00, 'USD', 'GLOBAL', 'EXPENSE'),
    ('6040', 'Travel & Entertainment', '2025-03-31', 37000.00, 'USD', 'US-EAST', 'EXPENSE'),
    ('6050', 'Insurance Expense', '2025-03-31', 36000.00, 'USD', 'GLOBAL', 'EXPENSE'),
    ('7010', 'Depreciation Expense', '2025-03-31', 34000.00, 'USD', 'GLOBAL', 'EXPENSE'),
    ('8010', 'FX Gains/Losses', '2025-03-31', -4200.00, 'USD', 'GLOBAL', 'OTHER'),
    ('1010', 'Cash and Cash Equivalents', '2024-12-31', 2100000.00, 'USD', 'US-EAST', 'ASSET'),
    ('1020', 'Accounts Receivable', '2024-12-31', 1650000.00, 'USD', 'US-EAST', 'ASSET'),
    ('4010', 'Product Revenue', '2024-12-31', -12800000.00, 'USD', 'US-EAST', 'REVENUE');

-- --------------------------------------------------------------------------
-- Table 3: RECONCILIATIONS - Account reconciliation records
-- --------------------------------------------------------------------------
CREATE OR REPLACE TABLE SHARED_FINANCIAL_DATA.CORE.RECONCILIATIONS (
    RECON_ID            NUMBER AUTOINCREMENT,
    ACCOUNT_CODE        VARCHAR(20) NOT NULL,
    PERIOD_END_DATE     DATE NOT NULL,
    GL_BALANCE          NUMBER(18,2),
    SUB_LEDGER_BALANCE  NUMBER(18,2),
    DIFFERENCE          NUMBER(18,2),
    STATUS              VARCHAR(20),
    PREPARER            VARCHAR(100),
    REVIEWER            VARCHAR(100)
);

INSERT INTO SHARED_FINANCIAL_DATA.CORE.RECONCILIATIONS
    (ACCOUNT_CODE, PERIOD_END_DATE, GL_BALANCE, SUB_LEDGER_BALANCE, DIFFERENCE, STATUS, PREPARER, REVIEWER)
VALUES
    ('1010', '2025-03-31', 2450000.00, 2450000.00, 0, 'APPROVED', 'jsmith', 'cfo_jones'),
    ('1020', '2025-03-31', 1850000.00, 1847500.00, 2500.00, 'IN_REVIEW', 'tbrown', 'mgr_davis'),
    ('2010', '2025-03-31', -780000.00, -780000.00, 0, 'APPROVED', 'agarcia', 'mgr_davis'),
    ('2020', '2025-03-31', -540000.00, -540000.00, 0, 'APPROVED', 'hrteam', 'cfo_jones'),
    ('3010', '2025-03-31', -4500000.00, -4500000.00, 0, 'APPROVED', 'treasury', 'cfo_jones'),
    ('4010', '2025-03-31', -3200000.00, -3198000.00, -2000.00, 'OPEN', 'mwilson', NULL),
    ('5010', '2025-03-31', 1450000.00, 1450000.00, 0, 'APPROVED', 'mwilson', 'mgr_davis'),
    ('6020', '2025-03-31', 540000.00, 540000.00, 0, 'APPROVED', 'hrteam', 'cfo_jones'),
    ('1010', '2024-12-31', 2100000.00, 2100000.00, 0, 'APPROVED', 'jsmith', 'cfo_jones'),
    ('1020', '2024-12-31', 1650000.00, 1650000.00, 0, 'APPROVED', 'tbrown', 'mgr_davis'),
    ('2010', '2024-12-31', -720000.00, -720000.00, 0, 'APPROVED', 'agarcia', 'mgr_davis'),
    ('4010', '2024-12-31', -12800000.00, -12800000.00, 0, 'APPROVED', 'mwilson', 'cfo_jones'),
    ('1010', '2025-01-31', 2250000.00, 2250000.00, 0, 'APPROVED', 'jsmith', 'cfo_jones'),
    ('1010', '2025-02-28', 2380000.00, 2380000.00, 0, 'APPROVED', 'jsmith', 'cfo_jones'),
    ('1020', '2025-01-31', 1720000.00, 1718000.00, 2000.00, 'APPROVED', 'tbrown', 'mgr_davis'),
    ('1020', '2025-02-28', 1790000.00, 1790000.00, 0, 'APPROVED', 'tbrown', 'mgr_davis');

-- --------------------------------------------------------------------------
-- Table 4: CLOSE_TASKS - Period-close task tracking
-- --------------------------------------------------------------------------
CREATE OR REPLACE TABLE SHARED_FINANCIAL_DATA.CORE.CLOSE_TASKS (
    TASK_ID         NUMBER AUTOINCREMENT,
    TASK_NAME       VARCHAR(200) NOT NULL,
    PERIOD          VARCHAR(10) NOT NULL,
    ASSIGNED_TO     VARCHAR(100),
    DUE_DATE        DATE,
    COMPLETED_DATE  DATE,
    STATUS          VARCHAR(20),
    PRIORITY        VARCHAR(10),
    DEPARTMENT      VARCHAR(50)
);

INSERT INTO SHARED_FINANCIAL_DATA.CORE.CLOSE_TASKS
    (TASK_NAME, PERIOD, ASSIGNED_TO, DUE_DATE, COMPLETED_DATE, STATUS, PRIORITY, DEPARTMENT)
VALUES
    ('Post final journal entries', '2025-Q1', 'jsmith', '2025-04-02', '2025-04-01', 'COMPLETED', 'HIGH', 'Accounting'),
    ('Reconcile bank accounts', '2025-Q1', 'jsmith', '2025-04-03', '2025-04-02', 'COMPLETED', 'HIGH', 'Treasury'),
    ('Reconcile AR sub-ledger', '2025-Q1', 'tbrown', '2025-04-03', NULL, 'IN_PROGRESS', 'HIGH', 'Accounting'),
    ('Reconcile AP sub-ledger', '2025-Q1', 'agarcia', '2025-04-03', '2025-04-03', 'COMPLETED', 'HIGH', 'Accounting'),
    ('Review intercompany eliminations', '2025-Q1', 'kmueller', '2025-04-05', NULL, 'NOT_STARTED', 'HIGH', 'Consolidation'),
    ('Calculate depreciation', '2025-Q1', 'agarcia', '2025-04-02', '2025-04-01', 'COMPLETED', 'MEDIUM', 'Fixed Assets'),
    ('Accrue payroll liabilities', '2025-Q1', 'hrteam', '2025-04-02', '2025-04-02', 'COMPLETED', 'HIGH', 'HR'),
    ('FX revaluation', '2025-Q1', 'treasury', '2025-04-04', '2025-04-03', 'COMPLETED', 'MEDIUM', 'Treasury'),
    ('Revenue recognition review', '2025-Q1', 'mwilson', '2025-04-05', NULL, 'IN_PROGRESS', 'HIGH', 'Revenue'),
    ('Prepare consolidation package', '2025-Q1', 'cfo_jones', '2025-04-07', NULL, 'NOT_STARTED', 'CRITICAL', 'Consolidation'),
    ('Management review sign-off', '2025-Q1', 'cfo_jones', '2025-04-10', NULL, 'NOT_STARTED', 'CRITICAL', 'Executive'),
    ('Tax provision calculation', '2025-Q1', 'tax_team', '2025-04-08', NULL, 'NOT_STARTED', 'HIGH', 'Tax'),
    ('Post final journal entries', '2024-Q4', 'jsmith', '2025-01-02', '2025-01-02', 'COMPLETED', 'HIGH', 'Accounting'),
    ('Reconcile bank accounts', '2024-Q4', 'jsmith', '2025-01-03', '2025-01-03', 'COMPLETED', 'HIGH', 'Treasury'),
    ('Management review sign-off', '2024-Q4', 'cfo_jones', '2025-01-10', '2025-01-09', 'COMPLETED', 'CRITICAL', 'Executive');

-- --------------------------------------------------------------------------
-- Table 5: INTERCOMPANY_TRANSACTIONS - IC eliminations
-- --------------------------------------------------------------------------
CREATE OR REPLACE TABLE SHARED_FINANCIAL_DATA.CORE.INTERCOMPANY_TRANSACTIONS (
    TXN_ID      NUMBER AUTOINCREMENT,
    FROM_ENTITY VARCHAR(50) NOT NULL,
    TO_ENTITY   VARCHAR(50) NOT NULL,
    TXN_DATE    DATE NOT NULL,
    AMOUNT      NUMBER(18,2),
    CURRENCY    VARCHAR(3) DEFAULT 'USD',
    TXN_TYPE    VARCHAR(50),
    STATUS      VARCHAR(20),
    REFERENCE   VARCHAR(100)
);

INSERT INTO SHARED_FINANCIAL_DATA.CORE.INTERCOMPANY_TRANSACTIONS
    (FROM_ENTITY, TO_ENTITY, TXN_DATE, AMOUNT, CURRENCY, TXN_TYPE, STATUS, REFERENCE)
VALUES
    ('US-EAST', 'EU-WEST', '2025-01-15', 500000.00, 'USD', 'MANAGEMENT_FEE', 'MATCHED', 'IC-2025-001'),
    ('EU-WEST', 'US-EAST', '2025-01-15', 500000.00, 'USD', 'MANAGEMENT_FEE', 'MATCHED', 'IC-2025-001'),
    ('US-EAST', 'UK', '2025-02-01', 250000.00, 'GBP', 'IP_ROYALTY', 'MATCHED', 'IC-2025-002'),
    ('UK', 'US-EAST', '2025-02-01', 250000.00, 'GBP', 'IP_ROYALTY', 'MATCHED', 'IC-2025-002'),
    ('US-WEST', 'US-EAST', '2025-02-15', 120000.00, 'USD', 'COST_ALLOCATION', 'MATCHED', 'IC-2025-003'),
    ('US-EAST', 'US-WEST', '2025-02-15', 120000.00, 'USD', 'COST_ALLOCATION', 'MATCHED', 'IC-2025-003'),
    ('EU-WEST', 'UK', '2025-03-01', 180000.00, 'EUR', 'INVENTORY_TRANSFER', 'UNMATCHED', 'IC-2025-004'),
    ('UK', 'EU-WEST', '2025-03-01', 178500.00, 'EUR', 'INVENTORY_TRANSFER', 'UNMATCHED', 'IC-2025-004'),
    ('US-EAST', 'EU-WEST', '2025-03-15', 350000.00, 'USD', 'LOAN_PRINCIPAL', 'MATCHED', 'IC-2025-005'),
    ('EU-WEST', 'US-EAST', '2025-03-15', 350000.00, 'USD', 'LOAN_PRINCIPAL', 'MATCHED', 'IC-2025-005'),
    ('US-EAST', 'EU-WEST', '2025-03-15', 8750.00, 'USD', 'LOAN_INTEREST', 'MATCHED', 'IC-2025-005-INT'),
    ('EU-WEST', 'US-EAST', '2025-03-15', 8750.00, 'USD', 'LOAN_INTEREST', 'MATCHED', 'IC-2025-005-INT'),
    ('US-EAST', 'UK', '2025-03-20', 75000.00, 'GBP', 'SERVICE_FEE', 'PENDING', 'IC-2025-006'),
    ('US-WEST', 'EU-WEST', '2025-03-25', 95000.00, 'USD', 'COST_ALLOCATION', 'PENDING', 'IC-2025-007'),
    ('US-EAST', 'US-WEST', '2025-03-31', 200000.00, 'USD', 'MANAGEMENT_FEE', 'MATCHED', 'IC-2025-008'),
    ('US-WEST', 'US-EAST', '2025-03-31', 200000.00, 'USD', 'MANAGEMENT_FEE', 'MATCHED', 'IC-2025-008');


-- ============================================================================
-- DATABASE 2: SHARED_OPERATIONS_DATA
-- Shared with Azure consumer (<YOUR_ORG>.<AZURE_ACCOUNT_NAME>)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS SHARED_OPERATIONS_DATA;
CREATE SCHEMA IF NOT EXISTS SHARED_OPERATIONS_DATA.CORE;

-- --------------------------------------------------------------------------
-- Table 1: CUSTOMERS - Customer master data
-- --------------------------------------------------------------------------
CREATE OR REPLACE TABLE SHARED_OPERATIONS_DATA.CORE.CUSTOMERS (
    CUSTOMER_ID     NUMBER AUTOINCREMENT,
    NAME            VARCHAR(200) NOT NULL,
    INDUSTRY        VARCHAR(100),
    REGION          VARCHAR(50),
    COUNTRY         VARCHAR(50),
    TIER            VARCHAR(20),
    ARR             NUMBER(18,2),
    CREATED_DATE    DATE,
    ACCOUNT_MANAGER VARCHAR(100)
);

INSERT INTO SHARED_OPERATIONS_DATA.CORE.CUSTOMERS
    (NAME, INDUSTRY, REGION, COUNTRY, TIER, ARR, CREATED_DATE, ACCOUNT_MANAGER)
VALUES
    ('Alpha Corp', 'Financial Services', 'North America', 'United States', 'ENTERPRISE', 450000.00, '2022-03-15', 'Sarah Chen'),
    ('Beta Industries', 'Manufacturing', 'EMEA', 'Germany', 'ENTERPRISE', 380000.00, '2022-06-01', 'Klaus Weber'),
    ('Gamma LLC', 'Technology', 'North America', 'United States', 'MID-MARKET', 125000.00, '2023-01-10', 'Sarah Chen'),
    ('Delta Corp', 'Retail', 'EMEA', 'United Kingdom', 'ENTERPRISE', 520000.00, '2021-11-20', 'James Wright'),
    ('Epsilon SA', 'Healthcare', 'EMEA', 'France', 'MID-MARKET', 175000.00, '2023-04-05', 'Klaus Weber'),
    ('Zeta Inc', 'Financial Services', 'North America', 'Canada', 'SMB', 48000.00, '2024-01-15', 'Mike Torres'),
    ('Eta Global', 'Energy', 'APAC', 'Australia', 'ENTERPRISE', 290000.00, '2022-09-01', 'Lisa Tanaka'),
    ('Theta Partners', 'Professional Services', 'North America', 'United States', 'MID-MARKET', 98000.00, '2023-07-20', 'Mike Torres'),
    ('Iota Systems', 'Technology', 'APAC', 'Japan', 'ENTERPRISE', 410000.00, '2021-05-10', 'Lisa Tanaka'),
    ('Kappa Media', 'Media & Entertainment', 'North America', 'United States', 'MID-MARKET', 155000.00, '2023-09-12', 'Sarah Chen'),
    ('Lambda Pharma', 'Healthcare', 'EMEA', 'Switzerland', 'ENTERPRISE', 680000.00, '2020-12-01', 'Klaus Weber'),
    ('Mu Logistics', 'Transportation', 'APAC', 'Singapore', 'SMB', 62000.00, '2024-03-08', 'Lisa Tanaka'),
    ('Nu Financial', 'Financial Services', 'EMEA', 'United Kingdom', 'ENTERPRISE', 390000.00, '2022-01-25', 'James Wright'),
    ('Xi Robotics', 'Manufacturing', 'North America', 'United States', 'MID-MARKET', 210000.00, '2023-05-30', 'Mike Torres'),
    ('Omicron Energy', 'Energy', 'EMEA', 'Norway', 'ENTERPRISE', 340000.00, '2022-08-15', 'Klaus Weber');

-- --------------------------------------------------------------------------
-- Table 2: ORDERS - Sales orders
-- --------------------------------------------------------------------------
CREATE OR REPLACE TABLE SHARED_OPERATIONS_DATA.CORE.ORDERS (
    ORDER_ID        NUMBER AUTOINCREMENT,
    CUSTOMER_ID     NUMBER NOT NULL,
    ORDER_DATE      DATE NOT NULL,
    PRODUCT         VARCHAR(200),
    QUANTITY         NUMBER,
    UNIT_PRICE      NUMBER(18,2),
    TOTAL_AMOUNT    NUMBER(18,2),
    STATUS          VARCHAR(20),
    SHIP_DATE       DATE
);

INSERT INTO SHARED_OPERATIONS_DATA.CORE.ORDERS
    (CUSTOMER_ID, ORDER_DATE, PRODUCT, QUANTITY, UNIT_PRICE, TOTAL_AMOUNT, STATUS, SHIP_DATE)
VALUES
    (1, '2025-01-05', 'Platform License - Enterprise', 1, 450000.00, 450000.00, 'DELIVERED', '2025-01-06'),
    (2, '2025-01-10', 'Platform License - Enterprise', 1, 380000.00, 380000.00, 'DELIVERED', '2025-01-11'),
    (3, '2025-01-15', 'Platform License - Standard', 1, 125000.00, 125000.00, 'DELIVERED', '2025-01-16'),
    (4, '2025-01-20', 'Platform License - Enterprise', 1, 520000.00, 520000.00, 'DELIVERED', '2025-01-21'),
    (5, '2025-02-01', 'Platform License - Standard', 1, 175000.00, 175000.00, 'DELIVERED', '2025-02-02'),
    (1, '2025-02-10', 'Professional Services - Implementation', 40, 250.00, 10000.00, 'DELIVERED', '2025-02-28'),
    (2, '2025-02-15', 'Add-on Module - Advanced Analytics', 1, 45000.00, 45000.00, 'DELIVERED', '2025-02-16'),
    (6, '2025-02-20', 'Platform License - Starter', 1, 48000.00, 48000.00, 'DELIVERED', '2025-02-21'),
    (7, '2025-03-01', 'Platform License - Enterprise', 1, 290000.00, 290000.00, 'SHIPPED', '2025-03-05'),
    (8, '2025-03-05', 'Platform License - Standard', 1, 98000.00, 98000.00, 'SHIPPED', '2025-03-06'),
    (3, '2025-03-10', 'Add-on Module - Compliance Pack', 1, 25000.00, 25000.00, 'PROCESSING', NULL),
    (9, '2025-03-12', 'Platform License - Enterprise', 1, 410000.00, 410000.00, 'PROCESSING', NULL),
    (10, '2025-03-15', 'Platform License - Standard', 1, 155000.00, 155000.00, 'PROCESSING', NULL),
    (4, '2025-03-18', 'Professional Services - Training', 20, 200.00, 4000.00, 'PENDING', NULL),
    (11, '2025-03-20', 'Platform License - Enterprise', 1, 680000.00, 680000.00, 'PENDING', NULL),
    (1, '2025-03-22', 'Add-on Module - AI Insights', 1, 60000.00, 60000.00, 'PENDING', NULL),
    (12, '2025-03-25', 'Platform License - Starter', 1, 62000.00, 62000.00, 'PENDING', NULL);

-- --------------------------------------------------------------------------
-- Table 3: PRODUCTS - Product catalog
-- --------------------------------------------------------------------------
CREATE OR REPLACE TABLE SHARED_OPERATIONS_DATA.CORE.PRODUCTS (
    PRODUCT_ID      NUMBER AUTOINCREMENT,
    PRODUCT_NAME    VARCHAR(200) NOT NULL,
    CATEGORY        VARCHAR(100),
    UNIT_PRICE      NUMBER(18,2),
    COST            NUMBER(18,2),
    MARGIN_PCT      NUMBER(5,2),
    LAUNCH_DATE     DATE,
    IS_ACTIVE       BOOLEAN DEFAULT TRUE
);

INSERT INTO SHARED_OPERATIONS_DATA.CORE.PRODUCTS
    (PRODUCT_NAME, CATEGORY, UNIT_PRICE, COST, MARGIN_PCT, LAUNCH_DATE, IS_ACTIVE)
VALUES
    ('Platform License - Starter', 'License', 48000.00, 12000.00, 75.00, '2020-01-15', TRUE),
    ('Platform License - Standard', 'License', 125000.00, 28000.00, 77.60, '2020-01-15', TRUE),
    ('Platform License - Enterprise', 'License', 450000.00, 85000.00, 81.11, '2020-01-15', TRUE),
    ('Add-on Module - Advanced Analytics', 'Add-on', 45000.00, 8000.00, 82.22, '2021-06-01', TRUE),
    ('Add-on Module - Compliance Pack', 'Add-on', 25000.00, 5000.00, 80.00, '2022-03-15', TRUE),
    ('Add-on Module - AI Insights', 'Add-on', 60000.00, 15000.00, 75.00, '2024-01-10', TRUE),
    ('Professional Services - Implementation', 'Services', 250.00, 175.00, 30.00, '2020-01-15', TRUE),
    ('Professional Services - Training', 'Services', 200.00, 120.00, 40.00, '2020-01-15', TRUE),
    ('Professional Services - Custom Dev', 'Services', 300.00, 210.00, 30.00, '2021-01-01', TRUE),
    ('Legacy Module - Basic Reports', 'Add-on', 15000.00, 3000.00, 80.00, '2019-06-01', FALSE);

-- --------------------------------------------------------------------------
-- Table 4: SUPPORT_TICKETS - Customer support
-- --------------------------------------------------------------------------
CREATE OR REPLACE TABLE SHARED_OPERATIONS_DATA.CORE.SUPPORT_TICKETS (
    TICKET_ID       NUMBER AUTOINCREMENT,
    CUSTOMER_ID     NUMBER NOT NULL,
    CREATED_DATE    TIMESTAMP_NTZ NOT NULL,
    RESOLVED_DATE   TIMESTAMP_NTZ,
    CATEGORY        VARCHAR(100),
    PRIORITY        VARCHAR(20),
    STATUS          VARCHAR(20),
    ASSIGNEE        VARCHAR(100),
    SLA_MET         BOOLEAN
);

INSERT INTO SHARED_OPERATIONS_DATA.CORE.SUPPORT_TICKETS
    (CUSTOMER_ID, CREATED_DATE, RESOLVED_DATE, CATEGORY, PRIORITY, STATUS, ASSIGNEE, SLA_MET)
VALUES
    (1, '2025-01-08 09:15:00', '2025-01-08 11:30:00', 'Login Issue', 'HIGH', 'RESOLVED', 'support_anna', TRUE),
    (2, '2025-01-12 14:00:00', '2025-01-13 10:00:00', 'Data Import', 'MEDIUM', 'RESOLVED', 'support_bob', TRUE),
    (3, '2025-01-18 16:45:00', '2025-01-20 09:00:00', 'Performance', 'HIGH', 'RESOLVED', 'support_carlos', FALSE),
    (4, '2025-01-25 08:00:00', '2025-01-25 09:15:00', 'Feature Request', 'LOW', 'RESOLVED', 'support_anna', TRUE),
    (1, '2025-02-03 10:30:00', '2025-02-03 14:00:00', 'API Error', 'CRITICAL', 'RESOLVED', 'support_carlos', TRUE),
    (5, '2025-02-10 11:00:00', '2025-02-11 16:00:00', 'Configuration', 'MEDIUM', 'RESOLVED', 'support_diana', TRUE),
    (7, '2025-02-15 13:20:00', '2025-02-17 10:00:00', 'Data Export', 'MEDIUM', 'RESOLVED', 'support_bob', FALSE),
    (9, '2025-02-20 09:00:00', '2025-02-20 12:00:00', 'Login Issue', 'HIGH', 'RESOLVED', 'support_anna', TRUE),
    (2, '2025-03-01 08:30:00', '2025-03-01 15:00:00', 'Integration', 'HIGH', 'RESOLVED', 'support_carlos', TRUE),
    (11, '2025-03-05 14:15:00', '2025-03-06 09:00:00', 'Billing', 'MEDIUM', 'RESOLVED', 'support_diana', TRUE),
    (4, '2025-03-10 10:00:00', NULL, 'Performance', 'CRITICAL', 'IN_PROGRESS', 'support_carlos', NULL),
    (1, '2025-03-12 11:30:00', NULL, 'Feature Request', 'LOW', 'OPEN', 'support_bob', NULL),
    (8, '2025-03-15 09:45:00', NULL, 'Data Import', 'HIGH', 'IN_PROGRESS', 'support_anna', NULL),
    (13, '2025-03-18 16:00:00', NULL, 'API Error', 'CRITICAL', 'OPEN', NULL, NULL),
    (6, '2025-03-20 08:00:00', NULL, 'Configuration', 'MEDIUM', 'OPEN', NULL, NULL);

-- --------------------------------------------------------------------------
-- Table 5: USAGE_METRICS - Product usage telemetry
-- --------------------------------------------------------------------------
CREATE OR REPLACE TABLE SHARED_OPERATIONS_DATA.CORE.USAGE_METRICS (
    METRIC_ID           NUMBER AUTOINCREMENT,
    CUSTOMER_ID         NUMBER NOT NULL,
    METRIC_DATE         DATE NOT NULL,
    ACTIVE_USERS        NUMBER,
    API_CALLS           NUMBER,
    STORAGE_GB          NUMBER(10,2),
    FEATURE_FLAGS_USED  NUMBER
);

INSERT INTO SHARED_OPERATIONS_DATA.CORE.USAGE_METRICS
    (CUSTOMER_ID, METRIC_DATE, ACTIVE_USERS, API_CALLS, STORAGE_GB, FEATURE_FLAGS_USED)
VALUES
    (1, '2025-01-31', 145, 2850000, 42.5, 18),
    (2, '2025-01-31', 89, 1200000, 28.3, 12),
    (3, '2025-01-31', 34, 450000, 8.7, 7),
    (4, '2025-01-31', 210, 3800000, 65.2, 22),
    (5, '2025-01-31', 52, 680000, 15.1, 9),
    (7, '2025-01-31', 78, 950000, 22.8, 14),
    (9, '2025-01-31', 165, 4200000, 55.0, 20),
    (11, '2025-01-31', 320, 6100000, 98.5, 25),
    (1, '2025-02-28', 152, 3100000, 45.8, 19),
    (2, '2025-02-28', 93, 1350000, 30.1, 13),
    (3, '2025-02-28', 38, 520000, 9.4, 8),
    (4, '2025-02-28', 215, 3950000, 68.0, 22),
    (5, '2025-02-28', 55, 720000, 16.5, 10),
    (7, '2025-02-28', 82, 1020000, 24.3, 15),
    (9, '2025-02-28', 170, 4450000, 58.2, 21),
    (11, '2025-02-28', 328, 6350000, 102.1, 25),
    (1, '2025-03-31', 158, 3250000, 48.2, 20),
    (2, '2025-03-31', 97, 1480000, 32.5, 14),
    (3, '2025-03-31', 41, 590000, 10.2, 9),
    (4, '2025-03-31', 222, 4100000, 71.5, 23),
    (5, '2025-03-31', 58, 770000, 17.8, 11),
    (6, '2025-03-31', 12, 85000, 2.1, 4),
    (7, '2025-03-31', 85, 1100000, 26.0, 15),
    (8, '2025-03-31', 28, 320000, 6.5, 6),
    (9, '2025-03-31', 175, 4650000, 61.0, 21),
    (10, '2025-03-31', 45, 580000, 12.3, 8),
    (11, '2025-03-31', 335, 6500000, 105.8, 25),
    (12, '2025-03-31', 8, 42000, 1.2, 3),
    (13, '2025-03-31', 110, 1800000, 35.5, 16),
    (14, '2025-03-31', 62, 750000, 14.0, 10);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

SELECT 'SHARED_FINANCIAL_DATA' AS DATABASE_NAME, 'JOURNAL_ENTRIES' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM SHARED_FINANCIAL_DATA.CORE.JOURNAL_ENTRIES
UNION ALL
SELECT 'SHARED_FINANCIAL_DATA', 'ACCOUNT_BALANCES', COUNT(*) FROM SHARED_FINANCIAL_DATA.CORE.ACCOUNT_BALANCES
UNION ALL
SELECT 'SHARED_FINANCIAL_DATA', 'RECONCILIATIONS', COUNT(*) FROM SHARED_FINANCIAL_DATA.CORE.RECONCILIATIONS
UNION ALL
SELECT 'SHARED_FINANCIAL_DATA', 'CLOSE_TASKS', COUNT(*) FROM SHARED_FINANCIAL_DATA.CORE.CLOSE_TASKS
UNION ALL
SELECT 'SHARED_FINANCIAL_DATA', 'INTERCOMPANY_TRANSACTIONS', COUNT(*) FROM SHARED_FINANCIAL_DATA.CORE.INTERCOMPANY_TRANSACTIONS
UNION ALL
SELECT 'SHARED_OPERATIONS_DATA', 'CUSTOMERS', COUNT(*) FROM SHARED_OPERATIONS_DATA.CORE.CUSTOMERS
UNION ALL
SELECT 'SHARED_OPERATIONS_DATA', 'ORDERS', COUNT(*) FROM SHARED_OPERATIONS_DATA.CORE.ORDERS
UNION ALL
SELECT 'SHARED_OPERATIONS_DATA', 'PRODUCTS', COUNT(*) FROM SHARED_OPERATIONS_DATA.CORE.PRODUCTS
UNION ALL
SELECT 'SHARED_OPERATIONS_DATA', 'SUPPORT_TICKETS', COUNT(*) FROM SHARED_OPERATIONS_DATA.CORE.SUPPORT_TICKETS
UNION ALL
SELECT 'SHARED_OPERATIONS_DATA', 'USAGE_METRICS', COUNT(*) FROM SHARED_OPERATIONS_DATA.CORE.USAGE_METRICS;
