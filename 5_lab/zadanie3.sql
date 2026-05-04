-- 3.	Напишите триггер, позволяющий отслеживать статистические показатели, касающиеся продуктов. 
-- Т.е. для каждого существующего товара указывается количество заказчиков этого товара, количество заказанных единиц, суммарная стоимость заказа. 
-- Результаты будут храниться в таблице major_stats. 


-- 1. Таблица статистики
-- Сброс сессии (на случай старых блокировок)
COMMIT;

-- 1. Таблица статистики
CREATE TABLE major_stats (
    product_id     NUMBER PRIMARY KEY,
    customer_count NUMBER DEFAULT 0,
    units_ordered  NUMBER DEFAULT 0,
    total_value    NUMBER DEFAULT 0,
    last_updated   TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- 2. Триггер 
CREATE OR REPLACE TRIGGER trg_update_stats
AFTER INSERT OR UPDATE OR DELETE ON s_item
BEGIN
    DELETE FROM major_stats;
    
    INSERT INTO major_stats (product_id, customer_count, units_ordered, total_value, last_updated)
    SELECT 
        i.product_id,
        COUNT(DISTINCT o.customer_id),  -- уникальные заказчики
        SUM(i.quantity),                -- всего единиц
        SUM(i.quantity * i.price),      -- общая сумма
        SYSTIMESTAMP
    FROM s_item i
    JOIN s_ord o ON i.ord_id = o.id
    GROUP BY i.product_id;
END;
/
COMMIT;  

-- Тесты 
INSERT INTO s_ord (id, customer_id, date_ordered, sales_rep_id, total, payment_type)
VALUES (999, 201, SYSDATE, 11, 900, 'CREDIT');

INSERT INTO s_item (ord_id, item_id, product_id, price, quantity, quantity_shipped)
VALUES (999, 1, 20106, 9, 100, 100);
COMMIT;

SELECT product_id, customer_count, units_ordered, total_value 
FROM major_stats WHERE product_id = 20106;

-- Изменение количества
UPDATE s_item SET quantity = 150 WHERE ord_id = 999 AND item_id = 1;
COMMIT;

SELECT product_id, units_ordered, total_value 
FROM major_stats WHERE product_id = 20106;

-- Удаление теста
DELETE FROM s_item WHERE ord_id = 999 AND item_id = 1;
DELETE FROM s_ord WHERE id = 999;
COMMIT;

SELECT product_id, units_ordered, total_value 
FROM major_stats WHERE product_id = 20106;