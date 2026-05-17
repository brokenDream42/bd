-- ============================================================
-- Часть 5: Пакет для работы с журналом аудита
--   - Просмотр лога (фильтры по дате и типу операции)
--   - Откат операции (восстановление старого значения)
--   - Сводный отчет с сортировкой по 3 флагам
-- ============================================================

PROMPT >>> Создание спецификации пакета pkg_audit...

CREATE OR REPLACE PACKAGE pkg_audit IS
    -- Просмотр лога в DBMS_OUTPUT
    PROCEDURE view_log(
        p_date_from      IN TIMESTAMP DEFAULT NULL,
        p_date_to        IN TIMESTAMP DEFAULT NULL,
        p_operation_type IN VARCHAR2 DEFAULT NULL
    );

    -- Откат одной операции по ID записи из audit_log
    PROCEDURE rollback_operation(p_log_id IN NUMBER);

    -- Сводный отчет. Флаги: 1/0 (true/false)
    -- Приоритет сортировки: флаг 1 -> флаг 2 -> флаг 3
    FUNCTION get_report(
        p_flag1 IN NUMBER DEFAULT 0,
        p_flag2 IN NUMBER DEFAULT 0,
        p_flag3 IN NUMBER DEFAULT 0
    ) RETURN SYS_REFCURSOR;
END pkg_audit;
/

PROMPT >>> Создание тела пакета pkg_audit...

CREATE OR REPLACE PACKAGE BODY pkg_audit IS

    -- ===================================================
    -- Просмотр лога (DBMS_OUTPUT)
    -- ===================================================
    PROCEDURE view_log(
        p_date_from      IN TIMESTAMP DEFAULT NULL,
        p_date_to        IN TIMESTAMP DEFAULT NULL,
        p_operation_type IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        FOR rec IN (
            SELECT id,
                   table_name,
                   operation,
                   op_timestamp,
                   record_pk,
                   db_user
            FROM audit_log
            WHERE (p_date_from      IS NULL OR op_timestamp >= p_date_from)
              AND (p_date_to        IS NULL OR op_timestamp <= p_date_to)
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
    END view_log;

    -- ===================================================
    -- Откат операции по записи лога
    -- ===================================================
    PROCEDURE rollback_operation(p_log_id IN NUMBER) IS
        v_rec audit_log%ROWTYPE;
    BEGIN
        SELECT * INTO v_rec FROM audit_log WHERE id = p_log_id;

        IF v_rec.table_name = 'SELLERS' THEN
            IF v_rec.operation = 'DELETE' THEN
                INSERT INTO sellers (full_name, retail_outlet_id, salary_rate)
                VALUES (
                    JSON_VALUE(v_rec.old_data, '$.full_name'),
                    JSON_VALUE(v_rec.old_data, '$.retail_outlet_id' RETURNING NUMBER),
                    JSON_VALUE(v_rec.old_data, '$.salary_rate' RETURNING NUMBER)
                );
            ELSIF v_rec.operation = 'INSERT' THEN
                DELETE FROM sellers WHERE id = v_rec.record_pk;
            ELSIF v_rec.operation = 'UPDATE' THEN
                UPDATE sellers
                SET full_name        = JSON_VALUE(v_rec.old_data, '$.full_name'),
                    retail_outlet_id = JSON_VALUE(v_rec.old_data, '$.retail_outlet_id' RETURNING NUMBER),
                    salary_rate      = JSON_VALUE(v_rec.old_data, '$.salary_rate' RETURNING NUMBER)
                WHERE id = v_rec.record_pk;
            END IF;

        ELSIF v_rec.table_name = 'CUSTOMERS' THEN
            IF v_rec.operation = 'DELETE' THEN
                INSERT INTO customers (full_name, characteristics)
                VALUES (
                    JSON_VALUE(v_rec.old_data, '$.full_name'),
                    JSON_VALUE(v_rec.old_data, '$.characteristics')
                );
            ELSIF v_rec.operation = 'INSERT' THEN
                DELETE FROM customers WHERE id = v_rec.record_pk;
            ELSIF v_rec.operation = 'UPDATE' THEN
                UPDATE customers
                SET full_name       = JSON_VALUE(v_rec.old_data, '$.full_name'),
                    characteristics = JSON_VALUE(v_rec.old_data, '$.characteristics')
                WHERE id = v_rec.record_pk;
            END IF;

        ELSIF v_rec.table_name = 'SALES' THEN
            IF v_rec.operation = 'DELETE' THEN
                INSERT INTO sales ("date", product_id, quantity, sale_price, seller_id, retail_outlet_id, customer_id)
                VALUES (
                    TO_TIMESTAMP(JSON_VALUE(v_rec.old_data, '$.date'), 'YYYY-MM-DD"T"HH24:MI:SS.FF'),
                    JSON_VALUE(v_rec.old_data, '$.product_id' RETURNING NUMBER),
                    JSON_VALUE(v_rec.old_data, '$.quantity' RETURNING NUMBER),
                    JSON_VALUE(v_rec.old_data, '$.sale_price' RETURNING NUMBER),
                    JSON_VALUE(v_rec.old_data, '$.seller_id' RETURNING NUMBER),
                    JSON_VALUE(v_rec.old_data, '$.retail_outlet_id' RETURNING NUMBER),
                    JSON_VALUE(v_rec.old_data, '$.customer_id' RETURNING NUMBER)
                );
            ELSIF v_rec.operation = 'INSERT' THEN
                DELETE FROM sales WHERE id = v_rec.record_pk;
            ELSIF v_rec.operation = 'UPDATE' THEN
                UPDATE sales
                SET "date"             = TO_TIMESTAMP(JSON_VALUE(v_rec.old_data, '$.date'), 'YYYY-MM-DD"T"HH24:MI:SS.FF'),
                    product_id       = JSON_VALUE(v_rec.old_data, '$.product_id' RETURNING NUMBER),
                    quantity         = JSON_VALUE(v_rec.old_data, '$.quantity' RETURNING NUMBER),
                    sale_price       = JSON_VALUE(v_rec.old_data, '$.sale_price' RETURNING NUMBER),
                    seller_id        = JSON_VALUE(v_rec.old_data, '$.seller_id' RETURNING NUMBER),
                    retail_outlet_id = JSON_VALUE(v_rec.old_data, '$.retail_outlet_id' RETURNING NUMBER),
                    customer_id      = JSON_VALUE(v_rec.old_data, '$.customer_id' RETURNING NUMBER)
                WHERE id = v_rec.record_pk;
            END IF;
        END IF;

        -- Помечаем запись лога как отменённую (опционально, для наглядности)
        -- UPDATE audit_log SET operation = operation || '_ROLLBACKED' WHERE id = p_log_id;
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20010, 'Запись лога с ID=' || p_log_id || ' не найдена');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20011, 'Ошибка при откате: ' || SQLERRM);
    END rollback_operation;

    -- ===================================================
    -- Сводный отчет с гибкой сортировкой по флагам
    -- ===================================================
    FUNCTION get_report(
        p_flag1 IN NUMBER DEFAULT 0,
        p_flag2 IN NUMBER DEFAULT 0,
        p_flag3 IN NUMBER DEFAULT 0
    ) RETURN SYS_REFCURSOR IS
        v_cur SYS_REFCURSOR;
        v_sql VARCHAR2(2000);
        v_order VARCHAR2(500);
    BEGIN
        v_sql := 'SELECT table_name, operation, COUNT(*) as cnt ' ||
                 'FROM audit_log ' ||
                 'GROUP BY table_name, operation';

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
    END get_report;

END pkg_audit;
/

PROMPT >>> Пакет pkg_audit создан.
