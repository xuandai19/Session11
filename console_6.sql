CREATE TABLE flights (
    flight_id SERIAL PRIMARY KEY,
    flight_name VARCHAR(100),
    available_seats INT
);

CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    flight_id INT REFERENCES flights(flight_id),
    customer_name VARCHAR(100)
);

INSERT INTO flights (flight_name, available_seats)
VALUES ('VN123', 3),
       ('VN456', 2);

CREATE OR REPLACE PROCEDURE p_book_flight(
    p_flight_id INT,
    p_customer_name VARCHAR
)
LANGUAGE plpgsql AS $$
    BEGIN
        BEGIN
            UPDATE flights
            SET available_seats = available_seats - 1
            WHERE flight_id = p_flight_id AND available_seats > 0;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Chuyến bay không tồn tại hoặc đã hết chỗ!';
            END IF;

            INSERT INTO bookings(flight_id, customer_name)
            VALUES (p_flight_id, p_customer_name);

            COMMIT;

        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
            RAISE;
        END;
    END;
    $$;

CALL p_book_flight(1, 'Nguyen Van A');

CALL p_book_flight(999, 'Nguyen Van B');

SELECT * FROM flights;
SELECT * FROM bookings;




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



CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    stock INT,
    price NUMERIC(10,2)
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    total_amount DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    product_id INT REFERENCES products(product_id),
    quantity INT,
    subtotal NUMERIC(10,2)
);

INSERT INTO productS (product_name, stock, price)
VALUES ('Laptop MSI', 30, 100000),
       ('Laptop HP', 20, 300000);

CREATE OR REPLACE PROCEDURE pro_order(
    p_customer VARCHAR,
    p_proid INT,
    p_quantity INT
)
    LANGUAGE plpgsql AS $$
DECLARE
    p_price NUMERIC(10,2);
    p_order_id INT;
    p_stock INT;
BEGIN
    begin
        SELECT price, stock INTO p_price, p_stock
        FROM products
        WHERE product_id = p_proid
        FOR UPDATE;

        IF p_stock IS NULL THEN
            RAISE EXCEPTION 'Sản phẩm không tồn tại';
        ELSIF p_stock < p_quantity THEN
            RAISE EXCEPTION 'Không đủ hàng';
        END IF;

        INSERT INTO orders(customer_name, total_amount)
        VALUES (p_customer, p_price * p_quantity)
        RETURNING order_id INTO p_order_id;

        INSERT INTO order_items (order_id, product_id, quantity, subtotal)
        VALUES (p_order_id, p_proid, p_quantity, p_price * p_quantity);

        UPDATE products
        SET stock = stock - p_quantity
        WHERE product_id = p_proid;

        COMMIT;

    EXCEPTION
        WHEN others THEN
            ROLLBACK;
            RAISE;
    end;
end;
$$;

CALL pro_order ('Nguyen Van A',1, 2);
CALL pro_order ('Nguyen Van A',2, 1);

SELECT * FROM products;
SELECT * FROM orders;
SELECT * FROM order_items;



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

