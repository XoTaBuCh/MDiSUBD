-- Database: mdisubd

DROP DATABASE IF EXISTS mdisubd WITH (FORCE);

CREATE DATABASE mdisubd
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Russian_Russia.1251'
    LC_CTYPE = 'Russian_Russia.1251'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;
	
CREATE EXTENSION pgcrypto;
	
CREATE TABLE IF NOT EXISTS account_statuses(
	id SMALLSERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL UNIQUE	
);

CREATE TABLE IF NOT EXISTS medicine_types(
	id SMALLSERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL UNIQUE	
);

CREATE TABLE IF NOT EXISTS order_statuses(
	id SMALLSERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL UNIQUE	
);

CREATE TABLE IF NOT EXISTS users(
	id BIGSERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	number VARCHAR(255),
	email VARCHAR(255) NOT NULL UNIQUE,
	password TEXT NOT NULL,
	status_id SMALLSERIAL,
	CONSTRAINT fk_status FOREIGN KEY(status_id) REFERENCES account_statuses(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS user_actions(
	id BIGSERIAL PRIMARY KEY,
	user_id BIGSERIAL,
	name VARCHAR(500) NOT NULL,
	time timestamp,
	CONSTRAINT fk_user FOREIGN KEY(user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS clients(
	id BIGSERIAL PRIMARY KEY,
	user_id BIGSERIAL,
	CONSTRAINT fk_user FOREIGN KEY(user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS apothecaries(
	id BIGSERIAL PRIMARY KEY,
	user_id BIGSERIAL,
	CONSTRAINT fk_user FOREIGN KEY(user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS admins(
	id BIGSERIAL PRIMARY KEY,
	user_id BIGSERIAL,
	CONSTRAINT fk_user FOREIGN KEY(user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS addresses(
	id BIGSERIAL PRIMARY KEY,
	country VARCHAR(255) NOT NULL,
	city VARCHAR(255) NOT NULL,
	street_address VARCHAR(255) NOT NULL,
	lat numeric NOT NULL,
	lon numeric NOT NULL
);

CREATE TABLE IF NOT EXISTS pharmacies(
	id BIGSERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	address_id BIGSERIAL,
	apothecary_id BIGSERIAL,
	CONSTRAINT fk_apothecary FOREIGN KEY(apothecary_id) REFERENCES apothecaries(id) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_address FOREIGN KEY(address_id) REFERENCES addresses(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS medicines(
	id BIGSERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	type_id SMALLSERIAL,
	fabricator VARCHAR(255) NOT NULL,
	description VARCHAR(500) NOT NULL,
	CONSTRAINT fk_type FOREIGN KEY(type_id) REFERENCES medicine_types(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS products(
	id BIGSERIAL PRIMARY KEY,
	medicine_id BIGSERIAL,
	pharmacy_id BIGSERIAL,
	price money NOT NULL,
	amount BIGSERIAL NOT NULL CHECK(amount>=0),
	CONSTRAINT fk_pharmacy FOREIGN KEY(pharmacy_id) REFERENCES pharmacies(id) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_medicicne FOREIGN KEY(medicine_id) REFERENCES medicines(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS orders(
	id BIGSERIAL PRIMARY KEY,
	status_id SMALLSERIAL,
	client_id BIGSERIAL,
	price money NOT NULL,
	CONSTRAINT fk_status FOREIGN KEY(status_id) REFERENCES order_statuses(id) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_client FOREIGN KEY(client_id) REFERENCES clients(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS products_orders(
	id BIGSERIAL PRIMARY KEY,
	product_id BIGSERIAL,
	order_id BIGSERIAL,
	amount BIGSERIAL NOT NULL CHECK(amount>=0),
	CONSTRAINT fk_product FOREIGN KEY(product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_order FOREIGN KEY(order_id) REFERENCES orders(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS reviews(
	id BIGSERIAL PRIMARY KEY,
	client_id BIGSERIAL,
	pharmacy_id BIGSERIAL,
	message VARCHAR(500) NOT NULL,
	CONSTRAINT fk_client FOREIGN KEY(client_id) REFERENCES clients(id) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_pharmacy FOREIGN KEY(pharmacy_id) REFERENCES pharmacies(id) ON UPDATE CASCADE ON DELETE CASCADE
);


-- Procedure for create client
CREATE OR REPLACE PROCEDURE insert_client(name users.name%TYPE, number users.name%TYPE, email users.email%TYPE, password users.password%TYPE, status_id Integer)
LANGUAGE SQL
AS $$
WITH rows AS (INSERT INTO users(name, number, email, password, status_id) VALUES
(name, number, email, crypt(password, gen_salt('bf')), status_id) RETURNING id)
INSERT INTO clients(user_id)
    SELECT id
    FROM rows
    RETURNING id;
$$;

-- Procedure for create apothecary
CREATE OR REPLACE PROCEDURE insert_apothecary(name users.name%TYPE, number users.name%TYPE, email users.email%TYPE, password users.password%TYPE, status_id Integer)
LANGUAGE SQL
AS $$
WITH rows AS (INSERT INTO users(name, number, email, password, status_id) VALUES
(name, number, email, crypt(password, gen_salt('bf')), status_id) RETURNING id)
INSERT INTO apothecaries(user_id)
    SELECT id
    FROM rows
    RETURNING id;
$$;

-- Procedure for create admin
CREATE OR REPLACE PROCEDURE insert_admin(name users.name%TYPE, number users.name%TYPE, email users.email%TYPE, password users.password%TYPE, status_id Integer)
LANGUAGE SQL
AS $$
WITH rows AS (INSERT INTO users(name, number, email, password, status_id) VALUES
(name, number, email, crypt(password, gen_salt('bf')), status_id) RETURNING id)
INSERT INTO admins(user_id)
    SELECT id
    FROM rows
    RETURNING id;
$$;

-- Changing user status to deleted
CREATE OR REPLACE PROCEDURE user_delete(user_id Integer)
LANGUAGE SQL
AS $$
	UPDATE users SET status_id=4 WHERE id=user_id;
$$;

-- Changing user status
CREATE OR REPLACE PROCEDURE edit_user_status(user_id Integer, new_status_id Integer)
LANGUAGE SQL
AS $$
	UPDATE users SET status_id=new_status_id WHERE id=user_id;
$$;

-- Editing user data
CREATE OR REPLACE PROCEDURE edit_user(user_id Integer, new_name users.name%TYPE, new_number users.name%TYPE, new_password users.password%TYPE)
LANGUAGE SQL
AS $$
	UPDATE users SET name=new_name, number=new_number, password=crypt(new_password, gen_salt('bf')) WHERE id=user_id;
$$;

-- Editing product data
CREATE OR REPLACE PROCEDURE edit_product(product_id Integer, new_amount products.amount%TYPE, new_price numeric)
LANGUAGE SQL
AS $$
	UPDATE products SET amount=new_amount, price=new_price WHERE id=product_id;
$$;

-- Editing pharmacy data
CREATE OR REPLACE PROCEDURE edit_pharmacy(pharmacy_id Integer, new_name pharmacies.name%TYPE, new_country addresses.country%TYPE, new_city addresses.city%TYPE, new_street_address addresses.street_address%TYPE)
LANGUAGE SQL
AS $$
	UPDATE pharmacies SET name=new_name WHERE id=pharmacy_id;
	UPDATE addresses SET country=new_country, city=new_city, street_address=new_street_address WHERE addresses.id=(SELECT address_id FROM pharmacies WHERE id=pharmacy_id);
$$;

-- Delete pharmacy
CREATE OR REPLACE PROCEDURE delete_pharmacy(pharmacy_id Integer)
LANGUAGE SQL
AS $$
	DELETE FROM pharmacies WHERE id=pharmacy_id;
$$;

-- Edit medicine
CREATE OR REPLACE PROCEDURE edit_medicine(medicine_id Integer, new_name medicines.name%TYPE, new_type_id Integer, new_fabricator medicines.fabricator%TYPE, new_description medicines.description%TYPE)
LANGUAGE SQL
AS $$
	UPDATE medicines SET name=new_name, type_id=new_type_id, fabricator=new_fabricator, description=new_description WHERE id=medicine_id;
$$;

-- Delete medicine
CREATE OR REPLACE PROCEDURE delete_medicine(medicine_id Integer)
LANGUAGE SQL
AS $$
	DELETE FROM medicines WHERE id=medicine_id;
$$;

-- Add medicine type
CREATE OR REPLACE PROCEDURE add_medicine_type(name medicine_types.name%TYPE)
LANGUAGE SQL
AS $$
	INSERT INTO medicine_types(name) VALUES (name);
$$;

-- Add existing product
CREATE OR REPLACE PROCEDURE add_existing_product(pharmacy_id Integer, medicine_id Integer, amount products.amount%TYPE, price numeric)
LANGUAGE SQL
AS $$
	INSERT INTO products(medicine_id, pharmacy_id, price, amount) VALUES (medicine_id, pharmacy_id, price, amount);
$$;

-- Add new product
CREATE OR REPLACE PROCEDURE add_new_product(pharmacy_id Integer, name medicines.name%TYPE, type_id Integer, fabricator medicines.fabricator%TYPE, description medicines.description%TYPE, amount products.amount%TYPE, price products.price%TYPE)
LANGUAGE SQL
AS $$
	WITH rows AS (INSERT INTO medicines(name, type_id, fabricator, description) VALUES (name, type_id, fabricator, description) RETURNING id)

	INSERT INTO products(medicine_id, pharmacy_id, price, amount) VALUES ((SELECT id
    FROM rows), pharmacy_id, price, amount);
$$;

-- Add new pharmacy
CREATE OR REPLACE PROCEDURE add_pharmacy(user_id Integer, name pharmacies.name%TYPE, country addresses.country%TYPE, city addresses.city%TYPE, street_address addresses.street_address%TYPE, lat addresses.lat%TYPE, lon addresses.lon%TYPE)
LANGUAGE SQL
AS $$
	WITH rows AS (INSERT INTO addresses(country, city, street_address, lat, lon) VALUES (country, city, street_address, lat, lon) RETURNING id)

	INSERT INTO pharmacies(name, address_id, apothecary_id) VALUES (name, (SELECT id
    FROM rows), (SELECT apothecaries.id FROM apothecaries WHERE apothecaries.user_id=user_id LIMIT 1));
$$;

-- Accept product_order
CREATE OR REPLACE PROCEDURE accept_order(product_order_id Integer)
LANGUAGE SQL
AS $$
	UPDATE orders SET status_id=2 WHERE id IN (SELECT order_id FROM products_orders WHERE id=product_order_id);
$$;

-- Deny product_order
CREATE OR REPLACE PROCEDURE deny_order(product_order_id Integer)
LANGUAGE SQL
AS $$
	UPDATE orders SET status_id=3 WHERE id IN (SELECT order_id FROM products_orders WHERE id=product_order_id);
	UPDATE products SET amount=amount+(SELECT amount FROM products_orders WHERE id=product_order_id) WHERE id=(SELECT product_id FROM products_orders WHERE id=product_order_id);
$$;

-- DELETE product_order
CREATE OR REPLACE PROCEDURE delete_order(product_order_id Integer)
LANGUAGE SQL
AS $$
	UPDATE orders SET status_id=3 WHERE id IN (SELECT order_id FROM products_orders WHERE id=product_order_id);
	UPDATE products SET amount=amount+(SELECT amount FROM products_orders WHERE id=product_order_id) WHERE id=(SELECT product_id FROM products_orders WHERE id=product_order_id);
$$;

-- Edit or create review
CREATE OR REPLACE PROCEDURE edit_review(user_idd Integer, pharmacy_idd Integer, new_message reviews.message%TYPE)
LANGUAGE plpgsql
AS $$
BEGIN
	IF (SELECT count(r.id) FROM reviews r 
		JOIN clients c ON c.id=r.client_id 
		WHERE c.user_id=user_idd AND r.pharmacy_id=pharmacy_idd)=1 THEN
		
		UPDATE reviews SET message=new_message WHERE client_id=(SELECT id FROM clients WHERE user_id=user_idd) AND reviews.pharmacy_id=pharmacy_idd;
	ELSE 
		INSERT INTO reviews(client_id, pharmacy_id, message) VALUES ((SELECT id FROM clients WHERE user_id=user_idd), pharmacy_idd, new_message);
	END IF;
END;
$$;

-- Putting medicine into shopping cart procedure
CREATE OR REPLACE PROCEDURE put_in_shopping_cart(user_id Integer, product_id Integer, amount_pr Integer)
LANGUAGE plpgsql
AS $$
	DECLARE shopping_cart_orders_count Integer;
	DECLARE client_id Integer;
		
	BEGIN
	
	UPDATE products SET amount=amount-amount_pr WHERE products.id=product_id;
	
	SELECT id INTO client_id FROM clients WHERE clients.user_id=user_id;
	SELECT count(orders.id) INTO shopping_cart_orders_count FROM orders WHERE orders.client_id=client_id AND orders.status_id=5;
	
	IF shopping_cart_orders_count>0 THEN 
		WITH rows AS (INSERT INTO orders(status_id, client_id, price) VALUES
					 (5, client_id, 0) RETURNING id)

		INSERT INTO products_orders(product_id, order_id, amount) VALUES
			(product_id,
			(SELECT id
			FROM rows LIMIT 1), amount_pr);
	ELSE 
		INSERT INTO products_orders(product_id, order_id, amount) VALUES
			(product_id,
			(SELECT orders.id
			FROM orders WHERE orders.status_id=5 AND orders.client_id=client_id), amount_pr);
	END IF;
	END;
$$;

-- Функция логгирования заказов
CREATE OR REPLACE FUNCTION process_order_insert() RETURNS TRIGGER AS $update_price$
	DECLARE price Integer;
    BEGIN
		SELECT sum(products.price*products_orders.amount) INTO price FROM products 
			JOIN products_orders ON products.id=products_orders.product_id
			WHERE products_orders.id=NEW.order_id;
			
		UPDATE orders SET orders.price=price WHERE orders.id=NEW.order_id;
            RETURN NEW;
 	END;
$update_price$ LANGUAGE plpgsql;

-- Триггер для подсчета суммы заказа при создании
CREATE OR REPLACE TRIGGER update_price
AFTER INSERT ON products_orders
    FOR EACH ROW EXECUTE PROCEDURE process_order_insert();

-- Функция для выполнения триггера логгирования юзеров
CREATE OR REPLACE FUNCTION process_user_logging() RETURNS TRIGGER AS $logging$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
            INSERT INTO user_actions(user_id, name, time) VALUES (OLD.id, 'Delete user', now());
            RETURN OLD;
        ELSIF (TG_OP = 'UPDATE') THEN
            INSERT INTO user_actions(user_id, name, time) VALUES (NEW.id, 'Update user', now());
            RETURN NEW;
        ELSIF (TG_OP = 'INSERT') THEN
            INSERT INTO user_actions(user_id, name, time) VALUES (NEW.id, 'Insert user', now());
            RETURN NEW;
        END IF;
        RETURN NULL;
    END;
$logging$ LANGUAGE plpgsql;

-- Триггер для логирования юзеров
CREATE OR REPLACE TRIGGER logging
AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE PROCEDURE process_user_logging();
	
-- Функция для выполнения триггера логгирования аптек
CREATE OR REPLACE FUNCTION process_pharmacy_logging() RETURNS TRIGGER AS $logging$
	Declare user_id integer;
    BEGIN
        IF (TG_OP = 'DELETE') THEN
			SELECT users.id INTO user_id FROM users 
			JOIN apothecaries ON apothecaries.user_id=users.id
			JOIN pharmacies ON pharmacies.apothecary_id=apothecaries.id
			WHERE pharmacies.id=OLD.id;
            INSERT INTO user_actions(user_id, name, time) VALUES (user_id, 'Delete pharmacy', now());
            RETURN OLD;
        ELSIF (TG_OP = 'UPDATE') THEN
			SELECT users.id INTO user_id FROM users 
			JOIN apothecaries ON apothecaries.user_id=users.id
			JOIN pharmacies ON pharmacies.apothecary_id=apothecaries.id
			WHERE pharmacies.id=NEW.id;
            INSERT INTO user_actions(user_id, name, time) VALUES (user_id, 'Update pharmacy', now());
            RETURN NEW;
        ELSIF (TG_OP = 'INSERT') THEN
			SELECT users.id INTO user_id FROM users 
			JOIN apothecaries ON apothecaries.user_id=users.id
			JOIN pharmacies ON pharmacies.apothecary_id=apothecaries.id
			WHERE pharmacies.id=NEW.id;
            INSERT INTO user_actions(user_id, name, time) VALUES (user_id, 'Insert pharmacy', now());
            RETURN NEW;
        END IF;
        RETURN NULL;
    END;
$logging$ LANGUAGE plpgsql;

-- Триггер для логирования аптек
CREATE OR REPLACE TRIGGER logging
AFTER INSERT OR UPDATE OR DELETE ON pharmacies
    FOR EACH ROW EXECUTE PROCEDURE process_pharmacy_logging();
	
