CREATE MATERIALIZED VIEW mv_daily_fraud_summary AS
SELECT
    DATE(t.transaction_at) AS transaction_date,

    COUNT(t.transaction_id) AS total_transactions,

    COALESCE(SUM(t.amount), 0) AS total_transaction_amount,

    COUNT(CASE WHEN t.status = 'FLAGGED' THEN 1 END) AS flagged_transactions,

    COALESCE(SUM(CASE WHEN t.status = 'FLAGGED' THEN t.amount ELSE 0 END), 0)
        AS suspicious_transaction_amount,

    COALESCE(AVG(t.risk_score), 0) AS average_risk_score,

    COUNT(DISTINCT fa.alert_id) AS total_fraud_alerts

FROM transactions t
         LEFT JOIN fraud_alerts fa
                   ON t.transaction_id = fa.transaction_id

GROUP BY DATE(t.transaction_at);