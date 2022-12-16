# main.py

from flask import Blueprint, render_template, redirect, url_for, request
from flask_login import login_required, current_user, logout_user

from project import db

main = Blueprint('main', __name__)


@main.route('/')
def index():
    return render_template('index.html')


@main.route('/profile')
@login_required
def profile():
    return render_template('profile.html', user=current_user)


@main.route('/profile/delete')
@login_required
def profile_delete():
    user_id = current_user.id
    logout_user()
    db.session.execute(f"CALL user_delete({user_id})")
    db.session.commit()

    return redirect(url_for('main.index'))


@main.route('/profile/edit', methods=['POST'])
@login_required
def profile_edit():
    name = request.form.get('name')
    number = request.form.get('number')
    password = request.form.get('password')

    db.session.execute(f"CALL edit_user({current_user.id}, '{name}', '{number}', '{password}')")
    db.session.commit()

    return redirect(url_for('main.index'))
