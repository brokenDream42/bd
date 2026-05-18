-- ============================================================
-- БАЗА ДАННЫХ: Учет товарооборота розничных торговых предприятий
-- Семестровая работа (новая, часть 1 — схема и данные)
-- СУБД: Oracle 12c+
-- ============================================================

PROMPT >>> Очистка старых объектов (если есть)...

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE order_details CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE orders CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE sales CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE sections CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE sellers CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE customers CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE products CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE suppliers CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE retail_outlets CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

PROMPT >>> Создание таблиц...

-- Торговые точки
CREATE TABLE retail_outlets (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR2(255) NOT NULL,
    type VARCHAR2(30) NOT NULL CHECK (type IN ('department_store','grocery_store','kiosk','stall')),
    address VARCHAR2(255),
    area NUMBER(10,2),
    rent NUMBER(10,2),
    utilities NUMBER(10,2),
    counters_count NUMBER(5)
);

-- Продавцы
CREATE TABLE sellers (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR2(255) NOT NULL,
    retail_outlet_id NUMBER NOT NULL,
    salary_rate NUMBER(10,2) CHECK (salary_rate >= 0)
);

-- Секции
CREATE TABLE sections (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    retail_outlet_id NUMBER NOT NULL,
    name VARCHAR2(255) NOT NULL,
    floor NUMBER(3),
    manager_id NUMBER
);

-- Покупатели
CREATE TABLE customers (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR2(255),
    characteristics VARCHAR2(2000)
);

-- Товары
CREATE TABLE products (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR2(255) NOT NULL,
    description VARCHAR2(2000)
);

-- Поставщики
CREATE TABLE suppliers (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR2(255) NOT NULL,
    contacts VARCHAR2(2000),
    active NUMBER(1) DEFAULT 1 CHECK (active IN (0,1))
);

-- Заказы поставщикам
CREATE TABLE orders (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_id NUMBER NOT NULL,
    "date" TIMESTAMP DEFAULT SYSTIMESTAMP,
    status VARCHAR2(20) DEFAULT 'created' CHECK (status IN ('created','sent','received','canceled'))
);

-- Детали заказов
CREATE TABLE order_details (
    order_id NUMBER NOT NULL,
    product_id NUMBER NOT NULL,
    quantity NUMBER(10,2) NOT NULL CHECK (quantity > 0),
    price NUMBER(10,2) NOT NULL CHECK (price > 0),
    PRIMARY KEY (order_id, product_id)
);

-- Продажи
CREATE TABLE sales (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "date" TIMESTAMP DEFAULT SYSTIMESTAMP,
    product_id NUMBER NOT NULL,
    quantity NUMBER(10,2) NOT NULL CHECK (quantity > 0),
    sale_price NUMBER(10,2) NOT NULL CHECK (sale_price > 0),
    seller_id NUMBER NOT NULL,
    retail_outlet_id NUMBER NOT NULL,
    customer_id NUMBER
);

PROMPT >>> Создание связей (Foreign Keys)...

ALTER TABLE sellers
    ADD CONSTRAINT fk_sellers_outlet
    FOREIGN KEY (retail_outlet_id) REFERENCES retail_outlets(id)
    ON DELETE CASCADE;
    

ALTER TABLE sections
    ADD CONSTRAINT fk_sections_outlet
    FOREIGN KEY (retail_outlet_id) REFERENCES retail_outlets(id)
    ON DELETE CASCADE;

ALTER TABLE sections
    ADD CONSTRAINT fk_sections_manager
    FOREIGN KEY (manager_id) REFERENCES sellers(id)
    ON DELETE SET NULL;

ALTER TABLE orders
    ADD CONSTRAINT fk_orders_supplier
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
    ON DELETE CASCADE;

ALTER TABLE order_details
    ADD CONSTRAINT fk_od_order
    FOREIGN KEY (order_id) REFERENCES orders(id)
    ON DELETE CASCADE;

ALTER TABLE order_details
    ADD CONSTRAINT fk_od_product
    FOREIGN KEY (product_id) REFERENCES products(id)
    ON DELETE CASCADE;

ALTER TABLE sales
    ADD CONSTRAINT fk_sales_product
    FOREIGN KEY (product_id) REFERENCES products(id)
    ON DELETE CASCADE;

ALTER TABLE sales
    ADD CONSTRAINT fk_sales_seller
    FOREIGN KEY (seller_id) REFERENCES sellers(id)
    ON DELETE CASCADE;

ALTER TABLE sales
    ADD CONSTRAINT fk_sales_outlet
    FOREIGN KEY (retail_outlet_id) REFERENCES retail_outlets(id)
    ON DELETE CASCADE;

ALTER TABLE sales
    ADD CONSTRAINT fk_sales_customer
    FOREIGN KEY (customer_id) REFERENCES customers(id)
    ON DELETE SET NULL;

PROMPT >>> Создание индексов...

CREATE INDEX idx_sales_date ON sales("date");
CREATE INDEX idx_sales_product ON sales(product_id);
CREATE INDEX idx_sales_outlet ON sales(retail_outlet_id);
CREATE INDEX idx_orders_supplier ON orders(supplier_id);
CREATE INDEX idx_sections_outlet ON sections(retail_outlet_id);

PROMPT >>> Заполнение данными...

-- Поставщики
INSERT INTO suppliers (name, contacts, active) VALUES ('LLC "BreadFactory"', 'ul. Bakerskaya, 15, tel. 123-4567', 1);
INSERT INTO suppliers (name, contacts, active) VALUES ('LLC "MilkCorp"', 'ul. Dairy Lane, 8, tel. 234-5678', 1);
INSERT INTO suppliers (name, contacts, active) VALUES ('LLC "MeatMasters"', 'ul. Butcher Street, 22, tel. 345-6789', 1);
INSERT INTO suppliers (name, contacts, active) VALUES ('LLC "TeaKingdom"', 'ul. Tea Avenue, 30, tel. 456-7890', 1);
INSERT INTO suppliers (name, contacts, active) VALUES ('LLC "CoffeeAndSugar"', 'ul. Sweet Street, 5, tel. 567-8901', 1);

-- Товары
INSERT INTO products (name, description) VALUES ('Bread', 'Premium wheat bread');
INSERT INTO products (name, description) VALUES ('Milk', 'Cow milk 3.2% fat');
INSERT INTO products (name, description) VALUES ('Cheese', 'Aged cheddar cheese');
INSERT INTO products (name, description) VALUES ('Sausage', 'Boiled sausage');
INSERT INTO products (name, description) VALUES ('Cookies', 'Sandwich cookies');
INSERT INTO products (name, description) VALUES ('Tea', 'Black tea');
INSERT INTO products (name, description) VALUES ('Coffee', 'Ground coffee');
INSERT INTO products (name, description) VALUES ('Sugar', 'Granulated sugar');
INSERT INTO products (name, description) VALUES ('Butter', 'Sunflower butter');
INSERT INTO products (name, description) VALUES ('Cereal', 'Rice cereal');

-- Торговые точки
INSERT INTO retail_outlets (name, type, address, area, rent, utilities, counters_count) VALUES
('Walmart "Central"', 'department_store', 'ul. Centralnaya, 1', 1500, 150000, 50000, 25);
INSERT INTO retail_outlets (name, type, address, area, rent, utilities, counters_count) VALUES
('7-Eleven "Moscow"', 'grocery_store', 'ul. Moskovskaya, 10', 300, 45000, 15000, 8);
INSERT INTO retail_outlets (name, type, address, area, rent, utilities, counters_count) VALUES
('Starbucks "Home Corner"', 'kiosk', 'ul. Lenina, 25', 15, 10000, 3000, 2);
INSERT INTO retail_outlets (name, type, address, area, rent, utilities, counters_count) VALUES
('Apple Store "Market"', 'stall', 'ul. Rynochnaya, 5', 5, 5000, 1000, 1);
INSERT INTO retail_outlets (name, type, address, area, rent, utilities, counters_count) VALUES
('Costco "North"', 'department_store', 'ul. Severnaya, 15', 1200, 120000, 40000, 20);
INSERT INTO retail_outlets (name, type, address, area, rent, utilities, counters_count) VALUES
('Whole Foods "South"', 'grocery_store', 'ul. Yuzhnaya, 8', 250, 35000, 12000, 6);

-- Продавцы
INSERT INTO sellers (full_name, retail_outlet_id, salary_rate) VALUES ('Tony Stark', 1, 45000);
INSERT INTO sellers (full_name, retail_outlet_id, salary_rate) VALUES ('Peter Parker', 1, 42000);
INSERT INTO sellers (full_name, retail_outlet_id, salary_rate) VALUES ('Bruce Wayne', 2, 38000);
INSERT INTO sellers (full_name, retail_outlet_id, salary_rate) VALUES ('Clark Kent', 3, 30000);
INSERT INTO sellers (full_name, retail_outlet_id, salary_rate) VALUES ('Steve Rogers', 4, 25000);
INSERT INTO sellers (full_name, retail_outlet_id, salary_rate) VALUES ('Natasha Romanoff', 5, 44000);
INSERT INTO sellers (full_name, retail_outlet_id, salary_rate) VALUES ('Thor Odinson', 6, 36000);
INSERT INTO sellers (full_name, retail_outlet_id, salary_rate) VALUES ('Bruce Banner', 1, 43000);
INSERT INTO sellers (full_name, retail_outlet_id, salary_rate) VALUES ('Wanda Maximoff', 5, 43500);
INSERT INTO sellers (full_name, retail_outlet_id, salary_rate) VALUES ('Stephen Strange', 2, 37500);

-- Секции
INSERT INTO sections (retail_outlet_id, name, floor, manager_id) VALUES (1, 'Groceries', 1, 1);
INSERT INTO sections (retail_outlet_id, name, floor, manager_id) VALUES (1, 'Household Chemicals', 1, 2);
INSERT INTO sections (retail_outlet_id, name, floor, manager_id) VALUES (1, 'Clothing', 2, 8);
INSERT INTO sections (retail_outlet_id, name, floor, manager_id) VALUES (5, 'Groceries', 1, 6);
INSERT INTO sections (retail_outlet_id, name, floor, manager_id) VALUES (5, 'Home Goods', 2, 9);

-- Покупатели
INSERT INTO customers (full_name, characteristics) VALUES
('Elon Musk', '{"age": 35, "gender": "male", "phone": "+79001234567"}');
INSERT INTO customers (full_name, characteristics) VALUES
('Taylor Swift', '{"age": 28, "gender": "female", "phone": "+79002345678"}');
INSERT INTO customers (full_name, characteristics) VALUES
('Jeff Bezos', '{"age": 42, "gender": "male", "phone": "+79003456789"}');
INSERT INTO customers (full_name, characteristics) VALUES
('Emma Watson', '{"age": 31, "gender": "female", "phone": "+79004567890"}');

-- Заказы
INSERT INTO orders (supplier_id, "date", status) VALUES (1, TIMESTAMP '2025-01-15 09:00:00', 'received');
INSERT INTO orders (supplier_id, "date", status) VALUES (2, TIMESTAMP '2025-01-16 10:30:00', 'received');
INSERT INTO orders (supplier_id, "date", status) VALUES (3, TIMESTAMP '2025-01-17 11:15:00', 'sent');
INSERT INTO orders (supplier_id, "date", status) VALUES (1, TIMESTAMP '2025-01-18 08:45:00', 'created');
INSERT INTO orders (supplier_id, "date", status) VALUES (4, TIMESTAMP '2025-01-19 14:20:00', 'canceled');

-- Детали заказов
INSERT INTO order_details (order_id, product_id, quantity, price) VALUES (1, 1, 100, 30);
INSERT INTO order_details (order_id, product_id, quantity, price) VALUES (1, 2, 50, 75);
INSERT INTO order_details (order_id, product_id, quantity, price) VALUES (2, 2, 80, 70);
INSERT INTO order_details (order_id, product_id, quantity, price) VALUES (2, 3, 30, 400);
INSERT INTO order_details (order_id, product_id, quantity, price) VALUES (3, 4, 40, 350);
INSERT INTO order_details (order_id, product_id, quantity, price) VALUES (4, 5, 60, 120);
INSERT INTO order_details (order_id, product_id, quantity, price) VALUES (5, 6, 25, 300);

-- Продажи
INSERT INTO sales ("date", product_id, quantity, sale_price, seller_id, retail_outlet_id, customer_id) VALUES
(TIMESTAMP '2025-01-15 10:15:00', 1, 2, 45, 1, 1, 1);
INSERT INTO sales ("date", product_id, quantity, sale_price, seller_id, retail_outlet_id, customer_id) VALUES
(TIMESTAMP '2025-01-15 11:30:00', 2, 1, 95, 2, 1, 2);
INSERT INTO sales ("date", product_id, quantity, sale_price, seller_id, retail_outlet_id, customer_id) VALUES
(TIMESTAMP '2025-01-16 09:45:00', 3, 0.5, 550, 1, 1, 3);
INSERT INTO sales ("date", product_id, quantity, sale_price, seller_id, retail_outlet_id, customer_id) VALUES
(TIMESTAMP '2025-01-16 14:20:00', 6, 1, 350, 8, 1, 4);
INSERT INTO sales ("date", product_id, quantity, sale_price, seller_id, retail_outlet_id, customer_id) VALUES
(TIMESTAMP '2025-01-15 12:10:00', 1, 1, 40, 3, 2, 1);
INSERT INTO sales ("date", product_id, quantity, sale_price, seller_id, retail_outlet_id, customer_id) VALUES
(TIMESTAMP '2025-01-16 15:45:00', 4, 0.3, 450, 10, 2, 2);
INSERT INTO sales ("date", product_id, quantity, sale_price, seller_id, retail_outlet_id, customer_id) VALUES
(TIMESTAMP '2025-01-15 16:30:00', 1, 1, 50, 4, 3, NULL);
INSERT INTO sales ("date", product_id, quantity, sale_price, seller_id, retail_outlet_id, customer_id) VALUES
(TIMESTAMP '2025-01-16 17:15:00', 5, 2, 80, 4, 3, NULL);
INSERT INTO sales ("date", product_id, quantity, sale_price, seller_id, retail_outlet_id, customer_id) VALUES
(TIMESTAMP '2025-01-15 18:00:00', 9, 1, 150, 5, 4, NULL);
INSERT INTO sales ("date", product_id, quantity, sale_price, seller_id, retail_outlet_id, customer_id) VALUES
(TIMESTAMP '2025-01-16 19:30:00', 10, 2, 120, 5, 4, NULL);

COMMIT;

PROMPT >>> Схема и данные созданы успешно.
