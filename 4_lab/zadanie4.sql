CREATE OR REPLACE PROCEDURE move_dept (
    p_new_region_id IN NUMBER,
    p_dept_id       IN NUMBER
) IS
    v_dept_name s_dept.name%TYPE;
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cnt FROM s_dept WHERE id = p_dept_id;
    IF v_cnt = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: отдел не найден.');
        RETURN;
    END IF;

    SELECT name INTO v_dept_name FROM s_dept WHERE id = p_dept_id;

    SELECT COUNT(*) INTO v_cnt FROM s_region WHERE id = p_new_region_id;
    IF v_cnt = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: регион не найден.');
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM s_dept
    WHERE name = v_dept_name AND region_id = p_new_region_id AND id != p_dept_id;
    IF v_cnt > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: в этом регионе уже есть отдел с таким названием.');
        RETURN;
    END IF;

    UPDATE s_dept SET region_id = p_new_region_id WHERE id = p_dept_id;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Отдел успешно перемещен.');
END;
/
-- Тест:
EXEC move_dept(6, 34);
SELECT id, name, region_id FROM s_dept WHERE id = 34;