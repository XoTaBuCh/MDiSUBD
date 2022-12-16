from flask import Blueprint, render_template, redirect, url_for, request
from flask_login import current_user

from project import db

medicine = Blueprint('medicine', __name__)


@medicine.route('/medicine/<int:medicine_id>')
def medicine_get(medicine_id):
    medicine_info = list(db.session.execute(
        f"SELECT m.name, mt.name, fabricator, description FROM medicines m "
        f"JOIN medicine_types mt ON m.type_id = mt.id "
        f"WHERE m.id={medicine_id};"))
    products = list(db.session.execute(
        f"SELECT pr.price, pr.amount, ph.name, ph.id FROM products pr "
        f"JOIN pharmacies ph ON pr.pharmacy_id = ph.id "
        f"WHERE pr.medicine_id={medicine_id};"))
    client_flag = list(db.session.execute(
        f"SELECT user_id FROM clients "
        f"WHERE user_id={current_user.id};"))
    db.session.commit()
    return render_template("medicine.html", medicine=medicine_info, products=products, client_flag=client_flag)


@medicine.route('/medicine/<int:medicine_id>', methods=['POST'])
def medicine_post(medicine_id):
    product_id = request.form.get("product_id")
    amount = request.form.get("amount")
    db.session.execute(
        f"CALL put_in_shopping_cart({current_user.id}, {product_id}, {amount});")
    db.session.commit()
    return redirect(url_for('medicine.medicine_get', medicine_id=medicine_id))
