CREATE OR REPLACE PROCEDURE find_emp_by_salary (
    p_target_sal IN NUMBER
) IS
    v_min NUMBER := p_target_sal - 100;
    v_max NUMBER := p_target_sal + 100;
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cnt FROM s_emp WHERE salary BETWEEN v_min AND v_max;

    IF v_cnt = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Служащих с такой зарплатой нет.');
    ELSIF v_cnt > 1 THEN
        DBMS_OUTPUT.PUT_LINE('Служащих с такой зарплатой несколько. Найдено: ' || v_cnt);
        FOR r IN (SELECT e.last_name, d.name FROM s_emp e JOIN s_dept d ON e.dept_id = d.id
                  WHERE e.salary BETWEEN v_min AND v_max) LOOP
            DBMS_OUTPUT.PUT_LINE('  -> ' || r.last_name || ' | Отдел: ' || r.name);
        END LOOP;
    ELSE
        FOR r IN (SELECT e.last_name, d.name FROM s_emp e JOIN s_dept d ON e.dept_id = d.id
                  WHERE e.salary BETWEEN v_min AND v_max) LOOP
            DBMS_OUTPUT.PUT_LINE('Сотрудник: ' || r.last_name || ', Отдел: ' || r.name);
        END LOOP;
    END IF;
END;
/
-- Тесты:
EXEC find_emp_by_salary(1450); 
EXEC find_emp_by_salary(9999); 