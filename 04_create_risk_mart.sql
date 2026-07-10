DROP TABLE IF EXISTS mart_account_risk_summary;

-- Creating the aggregated Data Mart
CREATE TABLE mart_account_risk_summary AS
SELECT 
    fa.account_number,
    fb.bank_code AS primary_bank,
    COUNT(f.transaction_id) AS total_transactions_sent,
    ROUND(SUM(f.amount_paid), 2) AS total_volume_sent,
    ROUND(MAX(f.amount_paid), 2) AS max_single_transaction,
    
    -- Business Rule: Count the transactions over $10,000
    SUM(CASE WHEN f.amount_paid > 10000 THEN 1 ELSE 0 END) AS high_value_tx_count,
    
    -- Identify if this account was flagged in the Kaggle dataset's ground truth
    SUM(f.is_laundering) AS known_fraud_incidents,
    
    -- The AML Risk Scoring Engine
    CASE 
        WHEN SUM(f.is_laundering) > 0 THEN 'CRITICAL - Known Fraud'
        WHEN SUM(CASE WHEN f.amount_paid > 10000 THEN 1 ELSE 0 END) >= 5 AND SUM(f.amount_paid) > 100000 THEN 'HIGH - Structuring Risk'
        WHEN SUM(CASE WHEN f.amount_paid > 10000 THEN 1 ELSE 0 END) > 0 THEN 'MEDIUM - Elevated Volume'
        ELSE 'LOW - Standard Activity'
    END AS risk_tier

FROM fact_transactions f
JOIN dim_accounts fa ON f.from_account_id = fa.account_id
JOIN dim_banks fb ON f.from_bank_id = fb.bank_id
GROUP BY 
    fa.account_number, 
    fb.bank_code;

-- Adding indexes to our new Data Mart so Power BI can filter it instantly
CREATE INDEX idx_mart_risk_tier ON mart_account_risk_summary(risk_tier);
CREATE INDEX idx_mart_bank ON mart_account_risk_summary(primary_bank);