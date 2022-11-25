SELECT name FROM account_statuses;
SELECT id, name, email, status_id FROM users;

SELECT * FROM addresses;

SELECT id, name, email FROM users WHERE status_id=2; 
SELECT id, name, email FROM users WHERE status_id=1 ORDER BY name DESC;

-- запросы с несколькими условиями
SELECT * FROM user_actions WHERE time > '2016-06-22 19:10:25-07' AND user_id NOT IN (2, 3, 4);
SELECT city, street_address FROM addresses WHERE country='Belarus' AND lat BETWEEN 55.343 AND 55.35;

-- получение имени и описания лекарств, цена продукта в какой-то из аптек больше средней цены всех продуктов
SELECT name, description FROM medicines 
JOIN products ON medicines.id = products.id
WHERE products.price > (SELECT avg(price) FROM products);

--получение времени логов второго юзера
SELECT time FROM user_actions WHERE user_id=(SELECT id FROM users WHERE users.name='user2');

-- получение средней цены лекарств в каждой аптеке
SELECT pharmacies.name, AVG(products.price) FROM products
JOIN pharmacies ON pharmacies.id = products.pharmacy_id
GROUP BY pharmacies.name;

-- получение стоимости всех лекарств в каждой аптеке c общей стоимостью больше 2600
SELECT pharmacies.name, SUM(products.price * products.amount) FROM products
JOIN pharmacies ON pharmacies.id = products.pharmacy_id
GROUP BY pharmacies.name
HAVING SUM(products.price * products.amount)>2600;

-- LEFT JOIN всех продуктов с заказами
SELECT * from products as pr
LEFT JOIN products_orders as pro ON pr.id = pro.product_id
LEFT JOIN orders as o ON pro.order_id = o.id;

-- SELF JOIN над таблицей addresses для получения адресов из одного города
SELECT A.street_address, A.city
FROM addresses A, addresses B
WHERE A.id <> B.id
AND A.city = B.city
ORDER BY A.street_address;

-- обнавление таблицы, с установкой значений цены строк с ценой<50, на 3 больше 
UPDATE products
SET price = price + 3
WHERE price < 50;

-- удаление строк продуктов с производителем Aboba и ценой между 40 и 100
DELETE FROM products
WHERE fabricator='Aboba' AND price BETWEEN 40 AND 100;

-- поиск по подстроке с регистрозависимостью
SELECT name, email FROM users
WHERE email LIKE '%3@gmail%';

-- поиск по подстроке с регистронезависимостью
SELECT name, fabricator FROM medicines
WHERE name ILIKE '%кыев%';

-- Получение количества товара в аптеке с конструкцией CASE относительно 1
SELECT ph.name, m.name, pr.amount,
CASE WHEN pr.amount<1 THEN 'Меньше 1'
     WHEN pr.amount=1 THEN '1'
     ELSE 'Больше 1'
END as case_amount
FROM products AS pr
JOIN medicines AS m ON pr.medicine_id = m.id
JOIN pharmacies AS ph ON pr.pharmacy_id = ph.id;

-- Возвращаем забаненных юзеров если существуют замороженние юзеры
SELECT name, email from users
WHERE status_id = 2 AND EXISTS (SELECT name FROM users WHERE status_id = 3);

-- EXPLAIN запросов
EXPLAIN SELECT * FROM reviews;
EXPLAIN (ANALYZE) SELECT * FROM reviews;

-- Получение товров с конца со 2, 20 шт
SELECT * FROM products ORDER BY id DESC LIMIT 20 OFFSET 2;

-- Получим уникальные сочетания страны и города
SELECT DISTINCT country, city FROM addresses;

-- Объединяем цены в заказах и продуктах, удаляя повторения таких же цен в продуктах
SELECT products.price
FROM products
UNION SELECT orders.price
FROM orders;

SELECT DISTINCT city FROM addresses
WHERE country = 'Belarus';

