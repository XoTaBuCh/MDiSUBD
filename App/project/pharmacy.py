from flask import Blueprint, render_template, redirect, url_for, request
from flask_login import current_user

from project import db

pharmacy = Blueprint('pharmacy', __name__)


@pharmacy.route('/pharmacy/<int:pharmacy_id>')
def pharmacy_get(pharmacy_id):
    pharmacy_info = list(db.session.execute(
        f"SELECT p.name, a.country, a.city, a.street_address, p.id FROM pharmacies p "
        f"JOIN addresses a on p.address_id = a.id "
        f"WHERE p.id={pharmacy_id};"))
    products = list(db.session.execute(
        f"SELECT m.name, m.fabricator, m.description, pr.price::money::numeric::float8, pr.amount, pr.id "
        f"FROM products pr "
        f"JOIN medicines m ON pr.medicine_id = m.id "
        f"WHERE pr.pharmacy_id={pharmacy_id};"))
    apothecary_flag = list(db.session.execute(
        f"SELECT user_id FROM apothecaries "
        f"JOIN pharmacies ON apothecaries.id = pharmacies.apothecary_id "
        f"WHERE user_id={current_user.id} AND pharmacies.id={pharmacy_id};"))
    db.session.commit()

    return render_template("pharmacy.html", pharmacy=pharmacy_info, products=products, apothecary_flag=apothecary_flag)


@pharmacy.route('/pharmacy/<int:pharmacy_id>', methods=['POST'])
def pharmacy_post(pharmacy_id):
    product_id = request.form.get("product_id")
    amount = request.form.get("amount")
    price = request.form.get("price")
    db.session.execute(f"CALL edit_product({product_id}, {amount}, {price});")
    db.session.commit()
    return redirect(url_for('pharmacy.pharmacy_get', pharmacy_id=pharmacy_id))


@pharmacy.route('/pharmacy/<int:pharmacy_id>/edit', methods=['POST'])
def pharmacy_edit(pharmacy_id):
    name = request.form.get('name')
    country = request.form.get('country')
    city = request.form.get('city')
    street_address = request.form.get('street_address')

    db.session.execute(f"CALL edit_pharmacy({pharmacy_id}, '{name}', '{country}', '{city}', '{street_address}');")
    db.session.commit()

    return redirect(url_for('pharmacy.pharmacy_get', pharmacy_id=pharmacy_id))


@pharmacy.route('/pharmacy/<int:pharmacy_id>/delete', methods=['POST'])
def pharmacy_delete(pharmacy_id):
    db.session.execute(f"CALL delete_pharmacy({pharmacy_id});")
    db.session.commit()

    return redirect(url_for('main.index'))


@pharmacy.route('/pharmacy/<int:pharmacy_id>/delete_product', methods=['POST'])
def pharmacy_delete_product(pharmacy_id):
    product_id = request.form.get('product_id')
    db.session.execute(f"CALL delete_product({product_id});")
    db.session.commit()

    return redirect(url_for('pharmacy.pharmacy_get', pharmacy_id=pharmacy_id))


@pharmacy.route('/pharmacy/<int:pharmacy_id>/add_new_product')
def pharmacy_add_new_product(pharmacy_id):
    options = list(db.session.execute(f"SELECT id, name FROM medicine_types;"))
    db.session.commit()
    return render_template("add_new_product.html", options=options)


@pharmacy.route('/pharmacy/<int:pharmacy_id>/add_new_product', methods=['POST'])
def pharmacy_add_new_product_post(pharmacy_id):
    name = request.form.get('name')
    type_id = request.form.get('type')
    fabricator = request.form.get('fabricator')
    description = request.form.get('description')
    amount = request.form.get('amount')
    price = request.form.get('price')

    db.session.execute(f"CALL add_new_product({pharmacy_id}, '{name}', {type_id}, '{fabricator}', '{description}', "
                       f"{amount}, {price});")
    db.session.commit()
    return redirect(url_for('pharmacy.pharmacy_get', pharmacy_id=pharmacy_id))


@pharmacy.route('/pharmacy/<int:pharmacy_id>/add_existing_product')
def pharmacy_add_existing_product(pharmacy_id):
    options = list(db.session.execute(f"SELECT id, name, fabricator FROM medicines;"))
    db.session.commit()
    return render_template("add_existing_product.html", options=options)


@pharmacy.route('/pharmacy/<int:pharmacy_id>/add_existing_product', methods=['POST'])
def pharmacy_add_existing_product_post(pharmacy_id):
    medicine_id = request.form.get('medicine_id')
    amount = request.form.get('amount')
    price = request.form.get('price')

    db.session.execute(f"CALL add_existing_product({pharmacy_id}, {medicine_id}, {amount}, {price});")
    db.session.commit()

    return redirect(url_for('pharmacy.pharmacy_get', pharmacy_id=pharmacy_id))


@pharmacy.route('/pharmacy/<int:pharmacy_id>/orders')
def pharmacy_orders(pharmacy_id):
    active_orders = list(db.session.execute(f"SELECT po.id, m.name, po.amount, "
                                            f"po.amount*p.price::money::numeric::float8 FROM medicines m "
                                            f"JOIN products p ON m.id = p.medicine_id "
                                            f"JOIN products_orders po ON p.id = po.product_id "
                                            f"JOIN pharmacies p2 on p2.id = p.pharmacy_id "
                                            f"JOIN orders o on o.id = po.order_id "
                                            f"WHERE p2.id={pharmacy_id} AND o.status_id=1;"))

    other_orders = list(db.session.execute(f"SELECT m.name, po.amount, po.amount*p.price::money::numeric::float8, "
                                           f"os.name FROM medicines m "
                                           f"JOIN products p ON m.id = p.medicine_id "
                                           f"JOIN products_orders po ON p.id = po.product_id "
                                           f"JOIN pharmacies p2 on p2.id = p.pharmacy_id "
                                           f"JOIN orders o on o.id = po.order_id "
                                           f"JOIN order_statuses os ON os.id = o.status_id "
                                           f"WHERE p2.id={pharmacy_id} AND "
                                           f"o.status_id!=1;"))

    db.session.commit()

    return render_template("pharmacy_orders.html", active_orders=active_orders, other_orders=other_orders,
                           pharmacy_id=pharmacy_id)


@pharmacy.route('/pharmacy/<int:pharmacy_id>/orders/accept', methods=['POST'])
def pharmacy_orders_accept_post(pharmacy_id):
    product_order_id = request.form.get('product_order_id')

    db.session.execute(f"CALL accept_order({product_order_id});")
    db.session.commit()

    return redirect(url_for('pharmacy.pharmacy_orders', pharmacy_id=pharmacy_id))


@pharmacy.route('/pharmacy/<int:pharmacy_id>/orders/deny', methods=['POST'])
def pharmacy_orders_deny_post(pharmacy_id):
    product_order_id = request.form.get('product_order_id')

    db.session.execute(f"CALL deny_order({product_order_id});")
    db.session.commit()

    return redirect(url_for('pharmacy.pharmacy_orders', pharmacy_id=pharmacy_id))


@pharmacy.route('/pharmacy/<int:pharmacy_id>/reviews')
def pharmacy_reviews(pharmacy_id):
    reviews = list(db.session.execute(f"SELECT u.name, u.email, r.message FROM reviews r "
                                      f"JOIN clients c ON c.id = r.client_id "
                                      f"JOIN users u on u.id = c.user_id "
                                      f"WHERE r.pharmacy_id={pharmacy_id};"))

    client_flag = list(db.session.execute(f"SELECT user_id FROM clients c "
                                          f"WHERE user_id={current_user.id};"))

    db.session.commit()
    return render_template("pharmacy_reviews.html", reviews=reviews, client_flag=client_flag, pharmacy_id=pharmacy_id)


@pharmacy.route('/pharmacy/<int:pharmacy_id>/reviews/edit')
def pharmacy_reviews_edit(pharmacy_id):
    review = list(db.session.execute(f"SELECT r.message FROM reviews r "
                                     f"JOIN clients c ON c.id = r.client_id "
                                     f"JOIN users u on u.id = c.user_id "
                                     f"WHERE r.pharmacy_id={pharmacy_id} AND u.id={current_user.id};"))
    db.session.commit()

    return render_template("pharmacy_reviews_edit.html", review=review, pharmacy_id=pharmacy_id)


@pharmacy.route('/pharmacy/<int:pharmacy_id>/reviews/edit', methods=['POST'])
def pharmacy_reviews_edit_post(pharmacy_id):
    message = request.form.get('message')

    db.session.execute(f"CALL edit_review({current_user.id}, {pharmacy_id}, '{message}');")
    db.session.commit()

    return redirect(url_for('pharmacy.pharmacy_reviews_edit', pharmacy_id=pharmacy_id))
