-- 5.	Создайте таблицу, в которую будут заноситься данные о регистрации ошибок компиляции и ошибок этапа выполнения:
--   CREATE TABLE error_log(
--   timestamp    DATE,
--   username     VARCHAR2(30),
--   instanse               NUMBER,
--   database_name    VARCHAR2(50),
--   error_stack VARCHAR2(2000));
-- Создайте системный триггер для регистрации нужных сведений.
-- Сгенерируйте несколько ошибок и посмотрите, правильно триггер регистрирует их. 



CREATE TABLE error_log (
  timestamp     DATE DEFAULT SYSDATE,
  username      VARCHAR2(30),
  instance      NUMBER,
  database_name VARCHAR2(50),
  error_stack   VARCHAR2(2000)
);


CREATE OR REPLACE TRIGGER trg_error_log
AFTER SERVERERROR ON SCHEMA
BEGIN
  INSERT INTO error_log (timestamp, username, instance, database_name, error_stack)
  VALUES (
    SYSDATE,
    SYS_CONTEXT('USERENV', 'SESSION_USER'),
    SYS_CONTEXT('USERENV', 'INSTANCE'),
    SYS_CONTEXT('USERENV', 'DB_NAME'),
    SUBSTR(DBMS_UTILITY.FORMAT_ERROR_STACK, 1, 2000)
  );
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

-- Тесты
-- 1. Деление на ноль
BEGIN DBMS_OUTPUT.PUT_LINE(1/0); END;
/

-- 2. Несуществующая таблица
BEGIN EXECUTE IMMEDIATE 'SELECT * FROM fake_table_xyz_123'; END;
/

-- 3. Нарушение уникальности
CREATE TABLE test_unique (id NUMBER UNIQUE);
INSERT INTO test_unique VALUES (1);
INSERT INTO test_unique VALUES (1);  

-- 4. Ошибка преобразования типов
BEGIN DBMS_OUTPUT.PUT_LINE(TO_NUMBER('ABC')); END;
/

SELECT TO_CHAR(timestamp, 'DD.MM.YYYY HH24:MI:SS') AS error_time,
       username, error_stack
FROM error_log ORDER BY timestamp DESC;

-- Очистка
DROP TABLE test_unique;