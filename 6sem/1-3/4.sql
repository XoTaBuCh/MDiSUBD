----Parser----
CREATE OR REPLACE PACKAGE JSON_PARSER IS
    FUNCTION Parse_Arg(l_element JSON_ELEMENT_T) RETURN CLOB;
    FUNCTION Parse_Array_Args(l_json_array JSON_ARRAY_T, separator CLOB) RETURN CLOB;
    FUNCTION Parse_Array_Args(l_json_array JSON_KEY_LIST, separator CLOB) RETURN CLOB;
    FUNCTION Make_Operation(LHS CLOB, RHS CLOB, operation CLOB) RETURN CLOB;
    FUNCTION Get_Operation(l_object JSON_OBJECT_T) RETURN CLOB;
    FUNCTION GET_WHERE_TO_CLOB(l_json_array JSON_ARRAY_T) RETURN CLOB;
    FUNCTION Get_Select_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB;
    FUNCTION Get_Insert_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB;
    FUNCTION Get_UPDATE_TO_CLOB(l_json_array JSON_ARRAY_T) RETURN CLOB;
    FUNCTION Get_Update_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB;
    FUNCTION Get_Delete_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB;
    FUNCTION Get_COLUMNS_TO_CLOB(l_json_array JSON_ARRAY_T) RETURN CLOB;
    FUNCTION Get_Create_Table_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB;
    FUNCTION Get_Create_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB;
    FUNCTION Get_DML_Clob(key_t VARCHAR2, json_obj JSON_OBJECT_T) RETURN CLOB;
    FUNCTION Parse_Object_Args(l_object JSON_OBJECT_T) RETURN CLOB;
END JSON_PARSER;

CREATE OR REPLACE PACKAGE BODY JSON_PARSER IS

    FUNCTION Parse_Arg(l_element JSON_ELEMENT_T) RETURN CLOB
        IS
    BEGIN
        return CASE
                   WHEN l_element.is_Object() = TRUE THEN Parse_Object_Args(JSON_OBJECT_T(l_element))
                   WHEN l_element.is_Array() = TRUE THEN Parse_Array_Args(JSON_ARRAY_T(l_element), ';')
                   ELSE REPLACE(l_element.to_string(), '"', '')
            END;
    END;

    FUNCTION Parse_Array_Args(l_json_array JSON_ARRAY_T, separator CLOB) RETURN CLOB
        IS
        temp    CLOB;
        res     CLOB    := '';
        isFirst BOOLEAN := TRUE;
        counter NUMBER;
    BEGIN
        FOR counter IN 0 .. (l_json_array.get_size() - 1)
            LOOP
                temp := Parse_Arg(l_json_array.get(counter));
                IF isFirst = TRUE THEN
                    isFirst := FALSE;
                ELSE
                    temp := CONCAT(separator, temp);
                END IF;
                res := CONCAT(res, temp);
            END LOOP;
        return res;
    END;

    FUNCTION Parse_Array_Args(l_json_array JSON_KEY_LIST, separator CLOB) RETURN CLOB
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

    FUNCTION Make_Operation(LHS CLOB, RHS CLOB, operation CLOB) RETURN CLOB
        IS
    BEGIN
        return LHS || ' ' || operation || ' ' || RHS;
    END;

    FUNCTION Get_Operation(l_object JSON_OBJECT_T) RETURN CLOB
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
                       operation in ('=', '!=', '<>', '<', '>', '>=', '<=')
                       THEN Make_Operation(Parse_Arg(l_object.get('LHS')), Parse_Arg(l_object.get('RHS')), operation)
                   WHEN operation in ('IN', 'NOT IN') THEN Make_Operation(Parse_Arg(l_object.get('LHS')), '(' ||
                                                                                                          Parse_Array_Args(l_object.get_array('RHS'), ', ') ||
                                                                                                          ')',
                                                                          operation)
                   WHEN operation in ('EXISTS', 'NOT EXISTS')
                       THEN operation || ' (' || Parse_Arg(l_object.get('RHS')) || ')'
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
                                WHEN l_object.has('OPERATOR') = TRUE THEN Get_Operation(l_object)
                                ELSE ex
                    END;
                IF temp_str = ex THEN
                    raise_application_error(-20002, 'Unknown where command: ' || l_object.to_string());
                END IF;
                res := CONCAT(res, CONCAT(' ', temp_str));
            END LOOP;
        return res;
    END;

    FUNCTION Get_Select_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        table_name_t  CLOB;
        select_name_t CLOB;
        where_t       CLOB;
        into_t        CLOB;
        res_str       CLOB;
    BEGIN
        table_name_t := l_object.get_string('TABLE_NAME');
        select_name_t := Parse_array_Args(l_object.get_array('VALUES'), ', ');
        res_str := TO_CLOB('SELECT ' || select_name_t);
        IF l_object.has('INTO') = TRUE THEN
            into_t := Parse_Array_Args(l_object.get_array('INTO'), ', ');
            res_str := CONCAT(res_str, ' INTO ' || into_t);
        END IF;
        res_str := CONCAT(res_str, ' FROM ' || table_name_t);
        IF l_object.has('WHERE') = TRUE THEN
            where_t := Get_WHERE_TO_CLOB(l_object.get_array('WHERE'));
            res_str := CONCAT(res_str, ' WHERE' || where_t);
        END IF;
        return res_str;
    END;

    FUNCTION Get_Insert_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB
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
                temp_str := Parse_Arg(l_object_temp.get(l_key_list(counter)));
                IF isFirst = TRUE THEN
                    isFirst := FALSE;
                ELSE
                    temp_str := CONCAT(', ', temp_str);
                END IF;
                insert_name_t := CONCAT(insert_name_t, temp_str);
            END LOOP;
        select_name_t := Parse_Array_Args(l_key_list, ', ');
        res_str :=
                TO_CLOB('INSERT INTO ' || table_name_t || '(' || select_name_t || ') VALUES (' || insert_name_t || ')');
        IF l_object.has('WHERE') = TRUE THEN
            where_t := Get_WHERE_TO_CLOB(l_object.get_array('WHERE'));
            res_str := CONCAT(res_str, ' WHERE' || where_t);
        END IF;
        return res_str;
    END;

    FUNCTION GET_UPDATE_TO_CLOB(l_json_array JSON_ARRAY_T) RETURN CLOB
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
                    temp_str := Make_Operation(Parse_Arg(l_object.get('LHS')), Parse_Arg(l_object.get('RHS')), '=');
                    isFirst := FALSE;
                ELSE
                    temp_str := CONCAT(', ',
                                       Make_Operation(Parse_Arg(l_object.get('LHS')), Parse_Arg(l_object.get('RHS')),
                                                      '='));
                END IF;
                res := CONCAT(res, temp_str);
            END LOOP;
        return res;
    END;

    FUNCTION Get_Update_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        table_name_t CLOB;
        set_name_t   CLOB;
        where_t      CLOB;
        res_str      CLOB;
    BEGIN
        table_name_t := l_object.get_string('TABLE_NAME');
        set_name_t := Get_UPDATE_TO_CLOB(l_object.get_array('VALUES'));
        res_str := TO_CLOB('UPDATE ' || table_name_t || ' SET ' || set_name_t);
        IF l_object.has('WHERE') = TRUE THEN
            where_t := GET_WHERE_TO_CLOB(l_object.get_array('WHERE'));
            res_str := CONCAT(res_str, ' WHERE' || where_t);
        END IF;
        return res_str;
    END;

    FUNCTION Get_Delete_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB
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

    FUNCTION Get_COLUMS_TO_CLOB(l_json_array JSON_ARRAY_T) RETURN CLOB
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
                str := parse_arg(l_object.get('NAME')) || ' ' || parse_arg(l_object.get('TYPE'));
                IF isFirst = TRUE THEN
                    temp_str := str;
                    isFirst := FALSE;
                ELSE
                    temp_str := CONCAT(', ', str);
                END IF;
                IF l_object.has('OTHER') = TRUE THEN
                    other_t := Parse_Array_Args(l_object.get_array('OTHER'), ' ');
                    temp_str := CONCAT(temp_str, ' ' || other_t);
                END IF;
                res := CONCAT(res, temp_str);
            END LOOP;
        return res;
    END;

    FUNCTION Get_OTHER_OPTIONS_TO_CLOB(l_json_array JSON_ARRAY_T) RETURN CLOB
        IS
    BEGIN
        return parse_array_args(l_json_array, ' ');
    END;

    FUNCTION Get_Create_Table_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        table_name_t CLOB;
        colums_t     CLOB;
        res_str      CLOB;
    BEGIN
        table_name_t := l_object.get_string('NAME');
        colums_t := Get_COLUMNS_TO_CLOB(l_object.get_array('COLUMS'));
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
        do_t := Parse_array_args(l_object.get_array('DO'), '; ') || '; ';
        return res_str || chr(10) || ' BEGIN ' || chr(10) || do_t || chr(10) || ' END;' || chr(10);
    END;

    FUNCTION Get_Create_From_JSON_Object(l_object JSON_OBJECT_T) RETURN CLOB
        IS
        UNKNOWN_TYPE EXCEPTION;
        PRAGMA exception_init (UNKNOWN_TYPE , -20006);
        ex       VARCHAR2(10) := 'UNKNOWN';
        res      CLOB;
        type_obj CLOB;
    BEGIN
        type_obj := UPPER(l_object.get_string('TYPE'));
        res := CASE type_obj
                   WHEN 'TABLE' THEN Get_Create_Table_From_JSON_Object(l_object.get_object('VALUES'))
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
        trigger_name_t  CLOB;
        res_str         CLOB;
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

    FUNCTION Get_DML_Clob(key_t VARCHAR2, json_obj JSON_OBJECT_T) RETURN CLOB
        IS
        UNKNOWN_COMMAND EXCEPTION;
        PRAGMA exception_init (UNKNOWN_COMMAND, -20003 );
        str_exe CLOB;
        ex      VARCHAR2(10) := 'UNKNOWN';
    BEGIN
        str_exe := CASE UPPER(key_t)
                       WHEN 'SELECT' THEN Get_Select_From_JSON_Object(json_obj)
                       WHEN 'INSERT' THEN Get_Insert_From_JSON_Object(json_obj)
                       WHEN 'UPDATE' THEN Get_Update_From_JSON_Object(json_obj)
                       WHEN 'DELETE' THEN Get_Delete_From_JSON_Object(json_obj)
                       WHEN 'CREATE' THEN Get_Create_From_JSON_Object(json_obj)
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

    FUNCTION Parse_Object_Args(l_object JSON_OBJECT_T) RETURN CLOB
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
            res := Get_DML_Clob(l_key_list(1), l_object.get_object(l_key_list(1)));
        END IF;
        return res;
    END;
END JSON_PARSER;

----Examples----

CREATE TABLE YourTable(
    CODE INTEGER,
    VAL INTEGER
);

DECLARE
    l_object JSON_OBJECT_T;
    cur      SYS_REFCURSOR;
    CODE     integer;
    VAL      integer;
BEGIN
    l_object := JSON_OBJECT_T.Parse(
            '{
                "SELECT": {
                    "TABLE_NAME": "YourTable",
                    "VALUES": [
                        "CODE",
                        "Val"
                    ],
                    "WHERE": [
                        {
                            "LHS": "CODE",
                            "RHS": {
                                "TYPE": "INTEGER",
                                "VALUE": 5
                            },
                            "OPERATOR": "="
                        },
                        {
                            "SEPARATOR": "OR"
                        },
                        {
                            "OPERATOR": "EXISTS",
                            "RHS": {
                                "SELECT": {
                                    "TABLE_NAME": "YourTable",
                                    "VALUES": [
                                        "CODE",
                                        "Val"
                                    ],
                                    "WHERE": [
                                        {
                                            "LHS": "CODE",
                                            "RHS": [
                                                {
                                                    "TYPE": "INTEGER",
                                                    "VALUE": 9996
                                                },
                                                {
                                                    "TYPE": "INTEGER",
                                                    "VALUE": 9997
                                                },
                                                {
                                                    "TYPE": "INTEGER",
                                                    "VALUE": 9998
                                                },
                                                {
                                                    "TYPE": "INTEGER",
                                                    "VALUE": 9999
                                                },
                                                {
                                                    "TYPE": "INTEGER",
                                                    "VALUE": 10000
                                                }
                                            ],
                                            "OPERATOR": "NOT IN"
                                        }
                                    ]
                                }
                            }
                        }
                    ]
                }
            }');
    DBMS_OUTPUT.PUT_LINE('check');
    DBMS_OUTPUT.PUT_LINE(JSON_PARSER.Parse_Arg(l_object));
    cur := TRY_Get_Cursor_By(l_object);
    LOOP
        FETCH cur INTO CODE, VAL;
        EXIT WHEN cur%notfound;
        DBMS_OUTPUT.put_line(code || ' ' || val);
    END LOOP;
    close cur;
END;


SELECT *
FROM YourTable;

DECLARE
    l_object JSON_OBJECT_T;
    cur      SYS_REFCURSOR;
BEGIN
    l_object := JSON_OBJECT_T.Parse(
            '{
                "INSERT": {
                    "TABLE_NAME": "YourTable",
                    "VALUES": {
                        "VAL": {
                            "VALUE": 6,
                            "TYPE": "INTEGER"
                        }
                    }
                }
            }');
    DBMS_OUTPUT.PUT_LINE('check');
    DBMS_OUTPUT.PUT_LINE(JSON_PARSER.Parse_Arg(l_object));
    cur := Try_Get_Cursor_By(l_object);
    close cur;
END;

DECLARE
    l_object JSON_OBJECT_T;
    cur      SYS_REFCURSOR;
BEGIN
    l_object := JSON_OBJECT_T.Parse(
            '{
                "UPDATE": {
                    "TABLE_NAME": "YourTable",
                    "VALUES": [
                        {
                            "LHS": "VAL",
                            "RHS": {
                                "VALUE": 1000,
                                "TYPE": "INTEGER"
                            }
                        }
                    ],
                    "WHERE":[
                        {
                            "LHS": "CODE",
                            "RHS": {
                                "VALUE": 10002,
                                "TYPE": "INTEGER"
                            },
                            "OPERATOR": "="
                        }
                    ]
                }
            }');
    DBMS_OUTPUT.PUT_LINE('check');
    DBMS_OUTPUT.PUT_LINE(JSON_PARSER.Parse_Arg(l_object));
    cur := Try_Get_Cursor_By(l_object);
    close cur;
END;



DECLARE
    l_object JSON_OBJECT_T;
    cur      SYS_REFCURSOR;
BEGIN
    l_object := JSON_OBJECT_T.Parse(
            '{
                "DELETE": {
                    "TABLE_NAME": "YourTable"
                }
            }');
    DBMS_OUTPUT.PUT_LINE('check');
    cur := Try_Get_Cursor_By(l_object);
    close cur;
END;

select *
from yourtable;



DECLARE
    l_object JSON_OBJECT_T;
    cur      SYS_REFCURSOR;
BEGIN
    l_object := JSON_OBJECT_T.Parse(
            '{
                "START":[
                    {
                        "CREATE": {
                            "TYPE": "TABLE",
                            "VALUES": {
                                "NAME": "MyTableTEST",
                                "COLUMS": [
                                    {
                                        "NAME": "CODE",
                                        "TYPE": "INTEGER",
                                        "OTHER": [
                                            "NOT NULL"
                                        ]
                                    },
                                    {
                                        "NAME": "NAME",
                                        "TYPE": "VARCHAR(20)"
                                    }
                                ]
                            }
                        }
                    },
                    {
                        "CREATE": {
                            "TYPE": "SEQUENCE",
                            "VALUES": {
                                "NAME": "MyTableTEST_SEQ"
                            }
                        }
                    },
                    {
                        "CREATE": {
                            "TYPE": "TRIGGER",
                            "VALUES": {
                                "NAME": "MyTableTEST_Trigger",
                                "TYPE_WHEN": "Before",
                                "EVENT": "insert",
                                "TABLE_NAME": "MyTableTEST",
                                "OTHER_OPTIONS": [
                                    "FOR EACH ROW"
                                ],
                            "DO": [
                                {
                                    "SELECT": {
                                        "TABLE_NAME": "dual",
                                        "VALUES": [
                                            "MyTableTEST_SEQ.NEXTVAL"
                                        ],
                                        "INTO": [
                                            ":new.Code"
                                        ]
                                    }
                                }
                            ]
                            }
                        }
                    }
                ]
            }');
    DBMS_OUTPUT.PUT_LINE('check');
    DBMS_OUTPUT.PUT_LINE(JSON_PARSER.Parse_Arg(l_object.get('START')));
    cur := Try_Get_Cursor_By(l_object);
    close cur;
END;


select *
from MYTABLETEST;



INSERT INTO MYTABLETEST(NAME)
VALUES ('dfdsfsd');


DECLARE
    l_object JSON_OBJECT_T;
    cur      SYS_REFCURSOR;
BEGIN
    l_object := JSON_OBJECT_T.Parse(
            '{
                "START":[
                    {
                        "DROP": {
                            "TYPE": "TRIGGER",
                            "VALUES": {
                                "NAME": "MyTableTEST_Trigger"
                            }
                        }
                    },
                    {
                        "DROP": {
                            "TYPE": "TABLE",
                            "VALUES": {
                                "NAME": "MyTableTEST"
                            }
                        }
                    },
                    {
                        "DROP": {
                            "TYPE": "SEQUENCE",
                            "VALUES": {
                                "NAME": "MyTableTEST_SEQ"
                            }
                        }
                    }
                ]
            }');
    DBMS_OUTPUT.PUT_LINE('check');
    DBMS_OUTPUT.PUT_LINE(JSON_PARSER.Parse_Arg(l_object.get('START')));
    cur := Try_Get_Cursor_By(l_object);
    close cur;
END;

