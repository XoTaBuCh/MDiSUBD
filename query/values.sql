
INSERT INTO account_statuses(name) VALUES
('Active'),
('Banned'),
('Frozen'),
('Deleted');

INSERT INTO medicine_types(name) VALUES
('Pills'),
('Syrup'),
('Powders'),
('Mixture'),
('Ointment'),
('Capsules');

INSERT INTO order_statuses(name) VALUES
('Active'),
('Accepted'),
('Denied'),
('Completed'),
('In shopping cart');

INSERT INTO users(name, number, email, password, status_id) VALUES
('user1', '+375295115128', 'user1@gmail.com', crypt('User1@', gen_salt('bf')), 1),
('user2', '+375296843417', 'user2@gmail.com', crypt('User2@', gen_salt('bf')), 1),
('user3', '+375296228658', 'user3@gmail.com', crypt('User3@', gen_salt('bf')), 1),
('user4', '+375292517874', 'user4@gmail.com', crypt('User4@', gen_salt('bf')), 2),
('user5', '+375297459852', 'user5@gmail.com', crypt('User5@', gen_salt('bf')), 3),
('user6', '+375297459852', 'user6@gmail.com', crypt('User6@', gen_salt('bf')), 3);

INSERT INTO user_actions(user_id, name, time) VALUES
(1, 'User registered', '2016-06-22 19:10:25-07'),
(1, 'User logined', '2016-06-22 20:10:25-07'),
(2, 'User registered', '2020-06-22 19:10:25-07'),
(2, 'User logined', '2020-06-22 19:11:25-07'),
(2, 'User logouted', '2020-06-22 20:11:25-07');

INSERT INTO clients(user_id) VALUES
(1),
(3);

INSERT INTO apothecaries(user_id) VALUES
(2),
(4);

INSERT INTO admins(user_id) VALUES
(5);

INSERT INTO addresses(country, city, street_address, lat, lon) VALUES
('Belarus', 'Minsk', 'ul. Leonida Bedu 4', 55.343563, 27.434256),
('Belarus', 'Brest', 'ul. Moskovskaya 176', 55.434256, 27.211845),
('Belarus', 'Mogilev', 'ul. Lenina 15', 55.343563, 27.434256),
('Russia', 'Moskow', 'ul. Aboba 1', 55.343563, 27.434256),
('Belarus', 'Minsk', 'per. Gikalo 5', 55.343563, 27.434256);

INSERT INTO pharmacies(name, address_id, apothecary_id) VALUES
('Планета Здоровья', 1, 1),
('Белфармация', 2, 2),
('ФармОстров', 3, 1),
('АААптека', 4, 2),
('Добрыя Леки', 5, 1);

INSERT INTO medicines(name, type_id, fabricator, description) VALUES
('ФКЫевнагпролпо', 1, 'Atlant', 'Тантум Верде Форте'),
('РКЫВПМСЯЧПСРА', 2, 'Tesla', 'Атакует он микробы в горле'),
('аявпачрпосаке', 3, 'Integral', 'И если ты в теме, помни'),
('впяачирвпним', 4, 'Gefest', 'Это - Тантум Верде Форте'),
('ывпкрвеокнратвпы', 5, 'KAmaz', 'Вышел новый смартфон, у девочек работы по горло'),
('яачт прлоапрнвап', 6, 'Gorizont', 'И только у одной, все никак не перло'),
('чсмоншнелоав', 1, 'Tesla', 'Не помогали каблуки и короткие шорты'),
('вилнгленоекп', 2, 'Vladumcev', 'Тогда подруги подсказали Тантум Верде Форте'),
('вепопатпаике', 3, 'Aboba', 'Мне подпевают стадионы, клубы, корпораты');

INSERT INTO products(medicine_id, pharmacy_id, price, amount) VALUES
(1, 1, 22.8, 3),
(2, 1, 148.8, 3),
(3, 1, 13.12, 3),
(4, 1, 567.6, 3),
(5, 1, 4.3, 3),
(8, 1, 8.9, 3),
(9, 1, 99.9, 3),
(1, 2, 21.8, 3),
(2, 2, 148.5, 3),
(6, 2, 63.4, 3),
(7, 2, 54.3, 3),
(5, 2, 4.1, 3),
(8, 2, 8.9, 3),
(9, 2, 99.9, 3),
(6, 3, 63.4, 3),
(2, 3, 146.7, 3),
(3, 3, 13.11, 3),
(4, 3, 568.3, 3),
(5, 3, 4.2, 3),
(7, 3, 54.3, 3),
(9, 3, 99.9, 3),
(1, 4, 23.8, 3),
(2, 4, 145.8, 3),
(3, 4, 14.12, 3),
(4, 4, 567.3, 3),
(5, 4, 4.1, 3),
(6, 4, 63.4, 3),
(9, 4, 99.9, 3),
(1, 5, 24.8, 3),
(2, 5, 149.9, 3),
(7, 5, 54.3, 3),
(4, 5, 557.3, 3),
(5, 5, 4.7, 3),
(8, 5, 8.9, 3),
(9, 5, 99.9, 3);

INSERT INTO orders(status_id, client_id, price) VALUES
(1, 1, 22.8),
(2, 2, 145.8),
(3, 1, 13.11),
(4, 2, 99.9);

INSERT INTO products_orders(product_id, order_id, amount) VALUES
(2, 1, 1),
(1, 1, 1),
(23, 2, 1),
(17, 3, 2),
(35,4, 2);

INSERT INTO reviews(client_id, pharmacy_id, message) VALUES
(1, 1, 'GOD'),
(1, 2, 'GoOD'),
(1, 3, 'GOoooD'),
(1, 4, 'GO0d'),
(2, 5, 'not godd'),
(2, 3, 'bad'),
(2, 4, 'bed'),
(2, 2, 'dad');


CREATE INDEX medicines_idx ON medicines(id);
CREATE INDEX pharmacies_idx ON pharmacies(id);
CREATE INDEX reviews_idx ON reviews(id);
CREATE INDEX addresses_idx ON addresses(id);






CALL insert_client('user9', '+375295115128', 'user48@gmail.com', 'User8@', CAST (1 AS SMALLINT));
CALL put_in_shopping_cart(1, 2, 1)