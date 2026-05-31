CREATE SCHEMA IF NOT EXISTS fraud_system;

CREATE TABLE customers (
    customer_id BIGSERIAL PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255) UNIQUE,
    birth_date DATE,
    country_code VARCHAR(2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE accounts (
    account_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT REFERENCES customers(customer_id),
    account_number VARCHAR(30) UNIQUE,
    currency VARCHAR(3) CHECK (currency IN ('UAH', 'USD', 'EUR')),
    balance NUMERIC(12,2) DEFAULT 0 CHECK (balance >= 0),
    status VARCHAR(20) CHECK ( status IN ('ACTIVE', 'FROZEN', 'CLOSED')),
    opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cards (
    card_id BIGSERIAL PRIMARY KEY,
    account_id BIGINT REFERENCES accounts(account_id),
    card_number_hash VARCHAR(255) UNIQUE,
    card_type VARCHAR(20),
    status VARCHAR(20),
    expiration_date DATE
);

CREATE TABLE transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    account_id BIGINT REFERENCES accounts(account_id),
    card_id BIGINT REFERENCES cards(card_id),
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) CHECK (currency IN ('UAH', 'USD', 'EUR')),
    merchant_category VARCHAR(100),
    merchant_country VARCHAR(2),
    status VARCHAR(20) CHECK ( status IN ( 'PENDING', 'APPROVED', 'DECLINED', 'FLAGGED' ) ),
    risk_score INTEGER,
    transaction_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE transaction_status_history (
    history_id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT REFERENCES transactions(transaction_id),
    old_status VARCHAR(20),
    new_status VARCHAR(20) CHECK ( new_status IN ( 'PENDING', 'APPROVED', 'DECLINED', 'FLAGGED' ) ),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(100)
);

CREATE TABLE fraud_rules (
    rule_id BIGSERIAL PRIMARY KEY,
    rule_name VARCHAR(100),
    rule_type VARCHAR(100),
    threshold_value INTEGER CHECK (threshold_value >= 0),
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE fraud_alerts (
    alert_id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT REFERENCES transactions(transaction_id),
    rule_id BIGINT REFERENCES fraud_rules(rule_id),
    reason TEXT,
    risk_score INTEGER CHECK ( risk_score BETWEEN 0 AND 100 ),
    alert_status VARCHAR(20) CHECK ( alert_status IN ( 'OPEN', 'CLOSED', 'UNDER_REVIEW' ) ),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit_log (
    audit_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT REFERENCES customers(customer_id),
    table_name VARCHAR(100),
    operation VARCHAR(20) CHECK ( operation IN ( 'INSERT', 'UPDATE', 'DELETE' ) ),
    old_value JSON,
    new_value JSON,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);