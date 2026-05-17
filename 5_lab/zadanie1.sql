-- 1.	Напишите триггер для таблицы s_item, позволяющий контролировать изменение цены товара.  
-- Если новая цена отличается от старой более чем на 30%, выдаётся соответствующее сообщение и запрещается изменения данных. 
-- Реализовать используя исключения.

CREATE OR REPLACE TRIGGER trg_check_price
BEFORE UPDATE OF price ON s_item
FOR EACH ROW
DECLARE
  ex_price_limit EXCEPTION;  
BEGIN
  -- Проверяем условие: изменение более 30%
  IF :OLD.price IS NOT NULL AND :OLD.price <> 0 THEN
    IF ABS(:NEW.price - :OLD.price) / :OLD.price > 0.3 THEN
      RAISE ex_price_limit;  -- Вызываем исключение
    END IF;
  END IF;

EXCEPTION
  WHEN ex_price_limit THEN
    -- Блокируем операцию и выводим сообщение
    RAISE_APPLICATION_ERROR(-20001, 
      'Запрещено изменение цены более чем на 30%. Старая: ' || TO_CHAR(:OLD.price) || 
      ', Новая: ' || TO_CHAR(:NEW.price));
END;
/

-- Тесты задания 1
-- Сбрасываем цену к исходной
UPDATE s_item SET price = 9 WHERE ord_id = 97 AND item_id = 1;
COMMIT;

-- Допустимое изменение (+20%): 9 - 10.8
UPDATE s_item SET price = 10.8 WHERE ord_id = 97 AND item_id = 1;


-- Запрещённое изменение (+35%): 9 - 12.2
UPDATE s_item SET price = 100 WHERE ord_id = 97 AND item_id = 1;