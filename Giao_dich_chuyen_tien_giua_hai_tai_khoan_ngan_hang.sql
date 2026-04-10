CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    owner_name VARCHAR(100),
    balance NUMERIC(10,2)
);

INSERT INTO accounts (owner_name, balance)
VALUES ('A', 500.00),
       ('B', 300.00);

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
           OR a.account_id = recieve_id;
        IF cnt_acc != 2 THEN
            RAISE EXCEPTION 'Thông tin tài khoản không đúng';
        end if;

        UPDATE accounts
        SET balance = balance - amount_in
        WHERE account_id = sender_id;

        IF (SELECT balance FROM accounts WHERE account_id = sender_id) < 0 THEN
            RAISE EXCEPTION 'Số dư tài khoản không đủ';
        end if;

        UPDATE accounts
        SET balance = balance + amount_in
        WHERE account_id = recieve_id;

        COMMIT;

    EXCEPTION
        WHEN others THEN
            ROLLBACK;
            RAISE;
    end;
end;
$$;

CALL funds_transfer(1, 2, 100.00);

CALL funds_transfer(3, 2, 100.00);

SELECT * FROM accounts;

SELECT * FROM accounts;
SELECT * FROM transactions;

