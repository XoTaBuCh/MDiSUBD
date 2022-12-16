# auth.py
import psycopg2
from flask import Blueprint, render_template, redirect, url_for, request, flash
from sqlalchemy import func
from werkzeug.security import generate_password_hash, check_password_hash
from flask_login import login_user, logout_user, login_required
from .models import User
from . import db

auth = Blueprint('auth', __name__)


@auth.route('/login')
def login():
    return render_template('login.html')


@auth.route('/login', methods=['POST'])
def login_post():
    email = request.form.get('email')
    password = request.form.get('password')
    remember = True if request.form.get('remember') else False

    response = list(db.session.execute(f"SELECT users.id, users.name, number, email, password, account_statuses.name "
                                       f"FROM users JOIN account_statuses ON users.status_id=account_statuses.id "
                                       f"WHERE email='{email}' AND password=crypt('{password}', password)"))

    if not response:
        flash('Please check your login details and try again.')
        return redirect(url_for('auth.login'))

    user = User(response[0])

    login_user(user, remember=remember)
    return redirect(url_for('menu.menu_redirect'))


@auth.route('/signup')
def signup():
    return render_template('signup.html')


@auth.route('/signup', methods=['POST'])
def signup_post():
    name = request.form.get('name')
    number = request.form.get('number')
    email = request.form.get('email')
    password = request.form.get('password')

    response = list(db.session.execute(f"SELECT COUNT(*) FROM users WHERE users.email='{email}'"))

    if response[0][0]:
        flash('Email address already exists')
        return redirect(url_for('auth.signup'))

    db.session.execute(f"CALL insert_client('{name}', '{number}', '{email}', '{password}', 1)")
    db.session.commit()

    return redirect(url_for('auth.login'))


@auth.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('main.index'))
