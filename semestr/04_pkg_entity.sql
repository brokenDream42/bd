-- ============================================================
-- Часть 4: Процедуры для 3-х сущностей SELLERS, CUSTOMERS, SALES
-- ============================================================

-- ===================================================
-- SELLERS
-- ===================================================

CREATE OR REPLACE PROCEDURE add_seller(
    p_full_name IN VARCHAR2,
    p_retail_outlet_id IN NUMBER,
    p_salary_rate IN NUMBER,
    p_id OUT NUMBER
) IS
BEGIN
    INSERT INTO sellers (full_name, retail_outlet_id, salary_rate)
    VALUES (p_full_name, p_retail_outlet_id, p_salary_rate)
    RETURNING id INTO p_id;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20011, 'Продавец с такими данными уже существует');
    WHEN VALUE_ERROR THEN
        RAISE_APPLICATION_ERROR(-20012, 'Неверный формат данных при добавлении продавца');
END add_seller;
/

CREATE OR REPLACE PROCEDURE upd_seller(
    p_id IN NUMBER,
    p_full_name IN VARCHAR2,
    p_retail_outlet_id IN NUMBER,
    p_salary_rate IN NUMBER
) IS
BEGIN
    UPDATE sellers
    SET full_name = p_full_name,
        retail_outlet_id = p_retail_outlet_id,
        salary_rate = p_salary_rate
    WHERE id = p_id;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Продавец с ID=' || p_id || ' не найден');
    END IF;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20013, 'Дублирующие данные при обновлении продавца');
END upd_seller;
/

CREATE OR REPLACE PROCEDURE del_seller(p_id IN NUMBER) IS
BEGIN
    DELETE FROM sellers WHERE id = p_id;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Продавец с ID=' || p_id || ' не найден');
    END IF;
END del_seller;
/

-- ===================================================
-- CUSTOMERS
-- ===================================================

CREATE OR REPLACE PROCEDURE add_customer(
    p_full_name IN VARCHAR2,
    p_characteristics IN VARCHAR2,
    p_id OUT NUMBER
) IS
BEGIN
    INSERT INTO customers (full_name, characteristics)
    VALUES (p_full_name, p_characteristics)
    RETURNING id INTO p_id;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20021, 'Покупатель с такими данными уже существует');
    WHEN VALUE_ERROR THEN
        RAISE_APPLICATION_ERROR(-20022, 'Неверный формат данных при добавлении покупателя');
END add_customer;
/

CREATE OR REPLACE PROCEDURE upd_customer(
    p_id IN NUMBER,
    p_full_name IN VARCHAR2,
    p_characteristics IN VARCHAR2
) IS
BEGIN
    UPDATE customers
    SET full_name = p_full_name,
        characteristics = p_characteristics
    WHERE id = p_id;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Покупатель с ID=' || p_id || ' не найден');
    END IF;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20023, 'Дублирующие данные при обновлении покупателя');
END upd_customer;
/

CREATE OR REPLACE PROCEDURE del_customer(p_id IN NUMBER) IS
BEGIN
    DELETE FROM customers WHERE id = p_id;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Покупатель с ID=' || p_id || ' не найден');
    END IF;
END del_customer;
/

-- ===================================================
-- SALES
-- ===================================================

CREATE OR REPLACE PROCEDURE add_sale(
    p_product_id IN NUMBER,
    p_quantity IN NUMBER,
    p_sale_price IN NUMBER,
    p_seller_id IN NUMBER,
    p_retail_outlet_id IN NUMBER,
    p_customer_id IN NUMBER,
    p_id OUT NUMBER
) IS
BEGIN
    INSERT INTO sales (product_id, quantity, sale_price, seller_id, retail_outlet_id, customer_id)
    VALUES (p_product_id, p_quantity, p_sale_price, p_seller_id, p_retail_outlet_id, p_customer_id)
    RETURNING id INTO p_id;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20031, 'Продажа с такими данными уже существует');
    WHEN VALUE_ERROR THEN
        RAISE_APPLICATION_ERROR(-20032, 'Неверный формат данных при добавлении продажи');
END add_sale;
/

CREATE OR REPLACE PROCEDURE upd_sale(
    p_id IN NUMBER,
    p_product_id IN NUMBER,
    p_quantity IN NUMBER,
    p_sale_price IN NUMBER,
    p_seller_id IN NUMBER,
    p_retail_outlet_id IN NUMBER,
    p_customer_id IN NUMBER
) IS
BEGIN
    UPDATE sales
    SET product_id = p_product_id,
        quantity = p_quantity,
        sale_price = p_sale_price,
        seller_id = p_seller_id,
        retail_outlet_id = p_retail_outlet_id,
        customer_id = p_customer_id
    WHERE id = p_id;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Продажа с ID=' || p_id || ' не найдена');
    END IF;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20033, 'Дублирующие данные при обновлении продажи');
END upd_sale;
/

CREATE OR REPLACE PROCEDURE del_sale(p_id IN NUMBER) IS
BEGIN
    DELETE FROM sales WHERE id = p_id;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20006, 'Продажа с ID=' || p_id || ' не найдена');
    END IF;
END del_sale;
/

PROMPT >>> Процедуры созданы.
