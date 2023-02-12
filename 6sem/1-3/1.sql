DROP TABLE MyTable;
-----------
CREATE TABLE MyTable
(
    id    NUMBER UNIQUE NOT NULL,
    value NUMBER        NOT NULL
);
-----------
DECLARE
    i NUMBER;
BEGIN
    i := 1;
    LOOP
        INSERT INTO MyTable(id, value)
        VALUES (i, DBMS_RANDOM.RANDOM());
        i := i + 1;
        EXIT WHEN i > 10;
    END LOOP;
END;
-------------
SELECT *
FROM MyTable;
----------
DECLARE FUNCTION odd_or_even
    RETURN VARCHAR2
    IS
    even NUMBER;
    odd  NUMBER;
BEGIN
    SELECT COUNT(*) INTO even FROM MyTable WHERE MOD(value, 2) = 0;
    SELECT COUNT(*) INTO odd FROM MyTable WHERE MOD(value, 2) = 1;
    IF even > odd THEN
        RETURN 'TRUE';
    ELSIF even < odd THEN
        RETURN 'FALSE';
    ELSE
        RETURN 'EQUAL';
    END IF;
END odd_or_even;
BEGIN
    DBMS_OUTPUT.put_line(odd_or_even());
END;
-------
DECLARE
    FUNCTION insert_command(FIND_ID IN NUMBER)
        RETURN varchar2
        IS
        NEW_VALUE NUMBER;
        FLAG      NUMBER;
        invalid_input EXCEPTION;
    BEGIN
        SELECT COUNT(*) INTO FLAG FROM MyTable WHERE MyTable.id = FIND_ID;
        IF FLAG > 0 THEN
            SELECT VALUE INTO NEW_VALUE FROM MyTable WHERE MyTable.id = FIND_ID;
            RETURN 'INSERT INTO MyTable(id, val) VALUES (' || FIND_ID || ', ' ||
                   NEW_VALUE || ');';
        ELSE
            RAISE invalid_input;

        END IF;
    EXCEPTION
        WHEN invalid_input THEN
        RETURN 'Id doesnt exists';
    END insert_command;
BEGIN
    DBMS_OUTPUT.put_line(insert_command(1000000));
END;
----------
DECLARE
    PROCEDURE new_insert(NEW_ID IN number, NEW_VALUE IN number)
        IS
    BEGIN
        INSERT INTO MyTable VALUES (NEW_ID, NEW_VALUE);
    END new_insert;
    PROCEDURE new_update(NEW_ID IN number, NEW_VALUE IN number) IS
    BEGIN
        UPDATE MyTable
        SET MyTable.value=NEW_VALUE
        WHERE MyTable.id = NEW_ID;
    END new_update;
    PROCEDURE new_delete(NEW_ID IN number)
        IS
    BEGIN
        DELETE
        FROM MyTable
        WHERE MyTable.id = NEW_ID;
    END new_delete;
BEGIN
    new_insert(10002, 5);
    new_update(10002, 10);
    new_delete(10002);
END;
------------
CREATE OR REPLACE FUNCTION get_salary(salary IN NUMBER, bonus IN NUMBER)
    RETURN NUMBER IS
    invalid_input EXCEPTION;
BEGIN
    IF bonus < 0 OR salary < 0 THEN
        RAISE invalid_input;
    END IF;
    RETURN (1 + bonus * 0.01) * 12 * salary;
EXCEPTION
    WHEN invalid_input THEN
        RETURN 'Salary and bonus must be >= 0';
END get_salary;

DECLARE

BEGIN
    DBMS_OUTPUT.put_line(get_salary('ad', 2));

EXCEPTION
    WHEN INVALID_NUMBER OR VALUE_ERROR THEN
        DBMS_OUTPUT.put_line('Invalid input type');
END;