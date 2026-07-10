-- 1. Populate dim_banks with unique bank codes across both source and destination
INSERT INTO dim_banks (bank_code)
SELECT DISTINCT from_bank FROM staging_transactions
UNION
SELECT DISTINCT to_bank FROM staging_transactions
ON CONFLICT (bank_code) DO NOTHING;

-- 2. Populate dim_accounts with unique accounts across both directions
INSERT INTO dim_accounts (account_number)
SELECT DISTINCT from_account FROM staging_transactions
UNION
SELECT DISTINCT to_account FROM staging_transactions
ON CONFLICT (account_number) DO NOTHING;

-- 3. Populate dim_payment_methods
INSERT INTO dim_payment_methods (payment_format)
SELECT DISTINCT payment_format FROM staging_transactions
ON CONFLICT (payment_format) DO NOTHING;

-- 4. Populate Core Fact Table by joining back to dimensions to resolve IDs
INSERT INTO fact_transactions (
    timestamp, from_bank_id, from_account_id, to_bank_id, to_account_id, 
    amount_received, receiving_currency, amount_paid, payment_currency, method_id, is_laundering
)
SELECT 
    s.timestamp,
    fb.bank_id,
    fa.account_id,
    tb.bank_id,
    ta.account_id,
    s.amount_received,
    s.receiving_currency,
    s.amount_paid,
    s.payment_currency,
    pm.method_id,
    s.is_laundering
FROM staging_transactions s
JOIN dim_banks fb ON s.from_bank = fb.bank_code
JOIN dim_accounts fa ON s.from_account = fa.account_number
JOIN dim_banks tb ON s.to_bank = tb.bank_code
JOIN dim_accounts ta ON s.to_account = ta.account_number
JOIN dim_payment_methods pm ON s.payment_format = pm.payment_format;