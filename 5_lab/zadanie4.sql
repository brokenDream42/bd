-- 4.	Создайте таблицу, в которую будут заноситься данные регистрации моментов создания объектов словаря данных:
--  CREATE TABLE  ddl_creations (
--   user_id                 VARCHAR2(30),
--   object_type VARCHAR2(30),
--   object_name         VARCHAR2(30),
--   object_owner   VARCHAR2(30),
--   creation date          DATE);
-- Создайте системный триггер для регистрации нужных сведений. 


CREATE TABLE ddl_creations (
  user_id       VARCHAR2(30),
  object_type   VARCHAR2(30),
  object_name   VARCHAR2(30),
  object_owner  VARCHAR2(30),
  creation_date DATE DEFAULT SYSDATE
);



CREATE OR REPLACE TRIGGER trg_ddl_log
AFTER CREATE ON SCHEMA  -- Отслеживаем события в текущей схеме пользователя
-- Если есть права администратора, можно использовать: AFTER CREATE ON DATABASE
BEGIN
  INSERT INTO ddl_creations (
    user_id,
    object_type,
    object_name,
    object_owner,
    creation_date
  )
  VALUES (
    SYS_CONTEXT('USERENV', 'SESSION_USER'),  -- Кто создал
    ORA_DICT_OBJ_TYPE,                        -- Тип объекта (TABLE, VIEW, TRIGGER...)
    ORA_DICT_OBJ_NAME,                        -- Имя объекта
    ORA_DICT_OBJ_OWNER,                       -- Владелец (схема)
    SYSDATE                                   -- Время создания
  );
EXCEPTION
  WHEN OTHERS THEN
    -- Если логирование упадёт, не блокируем основную операцию CREATE
    NULL;
END;
/



--  Просмотр текущих записей (должно быть пусто)
SELECT * FROM ddl_creations;

--  Тест 1: Создаём тестовую таблицу
CREATE TABLE test_obj_4 (
  id NUMBER,
  name VARCHAR2(50)
);

--  Тест 2: Создаём представление
CREATE OR REPLACE VIEW test_view_4 AS
SELECT id FROM test_obj_4;

--  Тест 3: Создаём индекс
CREATE INDEX idx_test_obj_4 ON test_obj_4(id);

--  Просмотр лога: должны появиться 3 новые записи
SELECT user_id, object_type, object_name, object_owner, 
       TO_CHAR(creation_date, 'DD.MM.YYYY HH24:MI:SS') AS created
FROM ddl_creations
ORDER BY creation_date DESC;

--  Очистка тестовых объектов (по желанию)
DROP TABLE test_obj_4;
DROP VIEW test_view_4;
