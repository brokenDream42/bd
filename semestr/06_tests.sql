-- ============================================================
-- Часть 6: Тестовые сценарии и демонстрация работы
-- ============================================================

SET SERVEROUTPUT ON;
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'DD.MM.YYYY HH24:MI:SS';

PROMPT >>> ============================================
PROMPT >>> ДЕМО 1: CRUD через пакет + автологирование
PROMPT >>> ============================================

DECLARE
    v_id NUMBER;
BEGIN
    -- INSERT seller
    pkg_entity_crud.add_seller('Test Seller', 1, 50000, v_id);
    DBMS_OUTPUT.PUT_LINE('Добавлен продавец, ID=' || v_id);

    -- UPDATE seller
    pkg_entity_crud.upd_seller(v_id, 'Test Seller Updated', 2, 55000);
    DBMS_OUTPUT.PUT_LINE('Обновлен продавец, ID=' || v_id);

    -- INSERT customer
    pkg_entity_crud.add_customer('Test Customer', '{"age":25}', v_id);
    DBMS_OUTPUT.PUT_LINE('Добавлен покупатель, ID=' || v_id);

    -- DELETE customer
    pkg_entity_crud.del_customer(v_id);
    DBMS_OUTPUT.PUT_LINE('Удален покупатель, ID=' || v_id);
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
-- Предположим, последняя запись в логе с operation='UPDATE' имеет ID=N
-- Замените :log_id на реальный ID из вывода выше

-- Пример отката (раскомментируйте и подставьте ID):
-- BEGIN
--     pkg_audit.rollback_operation(:log_id);
--     DBMS_OUTPUT.PUT_LINE('Операция откатана');
-- END;
-- /

PROMPT >>> ============================================
PROMPT >>> ДЕМО 4: Сводный отчет (разные флаги)
PROMPT >>> ============================================

DECLARE
    v_cur SYS_REFCURSOR;
    v_table_name VARCHAR2(30);
    v_operation  VARCHAR2(10);
    v_cnt        NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Без флагов (по умолчанию) ---');
    v_cur := pkg_audit.get_report(0, 0, 0);
    LOOP
        FETCH v_cur INTO v_table_name, v_operation, v_cnt;
        EXIT WHEN v_cur%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(RPAD(v_table_name, 10) || ' | ' || RPAD(v_operation, 6) || ' | ' || v_cnt);
    END LOOP;
    CLOSE v_cur;

    DBMS_OUTPUT.PUT_LINE('--- Флаг 1: по названию сущности ---');
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

SELECT id,
       table_name,
       operation,
       TO_CHAR(op_timestamp, 'DD.MM.YYYY HH24:MI:SS') as ts,
       record_pk,
       db_user
FROM audit_log
ORDER BY id DESC
FETCH FIRST 20 ROWS ONLY;

PROMPT >>> Тестирование завершено.
