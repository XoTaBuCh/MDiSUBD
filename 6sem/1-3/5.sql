drop table orders;
drop table customers;
drop table medicines;


CREATE TABLE customers
(
    customer_id  NUMBER(10)
        CONSTRAINT PK_customers PRIMARY KEY,
    first_name   VARCHAR2(50),
    last_name    VARCHAR2(50),
    email        VARCHAR2(100) UNIQUE,
    phone_number VARCHAR2(50)
);

CREATE TABLE medicines
(
    medicine_id   NUMBER(10)
        CONSTRAINT PK_medicines PRIMARY KEY,
    medicine_name VARCHAR2(100),
    description   VARCHAR2(500),
    price         NUMBER
);

CREATE TABLE orders
(
    order_id    NUMBER(10)
        CONSTRAINT PK_orders PRIMARY KEY,
    order_date  DATE,
    customer_id NUMBER(10),
    medicine_id NUMBER(10),
    amount      NUMBER(10),
    CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
    CONSTRAINT fk_medicine FOREIGN KEY (medicine_id) REFERENCES medicines (medicine_id)
);

--------------

drop table customers_history;
drop table medicines_history;
drop table orders_history;

CREATE TABLE customers_history
(
    action_id    number,
    customer_id  NUMBER(10),
    first_name   VARCHAR2(50),
    last_name    VARCHAR2(50),
    email        VARCHAR2(100),
    phone_number VARCHAR2(50),
    change_date  DATE,
    change_type  VARCHAR2(10)
);

CREATE TABLE medicines_history
(
    action_id     number,
    medicine_id   NUMBER(10),
    medicine_name VARCHAR2(100),
    description   VARCHAR2(500),
    price         NUMBER,
    change_date   DATE,
    change_type   VARCHAR2(10)
);

CREATE TABLE orders_history
(
    action_id   number,
    order_id    NUMBER(10),
    order_date  DATE,
    customer_id NUMBER(10),
    medicine_id NUMBER(10),
    amount      NUMBER(10),
    change_date DATE,
    change_type VARCHAR2(10)
);

drop table reports_history;
create table reports_history
(
    id          number GENERATED ALWAYS AS IDENTITY,
    report_date timestamp,
    CONSTRAINT PK_reports PRIMARY KEY (id)
);

insert into reports_history(report_date)
values (to_timestamp('1000-04-23 18:25:00', 'YYYY-MM-DD HH24:MI:SS'));
select *
from reports_history;

drop sequence history_seq;
create sequence history_seq start with 1;


--------------------------

CREATE OR REPLACE TRIGGER tr_customers_insert
    AFTER INSERT
    ON customers
    FOR EACH ROW
BEGIN
    INSERT INTO customers_history (action_id, customer_id, first_name, last_name, email, phone_number, change_date,
                                   change_type)
    VALUES (history_seq.nextval, :NEW.customer_id, :NEW.first_name, :NEW.last_name, :NEW.email, :NEW.phone_number,
            SYSDATE, 'INSERT');
END;

CREATE OR REPLACE TRIGGER tr_customers_update
    AFTER UPDATE
    ON customers
    FOR EACH ROW
DECLARE
    v_id number;
BEGIN
    INSERT INTO customers_history (action_id, customer_id, first_name, last_name, email, phone_number, change_date,
                                   change_type)
    VALUES (HISTORY_SEQ.nextval, :OLD.customer_id, :OLD.first_name, :OLD.last_name, :OLD.email, :OLD.phone_number,
            SYSDATE, 'DELETE');

    INSERT INTO customers_history (action_id, customer_id, first_name, last_name, email, phone_number, change_date,
                                   change_type)
    VALUES (HISTORY_SEQ.nextval, :OLD.customer_id, :OLD.first_name, :OLD.last_name, :OLD.email, :OLD.phone_number,
            SYSDATE, 'UPDATE');

    INSERT INTO customers_history (action_id, customer_id, first_name, last_name, email, phone_number, change_date,
                                   change_type)
    VALUES (HISTORY_SEQ.nextval, :NEW.customer_id, :NEW.first_name, :NEW.last_name, :NEW.email, :NEW.phone_number,
            SYSDATE, 'INSERT');
END;

CREATE OR REPLACE TRIGGER tr_customers_delete
    AFTER DELETE
    ON customers
    FOR EACH ROW
BEGIN
    INSERT INTO customers_history (action_id, customer_id, first_name, last_name, email, phone_number, change_date,
                                   change_type)
    VALUES (history_seq.nextval, :OLD.customer_id, :OLD.first_name, :OLD.last_name, :OLD.email, :OLD.phone_number,
            SYSDATE, 'DELETE');
END;

CREATE OR REPLACE TRIGGER tr_medicines_insert
    AFTER INSERT
    ON medicines
    FOR EACH ROW
BEGIN
    INSERT INTO medicines_history (action_id, medicine_id, medicine_name, description, price, change_date, change_type)
    VALUES (history_seq.nextval, :new.medicine_id, :new.medicine_name, :new.description, :new.price, SYSDATE, 'INSERT');
END;

CREATE OR REPLACE TRIGGER tr_medicines_update
    AFTER UPDATE
    ON medicines
    FOR EACH ROW
DECLARE
    v_id number;
BEGIN
    v_id := HISTORY_SEQ.nextval;
    INSERT INTO medicines_history (action_id, medicine_id, medicine_name, description, price, change_date, change_type)
    VALUES (v_id, :old.medicine_id, :old.medicine_name, :old.description, :old.price, SYSDATE, 'DELETE');

    INSERT INTO medicines_history (action_id, medicine_id, medicine_name, description, price, change_date, change_type)
    VALUES (v_id, :old.medicine_id, :old.medicine_name, :old.description, :old.price, SYSDATE, 'UPDATE');

    INSERT INTO medicines_history (action_id, medicine_id, medicine_name, description, price, change_date, change_type)
    VALUES (v_id, :new.medicine_id, :new.medicine_name, :new.description, :new.price, SYSDATE, 'INSERT');
END;

CREATE OR REPLACE TRIGGER tr_medicines_delete
    AFTER DELETE
    ON medicines
    FOR EACH ROW
BEGIN
    INSERT INTO medicines_history (action_id, medicine_id, medicine_name, description, price, change_date, change_type)
    VALUES (history_seq.nextval, :old.medicine_id, :old.medicine_name, :old.description, :old.price, SYSDATE, 'DELETE');
END;

CREATE OR REPLACE TRIGGER tr_orders_insert
    AFTER INSERT
    ON orders
    FOR EACH ROW
DECLARE
BEGIN
    INSERT INTO orders_history (action_id, order_id, order_date, customer_id, medicine_id, amount, change_date,
                                change_type)
    VALUES (history_seq.NEXTVAL, :NEW.order_id, :NEW.order_date, :NEW.customer_id, :NEW.medicine_id, :NEW.amount,
            SYSDATE, 'INSERT');
END;

CREATE OR REPLACE TRIGGER tr_orders_update
    AFTER UPDATE
    ON orders
    FOR EACH ROW
DECLARE
    v_id number;
BEGIN
    v_id := HISTORY_SEQ.nextval;
    INSERT INTO orders_history (action_id, order_id, order_date, customer_id, medicine_id, amount, change_date,
                                change_type)
    VALUES (v_id, :OLD.order_id, :OLD.order_date, :OLD.customer_id, :OLD.medicine_id, :OLD.amount, SYSDATE, 'DELETE');

    INSERT INTO orders_history (action_id, order_id, order_date, customer_id, medicine_id, amount, change_date,
                                change_type)
    VALUES (v_id, :OLD.order_id, :OLD.order_date, :OLD.customer_id, :OLD.medicine_id, :OLD.amount, SYSDATE, 'UPDATE');

    INSERT INTO orders_history (action_id, order_id, order_date, customer_id, medicine_id, amount, change_date,
                                change_type)
    VALUES (v_id, :NEW.order_id, :NEW.order_date, :NEW.customer_id, :NEW.medicine_id, :NEW.amount, SYSDATE, 'INSERT');
END;

CREATE OR REPLACE TRIGGER tr_orders_delete
    AFTER DELETE
    ON orders
    FOR EACH ROW
DECLARE
BEGIN
    INSERT INTO orders_history (action_id, order_id, order_date, customer_id, medicine_id, amount, change_date,
                                change_type)
    VALUES (history_seq.NEXTVAL, :OLD.order_id, :OLD.order_date, :OLD.customer_id, :OLD.medicine_id, :OLD.amount,
            SYSDATE, 'DELETE');
END;


--------------


CREATE OR REPLACE PACKAGE func_package IS
    procedure roll_back(date_time timestamp);
    procedure roll_back(date_time number);
    procedure report(t_begin in timestamp, t_end in timestamp);
    procedure report;
END func_package;

CREATE OR REPLACE PACKAGE BODY func_package IS
    PROCEDURE roll_back(date_time timestamp) IS
    begin
        rollback_by_date(date_time);
    END roll_back;

    PROCEDURE roll_back(date_time number) IS
    BEGIN
        DECLARE
            current_time timestamp := systimestamp;
        BEGIN
            current_time := current_time - NUMTODSINTERVAL(date_time / 1000, 'SECOND');
            rollback_by_date(current_time);
        END;
    END roll_back;

    PROCEDURE report(t_begin in timestamp, t_end in timestamp) IS
        v_cur timestamp;
    begin

        SELECT CAST(SYSDATE AS TIMESTAMP) into v_cur FROM dual;

        if t_end > v_cur then
            create_report(t_begin, v_cur);
            insert into reports_history(report_date) values (v_cur);
        else
            create_report(t_begin, t_end);
            insert into reports_history(report_date) values (t_end);
        end if;
    END report;

    PROCEDURE report IS
        v_begin timestamp;
        v_cur   timestamp;
    begin

        SELECT CAST(SYSDATE AS TIMESTAMP) into v_cur FROM dual;

        select REPORT_DATE
        into v_begin
        from REPORTS_HISTORY
        where id = (select MAX(id) from REPORTS_HISTORY);

        create_report(v_begin, v_cur);

        insert into reports_history(report_date) values (v_cur);
    END report;

END func_package;


-----------------------------

create or replace procedure rollback_by_date(date_time in timestamp)
as
begin
    disable_all_constraints('orders');
    disable_all_constraints('customers');
    disable_all_constraints('medicines');

    delete from orders;
    delete from customers;
    delete from medicines;

    for i in (select * from customers_history where CHANGE_DATE <= date_time ORDER BY ACTION_ID)
        LOOP
            if i.CHANGE_TYPE = 'INSERT' then
                insert into customers values (i.customer_ID, i.FIRST_NAME, i.LAST_NAME, i.EMAIL, i.PHONE_NUMBER);
            elsif i.CHANGE_TYPE = 'DELETE' then
                delete from customers where customer_ID = i.customer_ID;
            end if;
        end loop;

    for i in (select * from medicines_history where CHANGE_DATE <= date_time ORDER BY ACTION_ID)
        LOOP
            if i.CHANGE_TYPE = 'INSERT' then
                insert into medicines values (i.medicine_ID, i.medicine_NAME, i.DESCRIPTION, i.PRICE);
            elsif i.CHANGE_TYPE = 'DELETE' then
                delete from medicines where medicine_ID = i.medicine_ID;
            end if;
        end loop;

    for i in (select * from orders_history where CHANGE_DATE <= date_time ORDER BY ACTION_ID)
        LOOP
            if i.CHANGE_TYPE = 'INSERT' then
                insert into orders values (i.ORDER_ID, i.ORDER_DATE, i.customer_ID, i.medicine_ID, i.amount);
            elsif i.CHANGE_TYPE = 'DELETE' then
                delete from orders where orders.ORDER_ID = i.ORDER_ID;
            end if;
            commit;
        end loop;

    delete
    from customers_history
    where CHANGE_DATE > date_time;

    delete
    from medicines_history
    where CHANGE_DATE > date_time;

    delete
    from orders_history
    where CHANGE_DATE > date_time;

    enable_all_constraints('customers');
    enable_all_constraints('medicines');
    enable_all_constraints('orders');
end;

CREATE OR REPLACE PROCEDURE disable_all_constraints(p_table_name IN VARCHAR2) IS
BEGIN
    FOR c IN (SELECT constraint_name
              FROM user_constraints
              WHERE table_name = p_table_name)
        LOOP
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table_name || ' DISABLE CONSTRAINT ' || c.constraint_name;
            DBMS_OUTPUT.PUT_LINE('ALTER TABLE ' || p_table_name || ' DISABLE CONSTRAINT ' || c.constraint_name);
        END LOOP;

    EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table_name || ' DISABLE ALL TRIGGERS';
END;

CREATE OR REPLACE PROCEDURE enable_all_constraints(p_table_name IN VARCHAR2) IS
BEGIN
    FOR c IN (SELECT constraint_name
              FROM user_constraints
              WHERE table_name = p_table_name)
        LOOP
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table_name || ' ENABLE CONSTRAINT ' || c.constraint_name;
            DBMS_OUTPUT.PUT_LINE('ALTER TABLE ' || p_table_name || ' ENABLE CONSTRAINT ' || c.constraint_name);
        END LOOP;

    EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table_name || ' ENABLE ALL TRIGGERS';
END;


CREATE OR REPLACE DIRECTORY my_dir AS 'D:\MDiSUBD\6sem\1-3';

create or replace procedure create_report(t_begin in timestamp, t_end in timestamp)
as
    v_result varchar2(4000);
    i_count  number;
    u_count  number;
    d_count  number;
    my_file  UTL_FILE.FILE_TYPE;
begin

    v_result := '<h1>Customers:</h1>' || CHR(10);

    select count(*)
    into u_count
    from customers_history
    where CHANGE_DATE between t_begin and t_end
      and CHANGE_TYPE = 'UPDATE';

    select count(*)
    into i_count
    from customers_history
    where CHANGE_DATE between t_begin and t_end
      and CHANGE_TYPE = 'INSERT';

    select count(*)
    into d_count
    from customers_history
    where CHANGE_DATE between t_begin and t_end
      and CHANGE_TYPE = 'DELETE';

    i_count := i_count - u_count;
    d_count := d_count - u_count;

    v_result := v_result || '<h2 style="color:green">   Insert: ' || i_count || '</h2>' || CHR(10) ||
                '<h2 style="color:orange">   Update: ' || u_count || '</h2>' || CHR(10) ||
                '<h2 style="color:red">   Delete: ' || d_count || '</h2>' || CHR(10);

    select count(*)
    into u_count
    from medicines_history
    where CHANGE_DATE between t_begin and t_end
      and CHANGE_TYPE = 'UPDATE';

    select count(*)
    into i_count
    from medicines_history
    where CHANGE_DATE between t_begin and t_end
      and CHANGE_TYPE = 'INSERT';

    select count(*)
    into d_count
    from medicines_history
    where CHANGE_DATE between t_begin and t_end
      and CHANGE_TYPE = 'DELETE';

    i_count := i_count - u_count;
    d_count := d_count - u_count;

    v_result := v_result || '<h1>Medicines:</h1>' || CHR(10) ||
                '<h2 style="color:green">   Insert: ' || i_count || '</h2>' || CHR(10) ||
                '<h2 style="color:orange">   Update: ' || u_count || '</h2>' || CHR(10) ||
                '<h2 style="color:red">   Delete: ' || d_count || '</h2>' || CHR(10);

    select count(*)
    into u_count
    from orders_history
    where CHANGE_DATE between t_begin and t_end
      and CHANGE_TYPE = 'UPDATE';

    select count(*)
    into i_count
    from orders_history
    where CHANGE_DATE between t_begin and t_end
      and CHANGE_TYPE = 'INSERT';

    select count(*)
    into d_count
    from orders_history
    where CHANGE_DATE between t_begin and t_end
      and CHANGE_TYPE = 'DELETE';

    i_count := i_count - u_count;
    d_count := d_count - u_count;

    v_result := v_result || '<h1>Orders:</h1>' || CHR(10) ||
                '<h2 style="color:green">   Insert: ' || i_count || '</h2>' || CHR(10) ||
                '<h2 style="color:orange">   Update: ' || u_count || '</h2>' || CHR(10) ||
                '<h2 style="color:red">   Delete: ' || d_count || '</h2>' || CHR(10);
    my_file := UTL_FILE.FOPEN('MY_DIR', 'report.html', 'w');
    UTL_FILE.PUT_LINE(my_file, v_result);
    UTL_FILE.FCLOSE(my_file);
    DBMS_OUTPUT.PUT_LINE(v_result);

end;

----------------------------!!!!-------------------

delete
from orders;
delete
from customers;
delete
from medicines;

INSERT INTO customers (customer_id, first_name, last_name, email, phone_number)
VALUES (1, 'Abobus', 'Abobovich', 'abobus@gmail.com', '7788 pozvoni i my podbrosim');

INSERT INTO customers (customer_id, first_name, last_name, email, phone_number)
VALUES (2, 'Aboba', 'Abobovna', 'aboba@gmail.com', 'ты куда звонишь');

UPDATE customers
set phone_number = 'сюда'
where customer_id = 2;

INSERT INTO medicines (medicine_id, medicine_name, description, price)
VALUES (1, 'Активированный уголь', 'А может лучше негром стать', 0.50);

INSERT INTO medicines (medicine_id, medicine_name, description, price)
VALUES (2, 'DUREX', 'LETS CELEBRATE AND SUCK SOME DICKS', 300.00);

INSERT INTO orders (order_id, order_date, customer_id, medicine_id, amount)
VALUES (1, TO_DATE('2000-01-01', 'YYYY-MM-DD'), 1, 1, 1);

INSERT INTO orders (order_id, order_date, customer_id, medicine_id, amount)
VALUES (2, TO_DATE('2023-05-05', 'YYYY-MM-DD'), 2, 2, 2);

delete
from orders
where order_id = 2;

---------------

select *
from customers;
select *
from customers_history;

select *
from medicines;
select *
from medicines_history;

select *
from orders;
select *
from orders_history;

select *
from reports_history;

call rollback_by_date(to_timestamp('2023-04-29 10:00:00', 'YYYY-MM-DD HH24:MI:SS'));
call rollback_by_date(to_timestamp('2023-05-01 23:30:40', 'YYYY-MM-DD HH24:MI:SS'));
call FUNC_PACKAGE.ROLL_BACK(100000);
call FUNC_PACKAGE.ROLL_BACK(to_timestamp('2023-04-24 19:25:00', 'YYYY-MM-DD HH24:MI:SS'));
call FUNC_PACKAGE.REPORT();
call FUNC_PACKAGE.REPORT(to_timestamp('2023-04-29 10:00:00', 'YYYY-MM-DD HH24:MI:SS'),
                         to_timestamp('2024-05-02 23:30:40', 'YYYY-MM-DD HH24:MI:SS'));