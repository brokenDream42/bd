CREATE OR REPLACE PACKAGE DEPT_UTILS AS
  -- Публичные процедуры и функции (доступны извне)
  PROCEDURE MY_PROCEDURE;
  
  PROCEDURE INSERT_S_DEPT(
    p_id        IN NUMBER,
    p_name      IN VARCHAR2,
    p_region_id IN NUMBER DEFAULT NULL
  );
  
  PROCEDURE UPDATE_DEPT_REGION(
    p_id        IN NUMBER,
    p_region_id IN NUMBER
  );
  
  PROCEDURE DELETE_DEPT(p_id IN NUMBER);
  
  PROCEDURE CALC_DIV_ADD(
    p_a       IN NUMBER,
    p_b       IN NUMBER,
    p_result  OUT NUMBER
  );
  
  FUNCTION ANNUAL_TOTAL_REWARD(
    p_salary    IN NUMBER,
    p_bonus_pct IN NUMBER
  ) RETURN NUMBER;
  
  -- Глобальная константа (пример)
  G_APP_NAME CONSTANT VARCHAR2(30) := 'SDB Lab #1';
END DEPT_UTILS;
/

CREATE OR REPLACE PACKAGE BODY DEPT_UTILS AS

  -- Реализация MY_PROCEDURE
  PROCEDURE MY_PROCEDURE IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE('My procedure works');
  END MY_PROCEDURE;

  -- Реализация INSERT_S_DEPT
  PROCEDURE INSERT_S_DEPT(
    p_id        IN NUMBER,
    p_name      IN VARCHAR2,
    p_region_id IN NUMBER DEFAULT NULL
  ) IS
  BEGIN
    INSERT INTO S_DEPT (id, name, region_id) 
    VALUES (p_id, p_name, p_region_id);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Отдел добавлен: ID=' || p_id);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      DBMS_OUTPUT.PUT_LINE('Ошибка: Отдел с ID=' || p_id || ' уже существует');
  END INSERT_S_DEPT;

  -- Реализация UPDATE_DEPT_REGION
  PROCEDURE UPDATE_DEPT_REGION(
    p_id        IN NUMBER,
    p_region_id IN NUMBER
  ) IS
    v_count NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_count FROM S_DEPT WHERE id = p_id;
    IF v_count = 0 THEN
      DBMS_OUTPUT.PUT_LINE('Ошибка: Отдел с ID=' || p_id || ' не найден');
      RETURN;
    END IF;
    
    UPDATE S_DEPT SET region_id = p_region_id WHERE id = p_id;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Регион отдела ID=' || p_id || ' обновлён на ' || p_region_id);
  END UPDATE_DEPT_REGION;

  -- Реализация DELETE_DEPT
  PROCEDURE DELETE_DEPT(p_id IN NUMBER) IS
    v_count NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_count FROM S_DEPT WHERE id = p_id;
    IF v_count = 0 THEN
      DBMS_OUTPUT.PUT_LINE('Ошибка: Отдел с ID=' || p_id || ' не найден');
      RETURN;
    END IF;
    
    DELETE FROM S_DEPT WHERE id = p_id;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Отдел ID=' || p_id || ' удалён');
  END DELETE_DEPT;

  -- Реализация CALC_DIV_ADD
  PROCEDURE CALC_DIV_ADD(
    p_a       IN NUMBER,
    p_b       IN NUMBER,
    p_result  OUT NUMBER
  ) IS
  BEGIN
    IF p_b = 0 THEN
      p_result := NULL;
      DBMS_OUTPUT.PUT_LINE('Ошибка: деление на ноль');
      RETURN;
    END IF;
    p_result := p_a / p_b + p_b;
    DBMS_OUTPUT.PUT_LINE('Результат: ' || p_result);
  END CALC_DIV_ADD;

  -- Реализация функции
  FUNCTION ANNUAL_TOTAL_REWARD(
    p_salary    IN NUMBER,
    p_bonus_pct IN NUMBER
  ) RETURN NUMBER IS
  BEGIN
    IF p_salary IS NULL THEN
      RETURN 0;
    ELSIF p_bonus_pct IS NULL THEN
      RETURN p_salary;
    ELSE
      RETURN p_salary + p_salary * (p_bonus_pct / 100);
    END IF;
  END ANNUAL_TOTAL_REWARD;

END DEPT_UTILS;
/