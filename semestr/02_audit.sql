-- ============================================================
-- Часть 2: Система аудита (логирование с откатом)
-- Таблица для хранения истории изменений 3-х выбранных сущностей:
--   SELLERS, CUSTOMERS, SALES
-- ============================================================

PROMPT >>> Создание таблицы аудита...

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE audit_log CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE audit_log (
    id           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name   VARCHAR2(30)  NOT NULL,
    operation    VARCHAR2(10)  NOT NULL CHECK (operation IN ('INSERT','UPDATE','DELETE')),
    op_timestamp TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    record_pk    NUMBER        NOT NULL,
    old_data     CLOB,                      -- JSON данных ДО операции
    new_data     CLOB,                      -- JSON данных ПОСЛЕ операции
    db_user      VARCHAR2(30)  DEFAULT USER,
    machine      VARCHAR2(50)  DEFAULT SYS_CONTEXT('USERENV', 'HOST')
);

COMMENT ON TABLE audit_log IS 'Лог изменений по сущностям SELLERS, CUSTOMERS, SALES';
COMMENT ON COLUMN audit_log.table_name   IS 'Название сущности (таблицы)';
COMMENT ON COLUMN audit_log.operation    IS 'Тип операции: INSERT/UPDATE/DELETE';
COMMENT ON COLUMN audit_log.op_timestamp IS 'Дата и время операции';
COMMENT ON COLUMN audit_log.record_pk    IS 'Первичный ключ изменённой записи';
COMMENT ON COLUMN audit_log.old_data     IS 'JSON со старыми значениями (для UPDATE/DELETE)';
COMMENT ON COLUMN audit_log.new_data     IS 'JSON с новыми значениями (для INSERT/UPDATE)';
COMMENT ON COLUMN audit_log.db_user      IS 'Пользователь БД, выполнивший операцию';
COMMENT ON COLUMN audit_log.machine      IS 'Рабочая станция';

PROMPT >>> Индексы для быстрого поиска по логу...

CREATE INDEX idx_audit_table     ON audit_log(table_name);
CREATE INDEX idx_audit_operation ON audit_log(operation);
CREATE INDEX idx_audit_timestamp ON audit_log(op_timestamp);
CREATE INDEX idx_audit_record    ON audit_log(record_pk);

PROMPT >>> Таблица аудита готова.
