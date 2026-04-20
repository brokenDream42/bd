CREATE OR REPLACE PROCEDURE add_new_region (
    p_region_id   IN s_region.id%TYPE,
    p_region_name IN s_region.name%TYPE
) IS
    CURSOR c_dept_names IS
        SELECT DISTINCT name FROM s_dept;
    v_new_id NUMBER;
BEGIN
    INSERT INTO s_region (id, name) VALUES (p_region_id, p_region_name);

    FOR r IN c_dept_names LOOP
        SELECT NVL(MAX(id), 0) + 1 INTO v_new_id FROM s_dept;
        EXECUTE IMMEDIATE 'INSERT INTO s_dept (id, name, region_id) VALUES (:1, :2, :3)'
            USING v_new_id, r.name, p_region_id;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Регион и отделы успешно добавлены.');
END;
/

--EXEC add_new_region(15, 'Test_Region');
-- Проверка региона по первичному ключу ID:
SELECT * FROM s_region WHERE id = 15;
SELECT id, name, region_id FROM s_dept WHERE region_id = 15 ORDER BY name;