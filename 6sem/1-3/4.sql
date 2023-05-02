----Parser----
CREATE OR REPLACE PACKAGE PARSER IS
    FUNCTION PARSE_OBJECTS(l_element JSON_ELEMENT_T) RETURN CLOB;
    FUNCTION PARSE_ARRAYS(l_json_array JSON_ARRAY_T, separator CLOB) RETURN CLOB;
    FUNCTION PARSE_ARRAYS(l_json_array JSON_KEY_LIST, separator CLOB) RETURN CLOB;
    FUNCTION CREATE_OPERATION(LHS CLOB, RHS CLOB, operation CLOB) RETURN CLOB;
    FUNCTION GET_OPERATION(l_object JSON_OBJECT_T) RETURN CLOB;
    FUNCTION GET_WHERE_TO_CLOB(l_json_array JSON_ARRAY_T) RETURN CLOB;
    FUNCTION GET_SELECT(l_object JSON_OBJECT_T) RETURN CLOB;
    FUNCTION GET_INSERT(l_object JSON_OBJECT_T) RETURN CLOB;
    FUNCTION GET_UPDATE(l_json_array JSON_ARRAY_T) RETURN CLOB;
    FUNCTION GET_UPDATE_FROM_OBJECT(l_object JSON_OBJECT_T) RETURN CLOB;
    FUNCTION GET_DELETE_FROM_OBJECT(l_object JSON_OBJECT_T) RETURN CLOB;
    FUNCTION GET_COLUMNS(l_json_array JSON_ARRAY_T) RETURN CLOB;
    FUNCTION GET_CREATE_TABLE(l_object JSON_OBJECT_T) RETURN CLOB;
    FUNCTION GET_CREATE(l_object JSON_OBJECT_T) RETURN CLOB;
    FUNCTION GET_DML(key_t VARCHAR2, json_obj JSON_OBJECT_T) RETURN CLOB;
    FUNCTION PARSE_OBJECT_ARGS(l_object JSON_OBJECT_T) RETURN CLOB;
END PARSER;

CREATE OR REPLACE PACKAGE BODY PARSER IS

    FUNCTION PARSE_OBJECTS(l_element JSON_ELEMENT_T) RETURN CLOB
        IS
    BEGIN
        return CASE
                   WHEN l_element.is_Object() = TRUE THEN PARSE_OBJECT_ARGS(JSON_OBJECT_T(l_element))
                   WHEN l_element.is_Array() = TRUE THEN PARSE_ARRAYS(JSON_ARRAY_T(l_element), ';')
                   ELSE REPLACE(l_element.to_string(), '"', '')
            END;
    END;

    FUNCTION PARSE_ARRAYS(l_json_array JSON_ARRAY_T, separator CLOB) RETURN CLOB
        IS
        temp    CLOB;
        res     CLOB    := '';
        isFirst BOOLEAN := TRUE;
        counter NUMBER;
    BEGIN
        FOR counter IN 0 .. (l_json_array.get_size() - 1)
            LOOP
                temp := PARSE_OBJECTS(l_json_array.get(counter));
                IF isFirst = TRUE THEN
                    isFirst := FALSE;
                ELSE
                    temp := CONCAT(separator, temp);
                END IF;
                res := CONCAT(res, temp);
            END LOOP;
        return res;
    END;

    FUNCTION PARSE_ARRAYS(l_json_array JSON_KEY_LIST, separator CLOB) RETURN CLOB
        IS
        temp    CLOB;
        res     CLOB    := '';
        isFirst BOOLEAN := TRUE;
        counter NUMBER;
    BEGIN
        FOR counter IN 1 .. l_json_array.COUNT
            LOOP
                temp := l_json_array(counter);
                IF isFirst = TRUE THEN
                    isFirst := FALSE;
                ELSE
                    temp := CONCAT(separator, temp);
                END IF;
                res := CONCAT(res, temp);
            END LOOP;
        return res;
    END;

    FUNCTION CREATE_OPERATION(LHS CLOB, RHS CLOB, operation CLOB) RETURN CLOB
        IS
    BEGIN
        return LHS || ' ' || operation || ' ' || RHS;
    END;

    FUNCTION GET_OPERATION(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        UNKNOWN_OPERATION EXCEPTION;
        PRAGMA exception_init (UNKNOWN_OPERATION , -20001 );
        ex        VARCHAR2(10) := 'UNKNOWN';
        res       CLOB;
        operation CLOB;
    BEGIN
        operation := UPPER(l_object.get_string('OPERATOR'));
        res := CASE
                   WHEN
                       operation in ('=', '!=', '<>', '<', '>', '>=', '<=', 'LIKE')
                       THEN CREATE_OPERATION(PARSE_OBJECTS(l_object.get('LHS')), PARSE_OBJECTS(l_object.get('RHS')),
                                             operation)
                   WHEN operation in ('IN', 'NOT IN') THEN CREATE_OPERATION(PARSE_OBJECTS(l_object.get('LHS')), '(' ||
                                                                                                                PARSE_ARRAYS(l_object.get_array('RHS'), ', ') ||
                                                                                                                ')',
                                                                            operation)
                   WHEN operation in ('BETWEEN')
                       THEN CREATE_OPERATION(PARSE_OBJECTS(l_object.get('LHS')),
                                             PARSE_ARRAYS(l_object.get_array('RHS'), ' AND '),
                                             operation)
                   WHEN operation in ('EXISTS', 'NOT EXISTS')
                       THEN operation || ' (' || PARSE_OBJECTS(l_object.get('RHS')) || ')'
                   ELSE ex
            END;
        IF res = ex THEN raise_application_error(-20001, 'Unknown operation: ' || operation); END IF;
        return res;
    END;

    FUNCTION GET_WHERE_TO_CLOB(l_json_array JSON_ARRAY_T) RETURN CLOB
        IS
        UNKNOWN_WHERE EXCEPTION;
        PRAGMA exception_init (UNKNOWN_WHERE, -20002 );
        ex       VARCHAR2(10) := 'UNKNOWN';
        counter  NUMBER;
        res      CLOB         := '';
        temp_str CLOB;
        l_object JSON_OBJECT_T;
    BEGIN
        FOR counter IN 0 .. (l_json_array.get_size() - 1)
            LOOP
                l_object := JSON_OBJECT_T(l_json_array.get(counter));
                temp_str := CASE
                                WHEN l_object.has('SEPARATOR') = TRUE THEN l_object.get_string('SEPARATOR')
                                WHEN l_object.has('OPERATOR') = TRUE THEN GET_OPERATION(l_object)
                                ELSE ex
                    END;
                IF temp_str = ex THEN
                    raise_application_error(-20002, 'Unknown where command: ' || l_object.to_string());
                END IF;
                res := CONCAT(res, CONCAT(' ', temp_str));
            END LOOP;
        return res;
    END;

    FUNCTION GET_SELECT(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        table_name_t  CLOB;
        select_name_t CLOB;
        where_t       CLOB;
        into_t        CLOB;
        res_str       CLOB;
    BEGIN
        table_name_t := l_object.get_string('TABLE_NAME');
        select_name_t := PARSE_ARRAYS(l_object.get_array('VALUES'), ', ');
        res_str := TO_CLOB('SELECT ' || select_name_t);
        IF l_object.has('INTO') = TRUE THEN
            into_t := PARSE_ARRAYS(l_object.get_array('INTO'), ', ');
            res_str := CONCAT(res_str, ' INTO ' || into_t);
        END IF;
        res_str := CONCAT(res_str, ' FROM ' || table_name_t);
        IF l_object.has('WHERE') = TRUE THEN
            where_t := Get_WHERE_TO_CLOB(l_object.get_array('WHERE'));
            res_str := CONCAT(res_str, ' WHERE' || where_t);
        END IF;
        return res_str;
    END;

    FUNCTION GET_INSERT(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        table_name_t  CLOB;
        select_name_t CLOB;
        insert_name_t CLOB;
        where_t       CLOB;
        res_str       CLOB;
        temp_str      CLOB;
        l_key_list    json_key_list;
        l_object_temp JSON_OBJECT_T;
        isFirst       BOOLEAN := TRUE;
    BEGIN
        table_name_t := l_object.get_string('TABLE_NAME');
        l_object_temp := l_object.get_object('VALUES');
        l_key_list := l_object_temp.get_Keys();
        FOR counter IN 1 .. l_key_list.COUNT
            LOOP
                temp_str := PARSE_OBJECTS(l_object_temp.get(l_key_list(counter)));
                IF isFirst = TRUE THEN
                    isFirst := FALSE;
                ELSE
                    temp_str := CONCAT(', ', temp_str);
                END IF;
                insert_name_t := CONCAT(insert_name_t, temp_str);
            END LOOP;
        select_name_t := PARSE_ARRAYS(l_key_list, ', ');
        res_str :=
                TO_CLOB('INSERT INTO ' || table_name_t || '(' || select_name_t || ') VALUES (' || insert_name_t || ')');
        IF l_object.has('WHERE') = TRUE THEN
            where_t := Get_WHERE_TO_CLOB(l_object.get_array('WHERE'));
            res_str := CONCAT(res_str, ' WHERE' || where_t);
        END IF;
        return res_str;
    END;

    FUNCTION GET_UPDATE(l_json_array JSON_ARRAY_T) RETURN CLOB
        IS
        counter  NUMBER;
        res      CLOB    := '';
        temp_str CLOB;
        isFirst  BOOLEAN := TRUE;
        l_object JSON_OBJECT_T;
    BEGIN
        FOR counter IN 0 .. (l_json_array.get_size() - 1)
            LOOP
                l_object := JSON_OBJECT_T(l_json_array.get(counter));
                IF isFirst = TRUE THEN
                    temp_str := CREATE_OPERATION(PARSE_OBJECTS(l_object.get('LHS')), PARSE_OBJECTS(l_object.get('RHS')),
                                                 '=');
                    isFirst := FALSE;
                ELSE
                    temp_str := CONCAT(', ',
                                       CREATE_OPERATION(PARSE_OBJECTS(l_object.get('LHS')),
                                                        PARSE_OBJECTS(l_object.get('RHS')),
                                                        '='));
                END IF;
                res := CONCAT(res, temp_str);
            END LOOP;
        return res;
    END;

    FUNCTION GET_UPDATE_FROM_OBJECT(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        table_name_t CLOB;
        set_name_t   CLOB;
        where_t      CLOB;
        res_str      CLOB;
    BEGIN
        table_name_t := l_object.get_string('TABLE_NAME');
        set_name_t := GET_UPDATE(l_object.get_array('VALUES'));
        res_str := TO_CLOB('UPDATE ' || table_name_t || ' SET ' || set_name_t);
        IF l_object.has('WHERE') = TRUE THEN
            where_t := GET_WHERE_TO_CLOB(l_object.get_array('WHERE'));
            res_str := CONCAT(res_str, ' WHERE' || where_t);
        END IF;
        return res_str;
    END;

    FUNCTION GET_DELETE_FROM_OBJECT(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        table_name_t CLOB;
        where_t      CLOB;
        res_str      CLOB;
    BEGIN
        table_name_t := l_object.get_string('TABLE_NAME');
        res_str := TO_CLOB('DELETE FROM ' || table_name_t);
        IF l_object.has('WHERE') = TRUE THEN
            where_t := Get_WHERE_TO_CLOB(l_object.get_array('WHERE'));
            res_str := CONCAT(res_str, ' WHERE' || where_t);
        END IF;
        return res_str;
    END;

    FUNCTION GET_COLUMNS(l_json_array JSON_ARRAY_T) RETURN CLOB
        IS
        UNKNOWN_UPDATE EXCEPTION;
        PRAGMA exception_init (UNKNOWN_UPDATE , -20004 );
        counter  integer;
        res      CLOB    := '';
        temp_str CLOB;
        str      CLOB;
        isFirst  BOOLEAN := TRUE;
        other_t  CLOB;
        l_object JSON_OBJECT_T;
    BEGIN
        FOR counter IN 0 .. (l_json_array.get_size() - 1)
            LOOP
                l_object := JSON_OBJECT_T(l_json_array.get(counter));
                str := PARSE_OBJECTS(l_object.get('NAME')) || ' ' || PARSE_OBJECTS(l_object.get('TYPE'));
                IF isFirst = TRUE THEN
                    temp_str := str;
                    isFirst := FALSE;
                ELSE
                    temp_str := CONCAT(', ', str);
                END IF;
                IF l_object.has('OTHER') = TRUE THEN
                    other_t := PARSE_ARRAYS(l_object.get_array('OTHER'), ' ');
                    temp_str := CONCAT(temp_str, ' ' || other_t);
                END IF;
                res := CONCAT(res, temp_str);
            END LOOP;
        return res;
    END;

    FUNCTION Get_OTHER_OPTIONS_TO_CLOB(l_json_array JSON_ARRAY_T) RETURN CLOB
        IS
    BEGIN
        return PARSE_ARRAYS(l_json_array, ' ');
    END;

    FUNCTION GET_CREATE_TABLE(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        table_name_t CLOB;
        colums_t     CLOB;
        res_str      CLOB;
    BEGIN
        table_name_t := l_object.get_string('NAME');
        colums_t := GET_COLUMNS(l_object.get_array('COLUMS'));
        res_str := TO_CLOB('CREATE TABLE ' || table_name_t || '(' || colums_t || ')');
        return res_str;
    END;

    FUNCTION Get_Create_Sequence_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        sequence_name_t CLOB;
        res_str         CLOB;
    BEGIN
        sequence_name_t := l_object.get_string('NAME');
        res_str := TO_CLOB('CREATE SEQUENCE ' || sequence_name_t);
        return res_str;
    END;

    FUNCTION Get_Create_Trigger_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        trigger_name_t  CLOB;
        table_name_t    CLOB;
        type_when_t     CLOB;
        event_t         CLOB;
        other_options_t CLOB;
        do_t            CLOB;
        res_str         CLOB;
    BEGIN
        trigger_name_t := l_object.get_string('NAME');
        table_name_t := l_object.get_string('TABLE_NAME');
        type_when_t := l_object.get_string('TYPE_WHEN');
        event_t := l_object.get_string('EVENT');
        res_str := TO_CLOB('CREATE TRIGGER ' || trigger_name_t || ' ' || type_when_t || ' ' || event_t || ' ON ' ||
                           table_name_t);
        IF l_object.has('OTHER_OPTIONS') = TRUE THEN
            other_options_t := Get_OTHER_OPTIONS_TO_CLOB(l_object.get_array('OTHER_OPTIONS'));
            res_str := CONCAT(res_str, ' ' || other_options_t);
        END IF;
        do_t := PARSE_ARRAYS(l_object.get_array('DO'), '; ') || '; ';
        return res_str || chr(10) || ' BEGIN ' || chr(10) || do_t || chr(10) || ' END;' || chr(10);
    END;

    FUNCTION GET_CREATE(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        UNKNOWN_TYPE EXCEPTION;
        PRAGMA exception_init (UNKNOWN_TYPE , -20006);
        ex       VARCHAR2(10) := 'UNKNOWN';
        res      CLOB;
        type_obj CLOB;
    BEGIN
        type_obj := UPPER(l_object.get_string('TYPE'));
        res := CASE type_obj
                   WHEN 'TABLE' THEN GET_CREATE_TABLE(l_object.get_object('VALUES'))
                   WHEN 'SEQUENCE' THEN Get_Create_Sequence_From_JSON_Object(l_object.get_object('VALUES'))
                   WHEN 'TRIGGER' THEN Get_Create_Trigger_From_JSON_Object(l_object.get_object('VALUES'))
                   ELSE ex
            END;
        IF res = ex THEN raise_application_error(-20001, 'Unknown type: ' || type_obj); END IF;
        return res;
    END;

    FUNCTION Get_Drop_Table_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        table_name_t CLOB;
        res_str      CLOB;
    BEGIN
        table_name_t := l_object.get_string('NAME');
        res_str := TO_CLOB('DROP TABLE ' || table_name_t);
        return res_str;
    END;

    FUNCTION Get_Drop_Sequence_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        sequence_name_t CLOB;
        res_str         CLOB;
    BEGIN
        sequence_name_t := l_object.get_string('NAME');
        res_str := TO_CLOB('DROP SEQUENCE ' || sequence_name_t);
        return res_str;
    END;

    FUNCTION Get_Drop_Trigger_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        trigger_name_t CLOB;
        res_str        CLOB;
    BEGIN
        trigger_name_t := l_object.get_string('NAME');
        res_str := TO_CLOB('DROP TRIGGER ' || trigger_name_t);
        return res_str;
    END;

    FUNCTION Get_Drop_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        UNKNOWN_TYPE EXCEPTION;
        PRAGMA exception_init (UNKNOWN_TYPE , -20006);
        ex       VARCHAR2(10) := 'UNKNOWN';
        res      CLOB;
        type_obj CLOB;
    BEGIN
        type_obj := UPPER(l_object.get_string('TYPE'));
        res := CASE type_obj
                   WHEN 'TABLE' THEN Get_Drop_Table_From_JSON_Object(l_object.get_object('VALUES'))
                   WHEN 'SEQUENCE' THEN Get_Drop_Sequence_From_JSON_Object(l_object.get_object('VALUES'))
                   WHEN 'TRIGGER' THEN Get_Drop_Trigger_From_JSON_Object(l_object.get_object('VALUES'))
                   ELSE ex
            END;
        IF res = ex THEN raise_application_error(-20001, 'Unknown type: ' || type_obj); END IF;
        return res;
    END;

    FUNCTION GET_DML(key_t VARCHAR2, json_obj JSON_OBJECT_T) RETURN CLOB
        IS
        UNKNOWN_COMMAND EXCEPTION;
        PRAGMA exception_init (UNKNOWN_COMMAND, -20003 );
        str_exe CLOB;
        ex      VARCHAR2(10) := 'UNKNOWN';
    BEGIN
        str_exe := CASE UPPER(key_t)
                       WHEN 'SELECT' THEN GET_SELECT(json_obj)
                       WHEN 'INSERT' THEN GET_INSERT(json_obj)
                       WHEN 'UPDATE' THEN GET_UPDATE_FROM_OBJECT(json_obj)
                       WHEN 'DELETE' THEN GET_DELETE_FROM_OBJECT(json_obj)
                       WHEN 'CREATE' THEN GET_CREATE(json_obj)
                       WHEN 'DROP' THEN Get_Drop_From_JSON_Object(json_obj)
                       ELSE ex
            END;
        IF str_exe = ex THEN raise_application_error(-20003, 'Unknown command: ' || UPPER(key_t)); END IF;
        return str_exe;
    END;

    FUNCTION Parse_Int(l_element JSON_ELEMENT_T) RETURN CLOB
        IS
    BEGIN
        return REPLACE(l_element.to_string(), '"', '');
    END;

    FUNCTION Parse_Varchar2(l_element JSON_ELEMENT_T) RETURN CLOB
        IS
    BEGIN
        return REPLACE(l_element.to_string(), '"', '''');
    END;

    FUNCTION Parse_Timestamp(l_element JSON_ELEMENT_T) RETURN CLOB
        IS
    BEGIN
        return 'to_timestamp(' || Parse_Varchar2(l_element) || ', ''YYYY-MM-DD HH24:MI:SS'') ';
    END;

    FUNCTION PARSE_OBJECT_ARGS(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        INVALID_ARGS EXCEPTION;
        PRAGMA exception_init (INVALID_ARGS, -20001 );
        l_key_list json_key_list;
        res        CLOB := '';
    BEGIN
        IF l_object.has('TYPE') THEN
            res := CASE UPPER(l_object.get_string('TYPE'))
                       WHEN 'INTEGER' THEN Parse_int(l_object.get('VALUE'))
                       WHEN 'VARCHAR2' THEN Parse_Varchar2(l_object.get('VALUE'))
                       WHEN 'TIMESTAMP' THEN Parse_Timestamp(l_object.get('VALUE'))
                END;
        ELSE
            l_key_list := l_object.get_Keys();
            IF l_key_list.COUNT != 1 THEN
                raise INVALID_ARGS;
            END IF;
            res := GET_DML(l_key_list(1), l_object.get_object(l_key_list(1)));
        END IF;
        return res;
    END;
END PARSER;

----Методы----
DROP TYPE clobs_array;

CREATE OR REPLACE TYPE clobs_array IS TABLE OF CLOB;

CREATE OR REPLACE FUNCTION DO_PARSE(l_object JSON_OBJECT_T) RETURN clobs_array
    IS
    l_array   json_array_t;
    str_array clobs_array := clobs_array();
    counter   integer;
BEGIN
    IF l_object.has('START') = TRUE THEN
        l_array := l_object.get_array('START');
        FOR counter in 0..(l_array.get_size() - 1)
            LOOP
                str_array.extend();
                str_array(str_array.COUNT) := PARSER.PARSE_OBJECTS(l_array.get(counter));
            END LOOP;
    ELSE
        str_array.extend();
        str_array(str_array.COUNT) := PARSER.PARSE_OBJECTS(l_object);
    END IF;
    return str_array;
END;

CREATE OR REPLACE FUNCTION Get_Cursor_By(l_object JSON_OBJECT_T) RETURN SYS_REFCURSOR
    IS
    res_cur   SYS_REFCURSOR;
    str_array clobs_array;
    counter   integer;
BEGIN
    str_array := DO_PARSE(l_object);
    FOR counter in 1..str_array.COUNT
        LOOP
            OPEN res_cur for str_array(counter);
        END LOOP;
    return res_cur;
END;

CREATE OR REPLACE PROCEDURE Invoke_By(l_object JSON_OBJECT_T)
    IS
    str_array clobs_array;
    counter   integer;
BEGIN
    str_array := DO_PARSE(l_object);
    FOR counter in 1..str_array.COUNT
        LOOP
            DBMS_OUTPUT.PUT_LINE(str_array(counter) || ';');
            --EXECUTE IMMEDIATE str_array(counter);
        END LOOP;
END;

CREATE OR REPLACE FUNCTION Try_Get_Cursor_By(l_object JSON_OBJECT_T) RETURN SYS_REFCURSOR
    IS
    res SYS_REFCURSOR;
BEGIN
    res := Get_Cursor_By(l_object);
    return res;
EXCEPTION
    WHEN OTHERS THEN
        Invoke_By(l_object);
        OPEN res FOR
            select * from dual where 1 = 2;
        return res;
END;

----Examples----

DECLARE
    l_object JSON_OBJECT_T;
    cur      SYS_REFCURSOR;
BEGIN
    l_object := JSON_OBJECT_T.Parse(
            '{
  "START": [

    {
      "SELECT":
      {
        "TABLE_NAME": "T1",
        "VALUES":
        [
          "*"
        ],
        "WHERE":
        [
          {
            "LHS": "ID",
            "OPERATOR": "IN",
            "RHS": [{
              "SELECT":
              {
                "TABLE_NAME": "T2",
                "VALUES":
                [
                  "ID"
                ],
                "WHERE": [
                  {
                    "LHS": "NAME",
                    "OPERATOR": "LIKE",
                    "RHS": ''%a%''
                  },
                  {
                    "SEPARATOR": "AND"
                  },
                  {
                    "LHS": "NUM",
                    "OPERATOR": "BETWEEN",
                    "RHS": [
                      {
                        "VALUE": 2,
                        "TYPE": "INTEGER"
                    },
                    {
                      "VALUE": 4,
                      "TYPE": "INTEGER"
                    }]
                  }
                ]
              }
            }]
          }
        ]
      }
    }
  ]
}');
    cur := Try_Get_Cursor_By(l_object);

    close cur;
END;

CREATE OR REPLACE DIRECTORY DIR AS 'D:\MDiSUBD\6sem\1-3';


DECLARE
    file     UTL_FILE.FILE_TYPE;
    text     CLOB;
    temp     CLOB;
    l_object JSON_OBJECT_T;
    cur      SYS_REFCURSOR;


DECLARE
    file_handle UTL_FILE.FILE_TYPE;
    clob_data   CLOB;
    buffer      VARCHAR2(32767);
    amount      INTEGER := 32767;
    l_object    JSON_OBJECT_T;

BEGIN
    file_handle := UTL_FILE.FOPEN('DIR', 'query.json', 'R');
    DBMS_LOB.CREATETEMPORARY(clob_data, TRUE);
    LOOP
        UTL_FILE.GET_LINE(file_handle, buffer, amount);
        DBMS_LOB.WRITEAPPEND(clob_data, LENGTH(buffer), buffer);
        EXIT WHEN buffer = '}';
    END LOOP;
    UTL_FILE.FCLOSE(file_handle);
    l_object = JSON_OBJECT_T.Parse(clob_data);
    cur := Try_Get_Cursor_By(l_object);

    close cur;

END;
