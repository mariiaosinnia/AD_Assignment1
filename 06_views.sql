CREATE OR REPLACE VIEW vw_customer_accounts AS
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    a.account_id,
    a.account_number,
    a.currency,
    a.balance,
    a.status AS account_status
FROM customers c
         JOIN accounts a ON c.customer_id = a.customer_id;


CREATE OR REPLACE VIEW vw_recent_transactions AS
SELECT
    transaction_id,
    account_id,
    amount,
    currency,
    status,
    risk_score,
    transaction_at
FROM transactions
WHERE transaction_at >= NOW() - INTERVAL '7 days';


CREATE OR REPLACE VIEW vw_flagged_transactions AS
SELECT
    transaction_id,
    account_id,
    amount,
    currency,
    risk_score,
    status,
    transaction_at
FROM transactions
WHERE status = 'FLAGGED';


CREATE OR REPLACE VIEW vw_customer_risk_profile AS
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(t.transaction_id) AS total_transactions,
    COALESCE(AVG(t.risk_score), 0) AS avg_risk_score,
    COALESCE(SUM(t.amount), 0) AS total_volume
FROM customers c
         LEFT JOIN accounts a ON c.customer_id = a.customer_id
         LEFT JOIN transactions t ON a.account_id = t.account_id
GROUP BY c.customer_id, c.first_name, c.last_name;