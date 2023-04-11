alter session set current_schema = XOTAB;

CREATE OR REPLACE FUNCTION compare_schemas(dev_schema_name IN VARCHAR2, prod_schema_name IN VARCHAR2)
    RETURN VARCHAR2
AS
    cursor c_dev_tables is
        SELECT table_name
        FROM all_tables
        WHERE owner = dev_schema_name;
    cursor c_prod_tables is
        SELECT table_name
        FROM all_tables
        WHERE owner = prod_schema_name;
    cursor c_dev_objects is
        SELECT object_name, object_type, dbms_metadata.get_ddl(object_type, object_name, dev_schema_name) as ddl
        FROM all_objects
        WHERE owner = dev_schema_name
          AND object_type IN ('FUNCTION', 'PROCEDURE', 'PACKAGE', 'PACKAGE BODY', 'INDEX');
    cursor c_prod_objects is
        SELECT object_name, object_type
        FROM all_objects
        WHERE owner = prod_schema_name
          AND object_type IN ('FUNCTION', 'PROCEDURE', 'PACKAGE', 'PACKAGE BODY', 'INDEX');
    type t_diff_list is table of varchar2(100);
    diff_list       t_diff_list     := t_diff_list();
    current_table   varchar2(30);
    current_object  varchar2(100);
    first_iteration boolean         := true;
    result          varchar2(32000) := '';
BEGIN
    DBMS_OUTPUT.PUT_LINE('1');
-- Compare tables
    open c_dev_tables;
    open c_prod_tables;
    loop
        fetch c_dev_tables into current_table;
        exit when c_dev_tables%notfound;
        if first_iteration or current_table != dev_row.table_name then
            if diff_list.count > 0 then
                result := result || current_table || ' is different in ' || dev_schema_name || ' and ' ||
                          prod_schema_name || ' schemas' || chr(10);
                for i in 1..diff_list.count
                    loop
                        result := result || diff_list(i) || chr(10);
                    end loop;
                diff_list.delete;
            end if;
            first_iteration := false;
        end if;

        if not exists (select 1 from all_tables where owner = prod_schema_name and table_name = current_table) then
            result := result || current_table || ' is not found in ' || prod_schema_name || ' schema' || chr(10);
            continue;
        end if;

        execute immediate 'alter session set current_schema = ' || dev_schema_name;
        execute immediate 'select dbms_metadata.compare_table_ddl(''' || current_table || ''', ''' || current_table ||
                          ''', ''' || dev_schema_name || ''', ''' || prod_schema_name || ''') from dual' into result;
        if result is not null then
            result := 'Table ' || current_table || ' has differences:' || chr(10) || result || chr(10);
        end if;
    end loop;

    if diff_list.count > 0 then
        result := result || current_table || ' is different in ' || dev_schema_name || ' and ' || prod_schema_name ||
                  ' schemas' || chr(10);
        for i in 1..diff_list.count
            loop
                result := result || diff_list(i) || chr(10);
            end loop;
    end if;

    close c_dev_tables;
    close c_prod_tables;

-- Compare objects
    open c_dev_objects;
    open c_prod_objects;
    loop
        fetch c_dev_objects into current_object, object_type, ddl;
        exit when c_dev_objects%notfound;

        if not exists(select 1
                      from all_objects
                      where owner = prod_schema_name
                        and object_name = current_object
                        and object_type = object_type) then
            result := result || current_object || ' (' || object_type || ')' || ' is not found in ' ||
                      prod_schema_name ||
                      ' schema' || chr(10);
            continue;
        end if;

        execute immediate 'alter session set current_schema = ' || dev_schema_name;
        execute immediate 'select dbms_metadata.compare_' || object_type || '_ddl(''' || current_object || ''', ''' ||
                          dev_schema_name || ''', ''' || prod_schema_name || ''') from dual' into result;
        if result is not null then
            diff_list.extend;
            diff_list(diff_list.count) := current_object || ' (' || object_type || ')' || ': ' || result;
        end if;
    end loop;

    if diff_list.count > 0 then
        result := result || 'Objects with differences:' || chr(10);
        for i in 1..diff_list.count
            loop
                result := result || diff_list(i) || chr(10);
            end loop;
    end if;

    close c_dev_objects;
    close c_prod_objects;

-- Delete objects missing in prod
    execute immediate 'alter session set current_schema = ' || prod_schema_name;
    for dev_obj in (SELECT object_name, object_type
                    FROM all_objects
                    WHERE owner = dev_schema_name
                      AND object_type IN ('FUNCTION', 'PROCEDURE', 'PACKAGE', 'PACKAGE BODY', 'INDEX')
                      AND NOT EXISTS(SELECT 1
                                     FROM all_objects
                                     WHERE owner = prod_schema_name
                                       AND object_name = dev_obj.object_name
                                       AND object_type = dev_obj.object_type))
        loop
            execute immediate 'drop ' || dev_obj.object_type || ' ' || dev_obj.object_name;
            result := result || dev_obj.object_name || ' (' || dev_obj.object_type || ')' || ' was deleted from ' ||
                      prod_schema_name || ' schema' || chr(10);
        end loop;

    return result;

END compare_schemas;
BEGIN
    dbms_output.put_line(compare_schemas('DEV', 'PROD'));
END;
----dev-----
alter session set current_schema = DEV;

DROP TABLE USERS;
CREATE TABLE USERS
(
    ID   NUMBER PRIMARY KEY NOT NULL,
    NAME VARCHAR2(100)      NOT NULL,
    AGE  NUMBER
);
CREATE TABLE CLIENTS
(
    ID      NUMBER PRIMARY KEY NOT NULL,
    USER_ID NUMBER             NOT NULL,
    CONSTRAINT fk_user FOREIGN KEY (USER_ID) REFERENCES USERS (ID),
    phone   VARCHAR2(10)
);
----prod----
alter session set current_schema = PROD;
CREATE TABLE USERS
(
    ID   NUMBER PRIMARY KEY NOT NULL,
    NAME VARCHAR2(100)      NOT NULL,
    AGE  NUMBER
);
CREATE TABLE CLIENTS
(
    ID      NUMBER PRIMARY KEY NOT NULL,
    USER_ID NUMBER             NOT NULL,
    CONSTRAINT fk_user FOREIGN KEY (USER_ID) REFERENCES USERS (ID),
    email   VARCHAR2(100)
);