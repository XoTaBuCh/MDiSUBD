CREATE TABLE GROUPS
(
    ID    NUMBER PRIMARY KEY NOT NULL,
    NAME  VARCHAR2(100)      NOT NULL,
    C_VAL NUMBER
);

CREATE TABLE STUDENTS
(
    ID       NUMBER PRIMARY KEY,
    NAME     VARCHAR2(100),
    GROUP_ID NUMBER REFERENCES GROUPS (ID)
);
--------
CREATE SEQUENCE STUDENTS_SEQ
    START WITH 1
    INCREMENT BY 1
    CACHE 10;

CREATE SEQUENCE GROUPS_SEQ
    START WITH 1
    INCREMENT BY 1
    CACHE 10;

CREATE TRIGGER before_insert_students_trigger
    BEFORE INSERT
    ON STUDENTS
    FOR EACH ROW
BEGIN
    :new.ID := STUDENTS_SEQ.NEXTVAL;
END;


CREATE OR REPLACE TRIGGER before_insert_groups_trigger
    BEFORE INSERT
    ON GROUPS
    FOR EACH ROW
DECLARE
    flag NUMBER;
    name_taken EXCEPTION;
BEGIN
    IF :new.ID IS NULL AND INSERTING THEN
        SELECT GROUPS_SEQ.NEXTVAL INTO :new.ID FROM DUAL;
    END IF;

    IF :new.NAME IS NOT NULL THEN
        SELECT COUNT(*) INTO flag FROM GROUPS WHERE NAME = :new.NAME;
        IF flag > 0 THEN
            raise name_taken;
        END IF;
    END IF;
END;

INSERT INTO GROUPS(ID, name, C_VAL)
VALUES (0, 'asfa', 3);
SELECT *
FROM GROUPS;
------------
CREATE OR REPLACE TRIGGER GROUP_DEL
    BEFORE DELETE
    ON GROUPS
    FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    recursive INTEGER := 0;
BEGIN
    SELECT COUNT(*)
    INTO recursive
    FROM user_triggers
    WHERE trigger_name = 'GROUP_DEL'
      AND triggering_event = 'DELETE'
      AND status = 'ENABLED';

    IF recursive = 0 THEN
        DELETE
        FROM STUDENTS
        WHERE GROUP_ID = :OLD.id;
        COMMIT;
    END IF;
END;


CREATE OR REPLACE TRIGGER STUDENT_DEL
    BEFORE DELETE
    ON STUDENTS
    FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    recursive INTEGER := 0;
BEGIN
    SELECT COUNT(*)
    INTO recursive
    FROM user_triggers
    WHERE trigger_name = 'GROUP_DEL'
      AND triggering_event = 'DELETE'
      AND status = 'ENABLED';

    IF recursive = 0 THEN
        DELETE FROM GROUPS WHERE ID = :old.GROUP_ID;
        COMMIT;
    END IF;
END;

INSERT INTO STUDENTS(ID, name, GROUP_ID)
VALUES (0, 'asfa', 4);

SELECT *
FROM GROUPS;
SELECT *
FROM STUDENTS;

DELETE
FROM STUDENTS
WHERE ID = 1;
-----------
DROP TABLE LOGS;

CREATE TABLE LOGS
(
    TIME        TIMESTAMP     NOT NULL,
    MESSAGE     VARCHAR2(100) NOT NULL,
    ST_ID       NUMBER,
    ST_ID_OLD   NUMBER,
    ST_NAME     VARCHAR2(100),
    ST_GROUP_ID NUMBER
);

CREATE OR REPLACE TRIGGER logging
    AFTER INSERT OR DELETE OR UPDATE
    ON STUDENTS
    FOR EACH ROW
BEGIN
    CASE
        WHEN INSERTING THEN INSERT INTO LOGS VALUES (SYSTIMESTAMP, 'INSERT', :new.ID, null, null, null);
        WHEN UPDATING THEN INSERT INTO LOGS VALUES (SYSTIMESTAMP, 'UPDATE', :new.ID, :old.ID, :old.NAME, :old.GROUP_ID);
        WHEN DELETING THEN INSERT INTO LOGS VALUES (SYSTIMESTAMP, 'DELETE', null, :old.ID, :old.NAME, :old.GROUP_ID);
        END CASE;
END;
---------
CREATE OR REPLACE PROCEDURE GO_BACK(restore_time IN TIMESTAMP)
    IS
    CURSOR s_logs IS
        SELECT *
        FROM LOGS
        WHERE TIME >= restore_time
        ORDER BY TIME DESC;
    invalid_log EXCEPTION;
BEGIN
    FOR log IN s_logs
        LOOP
            CASE
                WHEN log.MESSAGE = 'INSERT' THEN DELETE FROM STUDENTS WHERE ID = log.ST_ID;
                WHEN log.MESSAGE = 'UPDATE' THEN UPDATE STUDENTS
                                                 SET ID=log.ST_ID_OLD,
                                                     NAME=log.ST_NAME,
                                                     GROUP_ID =log.ST_GROUP_ID
                                                 WHERE ID = log.ST_ID;
                WHEN log.MESSAGE = 'DELETE'
                    THEN INSERT INTO STUDENTS VALUES (log.ST_ID_OLD, log.ST_NAME, log.ST_GROUP_ID);
                ELSE raise invalid_log;
                END CASE;
            DELETE FROM LOGS WHERE TIME = log.TIME;
        END LOOP;
END GO_BACK;

CREATE OR REPLACE PROCEDURE GO_BACK_OFFSET(offset IN INTERVAL DAY TO SECOND)
    IS
BEGIN
    GO_BACK(LOCALTIMESTAMP - offset);
END GO_BACK_OFFSET;

SELECT *
FROM STUDENTS;
DELETE
FROM LOGS;

INSERT INTO STUDENTS(ID, name, GROUP_ID)
VALUES (0, 'asfa', 4);

UPDATE STUDENTS
SET ID=3,
    NAME='gdrst',
    GROUP_ID=2
WHERE ID = 4;

DELETE
FROM STUDENTS
WHERE ID = 3;

SELECT *
FROM LOGS;
BEGIN
    GO_BACK(TO_TIMESTAMP(CURRENT_TIMESTAMP - 45));
END;
-----------
CREATE OR REPLACE TRIGGER UPDATE_GROUPS
    AFTER INSERT OR DELETE OR UPDATE
    ON STUDENTS
    FOR EACH ROW
BEGIN
    CASE
        WHEN INSERTING THEN UPDATE GROUPS
                            SET C_VAL=C_VAL + 1
                            WHERE ID = :new.GROUP_ID;
        WHEN UPDATING THEN UPDATE GROUPS
                           SET C_VAL=C_VAL + 1
                           WHERE ID = :new.GROUP_ID;
                           UPDATE GROUPS
                           SET C_VAL=C_VAL - 1
                           WHERE ID = :old.GROUP_ID;
        WHEN DELETING THEN UPDATE GROUPS
                           SET C_VAL=C_VAL - 1
                           WHERE ID = :old.GROUP_ID;
        END CASE;
END;
