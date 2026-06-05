CREATE MATERIALIZED VIEW mv_daily_fraud_summary AS

WITH ranked_customers AS (
    SELECT
        DATE(t.transaction_at) AS transaction_date,
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        AVG(t.risk_score) AS avg_risk_score,

        ROW_NUMBER() OVER (
            PARTITION BY DATE(t.transaction_at)
            ORDER BY AVG(t.risk_score) DESC
            ) AS rn

    FROM transactions t
             JOIN accounts a
                  ON t.account_id = a.account_id
             JOIN customers c
                  ON a.customer_id = c.customer_id

    GROUP BY
        DATE(t.transaction_at),
        c.customer_id,
        c.first_name,
        c.last_name
),

     top_customers AS (
         SELECT
             transaction_date,

             STRING_AGG(
                     customer_name,
                     ', '
                     ORDER BY avg_risk_score DESC
             ) AS top_risky_customers

         FROM ranked_customers

         WHERE rn <= 3

         GROUP BY transaction_date
     )

SELECT
    DATE(t.transaction_at) AS transaction_date,

    COUNT(*) AS total_transactions,

    COALESCE(SUM(t.amount), 0) AS total_transaction_amount,

    COUNT(*) FILTER (
        WHERE t.status = 'FLAGGED'
        ) AS flagged_transactions,

    COALESCE(
                    SUM(t.amount) FILTER (
                WHERE t.status = 'FLAGGED'
                ),
                    0
    ) AS suspicious_transaction_amount,

    ROUND(AVG(t.risk_score), 2) AS average_risk_score,

    COUNT(DISTINCT fa.alert_id) AS total_fraud_alerts,

    tc.top_risky_customers

FROM transactions t

         LEFT JOIN fraud_alerts fa
                   ON t.transaction_id = fa.transaction_id

         LEFT JOIN top_customers tc
                   ON tc.transaction_date = DATE(t.transaction_at)

GROUP BY
    DATE(t.transaction_at),
    tc.top_risky_customers;

