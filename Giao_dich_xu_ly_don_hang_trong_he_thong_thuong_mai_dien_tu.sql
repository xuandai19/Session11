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
