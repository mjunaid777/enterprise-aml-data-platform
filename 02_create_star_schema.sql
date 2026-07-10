-- Cleaning up the existing warehouse tables if they exist to allow clean deployments
DROP TABLE IF EXISTS fact_transactions CASCADE;
DROP TABLE IF EXISTS dim_accounts CASCADE;
DROP TABLE IF EXISTS dim_banks CASCADE;
DROP TABLE IF EXISTS dim_payment_methods CASCADE;

-- 1. Creating Dimension: Banks
CREATE TABLE dim_banks (
    bank_id SERIAL PRIMARY KEY,
    bank_code VARCHAR(100) UNIQUE NOT NULL
);

-- 2. Creating Dimension: Accounts
CREATE TABLE dim_accounts (
    account_id SERIAL PRIMARY KEY,
    account_number VARCHAR(100) UNIQUE NOT NULL
);

-- 3. Creating Dimension: Payment Methods
CREATE TABLE dim_payment_methods (
    method_id SERIAL PRIMARY KEY,
    payment_format VARCHAR(50) UNIQUE NOT NULL
);

-- 4. Creating Core Fact Table
CREATE TABLE fact_transactions (
    transaction_id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    from_bank_id INT REFERENCES dim_banks(bank_id),
    from_account_id INT REFERENCES dim_accounts(account_id),
    to_bank_id INT REFERENCES dim_banks(bank_id),
    to_account_id INT REFERENCES dim_accounts(account_id),
    amount_received NUMERIC(15, 2) NOT NULL,
    receiving_currency VARCHAR(50) NOT NULL,
    amount_paid NUMERIC(15, 2) NOT NULL,
    payment_currency VARCHAR(50) NOT NULL,
    method_id INT REFERENCES dim_payment_methods(method_id),
    is_laundering INT NOT NULL
);

-- 5. Performance Optimization: High-Performance Indexes for Foreign Keys
CREATE INDEX idx_fact_from_bank ON fact_transactions(from_bank_id);
CREATE INDEX idx_fact_to_bank ON fact_transactions(to_bank_id);
CREATE INDEX idx_fact_from_account ON fact_transactions(from_account_id);
CREATE INDEX idx_fact_to_account ON fact_transactions(to_account_id);
CREATE INDEX idx_fact_method ON fact_transactions(method_id);
CREATE INDEX idx_fact_timestamp ON fact_transactions(timestamp);