DECLARE
  v_cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt 
  FROM user_constraints 
  WHERE table_name = 'S_EMP' 
    AND constraint_name LIKE '%COMMISSION_PCT%';
    
  IF v_cnt > 0 THEN
    FOR rec IN (SELECT constraint_name FROM user_constraints 
                WHERE table_name = 'S_EMP' 
                  AND constraint_name LIKE '%COMMISSION_PCT%') LOOP
      EXECUTE IMMEDIATE 'ALTER TABLE s_emp DROP CONSTRAINT ' || rec.constraint_name;
      DBMS_OUTPUT.PUT_LINE('Ограничение ' || rec.constraint_name || ' удалено.');
    END LOOP;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Ограничение для COMMISSION_PCT не найдено — пропускаем.');
  END IF;
END;
/


DROP TABLE ZAKAZ PURGE;
CREATE TABLE ZAKAZ (
    id NUMBER PRIMARY KEY,
    customer_id NUMBER,
    order_id NUMBER,
    product_id NUMBER,
    quantity NUMBER,
    comments VARCHAR2(100)  -- ← КРИТИЧЕСКИ ВАЖНО
);

DROP SEQUENCE seq_zakaz;
CREATE SEQUENCE seq_zakaz START WITH 1;

DROP TABLE STAG PURGE;
CREATE TABLE STAG (
    id NUMBER PRIMARY KEY,
    emp_id NUMBER,
    fio VARCHAR2(100),
    count_ord NUMBER,
    sum_ord NUMBER,
    commentar VARCHAR2(200)
);

DROP SEQUENCE seq_stag;
CREATE SEQUENCE seq_stag START WITH 1;


CREATE OR REPLACE PROCEDURE SET_COMM(p_emp_id IN NUMBER) IS
    v_total_sales NUMBER := 0;
    v_commission_pct NUMBER;
BEGIN
    SELECT NVL(SUM(total), 0) INTO v_total_sales
    FROM s_ord
    WHERE sales_rep_id = p_emp_id;
    
    IF v_total_sales = 0 THEN
        v_commission_pct := 0;
        DBMS_OUTPUT.PUT_LINE('У служащего с ID=' || p_emp_id || ' нет заказов. Комиссия = 0%.');
    ELSIF v_total_sales < 10000 THEN
        v_commission_pct := 10;
        DBMS_OUTPUT.PUT_LINE('Сумма продаж = ' || v_total_sales || '. Комиссия = 10%.');
    ELSIF v_total_sales <= 1000000 THEN
        v_commission_pct := 15;
        DBMS_OUTPUT.PUT_LINE('Сумма продаж = ' || v_total_sales || '. Комиссия = 15%.');
    ELSE
        v_commission_pct := 15;
        DBMS_OUTPUT.PUT_LINE('Сумма продаж = ' || v_total_sales || '. Комиссия = 15%.');
    END IF;
    
    UPDATE s_emp SET commission_pct = v_commission_pct WHERE id = p_emp_id;
    
    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Служащий с ID=' || p_emp_id || ' не найден.');
    ELSE
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Комиссия для служащего ID=' || p_emp_id || ' обновлена на ' || v_commission_pct || '%.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Ошибка SET_COMM: ' || SQLERRM);
        RAISE;
END SET_COMM;
/


CREATE OR REPLACE PROCEDURE CUST_UPDATE IS
    v_updated_count NUMBER := 0;
    v_credit_rating VARCHAR2(20);
    CURSOR c_customers IS SELECT id, region_id FROM s_customer FOR UPDATE;
    v_customer c_customers%ROWTYPE;
BEGIN
    OPEN c_customers;
    LOOP
        FETCH c_customers INTO v_customer;
        EXIT WHEN c_customers%NOTFOUND;
        IF MOD(v_customer.region_id, 2) = 0 THEN
            v_credit_rating := 'Excellent';
        ELSE
            v_credit_rating := 'Good';
        END IF;
        UPDATE s_customer SET credit_rating = v_credit_rating WHERE CURRENT OF c_customers;
        v_updated_count := v_updated_count + 1;
    END LOOP;
    CLOSE c_customers;
    DBMS_OUTPUT.PUT_LINE('Обновлено ' || v_updated_count || ' заказчиков.');
    DBMS_OUTPUT.PUT_LINE('ВНИМАНИЕ: Изменения НЕ зафиксированы (нет COMMIT).');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка CUST_UPDATE: ' || SQLERRM);
        RAISE;
END CUST_UPDATE;
/


CREATE OR REPLACE FUNCTION CALC_EMPLOYMENT(p_start_date IN DATE, p_flag IN VARCHAR2) 
RETURN VARCHAR2 IS
    v_years NUMBER;
    v_anniversary_date DATE;
BEGIN
    v_years := TRUNC(MONTHS_BETWEEN(SYSDATE, p_start_date) / 12);
    v_anniversary_date := ADD_MONTHS(p_start_date, 120);
    IF UPPER(p_flag) = 'YEARS' THEN
        RETURN TO_CHAR(v_years);
    ELSIF UPPER(p_flag) = 'DATE' THEN
        RETURN TO_CHAR(v_anniversary_date, 'DD.MM.YYYY');
    ELSE
        RETURN 'Ошибка: флаг должен быть YEARS или DATE';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Ошибка: ' || SQLERRM;
END CALC_EMPLOYMENT;
/


CREATE OR REPLACE PROCEDURE ZAKAZ_P IS
    v_total_customers NUMBER;
    v_updated_customers NUMBER := 0;
    v_out_region_count NUMBER;
    CURSOR c_customers IS
        SELECT c.id AS customer_id, o.id AS order_id, i.product_id, i.quantity, r.name AS region_name
        FROM s_customer c
        JOIN s_ord o ON c.id = o.customer_id
        JOIN s_item i ON o.id = i.ord_id
        JOIN s_region r ON c.region_id = r.id
        WHERE c.id IN (SELECT customer_id FROM s_ord GROUP BY customer_id HAVING SUM(total) > 50000);
    v_customer c_customers%ROWTYPE;
    v_comment VARCHAR2(100);
BEGIN
    SELECT COUNT(*) INTO v_total_customers FROM (SELECT customer_id FROM s_ord GROUP BY customer_id HAVING SUM(total) > 50000);
    OPEN c_customers;
    LOOP
        FETCH c_customers INTO v_customer;
        EXIT WHEN c_customers%NOTFOUND;
        IF UPPER(v_customer.region_name) = 'EUROPE' THEN
            v_comment := NULL;
        ELSE
            v_comment := 'out region';
        END IF;
        INSERT INTO ZAKAZ (id, customer_id, order_id, product_id, quantity, comments)
        VALUES (seq_zakaz.NEXTVAL, v_customer.customer_id, v_customer.order_id, v_customer.product_id, v_customer.quantity, v_comment);
        v_updated_customers := v_updated_customers + 1;
    END LOOP;
    CLOSE c_customers;
    SELECT COUNT(*) INTO v_out_region_count FROM ZAKAZ WHERE comments = 'out region';
    IF v_updated_customers = v_out_region_count AND v_updated_customers > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Нет заказчиков из европейского региона.');
    END IF;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('В таблицу ZAKAZ внесено ' || v_updated_customers || ' записей.');
    DBMS_OUTPUT.PUT_LINE('Из них "out region": ' || v_out_region_count);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Ошибка ZAKAZ_P: ' || SQLERRM);
        RAISE;
END ZAKAZ_P;
/


CREATE OR REPLACE PROCEDURE PROCESS_EMPLOYEES IS
    v_start_date DATE;
    v_years NUMBER;
    v_anniversary_date DATE;
    v_years_to_anniversary NUMBER;
    CURSOR c_stag IS SELECT id, emp_id FROM STAG FOR UPDATE;
    v_record c_stag%ROWTYPE;
BEGIN
    -- Заполнение таблицы STAG
    INSERT INTO STAG (id, emp_id, fio, count_ord, sum_ord, commentar)
    SELECT seq_stag.NEXTVAL, emp_data.emp_id, emp_data.fio, emp_data.count_ord, emp_data.sum_ord, NULL
    FROM (SELECT e.id AS emp_id, e.last_name || ' ' || e.first_name AS fio, COUNT(o.id) AS count_ord, NVL(SUM(o.total), 0) AS sum_ord
          FROM s_emp e LEFT JOIN s_ord o ON e.id = o.sales_rep_id GROUP BY e.id, e.last_name, e.first_name, e.start_date) emp_data;
    
    DBMS_OUTPUT.PUT_LINE('В таблицу STAG внесено ' || SQL%ROWCOUNT || ' сотрудников.');
    
    -- Обработка комментариев 
    OPEN c_stag;
    LOOP
        FETCH c_stag INTO v_record;
        EXIT WHEN c_stag%NOTFOUND;
        
        SELECT start_date INTO v_start_date FROM s_emp WHERE id = v_record.emp_id;
        v_years := TRUNC(MONTHS_BETWEEN(SYSDATE, v_start_date) / 12);
        
        IF MOD(v_record.id, 2) = 0 THEN
            -- Чётные: стаж в годах
            UPDATE STAG SET commentar = 'стаж ' || v_years || ' лет' WHERE CURRENT OF c_stag;
        ELSE
            -- Нечётные: время до 10-летия 
            v_anniversary_date := ADD_MONTHS(v_start_date, 120);
            v_years_to_anniversary := TRUNC(MONTHS_BETWEEN(v_anniversary_date, SYSDATE) / 12);
            
            IF v_years_to_anniversary <= 0 THEN
                UPDATE STAG SET commentar = 'стаж превышает 10 лет (' || v_years || ' лет)' WHERE CURRENT OF c_stag;
            ELSE
                UPDATE STAG SET commentar = 'До 10-тилетия раб. деят. осталось ' || v_years_to_anniversary || ' лет' WHERE CURRENT OF c_stag;
            END IF;
        END IF;
    END LOOP;
    CLOSE c_stag;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Обработка сотрудников завершена.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Ошибка PROCESS_EMPLOYEES: ' || SQLERRM);
        RAISE;
END PROCESS_EMPLOYEES;
/







SET SERVEROUTPUT ON SIZE 1000000;

-- Тест 1: Процедура SET_COMM
-- Служащий с заказами
EXEC SET_COMM(11);


-- Служащий без заказов
EXEC SET_COMM(5);

-- Тест 2: Процедура CUST_UPDATE (без фиксации!)
EXEC CUST_UPDATE;
SELECT id, name, region_id, credit_rating FROM s_customer WHERE ROWNUM <= 5;
ROLLBACK;  -- Отмена изменений

-- Тест 3: Функция CALC_EMPLOYMENT
SELECT 
  CALC_EMPLOYMENT(DATE '1990-03-03', 'YEARS') AS "Стаж_лет",
  CALC_EMPLOYMENT(DATE '1990-03-03', 'DATE') AS "Дата_10летия"
FROM DUAL;

-- Тест 4: Процедура ZAKAZ_P
EXEC ZAKAZ_P;
SELECT * FROM ZAKAZ;

-- Тест 5: Процедура PROCESS_EMPLOYEES
EXEC PROCESS_EMPLOYEES;
SELECT * FROM STAG;