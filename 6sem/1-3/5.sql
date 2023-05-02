drop table orders;
drop table clients;
drop table products;


CREATE TABLE clients (
  client_id NUMBER(10) CONSTRAINT PK_clients PRIMARY KEY,
  first_name VARCHAR2(50),
  last_name VARCHAR2(50),
  email VARCHAR2(100) UNIQUE,
  phone_number VARCHAR2(20)
);

CREATE TABLE products (
  product_id NUMBER(10) CONSTRAINT PK_products PRIMARY KEY,
  product_name VARCHAR2(100),
  description VARCHAR2(500),
  price NUMBER
);

CREATE TABLE orders (
  order_id NUMBER(10) CONSTRAINT PK_orders PRIMARY KEY,
  order_date DATE,
  client_id NUMBER(10),
  product_id NUMBER(10),
  quantity NUMBER(10),
  CONSTRAINT fk_client FOREIGN KEY (client_id) REFERENCES clients(client_id),
  CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES products(product_id)
);

delete from orders;
delete from clients;
delete from products;

INSERT INTO clients (client_id, first_name, last_name, email, phone_number)
VALUES (1, 'John', 'Doe', 'johndoe@example.com', '555-1234');

INSERT INTO clients (client_id, first_name, last_name, email, phone_number)
VALUES (2, 'Jane', 'Smith', 'janesmith@example.com', '555-5678');

UPDATE clients set phone_number = '123-1234' where client_id = 2;

INSERT INTO products (product_id, product_name, description, price)
VALUES (1, 'T-Shirt', 'A comfortable cotton t-shirt', 20.00);

INSERT INTO products (product_id, product_name, description, price)
VALUES (2, 'Hoodie', 'A warm and cozy hoodie', 40.00);

INSERT INTO orders (order_id, order_date, client_id, product_id, quantity)
VALUES (1, TO_DATE('2023-01-01', 'YYYY-MM-DD'), 1, 1, 3);

INSERT INTO orders (order_id, order_date, client_id, product_id, quantity)
VALUES (2, TO_DATE('2023-01-02', 'YYYY-MM-DD'), 2, 2, 1);

delete from orders where order_id = 2;

--------------

drop table clients_history;
drop table products_history;
drop table orders_history;

CREATE TABLE clients_history (
  action_id number,
  client_id NUMBER(10),
  first_name VARCHAR2(50),
  last_name VARCHAR2(50),
  email VARCHAR2(100),
  phone_number VARCHAR2(20),
  change_date DATE,
  change_type VARCHAR2(10)
);

CREATE TABLE products_history (
  action_id number,
  product_id NUMBER(10),
  product_name VARCHAR2(100),
  description VARCHAR2(500),
  price NUMBER,
  change_date DATE,
  change_type VARCHAR2(10)
);

CREATE TABLE orders_history (
  action_id number,
  order_id NUMBER(10),
  order_date DATE,
  client_id NUMBER(10),
  product_id NUMBER(10),
  quantity NUMBER(10),
  change_date DATE,
  change_type VARCHAR2(10)
);

drop table reports_history;
create table reports_history
(
    id number GENERATED ALWAYS AS IDENTITY,
    report_date timestamp,
    CONSTRAINT PK_reports PRIMARY KEY (id)
);

insert into reports_history(report_date) values(to_timestamp('0000-04-23 18:25:00', 'YYYY-MM-DD HH24:MI:SS'));
select * from reports_history;

create sequence history_seq start with 1;


--------------------------

CREATE OR REPLACE TRIGGER tr_clients_insert
AFTER INSERT ON clients
FOR EACH ROW
BEGIN
  INSERT INTO clients_history (action_id, client_id, first_name, last_name, email, phone_number, change_date, change_type)
  VALUES (history_seq.nextval, :NEW.client_id, :NEW.first_name, :NEW.last_name, :NEW.email, :NEW.phone_number, SYSDATE, 'INSERT');
END;

CREATE OR REPLACE TRIGGER tr_clients_update
AFTER UPDATE ON clients
FOR EACH ROW
DECLARE
  v_id number;
BEGIN
  INSERT INTO clients_history (action_id, client_id, first_name, last_name, email, phone_number, change_date, change_type)
  VALUES (HISTORY_SEQ.nextval, :OLD.client_id, :OLD.first_name, :OLD.last_name, :OLD.email, :OLD.phone_number, SYSDATE, 'DELETE');

  INSERT INTO clients_history (action_id, client_id, first_name, last_name, email, phone_number, change_date, change_type)
  VALUES (HISTORY_SEQ.nextval, :OLD.client_id, :OLD.first_name, :OLD.last_name, :OLD.email, :OLD.phone_number, SYSDATE, 'UPDATE');

  INSERT INTO clients_history (action_id, client_id, first_name, last_name, email, phone_number, change_date, change_type)
  VALUES (HISTORY_SEQ.nextval, :NEW.client_id, :NEW.first_name, :NEW.last_name, :NEW.email, :NEW.phone_number, SYSDATE, 'INSERT');
END;

CREATE OR REPLACE TRIGGER tr_clients_delete
AFTER DELETE ON clients
FOR EACH ROW
BEGIN
  INSERT INTO clients_history (action_id, client_id, first_name, last_name, email, phone_number, change_date, change_type)
  VALUES (history_seq.nextval, :OLD.client_id, :OLD.first_name, :OLD.last_name, :OLD.email, :OLD.phone_number, SYSDATE, 'DELETE');
END;

CREATE OR REPLACE TRIGGER tr_products_insert
AFTER INSERT ON products
FOR EACH ROW
BEGIN
  INSERT INTO products_history (action_id, product_id, product_name, description, price, change_date, change_type)
  VALUES (history_seq.nextval, :new.product_id, :new.product_name, :new.description, :new.price, SYSDATE, 'INSERT');
END;

CREATE OR REPLACE TRIGGER tr_products_update
AFTER UPDATE ON products
FOR EACH ROW
DECLARE
  v_id number;
BEGIN
  v_id := HISTORY_SEQ.nextval;
  INSERT INTO products_history (action_id, product_id, product_name, description, price, change_date, change_type)
  VALUES (v_id, :old.product_id, :old.product_name, :old.description, :old.price, SYSDATE, 'DELETE');

  INSERT INTO products_history (action_id, product_id, product_name, description, price, change_date, change_type)
  VALUES (v_id, :old.product_id, :old.product_name, :old.description, :old.price, SYSDATE, 'UPDATE');

  INSERT INTO products_history (action_id, product_id, product_name, description, price, change_date, change_type)
  VALUES (v_id, :new.product_id, :new.product_name, :new.description, :new.price, SYSDATE, 'INSERT');
END;

CREATE OR REPLACE TRIGGER tr_products_delete
AFTER DELETE ON products
FOR EACH ROW
BEGIN
  INSERT INTO products_history (action_id, product_id, product_name, description, price, change_date, change_type)
  VALUES (history_seq.nextval, :old.product_id, :old.product_name, :old.description, :old.price, SYSDATE, 'DELETE');
END;

CREATE OR REPLACE TRIGGER tr_orders_insert
AFTER INSERT ON orders
FOR EACH ROW
DECLARE
BEGIN
  INSERT INTO orders_history (action_id, order_id, order_date, client_id, product_id, quantity, change_date, change_type)
  VALUES (history_seq.NEXTVAL, :NEW.order_id, :NEW.order_date, :NEW.client_id, :NEW.product_id, :NEW.quantity, SYSDATE, 'INSERT');
END;

CREATE OR REPLACE TRIGGER tr_orders_update
AFTER UPDATE ON orders
FOR EACH ROW
DECLARE
  v_id number;
BEGIN
  v_id := HISTORY_SEQ.nextval;
  INSERT INTO orders_history (action_id, order_id, order_date, client_id, product_id, quantity, change_date, change_type)
  VALUES (v_id, :OLD.order_id, :OLD.order_date, :OLD.client_id, :OLD.product_id, :OLD.quantity, SYSDATE, 'DELETE');

  INSERT INTO orders_history (action_id, order_id, order_date, client_id, product_id, quantity, change_date, change_type)
  VALUES (v_id, :OLD.order_id, :OLD.order_date, :OLD.client_id, :OLD.product_id, :OLD.quantity, SYSDATE, 'UPDATE');

  INSERT INTO orders_history (action_id, order_id, order_date, client_id, product_id, quantity, change_date, change_type)
  VALUES (v_id, :NEW.order_id, :NEW.order_date, :NEW.client_id, :NEW.product_id, :NEW.quantity, SYSDATE, 'INSERT');
END;

CREATE OR REPLACE TRIGGER tr_orders_delete
AFTER DELETE ON orders
FOR EACH ROW
DECLARE
BEGIN
  INSERT INTO orders_history (action_id, order_id, order_date, client_id, product_id, quantity, change_date, change_type)
  VALUES (history_seq.NEXTVAL, :OLD.order_id, :OLD.order_date, :OLD.client_id, :OLD.product_id, :OLD.quantity, SYSDATE, 'DELETE');
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
          insert into reports_history(report_date) values(v_cur);
      else
          create_report(t_begin, t_end);
          insert into reports_history(report_date) values(t_end);
      end if;
  END report;

  PROCEDURE report IS
    v_begin timestamp;
    v_cur timestamp;
  begin

      SELECT CAST(SYSDATE AS TIMESTAMP) into v_cur FROM dual;

      select REPORT_DATE
      into v_begin
      from REPORTS_HISTORY
      where id = (select MAX(id) from REPORTS_HISTORY);

      create_report(v_begin, v_cur);

      insert into reports_history(report_date) values(v_cur);
  END report;

END func_package;


-----------------------------

create or replace procedure rollback_by_date (date_time in timestamp)
as
begin
    disable_all_constraints('ORDERS');
    disable_all_constraints('CLIENTS');
    disable_all_constraints('PRODUCTS');

    delete from clients;
    delete from products;
    delete from orders;

    for i in (select * from clients_history where CHANGE_DATE <= date_time ORDER BY ACTION_ID) LOOP
        if i.CHANGE_TYPE = 'INSERT' then
          insert into clients values (i.CLIENT_ID, i.FIRST_NAME, i.LAST_NAME, i.EMAIL, i.PHONE_NUMBER);
        elsif i.CHANGE_TYPE = 'DELETE' then
          delete from clients where CLIENT_ID = i.CLIENT_ID;
        end if;
    end loop;

    for i in (select * from products_history where CHANGE_DATE <= date_time ORDER BY ACTION_ID) LOOP
        if i.CHANGE_TYPE = 'INSERT' then
          insert into products values (i.PRODUCT_ID, i.PRODUCT_NAME, i.DESCRIPTION, i.PRICE);
        elsif i.CHANGE_TYPE = 'DELETE' then
          delete from products where PRODUCT_ID = i.PRODUCT_ID;
        end if;
    end loop;

    for i in (select * from orders_history where CHANGE_DATE <= date_time ORDER BY ACTION_ID) LOOP
        if i.CHANGE_TYPE = 'INSERT' then
          insert into orders values (i.ORDER_ID, i.ORDER_DATE, i.CLIENT_ID, i.PRODUCT_ID, i.QUANTITY);
        elsif i.CHANGE_TYPE = 'DELETE' then
          delete from orders where orders.ORDER_ID = i.ORDER_ID;
        end if;
        commit;
    end loop;

    delete from clients_history
    where CHANGE_DATE > date_time;

    delete from products_history
    where CHANGE_DATE > date_time;

    delete from orders_history
    where CHANGE_DATE > date_time;

    enable_all_constraints('CLIENTS');
    enable_all_constraints('PRODUCTS');
    enable_all_constraints('ORDERS');
end;

CREATE OR REPLACE PROCEDURE disable_all_constraints(p_table_name IN VARCHAR2) IS
BEGIN
  FOR c IN (SELECT constraint_name
            FROM user_constraints
            WHERE table_name = p_table_name) LOOP
    EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table_name || ' DISABLE CONSTRAINT ' || c.constraint_name;
    DBMS_OUTPUT.PUT_LINE('ALTER TABLE ' || p_table_name || ' DISABLE CONSTRAINT ' || c.constraint_name);
  END LOOP;

  EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table_name || ' DISABLE ALL TRIGGERS';
END;

CREATE OR REPLACE PROCEDURE enable_all_constraints(p_table_name IN VARCHAR2) IS
BEGIN
  FOR c IN (SELECT constraint_name
            FROM user_constraints
            WHERE table_name = p_table_name) LOOP
    EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table_name || ' ENABLE CONSTRAINT ' || c.constraint_name;
    DBMS_OUTPUT.PUT_LINE('ALTER TABLE ' || p_table_name || ' ENABLE CONSTRAINT ' || c.constraint_name);
  END LOOP;

  EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table_name || ' ENABLE ALL TRIGGERS';
END;



create or replace procedure create_report(t_begin in timestamp, t_end in timestamp)
as
    v_result varchar2(4000);
    i_count number;
    u_count number;
    d_count number;
begin

    v_result :=    '<table>
                      <tr>
                        <th>Table</th>
                        <th>INSERT</th>
                        <th>UPDATE</th>
                        <th>DELETE</th>
                      </tr>
                      ';

    select count(*) into u_count
    from CLIENTS_HISTORY
    where CHANGE_DATE between t_begin and t_end
    and CHANGE_TYPE = 'UPDATE';

    select count(*) into i_count
    from CLIENTS_HISTORY
    where CHANGE_DATE between t_begin and t_end
    and CHANGE_TYPE = 'INSERT';

    select count(*) into d_count
    from CLIENTS_HISTORY
    where CHANGE_DATE between t_begin and t_end
    and CHANGE_TYPE = 'DELETE';

    i_count := i_count - u_count;
    d_count := d_count - u_count;

    v_result := v_result || '<tr>
                               <td>Clients</td>
                               <td>' || i_count || '</td>
                               <td>' || u_count || '</td>
                               <td>' || d_count ||'</td>
                             </tr>
                              ';

    select count(*) into u_count
    from PRODUCTS_HISTORY
    where CHANGE_DATE between t_begin and t_end
    and CHANGE_TYPE = 'UPDATE';

    select count(*) into i_count
    from PRODUCTS_HISTORY
    where CHANGE_DATE between t_begin and t_end
    and CHANGE_TYPE = 'INSERT';

    select count(*) into d_count
    from PRODUCTS_HISTORY
    where CHANGE_DATE between t_begin and t_end
    and CHANGE_TYPE = 'DELETE';

    i_count := i_count - u_count;
    d_count := d_count - u_count;

    v_result := v_result || '<tr>
                               <td>Products</td>
                               <td>' || i_count || '</td>
                               <td>' || u_count || '</td>
                               <td>' || d_count ||'</td>
                             </tr>
                              ';

    select count(*) into u_count
    from ORDERS_HISTORY
    where CHANGE_DATE between t_begin and t_end
    and CHANGE_TYPE = 'UPDATE';

    select count(*) into i_count
    from ORDERS_HISTORY
    where CHANGE_DATE between t_begin and t_end
    and CHANGE_TYPE = 'INSERT';

    select count(*) into d_count
    from ORDERS_HISTORY
    where CHANGE_DATE between t_begin and t_end
    and CHANGE_TYPE = 'DELETE';

    i_count := i_count - u_count;
    d_count := d_count - u_count;

    v_result := v_result || '<tr>
                               <td>Orders</td>
                               <td>' || i_count || '</td>
                               <td>' || u_count || '</td>
                               <td>' || d_count ||'</td>
                             </tr>
                              ';

    v_result := v_result || '</table>';
    DBMS_OUTPUT.PUT_LINE(v_result);

end;

----------------------------

select * from clients;
select * from CLIENTS_HISTORY;

select * from PRODUCTS;
select * from PRODUCTS_HISTORY;

select * from ORDERS;
select * from ORDERS_HISTORY;

call rollback_by_date(to_timestamp('2022-04-23 18:25:00', 'YYYY-MM-DD HH24:MI:SS'));
call rollback_by_date(to_timestamp('2023-04-24 19:25:00', 'YYYY-MM-DD HH24:MI:SS'));
call FUNC_PACKAGE.ROLL_BACK(60000);
call FUNC_PACKAGE.ROLL_BACK(to_timestamp('2023-04-24 19:25:00', 'YYYY-MM-DD HH24:MI:SS'));
call FUNC_PACKAGE.REPORT();
call FUNC_PACKAGE.REPORT(to_timestamp('2022-03-10 15:30:00', 'YYYY-MM-DD HH24:MI:SS'), to_timestamp('2024-03-10 15:30:00', 'YYYY-MM-DD HH24:MI:SS'));
call CREATE_REPORT(to_timestamp('2022-03-10 15:30:00', 'YYYY-MM-DD HH24:MI:SS'), to_timestamp('2024-03-10 15:30:00', 'YYYY-MM-DD HH24:MI:SS'));