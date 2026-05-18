-- ============================================================
-- Часть 3: Триггеры автоматического логирования
-- Для таблиц: SELLERS, CUSTOMERS, SALES
-- Тип триггера: AFTER INSERT OR UPDATE OR DELETE
-- Формат данных: KEY=VALUE|KEY2=VALUE2 (как в 5-й лабе)
-- ============================================================

PROMPT >>> Создание триггера для SELLERS...

CREATE OR REPLACE TRIGGER trg_sellers_audit
    AFTER INSERT OR UPDATE OR DELETE ON sellers
    FOR EACH ROW
DECLARE
    v_old VARCHAR2(4000);
    v_new VARCHAR2(4000);
BEGIN
    IF NOT INSERTING THEN
        v_old := 'ID='||:OLD.id||
            '|FULL_NAME='||:OLD.full_name||
            '|RETAIL_OUTLET_ID='||NVL(TO_CHAR(:OLD.retail_outlet_id),'NULL')||
            '|SALARY_RATE='||NVL(TO_CHAR(:OLD.salary_rate),'NULL');
    END IF;
    IF NOT DELETING THEN
        v_new := 'ID='||:NEW.id||
            '|FULL_NAME='||:NEW.full_name||
            '|RETAIL_OUTLET_ID='||NVL(TO_CHAR(:NEW.retail_outlet_id),'NULL')||
            '|SALARY_RATE='||NVL(TO_CHAR(:NEW.salary_rate),'NULL');
    END IF;

    IF INSERTING THEN
        INSERT INTO audit_log (table_name, operation, record_pk, old_data, new_data)
        VALUES ('SELLERS', 'INSERT', :NEW.id, NULL, v_new);
    ELSIF UPDATING THEN
        INSERT INTO audit_log (table_name, operation, record_pk, old_data, new_data)
        VALUES ('SELLERS', 'UPDATE', :NEW.id, v_old, v_new);
    ELSIF DELETING THEN
        INSERT INTO audit_log (table_name, operation, record_pk, old_data, new_data)
        VALUES ('SELLERS', 'DELETE', :OLD.id, v_old, NULL);
    END IF;
END;
/

PROMPT >>> Создание триггера для CUSTOMERS...

CREATE OR REPLACE TRIGGER trg_customers_audit
    AFTER INSERT OR UPDATE OR DELETE ON customers
    FOR EACH ROW
DECLARE
    v_old VARCHAR2(4000);
    v_new VARCHAR2(4000);
BEGIN
    IF NOT INSERTING THEN
        v_old := 'ID='||:OLD.id||
            '|FULL_NAME='||:OLD.full_name||
            '|CHARACTERISTICS='||NVL(:OLD.characteristics,'NULL');
    END IF;
    IF NOT DELETING THEN
        v_new := 'ID='||:NEW.id||
            '|FULL_NAME='||:NEW.full_name||
            '|CHARACTERISTICS='||NVL(:NEW.characteristics,'NULL');
    END IF;

    IF INSERTING THEN
        INSERT INTO audit_log (table_name, operation, record_pk, old_data, new_data)
        VALUES ('CUSTOMERS', 'INSERT', :NEW.id, NULL, v_new);
    ELSIF UPDATING THEN
        INSERT INTO audit_log (table_name, operation, record_pk, old_data, new_data)
        VALUES ('CUSTOMERS', 'UPDATE', :NEW.id, v_old, v_new);
    ELSIF DELETING THEN
        INSERT INTO audit_log (table_name, operation, record_pk, old_data, new_data)
        VALUES ('CUSTOMERS', 'DELETE', :OLD.id, v_old, NULL);
    END IF;
END;
/

PROMPT >>> Создание триггера для SALES...

CREATE OR REPLACE TRIGGER trg_sales_audit
    AFTER INSERT OR UPDATE OR DELETE ON sales
    FOR EACH ROW
DECLARE
    v_old VARCHAR2(4000);
    v_new VARCHAR2(4000);
BEGIN
    IF NOT INSERTING THEN
        v_old := 'ID='||:OLD.id||
            '|DATE='||NVL(TO_CHAR(:OLD."date",'DD.MM.YYYY HH24:MI:SS'),'NULL')||
            '|PRODUCT_ID='||NVL(TO_CHAR(:OLD.product_id),'NULL')||
            '|QUANTITY='||NVL(TO_CHAR(:OLD.quantity),'NULL')||
            '|SALE_PRICE='||NVL(TO_CHAR(:OLD.sale_price),'NULL')||
            '|SELLER_ID='||NVL(TO_CHAR(:OLD.seller_id),'NULL')||
            '|RETAIL_OUTLET_ID='||NVL(TO_CHAR(:OLD.retail_outlet_id),'NULL')||
            '|CUSTOMER_ID='||NVL(TO_CHAR(:OLD.customer_id),'NULL');
    END IF;
    IF NOT DELETING THEN
        v_new := 'ID='||:NEW.id||
            '|DATE='||NVL(TO_CHAR(:NEW."date",'DD.MM.YYYY HH24:MI:SS'),'NULL')||
            '|PRODUCT_ID='||NVL(TO_CHAR(:NEW.product_id),'NULL')||
            '|QUANTITY='||NVL(TO_CHAR(:NEW.quantity),'NULL')||
            '|SALE_PRICE='||NVL(TO_CHAR(:NEW.sale_price),'NULL')||
            '|SELLER_ID='||NVL(TO_CHAR(:NEW.seller_id),'NULL')||
            '|RETAIL_OUTLET_ID='||NVL(TO_CHAR(:NEW.retail_outlet_id),'NULL')||
            '|CUSTOMER_ID='||NVL(TO_CHAR(:NEW.customer_id),'NULL');
    END IF;

    IF INSERTING THEN
        INSERT INTO audit_log (table_name, operation, record_pk, old_data, new_data)
        VALUES ('SALES', 'INSERT', :NEW.id, NULL, v_new);
    ELSIF UPDATING THEN
        INSERT INTO audit_log (table_name, operation, record_pk, old_data, new_data)
        VALUES ('SALES', 'UPDATE', :NEW.id, v_old, v_new);
    ELSIF DELETING THEN
        INSERT INTO audit_log (table_name, operation, record_pk, old_data, new_data)
        VALUES ('SALES', 'DELETE', :OLD.id, v_old, NULL);
    END IF;
END;
/

PROMPT >>> Все триггеры созданы.
