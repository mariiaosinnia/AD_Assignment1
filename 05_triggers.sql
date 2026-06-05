CREATE OR REPLACE FUNCTION trg_calculate_risk()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS $$
DECLARE
    v_score INT := 0;
BEGIN

    IF NEW.amount > 5000 THEN
        v_score := v_score + 50;
    END IF;

    IF is_high_risk_country(NEW.merchant_country) THEN
        v_score := v_score + 50;
    END IF;

    NEW.risk_score := v_score;

    IF v_score >= 50 THEN
        NEW.status := 'FLAGGED';
    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER trigger_transaction_risk
    BEFORE INSERT ON transactions
    FOR EACH ROW
EXECUTE FUNCTION trg_calculate_risk();


CREATE OR REPLACE FUNCTION trg_create_fraud_alert()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.risk_score >= 50 THEN
        INSERT INTO fraud_alerts (
            transaction_id,
            rule_id,
            reason,
            risk_score,
            alert_status
        )
        VALUES (
                   NEW.transaction_id,
                   NULL,
                   'Auto detected risk',
                   NEW.risk_score,
                   'OPEN'
               );
    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER trigger_fraud_alert
    AFTER INSERT ON transactions
    FOR EACH ROW
EXECUTE FUNCTION trg_create_fraud_alert();


CREATE OR REPLACE FUNCTION trg_update_balance()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.status = 'APPROVED' THEN
        UPDATE accounts
        SET balance = balance + NEW.amount
        WHERE account_id = NEW.account_id;
    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER trigger_balance_update
    AFTER UPDATE OF status ON transactions
    FOR EACH ROW
EXECUTE FUNCTION trg_update_balance();


CREATE OR REPLACE FUNCTION trg_status_history()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO transaction_status_history (
            transaction_id,
            old_status,
            new_status,
            changed_by
        )
        VALUES (
                   NEW.transaction_id,
                   OLD.status,
                   NEW.status,
                   'SYSTEM'
               );
    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER trigger_status_history
    AFTER UPDATE ON transactions
    FOR EACH ROW
EXECUTE FUNCTION trg_status_history();


CREATE OR REPLACE FUNCTION trg_audit_log()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (
            customer_id,
            table_name,
            operation,
            new_value
        )
        VALUES (
                   NEW.customer_id,
                   TG_TABLE_NAME,
                   TG_OP,
                   row_to_json(NEW)
               );

    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (
            customer_id,
            table_name,
            operation,
            old_value,
            new_value
        )
        VALUES (
                   COALESCE(NEW.customer_id, OLD.customer_id),
                   TG_TABLE_NAME,
                   TG_OP,
                   row_to_json(OLD),
                   row_to_json(NEW)
               );

    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (
            customer_id,
            table_name,
            operation,
            old_value
        )
        VALUES (
                   OLD.customer_id,
                   TG_TABLE_NAME,
                   TG_OP,
                   row_to_json(OLD)
               );
    END IF;

    RETURN NULL;
END;
$$;


CREATE TRIGGER trigger_audit_customers
    AFTER INSERT OR UPDATE OR DELETE ON customers
    FOR EACH ROW
EXECUTE FUNCTION trg_audit_log();


CREATE OR REPLACE FUNCTION trg_customer_delete_protection()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM accounts
        WHERE customer_id = OLD.customer_id
    ) THEN
        RAISE EXCEPTION 'Cannot delete customer with active accounts';
    END IF;

    RETURN OLD;
END;
$$;

CREATE TRIGGER trigger_customer_delete_protection
    BEFORE DELETE ON customers
    FOR EACH ROW
EXECUTE FUNCTION trg_customer_delete_protection();