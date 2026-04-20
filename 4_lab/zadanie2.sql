CREATE OR REPLACE PROCEDURE get_products_list (
    p_company_name IN VARCHAR2 DEFAULT NULL,
    p_product_name IN VARCHAR2 DEFAULT NULL,
    p_cursor OUT SYS_REFCURSOR
) IS
    v_sql VARCHAR2(1000);
BEGIN
    v_sql := 'SELECT p.name AS product_name, i.quantity, i.price
              FROM s_customer c
              JOIN s_ord o ON c.id = o.customer_id
              JOIN s_item i ON o.id = i.ord_id
              JOIN s_product p ON i.product_id = p.id
              WHERE 1=1';

    IF p_company_name IS NOT NULL THEN
        v_sql := v_sql || ' AND c.name = :1';
    END IF;
    IF p_product_name IS NOT NULL THEN
        v_sql := v_sql || ' AND p.name = :2';
    END IF;
    v_sql := v_sql || ' ORDER BY p.name';

    IF p_company_name IS NOT NULL AND p_product_name IS NOT NULL THEN
        OPEN p_cursor FOR v_sql USING p_company_name, p_product_name;
    ELSIF p_company_name IS NOT NULL THEN
        OPEN p_cursor FOR v_sql USING p_company_name;
    ELSIF p_product_name IS NOT NULL THEN
        OPEN p_cursor FOR v_sql USING p_product_name;
    ELSE
        OPEN p_cursor FOR v_sql;
    END IF;
END;
/
-- Тест 
VAR rc REFCURSOR;
EXEC get_products_list(p_company_name => 'Unisports', p_cursor => :rc);
PRINT rc;