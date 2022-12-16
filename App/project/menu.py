from flask import Blueprint, render_template, redirect, url_for, request
from flask_login import current_user

from project import db

menu = Blueprint('menu', __name__)


@menu.route('/menu')
def menu_redirect():
    clients = list(db.session.execute(f"SELECT user_id FROM clients WHERE user_id={current_user.id};"))
    if clients:
        return redirect(url_for('menu.client_menu'))

    apothecaries = list(db.session.execute(f"SELECT user_id FROM apothecaries WHERE user_id={current_user.id};"))
    if apothecaries:
        return redirect(url_for('menu.apothecary_menu'))

    admins = list(db.session.execute(f"SELECT user_id FROM admins WHERE user_id={current_user.id};"))
    if admins:
        return redirect(url_for('menu.admin_menu'))

    return redirect(url_for('menu.default_menu'))


@menu.route('/client')
def client_menu():
    search = request.args.get('search')
    medicines = list(
        db.session.execute(
            f"SELECT medicines.id, medicines.name, medicines.fabricator, medicine_types.name FROM medicines "
            f"JOIN medicine_types ON medicines.type_id = medicine_types.id "
            f"WHERE medicines.name ILIKE '%{search}%';"))
    db.session.commit()
    return render_template('client_menu.html', medicines=medicines)


@menu.route('/client/shopping_cart')
def shopping_cart():
    shopping_cart_orders = list(db.session.execute(f"SELECT po.id, m.name, po.amount, "
                                                   f"po.amount*p.price::money::numeric::float8 FROM medicines m "
                                                   f"JOIN products p ON m.id = p.medicine_id "
                                                   f"JOIN products_orders po ON p.id = po.product_id "
                                                   f"JOIN orders o on o.id = po.order_id "
                                                   f"JOIN clients c on c.id = o.client_id "
                                                   f"WHERE c.user_id={current_user.id} AND o.status_id=5;"))
    active_orders = list(db.session.execute(f"SELECT po.id, m.name, po.amount, "
                                            f"po.amount*p.price::money::numeric::float8 FROM medicines m "
                                            f"JOIN products p ON m.id = p.medicine_id "
                                            f"JOIN products_orders po ON p.id = po.product_id "
                                            f"JOIN orders o on o.id = po.order_id "
                                            f"JOIN clients c on c.id = o.client_id "
                                            f"WHERE c.user_id={current_user.id} AND o.status_id=1;"))
    other_orders = list(db.session.execute(f"SELECT m.name, po.amount, "
                                           f"po.amount*p.price::money::numeric::float8, os.name FROM medicines m "
                                           f"JOIN products p ON m.id = p.medicine_id "
                                           f"JOIN products_orders po ON p.id = po.product_id "
                                           f"JOIN orders o on o.id = po.order_id "
                                           f"JOIN order_statuses os ON os.id = o.status_id "
                                           f"JOIN clients c on c.id = o.client_id "
                                           f"WHERE c.user_id={current_user.id} AND o.status_id BETWEEN 2 AND 4;"))
    db.session.commit()

    return render_template('shopping_cart.html', shopping_cart_orders=shopping_cart_orders, active_orders=active_orders,
                           other_orders=other_orders)


@menu.route('/client/shopping_cart/delete', methods=['POST'])
def shopping_cart_delete():
    product_order_id = request.form.get('product_order_id')

    db.session.execute(f"CALL delete_order({product_order_id});")
    db.session.commit()

    return redirect(url_for('menu.shopping_cart'))


@menu.route('/apothecary')
def apothecary_menu():
    pharmacies = list(
        db.session.execute(
            f"SELECT p.id, p.name, a.country, a.city, a.street_address, a.lat, a.lon FROM pharmacies p "
            f"JOIN addresses a on p.address_id = a.id "
            f"JOIN apothecaries a2 on a2.id = p.apothecary_id "
            f"WHERE a2.user_id={current_user.id};"))
    db.session.commit()

    return render_template('apothecary_menu.html', pharmacies=pharmacies)


@menu.route('/apothecary/add_pharmacy')
def apothecary_add_pharmacy():
    return render_template('add_pharmacy.html')


@menu.route('/apothecary/add_pharmacy', methods=['POST'])
def apothecary_add_pharmacy_post():
    name = request.form.get('name')
    country = request.form.get('country')
    city = request.form.get('city')
    street_address = request.form.get('street_address')
    lat = request.form.get('lat')
    lon = request.form.get('lon')
    db.session.execute(
        f"CALL add_pharmacy({current_user.id}, '{name}', '{country}', '{city}', '{street_address}', {lat}, {lon});")
    db.session.commit()

    return redirect(url_for('menu.apothecary_menu'))


@menu.route('/admin')
def admin_menu():
    return render_template('admin_menu.html')


@menu.route('/admin/users')
def admin_menu_users():
    users = list(db.session.execute(f"SELECT u.id, u.name, u.email, u.number, a_s.id FROM users u "
                                    f"JOIN account_statuses a_s on a_s.id = u.status_id;"))
    statuses = list(db.session.execute(f"SELECT id, name FROM account_statuses;"))
    db.session.commit()

    return render_template('admin_menu_users.html', users=users, statuses=statuses)


@menu.route('/admin/users', methods=['POST'])
def admin_menu_users_post():
    user_id = request.form.get('user_id')
    status_id = request.form.get('status_id')

    db.session.execute(f"CALL edit_user_status({user_id}, {status_id});")
    db.session.commit()

    return redirect(url_for('menu.admin_menu'))


@menu.route('/admin/pharmacies')
def admin_menu_pharmacies():
    pharmacies = list(db.session.execute(f"SELECT p.name, a.country, a.city, a.street_address, p.id FROM pharmacies p "
                                         f"JOIN addresses a on p.address_id = a.id "
                                         f"ORDER BY p.id;"))
    db.session.commit()

    return render_template('admin_menu_pharmacies.html', pharmacies=pharmacies)


@menu.route('/admin/pharmacies', methods=['POST'])
def admin_menu_pharmacies_post():
    pharmacy_id = request.form.get('pharmacy_id')
    name = request.form.get('name')
    country = request.form.get('country')
    city = request.form.get('city')
    street_address = request.form.get('street_address')

    db.session.execute(f"CALL edit_pharmacy({pharmacy_id}, '{name}', '{country}', '{city}', '{street_address}');")
    db.session.commit()

    return redirect(url_for('menu.admin_menu_pharmacies'))


@menu.route('/admin/pharmacies/delete', methods=['POST'])
def admin_menu_pharmacies_delete_post():
    pharmacy_id = request.form.get('pharmacy_id')
    db.session.execute(f"CALL delete_pharmacy({pharmacy_id});")
    db.session.commit()

    return redirect(url_for('menu.admin_menu_pharmacies'))


@menu.route('/admin/medicines')
def admin_menu_medicines():
    medicines = list(db.session.execute(f"SELECT m.id, m.name, m.type_id, m.fabricator, m.description FROM medicines m "
                                        f"ORDER BY m.id;"))
    options = list(db.session.execute(f"SELECT id, name FROM medicine_types;"))
    db.session.commit()

    return render_template('admin_menu_medicines.html', medicines=medicines, options=options)


@menu.route('/admin/medicines', methods=['POST'])
def admin_menu_medicines_post():
    medicine_id = request.form.get('medicine_id')
    name = request.form.get('name')
    type_id = request.form.get('type_id')
    fabricator = request.form.get('fabricator')
    description = request.form.get('description')

    db.session.execute(f"CALL edit_medicine({medicine_id}, '{name}', {type_id}, '{fabricator}', '{description}');")
    db.session.commit()

    return redirect(url_for('menu.admin_menu_medicines'))


@menu.route('/admin/medicines/delete', methods=['POST'])
def admin_menu_medicines_delete_post():
    medicine_id = request.form.get('medicine_id')
    db.session.execute(f"CALL delete_medicine({medicine_id});")
    db.session.commit()

    return redirect(url_for('menu.admin_menu_medicines'))


@menu.route('/admin/medicines/add_type', methods=['POST'])
def admin_menu_medicines_type_post():
    type_name = request.form.get('type_name')
    db.session.execute(f"CALL add_medicine_type('{type_name}');")
    db.session.commit()

    return redirect(url_for('menu.admin_menu_medicines'))


@menu.route('/admin/products')
def admin_menu_products():
    products = list(db.session.execute(f"SELECT p.id, m.name, p.amount, p.price::money::numeric::float8,"
                                       f" p2.name FROM products p "
                                       f"JOIN medicines m on m.id = p.medicine_id "
                                       f"JOIN pharmacies p2 on p2.id = p.pharmacy_id "
                                       f"ORDER BY p.pharmacy_id, p.id;"))
    db.session.commit()

    return render_template('admin_menu_products.html', products=products)


@menu.route('/admin/products', methods=['POST'])
def admin_menu_products_post():
    product_id = request.form.get('product_id')
    amount = request.form.get('amount')
    price = request.form.get('price')

    db.session.execute(f"CALL edit_product({product_id}, {amount}, {price});")
    db.session.commit()

    return redirect(url_for('menu.admin_menu_products'))


@menu.route('/admin/orders')
def admin_menu_orders():
    orders = list(db.session.execute(f"SELECT m.name, u.email, po.amount, po.amount*p.price::money::numeric::float8,"
                                     f"os.name FROM products_orders po "
                                     f"JOIN orders o on o.id = po.order_id "
                                     f"JOIN order_statuses os on os.id = o.status_id "
                                     f"JOIN products p on p.id = po.product_id "
                                     f"JOIN medicines m on m.id = p.medicine_id "
                                     f"JOIN clients c on c.id = o.client_id "
                                     f"JOIN users u on u.id = c.user_id "
                                     f"ORDER BY o.client_id, o.status_id;"))
    db.session.commit()

    return render_template('admin_menu_orders.html', orders=orders)


@menu.route('/admin/products/delete', methods=['POST'])
def admin_menu_products_delete_post():
    product_id = request.form.get('product_id')
    db.session.execute(f"CALL delete_product({product_id});")
    db.session.commit()

    return redirect(url_for('menu.admin_menu_products'))


@menu.route('/default')
def default_menu():
    search = request.args.get('search')
    medicines = list(
        db.session.execute(
            f"SELECT medicines.id, medicines.name, medicines.fabricator, medicine_types.name FROM medicines "
            f"JOIN medicine_types ON medicines.type_id = medicine_types.id "
            f"WHERE medicines.name ILIKE '%{search}%';"))
    db.session.commit()
    return render_template('default_menu.html', medicines=medicines)
