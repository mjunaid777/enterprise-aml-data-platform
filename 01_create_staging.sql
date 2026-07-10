DROP TABLE IF EXISTS staging_transactions;

CREATE TABLE staging_transactions (
    timestamp TIMESTAMP,
    from_bank VARCHAR(100),
    from_account VARCHAR(100),
    to_bank VARCHAR(100),
    to_account VARCHAR(100),
    amount_received NUMERIC(15, 2),
    receiving_currency VARCHAR(10),
    amount_paid NUMERIC(15, 2),
    payment_format VARCHAR(50),
    is_laundering INT
);