-- ============================================================
-- Часть 3: Триггеры автоматического логирования
-- Для таблиц: SELLERS, CUSTOMERS, SALES
-- Тип триггера: AFTER INSERT OR UPDATE OR DELETE
-- (AFTER гарантирует, что GENERATED IDENTITY уже заполнено при INSERT)
-- ============================================================

PROMPT >>> Создание триггера для SELLERS...

CREATE OR REPLACE TRIGGER trg_sellers_audit
    AFTER INSERT OR UPDATE OR DELETE ON sellers
    FOR EACH ROW
DECLARE
    v_old_data CLOB;
    v_new_data CLOB;
BEGIN
    IF INSERTING THEN
        v_new_data := JSON_OBJECT(
            'id'               VALUE :NEW.id,
            'full_name'        VALUE :NEW.full_name,
            'retail_outlet_id' VALUE :NEW.retail_outlet_id,
            'salary_rate'      VALUE :NEW.salary_rate
        );
        INSERT INTO audit_log (table_name, operation, record_pk, old_data, new_data)
        VALUES ('SELLERS', 'INSERT', :NEW.id, NULL, v_new_data);

    ELSIF UPDATING THEN
        v_old_data := JSON_OBJECT(
            'id'               VALUE :OLD.id,
            'full_name'        VALUE :OLD.full_name,
            'retail_outlet_id' VALUE :OLD.retail_outlet_id,
            'salary_rate'      VALUE :OLD.salary_rate
        );
        v_new_data := JSON_OBJECT(
            'id'               VALUE :NEW.id,
            'full_name'        VALUE :NEW.full_name,
            'retail_outlet_id' VALUE :NEW.retail_outlet_id,
            'salary_rate'      VALUE :NEW.salary_rate
        );
        INSERT INTO audit_log (table_name, operation, record_pk, old_data, new_data)
        VALUES ('SELLERS', 'UPDATE', :NEW.id, v_old_data, v_new_data);

    ELSIF DELETING THEN
        v_old_data := JSON_OBJECT(
            'id'               VALUE :OLD.id,
            'full_name'        VALUE :OLD.full_name,
            'retail_outlet_id' VALUE :OLD.retail_outlet_id,
            'salary_rate'      VALUE :OLD.salary_rate
        );
        INSERT INTO audit_log (table_name, operation, record_pk, old_data, new_data)
        VALUES ('SELLERS', 'DELETE', :OLD.id, v_old_data, NULL);
    END IF;
END;
/

PROMPT >>> Создание триггера для CUSTOMERS...

CREATE OR REPLACE TRIGGER trg_customers_audit
    AFTER INSERT OR UPDATE OR DELETE ON customers
    FOR EACH ROW
DECLARE
    v_old_data CLOB;
    v_new_data CLOB;
BEGIN
    IF INSERTING THEN
        v_new_data := JSON_OBJECT(
            'id'               VALUE :NEW.id,
            'full_name'        VALUE :NEW.full_name,
            'characteristics'  VALUE :NEW.characteristics
        );
        INSERT INTO audit_log (table_name, operation, record_pk, old_data, new_data)
        VALUES ('CUSTOMERS', 'INSERT', :NEW.id, NULL, v_new_data);

    ELSIF UPDATING THEN
        v_old_data := JSON_OBJECT(
            'id'               VALUE :OLD.id,
            'full_name'        VALUE :OLD.full_name,
            'characteristics'  VALUE :OLD.characteristics
        );
        v_new_data := JSON_OBJECT(
            'id'               VALUE :NEW.id,
            'full_name'        VALUE :NEW.full_name,
            'characteristics'  VALUE :NEW.characteristics
        );
        INSERT INTO audit_log (table_name, operation, record_pk, old_data, new_data)
        VALUES ('CUSTOMERS', 'UPDATE', :NEW.id, v_old_data, v_new_data);

    ELSIF DELETING THEN
        v_old_data := JSON_OBJECT(
            'id'               VALUE :OLD.id,
            'full_name'        VALUE :OLD.full_name,
            'characteristics'  VALUE :OLD.characteristics
        );
        INSERT INTO audit_log (table_name, operation, record_pk, old_data, new_data)
        VALUES ('CUSTOMERS', 'DELETE', :OLD.id, v_old_data, NULL);
    END IF;
END;
/

PROMPT >>> Создание триггера для SALES...

CREATE OR REPLACE TRIGGER trg_sales_audit
    AFTER INSERT OR UPDATE OR DELETE ON sales
    FOR EACH ROW
DECLARE
    v_old_data CLOB;
    v_new_data CLOB;
BEGIN
    IF INSERTING THEN
        v_new_data := JSON_OBJECT(
            'id'               VALUE :NEW.id,
            'date'             VALUE :NEW."date",
            'product_id'       VALUE :NEW.product_id,
            'quantity'         VALUE :NEW.quantity,
            'sale_price'       VALUE :NEW.sale_price,
            'seller_id'        VALUE :NEW.seller_id,
            'retail_outlet_id' VALUE :NEW.retail_outlet_id,
            'customer_id'      VALUE :NEW.customer_id
        );
        INSERT INTO audit_log (table_name, operation, record_pk, old_data, new_data)
        VALUES ('SALES', 'INSERT', :NEW.id, NULL, v_new_data);

    ELSIF UPDATING THEN
        v_old_data := JSON_OBJECT(
            'id'               VALUE :OLD.id,
            'date'             VALUE :OLD."date",
            'product_id'       VALUE :OLD.product_id,
            'quantity'         VALUE :OLD.quantity,
            'sale_price'       VALUE :OLD.sale_price,
            'seller_id'        VALUE :OLD.seller_id,
            'retail_outlet_id' VALUE :OLD.retail_outlet_id,
            'customer_id'      VALUE :OLD.customer_id
        );
        v_new_data := JSON_OBJECT(
            'id'               VALUE :NEW.id,
            'date'             VALUE :NEW."date",
            'product_id'       VALUE :NEW.product_id,
            'quantity'         VALUE :NEW.quantity,
            'sale_price'       VALUE :NEW.sale_price,
            'seller_id'        VALUE :NEW.seller_id,
            'retail_outlet_id' VALUE :NEW.retail_outlet_id,
            'customer_id'      VALUE :NEW.customer_id
        );
        INSERT INTO audit_log (table_name, operation, record_pk, old_data, new_data)
        VALUES ('SALES', 'UPDATE', :NEW.id, v_old_data, v_new_data);

    ELSIF DELETING THEN
        v_old_data := JSON_OBJECT(
            'id'               VALUE :OLD.id,
            'date'             VALUE :OLD."date",
            'product_id'       VALUE :OLD.product_id,
            'quantity'         VALUE :OLD.quantity,
            'sale_price'       VALUE :OLD.sale_price,
            'seller_id'        VALUE :OLD.seller_id,
            'retail_outlet_id' VALUE :OLD.retail_outlet_id,
            'customer_id'      VALUE :OLD.customer_id
        );
        INSERT INTO audit_log (table_name, operation, record_pk, old_data, new_data)
        VALUES ('SALES', 'DELETE', :OLD.id, v_old_data, NULL);
    END IF;
END;
/

PROMPT >>> Все триггеры созданы.
