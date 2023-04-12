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

CREATE OR REPLACE PROCEDURE PROD_INDEX_CREATE(dev_schema_name VARCHAR2, prod_schema_name VARCHAR2)
    IS
    text VARCHAR2(100);
BEGIN
    FOR diff IN (select index_name, index_type, table_name
                 from all_indexes
                 where table_owner = dev_schema_name
                   and index_name not like '%_PK'
                   and index_name not in
                       (select index_name
                        from all_indexes
                        where table_owner = prod_schema_name
                          and index_name not like '%_PK'))
        LOOP
            select column_name
            INTO text
            from ALL_IND_COLUMNS
            where index_name = diff.index_name
              and table_owner = dev_schema_name;
            DBMS_OUTPUT.PUT_LINE('CREATE ' || diff.index_type || ' INDEX ' || diff.index_name || ' ON ' ||
                                 prod_schema_name || '.' || diff.table_name || '(' || text || ');');
        END LOOP;
END;

CREATE OR REPLACE PROCEDURE PROD_INDEX_DELETE(dev_schema_name VARCHAR2, prod_schema_name VARCHAR2)
    IS
BEGIN
    FOR diff IN (select index_name
                 from all_indexes
                 where table_owner = prod_schema_name
                   and index_name not like '%_PK'
                   and index_name not in
                       (select index_name
                        from all_indexes
                        where table_owner = dev_schema_name
                          and index_name not like '%_PK'))
        LOOP
            DBMS_OUTPUT.PUT_LINE('DROP INDEX ' || diff.index_name || ';');
        END LOOP;
END;

CREATE OR REPLACE PROCEDURE PROD_CREATE_LIST(dev_schema_name VARCHAR2, prod_schema_name VARCHAR2)
    IS
    counter    NUMBER(10);
    ddl_script VARCHAR2(3000);
BEGIN
    FOR diff IN (Select DISTINCT table_name
                 from all_tab_columns
                 where owner = dev_schema_name
                   and (table_name, column_name) not in
                       (select table_name, column_name from all_tab_columns where owner = prod_schema_name))
        LOOP
            counter := 0;

            SELECT COUNT(*)
            INTO counter
            FROM all_tables
            where owner = prod_schema_name
              and table_name = diff.table_name;

            IF counter > 0 THEN
                FOR res2 IN (Select DISTINCT column_name, data_type
                             from all_tab_columns
                             where owner = dev_schema_name
                               and table_name = diff.table_name
                               and (table_name, column_name) not in
                                   (select table_name, column_name from all_tab_columns where owner = prod_schema_name))
                    LOOP
                        ddl_script := 'ALTER TABLE ' || prod_schema_name || '.' || diff.table_name || ' ADD ' ||
                                      res2.column_name || ' ' || res2.data_type || ';';
                        INSERT INTO DDL_TABLE (TABLE_NAME, DDL_SCRIPT, "TYPE")
                        VALUES (diff.TABLE_NAME, ddl_script, 'TABLE');
                    END LOOP;
            ELSE
                ddl_script :=
                            'CREATE TABLE ' || prod_schema_name || '.' || diff.table_name || ' AS (SELECT * FROM ' ||
                            dev_schema_name || '.' || diff.table_name || ');';
                INSERT INTO DDL_TABLE (TABLE_NAME, DDL_SCRIPT, "TYPE")
                VALUES (diff.TABLE_NAME, ddl_script, 'TABLE');
            END IF;
        END LOOP;
END;

CREATE OR REPLACE PROCEDURE PROD_DELETE_LIST(dev_schema_name VARCHAR2, prod_schema_name VARCHAR2)
    IS
    counter    NUMBER(10);
    counter2   NUMBER(10);
    ddl_script VARCHAR2(3000);
BEGIN
    FOR diff IN (Select DISTINCT table_name
                 from all_tab_columns
                 where owner = prod_schema_name
                   and (table_name, column_name) not in
                       (select table_name, column_name from all_tab_columns where owner = dev_schema_name))
        LOOP
            counter := 0;
            counter2 := 0;

            SELECT COUNT(column_name)
            INTO counter
            FROM all_tab_columns
            where owner = prod_schema_name
              and table_name = diff.table_name;

            SELECT COUNT(column_name)
            INTO counter2
            FROM all_tab_columns
            where owner = dev_schema_name
              and table_name = diff.table_name;

            IF counter2 = 0 AND counter != 0 THEN
                ddl_script := 'DROP TABLE ' || prod_schema_name || '.' || diff.table_name ||
                              ' CASCADE CONSTRAINTS;';
                INSERT INTO DDL_TABLE (TABLE_NAME, DDL_SCRIPT, "TYPE")
                VALUES (diff.TABLE_NAME, ddl_script, 'TABLE');
            ELSE
                FOR res2 IN (SELECT column_name
                             FROM all_tab_columns
                             WHERE OWNER = prod_schema_name
                               AND table_name = diff.table_name
                               AND column_name NOT IN (SELECT column_name
                                                       FROM all_tab_columns
                                                       WHERE OWNER = dev_schema_name
                                                         AND table_name = diff.table_name))
                    LOOP
                        ddl_script := 'ALTER TABLE ' || prod_schema_name || '.' || diff.table_name ||
                                      ' DROP COLUMN ' || res2.column_name || ';';
                        INSERT INTO DDL_TABLE (TABLE_NAME, DDL_SCRIPT, "TYPE")
                        VALUES (diff.TABLE_NAME, ddl_script, 'TABLE');
                    END LOOP;
            END IF;
        END LOOP;
END;

--CALL PROD_CREATE_LIST('DEV', 'PROD');
--CALL PROD_DELETE_LIST('DEV', 'PROD');


create or replace procedure GET_TABLES_ORDER(schema_name in varchar2) as
begin
    EXECUTE IMMEDIATE 'TRUNCATE TABLE fk_table';
    dbms_output.put_line('Showing tables order in schema');

    FOR schema_table IN (SELECT tables1.table_name name
                         FROM all_tables tables1
                         WHERE OWNER = schema_name)
        LOOP

            INSERT INTO fk_table (child, parent)
            SELECT DISTINCT a.table_name, c_pk.table_name
            FROM all_cons_columns a
                     JOIN all_constraints c ON a.owner = c.owner AND a.constraint_name = c.constraint_name
                     JOIN all_constraints c_pk ON c.r_owner = c_pk.owner AND c.r_constraint_name = c_pk.constraint_name
            WHERE c.constraint_type = 'R'
              AND a.table_name = schema_table.name;

        END LOOP;

    FOR fk_cur IN (
        SELECT CHILD, PARENT, MAX(LEVEL_2) as level_3, MAX(CONNECT_BY_ISYCLE_2) as CONNECT_BY_ISYCLE_3
        FROM (SELECT CHILD, parent, CONNECT_BY_ISCYCLE as CONNECT_BY_ISYCLE_2, LEVEL as LEVEL_2
              FROM fk_table
              CONNECT BY NOCYCLE PRIOR PARENT = child) levels
        GROUP BY CHILD, PARENT
        ORDER BY level_3 DESC
        )
        LOOP
            IF fk_cur.CONNECT_BY_ISYCLE_3 = 0 THEN
                UPDATE DDL_TABLE
                SET PRIORITY = fk_cur.level_3
                WHERE DDL_TABLE.TABLE_NAME = fk_cur.CHILD;
            ELSE
                dbms_output.put_line('CYCLE IN TABLE' || fk_cur.CHILD);
            END IF;
        END LOOP;
end GET_TABLES_ORDER;

--CALL GET_TABLES_ORDER('DEV');

CREATE TABLE ddl_table
(
    table_name VARCHAR2(100),
    ddl_script VARCHAR2(3000),
    type       VARCHAR2(100),
    priority   NUMBER(10) DEFAULT 100000
);

CREATE TABLE fk_table
(
    id     NUMBER,
    child  VARCHAR2(100),
    parent VARCHAR2(100)
);



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