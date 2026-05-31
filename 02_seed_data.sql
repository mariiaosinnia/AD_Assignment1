TRUNCATE TABLE
    fraud_alerts,
    fraud_rules,
    transaction_status_history,
    transactions,
    cards,
    accounts,
    audit_log,
    customers
    RESTART IDENTITY CASCADE;

INSERT INTO customers (first_name, last_name, email, birth_date, country_code)
VALUES
    ('John', 'Smith', 'john.smith@email.com', '1990-01-01', 'US'),
    ('Emma', 'Brown', 'emma.brown@email.com', '1992-05-10', 'GB'),
    ('Olha', 'Kovalenko', 'olha.kovalenko@email.com', '1995-07-21', 'UA');

INSERT INTO accounts (customer_id, account_number, currency, balance, status)
VALUES
    (1, 'ACC100001', 'USD', 5000.00, 'ACTIVE'),
    (2, 'ACC100002', 'EUR', 3200.00, 'ACTIVE'),
    (3, 'ACC100003', 'UAH', 150000.00, 'ACTIVE');

INSERT INTO cards (account_id, card_number_hash, card_type, status, expiration_date)
VALUES
    (1, 'hash_card_1', 'VISA', 'ACTIVE', '2028-01-01'),
    (2, 'hash_card_2', 'MASTERCARD', 'ACTIVE', '2028-06-01'),
    (3, 'hash_card_3', 'VISA', 'ACTIVE', '2029-03-01');

INSERT INTO transactions (
    account_id,
    card_id,
    amount,
    currency,
    merchant_category,
    merchant_country,
    status,
    risk_score,
    transaction_at
)
VALUES
    (1, 1, 120.50, 'USD', 'GROCERY', 'US', 'APPROVED', 10, NOW() - INTERVAL '3 days'),
    (2, 2, 2500.00, 'EUR', 'ONLINE_TRANSFER', 'NG', 'FLAGGED', 85, NOW() - INTERVAL '2 days'),
    (3, 3, 500.00, 'UAH', 'RESTAURANT', 'UA', 'APPROVED', 20, NOW() - INTERVAL '1 day'),
    (1, 1, 9999.99, 'USD', 'CRYPTO', 'RU', 'FLAGGED', 95, NOW());

INSERT INTO fraud_rules (rule_name, rule_type, threshold_value, is_active)
VALUES
    ('High Amount Rule', 'AMOUNT', 5000, TRUE),
    ('High Risk Country Rule', 'GEO', 70, TRUE);

INSERT INTO fraud_alerts (transaction_id, rule_id, reason, risk_score, alert_status)
VALUES
    (2, 1, 'Large transaction from high-risk country', 85, 'OPEN'),
    (4, 2, 'Crypto transaction + sanctioned country', 95, 'UNDER_REVIEW');

INSERT INTO transaction_status_history (transaction_id, old_status, new_status, changed_by)
VALUES
    (2, 'PENDING', 'FLAGGED', 'SYSTEM'),
    (4, 'PENDING', 'FLAGGED', 'SYSTEM');

INSERT INTO audit_log (customer_id, table_name, operation, old_value, new_value)
VALUES
    (1, 'accounts', 'INSERT', '{"balance":0}', '{"balance":5000}'),
    (2, 'transactions', 'INSERT', '{"status":"PENDING"}', '{"status":"FLAGGED"}');