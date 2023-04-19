
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

