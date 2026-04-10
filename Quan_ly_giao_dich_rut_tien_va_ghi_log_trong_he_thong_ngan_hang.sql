CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    balance NUMERIC(12,2)
);

CREATE TABLE transactions (
    trans_id SERIAL PRIMARY KEY,
    account_id INT REFERENCES accounts(account_id),
    amount NUMERIC(12,2),
    trans_type VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE funds_transfer(
    sender_id INT,
    amount_in NUMERIC(12,2)
)
    LANGUAGE plpgsql AS $$
BEGIN
    begin
        IF (SELECT balance FROM accounts WHERE account_id = sender_id) < amount_in THEN
            RAISE EXCEPTION 'Số dư tài khoản không đủ';
        end if;

        UPDATE accounts
        SET balance = balance - amount_in
        WHERE account_id = sender_id;

        INSERT INTO transactions(account_id, amount, trans_type)
        VALUES (sender_id, amount_in, 'WITHDRAW');

    EXCEPTION
        WHEN others THEN
            ROLLBACK;
            RAISE;
    end;
end;
$$;

INSERT INTO accounts(customer_name, balance)
VALUES ('Nguyen Van A', 100000),
       ('Nguyen Van B', 30000);

CALL funds_transfer(1, 500000);

SELECT * FROM accounts;
SELECT * FROM transactions;

