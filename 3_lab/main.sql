BEGIN 
  EXECUTE IMMEDIATE 'DROP TABLE TOP_DOGS'; 
EXCEPTION WHEN OTHERS THEN NULL; 
END;
/

BEGIN 
  EXECUTE IMMEDIATE 'DROP PROCEDURE TOP_DOGS1'; 
EXCEPTION WHEN OTHERS THEN NULL; 
END;
/

BEGIN 
  EXECUTE IMMEDIATE 'DROP PROCEDURE SHOW_EXPERIENCED_EMPLOYEES'; 
EXCEPTION WHEN OTHERS THEN NULL; 
END;
/

BEGIN 
  EXECUTE IMMEDIATE 'DROP PROCEDURE ADD_STARS'; 
EXCEPTION WHEN OTHERS THEN NULL; 
END;
/

BEGIN 
  EXECUTE IMMEDIATE 'DROP PROCEDURE SHOW_MANAGERS_SUBORDINATES'; 
EXCEPTION WHEN OTHERS THEN NULL; 
END;
/

BEGIN 
  EXECUTE IMMEDIATE 'DROP PROCEDURE TOP_DOGS2'; 
EXCEPTION WHEN OTHERS THEN NULL; 
END;
/

BEGIN 
  EXECUTE IMMEDIATE 'ALTER TABLE S_EMP DROP COLUMN STARS'; 
EXCEPTION WHEN OTHERS THEN NULL; 
END;
/

CREATE TABLE TOP_DOGS (
    last_name VARCHAR2(25),
    salary    NUMBER(11,2)
);
/

CREATE OR REPLACE PROCEDURE TOP_DOGS1 (p_n IN NUMBER) IS
    v_count   NUMBER;
    v_counter NUMBER := 0;
    
    CURSOR c_emp IS
        SELECT last_name, salary
        FROM s_emp
        ORDER BY salary DESC;
        
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE TOP_DOGS';

    IF p_n = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Количество сотрудников (n) не может быть равно 0.');
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_count FROM s_emp;

    IF p_n > v_count THEN
        DBMS_OUTPUT.PUT_LINE('Предупреждение: Запрошено ' || p_n || 
                             ', но в таблице всего ' || v_count || ' сотрудников.');
    END IF;

    FOR r_emp IN c_emp LOOP
        EXIT WHEN v_counter >= p_n; 
        
        INSERT INTO TOP_DOGS (last_name, salary)
        VALUES (r_emp.last_name, r_emp.salary);
        
        v_counter := v_counter + 1;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Успешно добавлено ' || v_counter || ' записей.');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: ' || SQLERRM);
        ROLLBACK;
END TOP_DOGS1;
/

CREATE OR REPLACE PROCEDURE SHOW_EXPERIENCED_EMPLOYEES (p_years IN NUMBER) IS
    CURSOR c_exp_emp (p_min_months NUMBER) IS
        SELECT e.last_name, 
               r.name AS region_name, 
               COUNT(o.id) AS order_count
        FROM s_emp e
        JOIN s_dept d ON e.dept_id = d.id
        JOIN s_region r ON d.region_id = r.id
        LEFT JOIN s_ord o ON e.id = o.sales_rep_id
        WHERE MONTHS_BETWEEN(SYSDATE, e.start_date) > p_min_months
        GROUP BY e.last_name, r.name;
        
BEGIN
    DBMS_OUTPUT.PUT_LINE('Сотрудники со стажем более ' || p_years || ' лет:');
    
    FOR r IN c_exp_emp(p_years * 12) LOOP
        DBMS_OUTPUT.PUT_LINE('Сотрудник: ' || r.last_name || 
                             ', Регион: ' || r.region_name || 
                             ', Заказов: ' || r.order_count);
    END LOOP;
END SHOW_EXPERIENCED_EMPLOYEES;
/

ALTER TABLE s_emp ADD stars VARCHAR2(100);
/

CREATE OR REPLACE PROCEDURE ADD_STARS IS
    v_comm_pct   NUMBER;
    v_stars      VARCHAR2(100);
    v_counter    NUMBER;
    
    CURSOR c_emp IS
        SELECT id, commission_pct
        FROM s_emp
        FOR UPDATE;
        
BEGIN
    FOR r_emp IN c_emp LOOP
        v_comm_pct := ROUND(NVL(r_emp.commission_pct, 0));
        v_stars := '';
        v_counter := 1;
        
        WHILE v_counter <= v_comm_pct LOOP
            v_stars := v_stars || '*';
            v_counter := v_counter + 1;
        END LOOP;
        
        UPDATE s_emp
        SET stars = v_stars
        WHERE CURRENT OF c_emp;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Столбец STARS обновлен.');
END ADD_STARS;
/

CREATE OR REPLACE PROCEDURE SHOW_MANAGERS_SUBORDINATES (p_years IN NUMBER) IS
BEGIN
    DBMS_OUTPUT.PUT_LINE('Менеджеры и подчиненные (> ' || p_years || ' лет):');
    
    FOR r IN (
        SELECT 
            m.last_name AS manager_name,
            LISTAGG(e.last_name, ', ') WITHIN GROUP (ORDER BY e.last_name) AS subordinates
        FROM s_emp e
        JOIN s_emp m ON e.manager_id = m.id
        WHERE MONTHS_BETWEEN(SYSDATE, e.start_date) > (p_years * 12)
        GROUP BY m.last_name
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Менеджер: ' || r.manager_name || 
                             ' | Подчиненные: ' || NVL(r.subordinates, 'Нет'));
    END LOOP;
END SHOW_MANAGERS_SUBORDINATES;
/

DROP TABLE TOP_DOGS;
/

CREATE TABLE TOP_DOGS (
    last_name VARCHAR2(25),
    salary    NUMBER(11,2),
    comments  VARCHAR2(200)
);
/

CREATE OR REPLACE PROCEDURE TOP_DOGS2 (p_n IN NUMBER) IS
    v_nth_salary NUMBER;
    v_total      NUMBER;
    v_rows_inserted NUMBER;
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE TOP_DOGS';

    IF p_n <= 0 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: n должно быть больше 0.');
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_total FROM s_emp;
    
    IF p_n > v_total THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: В таблице всего ' || v_total || 
                             ' сотрудников, а запрошено ' || p_n);
        RETURN;
    END IF;

    SELECT salary INTO v_nth_salary
    FROM (
        SELECT salary, ROWNUM as rn
        FROM (
            SELECT DISTINCT salary FROM s_emp ORDER BY salary DESC
        )
    )
    WHERE rn = p_n;
    
    DBMS_OUTPUT.PUT_LINE('Найдена ' || p_n || '-ая зарплата: ' || v_nth_salary);
    
    INSERT INTO TOP_DOGS (last_name, salary, comments)
    SELECT 
        e.last_name,
        e.salary,
        (SELECT LISTAGG(e2.last_name, ', ') WITHIN GROUP (ORDER BY e2.last_name)
         FROM s_emp e2
         WHERE e2.salary = e.salary) AS comments
    FROM s_emp e
    WHERE e.salary >= v_nth_salary
    ORDER BY e.salary DESC, e.last_name;
    
    v_rows_inserted := SQL%ROWCOUNT;

    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('TOP_DOGS2 завершена. Добавлено строк: ' || v_rows_inserted);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Недостаточно сотрудников для n=' || p_n);
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: ' || SQLERRM);
        ROLLBACK;
END TOP_DOGS2;
/

EXEC TOP_DOGS1(5);
SELECT * FROM TOP_DOGS;

EXEC SHOW_EXPERIENCED_EMPLOYEES(2);

EXEC ADD_STARS;
SELECT last_name, commission_pct, stars FROM s_emp;

EXEC SHOW_MANAGERS_SUBORDINATES(1);

EXEC TOP_DOGS2(6);
SELECT * FROM TOP_DOGS;