alter session set current_schema = XOTAB;

CREATE OR REPLACE PROCEDURE PROD_PROCEDURE_CREATE(dev_schema_name VARCHAR2, prod_schema_name VARCHAR2)
    AUTHID CURRENT_USER
    IS
    counter NUMBER(10);
BEGIN
    FOR diff IN (select DISTINCT object_name
                 from all_objects
                 where object_type = 'PROCEDURE'
                   and owner = dev_schema_name
                   and object_name not in
                       (select object_name
                        from all_objects
                        where owner = prod_schema_name
                          and object_type = 'PROCEDURE'))
        LOOP
            counter := 0;
            DBMS_OUTPUT.PUT_LINE('CREATE OR REPLACE ');
            FOR res2 IN (select text
                         from all_source
                         where "TYPE" = 'PROCEDURE'
                           and name = diff.object_name
                           and owner = dev_schema_name)
                LOOP
                    IF counter != 0 THEN
                        DBMS_OUTPUT.PUT_LINE(RTRIM(res2.text, CHR(10) || CHR(13)));
                    ELSE
                        DBMS_OUTPUT.PUT_LINE(RTRIM(
                                    'PROCEDURE ' || prod_schema_name || '.' || SUBSTR(res2.text, 15),
                                    CHR(10) || CHR(13)));
                        counter := 1;
                    END IF;
                END LOOP;
        END LOOP;
END;

CREATE OR REPLACE PROCEDURE PROD_PROCEDURE_DELETE(dev_schema_name VARCHAR2, prod_schema_name VARCHAR2)
    AUTHID CURRENT_USER
    IS
BEGIN
    FOR diff IN (select DISTINCT object_name
                 from all_objects
                 where object_type = 'PROCEDURE'
                   and owner = prod_schema_name
                   and object_name not in
                       (select object_name from all_objects where owner = dev_schema_name and object_type = 'PROCEDURE'))
        LOOP
            DBMS_OUTPUT.PUT_LINE('DROP PROCEDURE ' || prod_schema_name || '.' || diff.object_name);
        END LOOP;
END;

---Если есть две процедуры с одинаковыми сигнатурами, но с разными телами
CREATE OR REPLACE PROCEDURE PROD_PROCEDURE_DELETE_CREATE(dev_schema_name VARCHAR2, prod_schema_name VARCHAR2)
    AUTHID CURRENT_USER
    IS
    counter NUMBER(10);
BEGIN
    FOR diff IN (SELECT DISTINCT object_name
                 FROM all_objects
                 WHERE object_type = 'PROCEDURE'
                   AND OWNER = dev_schema_name
                   AND object_name IN
                       (SELECT object_name
                        FROM all_objects
                        WHERE OWNER = prod_schema_name
                          AND object_type = 'PROCEDURE'))
        LOOP
            counter := 0;
            DBMS_OUTPUT.PUT_LINE('DROP PROCEDURE ' || prod_schema_name || '.' || diff.object_name || ';');
            DBMS_OUTPUT.PUT_LINE('CREATE OR REPLACE ');
            FOR body IN (SELECT text
                         FROM all_source
                         WHERE type = 'PROCEDURE'
                           AND name = diff.object_name
                           AND Owner = dev_schema_name)
                LOOP
                    IF counter != 0 THEN
                        DBMS_OUTPUT.PUT_LINE(RTRIM(body.text, CHR(10) || CHR(13)));
                    ELSE
                        DBMS_OUTPUT.PUT_LINE(RTRIM(
                                    'PROCEDURE ' || prod_schema_name || '.' || SUBSTR(body.text, 15),
                                    CHR(10) || CHR(13)));
                        counter := 1;
                    END IF;
                END LOOP;
        END LOOP;
END;

CREATE OR REPLACE PROCEDURE PROD_FUNCTION_CREATE(dev_schema_name VARCHAR2, prod_schema_name VARCHAR2)
    AUTHID CURRENT_USER
    IS
    counter NUMBER(10);
BEGIN
    FOR res IN (SELECT DISTINCT object_name
                FROM all_objects
                WHERE object_type = 'FUNCTION'
                  AND Owner = dev_schema_name
                  AND object_name NOT IN
                      (SELECT object_name FROM all_objects WHERE Owner = prod_schema_name AND object_type = 'FUNCTION'))
        LOOP
            counter := 0;
            DBMS_OUTPUT.PUT_LINE('CREATE OR REPLACE ');
            FOR res2 IN (SELECT text
                         FROM all_source
                         WHERE type = 'FUNCTION'
                           AND name = res.object_name
                           AND Owner = dev_schema_name)
                LOOP
                    IF counter != 0 THEN
                        DBMS_OUTPUT.PUT_LINE(RTRIM(res2.text, CHR(10) || CHR(13)));
                    ELSE
                        DBMS_OUTPUT.PUT_LINE(RTRIM('FUNCTION ' || prod_schema_name || '.' || SUBSTR(res2.text, 14),
                                                   CHR(10) || CHR(13)));
                        counter := 1;
                    END IF;
                END LOOP;
        END LOOP;
END;

CREATE OR REPLACE PROCEDURE PROD_FUNCTION_DELETE(dev_schema_name VARCHAR2, prod_schema_name VARCHAR2)
    AUTHID CURRENT_USER
    IS
BEGIN
    FOR diff IN (select DISTINCT object_name
                 from all_objects
                 where object_type = 'FUNCTION'
                   and owner = prod_schema_name
                   and object_name not in
                       (select object_name from all_objects where owner = dev_schema_name and object_type = 'FUNCTION'))
        LOOP
            DBMS_OUTPUT.PUT_LINE('DROP FUNCTION ' || prod_schema_name || '.' || diff.object_name);
        END LOOP;
END;

CREATE OR REPLACE PROCEDURE PROD_FUNCTION_DELETE_CREATE(dev_schema_name VARCHAR2, prod_schema_name VARCHAR2)
    AUTHID CURRENT_USER
    IS
    counter NUMBER(10);
BEGIN
    FOR res IN (SELECT DISTINCT object_name
                FROM all_objects
                WHERE object_type = 'FUNCTION'
                  AND Owner = dev_schema_name
                  AND object_name IN
                      (SELECT object_name FROM all_objects WHERE Owner = prod_schema_name AND object_type = 'FUNCTION'))
        LOOP
            counter := 0;
            DBMS_OUTPUT.PUT_LINE('DROP FUNCTION ' || prod_schema_name || '.' || res.object_name || ';');
            DBMS_OUTPUT.PUT_LINE('CREATE OR REPLACE ');
            FOR res2 IN (SELECT text
                         FROM all_source
                         WHERE "TYPE" = 'FUNCTION'
                           AND name = res.object_name
                           AND Owner = dev_schema_name)
                LOOP
                    IF counter != 0 THEN
                        DBMS_OUTPUT.PUT_LINE(RTRIM(res2.text, CHR(10) || CHR(13)));
                    ELSE
                        DBMS_OUTPUT.PUT_LINE(RTRIM('FUNCTION ' || prod_schema_name || '.' || SUBSTR(res2.text, 14),
                                                   CHR(10) || CHR(13)));
                        counter := 1;
                    END IF;
                END LOOP;
        END LOOP;
END;

----dev-----
CREATE USER dev IDENTIFIED BY admin;
GRANT ALL PRIVILEGES TO dev;
alter session set current_schema = DEV;

----prod----
CREATE USER prod IDENTIFIED BY admin;
GRANT ALL PRIVILEGES TO prod;
alter session set current_schema = PROD;

----tables----
DROP TABLE DEV.TABLE1;
CREATE TABLE DEV.TABLE1
(
    id    NUMBER       not null,
    aboba VARCHAR2(59) not null,
    CONSTRAINT table1_pk PRIMARY KEY (id)
);
DROP TABLE DEV.TABLE2;
CREATE TABLE DEV.TABLE2
(
    id    NUMBER(10)   not null,
    aboba VARCHAR2(59) not null,
    CONSTRAINT table2_pk PRIMARY KEY (id)
);

CREATE TABLE PROD.TABLE1
(
    id     NUMBER       not null,
    aboba  VARCHAR2(59) not null,
    aboba2 VARCHAR2(59),
    CONSTRAINT table1_pk PRIMARY KEY (id)
);

CREATE TABLE PROD.TABLE3
(
    id    NUMBER       not null,
    aboba VARCHAR2(59) not null,
    CONSTRAINT table3_pk PRIMARY KEY (id)
);

CREATE TABLE DEV.REF
(
    id    NUMBER       not null,
    aboba VARCHAR2(59) not null,
    CONSTRAINT three_pk PRIMARY KEY (id)
);

CREATE TABLE DEV.REF1
(
    id    NUMBER(10)   not null,
    id_2  NUMBER(10)   not null,
    aboba VARCHAR2(59) not null,
    CONSTRAINT two_pk PRIMARY KEY (id),
    CONSTRAINT two_fk FOREIGN KEY (id_2) REFERENCES DEV.REF (id)
);

CREATE TABLE DEV.REF2
(
    id    NUMBER(10)   not null,
    id_2  NUMBER(10)   not null,
    aboba VARCHAR2(59) not null,
    CONSTRAINT one_pk PRIMARY KEY (id),
    CONSTRAINT one_fk FOREIGN KEY (id_2) REFERENCES DEV.REF1 (id)
);

CREATE TABLE DEV.CYCLE
(
    id NUMBER(10) not null,

    CONSTRAINT pk PRIMARY KEY (id),
    CONSTRAINT fk FOREIGN KEY (id) REFERENCES DEV.CYCLE (id)
);
----procedures----
CREATE OR REPLACE PROCEDURE DEV.proc1(a VARCHAR2)
    IS
BEGIN
    DBMS_OUTPUT.PUT_LINE(a);
END;

CREATE OR REPLACE PROCEDURE PROD.proc1(a VARCHAR2)
    IS
BEGIN
    DBMS_OUTPUT.PUT_LINE(a);
END;


CREATE OR REPLACE PROCEDURE DEV.proc2(a VARCHAR2)
    IS
BEGIN
    DBMS_OUTPUT.PUT_LINE(a);
END;

CREATE OR REPLACE PROCEDURE PROD.proc2(a VARCHAR2)
    IS
BEGIN
    DBMS_OUTPUT.PUT_LINE(a);
    DBMS_OUTPUT.PUT_LINE(a);
END;

CREATE OR REPLACE PROCEDURE DEV.proc3(a VARCHAR2)
    IS
BEGIN
    DBMS_OUTPUT.PUT_LINE(a);
END;

CREATE OR REPLACE PROCEDURE PROD.proc4(a VARCHAR2)
    IS
BEGIN
    DBMS_OUTPUT.PUT_LINE(a);
END;
----functions----
CREATE OR REPLACE Function dev.FU1(a in VARCHAR2)
    return NUMBER
    IS
BEGIN
    DBMS_OUTPUT.PUT_LINE(a);
    RETURN 5;
END;
----indexes----
CREATE INDEX dev.some_index
    ON dev.TABLE1 (aboba);