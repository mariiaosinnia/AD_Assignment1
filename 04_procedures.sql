CREATE OR REPLACE PROCEDURE process_transaction(p_transaction_id BIGINT)
    LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE transactions
    SET status = 'APPROVED'
    WHERE transaction_id = p_transaction_id;
END;
$$;


CREATE OR REPLACE PROCEDURE create_fraud_alert(
    p_transaction_id BIGINT,
    p_reason TEXT,
    p_risk_score INT
)
    LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO fraud_alerts (
        transaction_id,
        rule_id,
        reason,
        risk_score,
        alert_status
    )
    VALUES (
               p_transaction_id,
               NULL,
               p_reason,
               p_risk_score,
               'OPEN'
           );
END;
$$;


CREATE OR REPLACE PROCEDURE freeze_account(p_account_id BIGINT)
    LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE accounts
    SET status = 'FROZEN'
    WHERE account_id = p_account_id;
END;
$$;


CREATE OR REPLACE PROCEDURE approve_pending_transactions()
    LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE transactions
    SET status = 'APPROVED'
    WHERE status = 'PENDING';
END;
$$;


CREATE OR REPLACE PROCEDURE refresh_fraud_dashboard()
    LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW mv_daily_fraud_summary;
END;
$$;