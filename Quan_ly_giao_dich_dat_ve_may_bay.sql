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
