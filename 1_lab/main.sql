CREATE OR REPLACE PROCEDURE MY_PROCEDURE IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('My procedure works');
END MY_PROCEDURE;
/
CREATE OR REPLACE PROCEDURE INSERT_S_DEPT(
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
    ROLLBACK;
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Ошибка вставки: ' || SQLERRM);
    ROLLBACK;
    RAISE;
END INSERT_S_DEPT;
/


CREATE OR REPLACE PROCEDURE UPDATE_DEPT_REGION(
  p_id        IN NUMBER,
  p_region_id IN NUMBER
) IS
BEGIN
  UPDATE S_DEPT 
  SET region_id = p_region_id 
  WHERE id = p_id;
  
  IF SQL%ROWCOUNT = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Ошибка: Отдел с ID=' || p_id || ' не найден');
  ELSE
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Регион отдела ID=' || p_id || ' обновлён на ' || p_region_id);
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Ошибка обновления: ' || SQLERRM);
    RAISE;
END UPDATE_DEPT_REGION;
/


CREATE OR REPLACE PROCEDURE DELETE_DEPT(p_id IN NUMBER) IS
BEGIN
  DELETE FROM S_DEPT 
  WHERE id = p_id;
  
  IF SQL%ROWCOUNT = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Ошибка: Отдел с ID=' || p_id || ' не найден');
  ELSE
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Отдел ID=' || p_id || ' удалён');
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Ошибка удаления: ' || SQLERRM);
    RAISE;
END DELETE_DEPT;
/


CREATE OR REPLACE PROCEDURE CALC_DIV_ADD(
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
  
  p_result := (p_a / p_b) + p_b;
  DBMS_OUTPUT.PUT_LINE('Результат: ' || p_result);
END CALC_DIV_ADD;
/


CREATE OR REPLACE FUNCTION ANNUAL_TOTAL_REWARD(
  p_salary    IN NUMBER,
  p_bonus_pct IN NUMBER
) RETURN NUMBER IS
BEGIN
  IF p_salary IS NULL THEN
    RETURN 0;
  END IF;
  IF p_bonus_pct IS NULL THEN
    RETURN p_salary;
  END IF;
  
  RETURN p_salary + (p_salary * (p_bonus_pct / 100));
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Ошибка в функции: ' || SQLERRM);
    RETURN NULL;
END ANNUAL_TOTAL_REWARD;
/


/*
-- Тестирование процедур
EXEC MY_PROCEDURE;

EXEC INSERT_S_DEPT(60, 'IT Dept', 1);

EXEC UPDATE_DEPT_REGION(60, 2);

EXEC DELETE_DEPT(60);

DECLARE
  v_result NUMBER;
BEGIN
  CALC_DIV_ADD(100, 5, v_result);
  DBMS_OUTPUT.PUT_LINE('CALC_DIV_ADD результат: ' || v_result);
END;
/

SELECT ANNUAL_TOTAL_REWARD(50000, 10) AS TOTAL FROM DUAL;
*/