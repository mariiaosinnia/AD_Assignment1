CREATE OR REPLACE FUNCTION get_customer_age(p_customer_id BIGINT)
    RETURNS INT
    LANGUAGE plpgsql
AS $$
DECLARE
    v_age INT;
BEGIN
    SELECT DATE_PART('year', AGE(birth_date))
    INTO v_age
    FROM customers
    WHERE customer_id = p_customer_id;

    RETURN v_age;
END;
$$;


CREATE OR REPLACE FUNCTION is_high_risk_country(p_country_code VARCHAR)
    RETURNS BOOLEAN
    LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p_country_code IN ('NG', 'RU', 'KP', 'IR');
END;
$$;


CREATE OR REPLACE FUNCTION mask_card_number(p_card_hash VARCHAR)
    RETURNS VARCHAR
    LANGUAGE plpgsql
AS $$
BEGIN
    RETURN '****' || RIGHT(p_card_hash, 4);
END;
$$;


CREATE OR REPLACE FUNCTION calculate_customer_daily_volume(
    p_customer_id BIGINT,
    p_date DATE
)
    RETURNS NUMERIC
    LANGUAGE plpgsql
AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(t.amount), 0)
    INTO v_total
    FROM transactions t
             JOIN accounts a ON t.account_id = a.account_id
    WHERE a.customer_id = p_customer_id
      AND DATE(t.transaction_at) = p_date;

    RETURN v_total;
END;
$$;


CREATE OR REPLACE FUNCTION calculate_transaction_risk_score(p_transaction_id BIGINT)
    RETURNS INT
    LANGUAGE plpgsql
AS $$
DECLARE
    v_score INT := 0;
    v_amount NUMERIC;
    v_country VARCHAR;
BEGIN
    SELECT amount, merchant_country
    INTO v_amount, v_country
    FROM transactions
    WHERE transaction_id = p_transaction_id;

    IF v_amount > 5000 THEN
        v_score := v_score + 50;
    END IF;

    IF v_country IN ('NG', 'RU', 'KP', 'IR') THEN
        v_score := v_score + 50;
    END IF;

    RETURN v_score;
END;
$$;