alter session set current_schema = XOTAB;

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