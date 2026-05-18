-- ============================================================
-- Часть 6: Тестовые сценарии и демонстрация работы
-- ============================================================

SET SERVEROUTPUT ON;
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'DD.MM.YYYY HH24:MI:SS';

PROMPT >>> ============================================
PROMPT >>> ДЕМО 1: Процедуры + автологирование
PROMPT >>> ============================================

DECLARE
    v_seller_id NUMBER;
    v_customer_id NUMBER;
    v_sale_id NUMBER;
BEGIN
    -- SELLERS: INSERT + UPDATE
    add_seller('Test Seller', 1, 50000, v_seller_id);
    DBMS_OUTPUT.PUT_LINE('Добавлен продавец, ID=' || v_seller_id);
    upd_seller(v_seller_id, 'Test Seller Updated', 2, 55000);
    DBMS_OUTPUT.PUT_LINE('Обновлен продавец, ID=' || v_seller_id);

    -- CUSTOMERS: INSERT + DELETE
    add_customer('Test Customer', '{"age":25}', v_customer_id);
    DBMS_OUTPUT.PUT_LINE('Добавлен покупатель, ID=' || v_customer_id);
    del_customer(v_customer_id);
    DBMS_OUTPUT.PUT_LINE('Удален покупатель, ID=' || v_customer_id);

    -- SALES: INSERT + UPDATE + DELETE
    add_sale(1, 2, 45, v_seller_id, 1, NULL, v_sale_id);
    DBMS_OUTPUT.PUT_LINE('Добавлена продажа, ID=' || v_sale_id);
    upd_sale(v_sale_id, 2, 3, 50, v_seller_id, 1, NULL);
    DBMS_OUTPUT.PUT_LINE('Обновлена продажа, ID=' || v_sale_id);
    del_sale(v_sale_id);
    DBMS_OUTPUT.PUT_LINE('Удалена продажа, ID=' || v_sale_id);

    COMMIT;
END;
/

PROMPT >>> ============================================
PROMPT >>> ДЕМО 2: Просмотр лога
PROMPT >>> ============================================

BEGIN
    pkg_audit.view_log;
END;
/

PROMPT >>> ============================================
PROMPT >>> ДЕМО 3: Откат операции UPDATE
PROMPT >>> ============================================

-- Пример отката (раскомментировать и подставить реальный ID):
-- BEGIN
--     pkg_audit.rollback_operation(:log_id);
--     DBMS_OUTPUT.PUT_LINE('Операция откатана');
--     COMMIT;
-- END;
-- /

PROMPT >>> ============================================
PROMPT >>> ДЕМО 4: Сводный отчет (разные флаги)
PROMPT >>> ============================================

DECLARE
    v_cur SYS_REFCURSOR;
    v_table_name VARCHAR2(30);
    v_operation VARCHAR2(10);
    v_cnt NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Без флагов ---');
    v_cur := pkg_audit.get_report(0, 0, 0);
    LOOP
        FETCH v_cur INTO v_table_name, v_operation, v_cnt;
        EXIT WHEN v_cur%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(RPAD(v_table_name, 10) || ' | ' || RPAD(v_operation, 6) || ' | ' || v_cnt);
    END LOOP;
    CLOSE v_cur;

    DBMS_OUTPUT.PUT_LINE('--- Флаг 1: по сущности ---');
    v_cur := pkg_audit.get_report(1, 0, 0);
    LOOP
        FETCH v_cur INTO v_table_name, v_operation, v_cnt;
        EXIT WHEN v_cur%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(RPAD(v_table_name, 10) || ' | ' || RPAD(v_operation, 6) || ' | ' || v_cnt);
    END LOOP;
    CLOSE v_cur;

    DBMS_OUTPUT.PUT_LINE('--- Флаг 1+3: по сущности, затем по количеству ---');
    v_cur := pkg_audit.get_report(1, 0, 1);
    LOOP
        FETCH v_cur INTO v_table_name, v_operation, v_cnt;
        EXIT WHEN v_cur%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(RPAD(v_table_name, 10) || ' | ' || RPAD(v_operation, 6) || ' | ' || v_cnt);
    END LOOP;
    CLOSE v_cur;
END;
/

PROMPT >>> ============================================
PROMPT >>> Проверка содержимого AUDIT_LOG
PROMPT >>> ============================================

SELECT id, table_name, operation,
    TO_CHAR(op_timestamp, 'DD.MM.YYYY HH24:MI:SS') as ts,
    record_pk, db_user
FROM audit_log
ORDER BY id DESC
FETCH FIRST 20 ROWS ONLY;

COMMIT;

PROMPT >>> Тестирование завершено.
