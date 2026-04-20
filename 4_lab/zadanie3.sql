CREATE OR REPLACE PROCEDURE rank_products (
    p_start_date IN DATE,
    p_end_date   IN DATE,
    p_profit     IN CHAR DEFAULT 'N',
    p_qty        IN CHAR DEFAULT 'N',
    p_orders     IN CHAR DEFAULT 'N'
) IS
    v_cur SYS_REFCURSOR;
    v_sql VARCHAR2(1500) := 'SELECT p.id, p.name, SUM(i.price * i.quantity) AS profit,
                             SUM(i.quantity) AS qty, COUNT(DISTINCT o.id) AS orders
                             FROM s_product p
                             JOIN s_item i ON p.id = i.product_id
                             JOIN s_ord o ON i.ord_id = o.id
                             WHERE o.date_ordered BETWEEN :1 AND :2
                             GROUP BY p.id, p.name ORDER BY ';
    v_sort VARCHAR2(200) := '';
    v_id NUMBER; v_name VARCHAR2(50);
    v_profit NUMBER; v_qty NUMBER; v_orders NUMBER;
BEGIN
    IF UPPER(p_profit) = 'Y' THEN v_sort := v_sort || ' profit DESC, '; END IF;
    IF UPPER(p_qty) = 'Y' THEN v_sort := v_sort || ' qty DESC, '; END IF;
    IF UPPER(p_orders) = 'Y' THEN v_sort := v_sort || ' orders DESC, '; END IF;
    
    v_sort := RTRIM(v_sort, ', ');
    IF v_sort IS NULL THEN v_sort := 'profit DESC'; END IF;

    OPEN v_cur FOR v_sql || v_sort USING p_start_date, p_end_date;

    DBMS_OUTPUT.PUT_LINE('ID | Товар | Прибыль | Кол-во | Заказы');
    LOOP
        FETCH v_cur INTO v_id, v_name, v_profit, v_qty, v_orders;
        EXIT WHEN v_cur%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(v_id || ' | ' || v_name || ' | ' || v_profit || ' | ' || v_qty || ' | ' || v_orders);
    END LOOP;
    CLOSE v_cur;
END;
/
-- Тест:
EXEC rank_products('28-AUG-92', '10-SEP-92', 'Y', 'Y', 'Y');

EXEC rank_products('28-AUG-92', '10-SEP-92', 'Y', 'N', 'Y');

EXEC rank_products('28-AUG-92', '10-SEP-92', 'Y', 'Y', 'N');