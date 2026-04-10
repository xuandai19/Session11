CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    owner_name VARCHAR(100),
    balance NUMERIC(12,2),
    status VARCHAR(10) DEFAULT 'ACTIVE'
);

CREATE TABLE transactions (
    trans_id SERIAL PRIMARY KEY,
    from_account INT REFERENCES accounts(account_id),
    to_account INT REFERENCES accounts(account_id),
    amount NUMERIC(12,2),
    status VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE funds_transfer(
    sender_id INT,
    recieve_id INT,
    amount_in FLOAT
)
    LANGUAGE plpgsql AS $$
DECLARE
    cnt_acc INT;
BEGIN
    begin
        SELECT count(a.account_id) INTO cnt_acc
        FROM accounts a
        WHERE a.account_id = sender_id
           OR a.account_id = recieve_id
            AND a.status;
        IF cnt_acc != 2 THEN
            RAISE EXCEPTION 'Thông tin tài khoản không đúng';
        end if;

        UPDATE accounts
        SET balance = balance - amount_in
        WHERE account_id = sender_id;

        IF (SELECT balance FROM accounts WHERE account_id = sender_id) < 0 THEN
            RAISE EXCEPTION 'Số dư tài khoản không đủ';
        end if;

        INSERT INTO transactions(from_account, to_account, amount, status)
        VALUES (sender_id, recieve_id, amount_in, 'COMPLETED');

        UPDATE accounts
        SET balance = balance + amount_in
        WHERE account_id = recieve_id;

    EXCEPTION
        WHEN others THEN
            RAISE;
    end;
end;
$$;

INSERT INTO accounts(owner_name, balance)
VALUES ('Nguyen Van A', 100000),
       ('Nguyen Van B', 30000);

call funds_transfer(1,2,40000);

SELECT * FROM accounts;
SELECT * FROM transactions;
