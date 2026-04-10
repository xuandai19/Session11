CREATE TABLE products (
                          product_id SERIAL PRIMARY KEY,
                          product_name VARCHAR(100),
                          stock INT,
                          price NUMERIC(10,2)
);

CREATE TABLE customers (
                           customer_id SERIAL PRIMARY KEY,
                           name VARCHAR(100),
                           balance NUMERIC(12,2)
);

CREATE TABLE orders (
                        order_id SERIAL PRIMARY KEY,
                        customer_id INT REFERENCES customers(customer_id),
                        total_amount DECIMAL(10,2),
                        created_at TIMESTAMP DEFAULT NOW(),
                        status VARCHAR(20) DEFAULT 'PENDING'
);

CREATE TABLE order_items (
                             item_id SERIAL PRIMARY KEY,
                             order_id INT REFERENCES orders(order_id),
                             product_id INT REFERENCES products(product_id),
                             quantity INT,
                             subtotal NUMERIC(10,2)
);

INSERT INTO customers(name, balance)
VALUES ('Tran Thi B', 1000000);

INSERT INTO products (product_name, stock, price)
VALUES ('Laptop MSI', 6, 100000),
       ('Chuột không dây', 8, 150000),
       ('Điện thoại Apple', 4, 300000);

CREATE OR REPLACE PROCEDURE cus_order(
    p_customer INT,
    p_proid INT,
    p_quantity INT
)
    LANGUAGE plpgsql AS
$$
DECLARE
    v_stock INT;
    v_price INT;
    v_balance NUMERIC;
BEGIN
    BEGIN
        SELECT stock, price INTO v_stock, v_price
        FROM products
        WHERE product_id = p_proid
        FOR UPDATE;

        IF v_stock < p_quantity THEN
            RAISE EXCEPTION 'Số lượng không đủ';
        end if;

        INSERT INTO orders (customer_id, total_amount, status)
        VALUES (p_customer, p_quantity * v_price, 'PENDING');

        SELECT balance INTO v_balance
        FROM customers
        WHERE  customer_id = p_customer;

        IF v_balance < (v_price * p_quantity) THEN
            RAISE EXCEPTION 'Quá số tiền bạn hiện có';
        end if;

        UPDATE orders
        SET status = 'COMPLETED'
        WHERE customer_id = p_customer;

        UPDATE products
        SET stock = stock - p_quantity
        WHERE product_id = p_proid;

        UPDATE customers
        SET balance = balance - (v_price * p_quantity)
        WHERE customer_id = p_customer;

    EXCEPTION
        WHEN others THEN
            RAISE;

    end;
end;
$$;

CALL cus_order(1,1,1);
CALL cus_order(1,3,2);

SELECT * FROM orders;
SELECT * FROM customers;
SELECT * FROM products;


DROP TABLE customers;
DROP TABLE products;
DROP TABLE orders;
DROP TABLE order_items;