-- ============================================================
-- Часть 5: Пакет для работы с журналом аудита
--   - Просмотр лога (фильтры по дате и типу операции)
--   - Откат операции (восстановление старого значения)
--   - Сводный отчет с сортировкой по 3 флагам
-- ============================================================

PROMPT >>> Создание заголовка пакета pkg_audit...

CREATE OR REPLACE PACKAGE pkg_audit IS
    PROCEDURE view_log(
        p_date_from IN TIMESTAMP DEFAULT NULL,
        p_date_to IN TIMESTAMP DEFAULT NULL,
        p_operation_type IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE rollback_operation(p_log_id IN NUMBER);

    FUNCTION get_report(
        p_flag1 IN NUMBER DEFAULT 0,
        p_flag2 IN NUMBER DEFAULT 0,
        p_flag3 IN NUMBER DEFAULT 0
    ) RETURN SYS_REFCURSOR;
END pkg_audit;
/

PROMPT >>> Создание тела пакета pkg_audit...

CREATE OR REPLACE PACKAGE BODY pkg_audit IS

    FUNCTION get_val(p_data VARCHAR2, p_key VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN REGEXP_SUBSTR(p_data, p_key || '=([^|]*)', 1, 1, NULL, 1);
    END get_val;

    PROCEDURE view_log(
        p_date_from IN TIMESTAMP DEFAULT NULL,
        p_date_to IN TIMESTAMP DEFAULT NULL,
        p_operation_type IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        FOR rec IN (
            SELECT id, table_name, operation, op_timestamp, record_pk, db_user
            FROM audit_log
            WHERE (p_date_from IS NULL OR op_timestamp >= p_date_from)
              AND (p_date_to IS NULL OR op_timestamp <= p_date_to)
              AND (p_operation_type IS NULL OR operation = p_operation_type)
            ORDER BY op_timestamp DESC
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(
                rec.id || ' | ' ||
                RPAD(rec.table_name, 10) || ' | ' ||
                RPAD(rec.operation, 6) || ' | ' ||
                TO_CHAR(rec.op_timestamp, 'DD.MM.YYYY HH24:MI:SS') || ' | PK=' ||
                rec.record_pk || ' | ' || rec.db_user
            );
        END LOOP;
    END;

    PROCEDURE rollback_operation(p_log_id IN NUMBER) IS
        v_rec audit_log%ROWTYPE;
        v_str VARCHAR2(4000);
        v_full_name VARCHAR2(255);
        v_retail_outlet_id NUMBER;
        v_salary_rate NUMBER;
        v_characteristics VARCHAR2(2000);
        v_date TIMESTAMP;
        v_product_id NUMBER;
        v_quantity NUMBER;
        v_sale_price NUMBER;
        v_seller_id NUMBER;
        v_retail_outlet_id_s NUMBER;
        v_customer_id NUMBER;
    BEGIN
        SELECT * INTO v_rec FROM audit_log WHERE id = p_log_id;

        IF v_rec.table_name = 'SELLERS' THEN
            IF v_rec.operation = 'DELETE' THEN
                v_str := get_val(v_rec.old_data, 'FULL_NAME');
                v_full_name := CASE WHEN v_str = 'NULL' THEN NULL ELSE v_str END;
                v_str := get_val(v_rec.old_data, 'RETAIL_OUTLET_ID');
                v_retail_outlet_id := CASE WHEN v_str = 'NULL' THEN NULL ELSE TO_NUMBER(v_str) END;
                v_str := get_val(v_rec.old_data, 'SALARY_RATE');
                v_salary_rate := CASE WHEN v_str = 'NULL' THEN NULL ELSE TO_NUMBER(v_str) END;

                INSERT INTO sellers (full_name, retail_outlet_id, salary_rate)
                VALUES (v_full_name, v_retail_outlet_id, v_salary_rate);

            ELSIF v_rec.operation = 'INSERT' THEN
                DELETE FROM sellers WHERE id = v_rec.record_pk;

            ELSIF v_rec.operation = 'UPDATE' THEN
                v_str := get_val(v_rec.old_data, 'FULL_NAME');
                v_full_name := CASE WHEN v_str = 'NULL' THEN NULL ELSE v_str END;
                v_str := get_val(v_rec.old_data, 'RETAIL_OUTLET_ID');
                v_retail_outlet_id := CASE WHEN v_str = 'NULL' THEN NULL ELSE TO_NUMBER(v_str) END;
                v_str := get_val(v_rec.old_data, 'SALARY_RATE');
                v_salary_rate := CASE WHEN v_str = 'NULL' THEN NULL ELSE TO_NUMBER(v_str) END;

                UPDATE sellers
                SET full_name = v_full_name,
                    retail_outlet_id = v_retail_outlet_id,
                    salary_rate = v_salary_rate
                WHERE id = v_rec.record_pk;
            END IF;

        ELSIF v_rec.table_name = 'CUSTOMERS' THEN
            IF v_rec.operation = 'DELETE' THEN
                v_str := get_val(v_rec.old_data, 'FULL_NAME');
                v_full_name := CASE WHEN v_str = 'NULL' THEN NULL ELSE v_str END;
                v_str := get_val(v_rec.old_data, 'CHARACTERISTICS');
                v_characteristics := CASE WHEN v_str = 'NULL' THEN NULL ELSE v_str END;

                INSERT INTO customers (full_name, characteristics)
                VALUES (v_full_name, v_characteristics);

            ELSIF v_rec.operation = 'INSERT' THEN
                DELETE FROM customers WHERE id = v_rec.record_pk;

            ELSIF v_rec.operation = 'UPDATE' THEN
                v_str := get_val(v_rec.old_data, 'FULL_NAME');
                v_full_name := CASE WHEN v_str = 'NULL' THEN NULL ELSE v_str END;
                v_str := get_val(v_rec.old_data, 'CHARACTERISTICS');
                v_characteristics := CASE WHEN v_str = 'NULL' THEN NULL ELSE v_str END;

                UPDATE customers
                SET full_name = v_full_name,
                    characteristics = v_characteristics
                WHERE id = v_rec.record_pk;
            END IF;

        ELSIF v_rec.table_name = 'SALES' THEN
            IF v_rec.operation = 'DELETE' THEN
                v_str := get_val(v_rec.old_data, 'DATE');
                v_date := CASE WHEN v_str = 'NULL' THEN NULL ELSE TO_TIMESTAMP(v_str, 'DD.MM.YYYY HH24:MI:SS') END;
                v_str := get_val(v_rec.old_data, 'PRODUCT_ID');
                v_product_id := CASE WHEN v_str = 'NULL' THEN NULL ELSE TO_NUMBER(v_str) END;
                v_str := get_val(v_rec.old_data, 'QUANTITY');
                v_quantity := CASE WHEN v_str = 'NULL' THEN NULL ELSE TO_NUMBER(v_str) END;
                v_str := get_val(v_rec.old_data, 'SALE_PRICE');
                v_sale_price := CASE WHEN v_str = 'NULL' THEN NULL ELSE TO_NUMBER(v_str) END;
                v_str := get_val(v_rec.old_data, 'SELLER_ID');
                v_seller_id := CASE WHEN v_str = 'NULL' THEN NULL ELSE TO_NUMBER(v_str) END;
                v_str := get_val(v_rec.old_data, 'RETAIL_OUTLET_ID');
                v_retail_outlet_id_s := CASE WHEN v_str = 'NULL' THEN NULL ELSE TO_NUMBER(v_str) END;
                v_str := get_val(v_rec.old_data, 'CUSTOMER_ID');
                v_customer_id := CASE WHEN v_str = 'NULL' THEN NULL ELSE TO_NUMBER(v_str) END;

                INSERT INTO sales ("date", product_id, quantity, sale_price, seller_id, retail_outlet_id, customer_id)
                VALUES (v_date, v_product_id, v_quantity, v_sale_price, v_seller_id, v_retail_outlet_id_s, v_customer_id);

            ELSIF v_rec.operation = 'INSERT' THEN
                DELETE FROM sales WHERE id = v_rec.record_pk;

            ELSIF v_rec.operation = 'UPDATE' THEN
                v_str := get_val(v_rec.old_data, 'DATE');
                v_date := CASE WHEN v_str = 'NULL' THEN NULL ELSE TO_TIMESTAMP(v_str, 'DD.MM.YYYY HH24:MI:SS') END;
                v_str := get_val(v_rec.old_data, 'PRODUCT_ID');
                v_product_id := CASE WHEN v_str = 'NULL' THEN NULL ELSE TO_NUMBER(v_str) END;
                v_str := get_val(v_rec.old_data, 'QUANTITY');
                v_quantity := CASE WHEN v_str = 'NULL' THEN NULL ELSE TO_NUMBER(v_str) END;
                v_str := get_val(v_rec.old_data, 'SALE_PRICE');
                v_sale_price := CASE WHEN v_str = 'NULL' THEN NULL ELSE TO_NUMBER(v_str) END;
                v_str := get_val(v_rec.old_data, 'SELLER_ID');
                v_seller_id := CASE WHEN v_str = 'NULL' THEN NULL ELSE TO_NUMBER(v_str) END;
                v_str := get_val(v_rec.old_data, 'RETAIL_OUTLET_ID');
                v_retail_outlet_id_s := CASE WHEN v_str = 'NULL' THEN NULL ELSE TO_NUMBER(v_str) END;
                v_str := get_val(v_rec.old_data, 'CUSTOMER_ID');
                v_customer_id := CASE WHEN v_str = 'NULL' THEN NULL ELSE TO_NUMBER(v_str) END;

                UPDATE sales
                SET "date" = v_date,
                    product_id = v_product_id,
                    quantity = v_quantity,
                    sale_price = v_sale_price,
                    seller_id = v_seller_id,
                    retail_outlet_id = v_retail_outlet_id_s,
                    customer_id = v_customer_id
                WHERE id = v_rec.record_pk;
            END IF;
        END IF;

        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20010, 'Запись лога с ID=' || p_log_id || ' не найдена');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20011, 'Ошибка при откате: ' || SQLERRM);
    END;

    FUNCTION get_report(
        p_flag1 IN NUMBER DEFAULT 0,
        p_flag2 IN NUMBER DEFAULT 0,
        p_flag3 IN NUMBER DEFAULT 0
    ) RETURN SYS_REFCURSOR IS
        v_cur SYS_REFCURSOR;
        v_sql VARCHAR2(2000);
        v_order VARCHAR2(500);
    BEGIN
        v_sql := 'SELECT table_name, operation, COUNT(*) as cnt FROM audit_log GROUP BY table_name, operation';

        IF p_flag1 = 1 THEN
            v_order := v_order || 'table_name, ';
        END IF;
        IF p_flag2 = 1 THEN
            v_order := v_order || 'operation, ';
        END IF;
        IF p_flag3 = 1 THEN
            v_order := v_order || 'cnt, ';
        END IF;

        IF v_order IS NOT NULL THEN
            v_sql := v_sql || ' ORDER BY ' || RTRIM(v_order, ', ');
        ELSE
            v_sql := v_sql || ' ORDER BY table_name, operation';
        END IF;

        OPEN v_cur FOR v_sql;
        RETURN v_cur;
    END;

END pkg_audit;
/

PROMPT >>> Пакет pkg_audit создан.
