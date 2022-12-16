
from flask import Flask
from flask_login import LoginManager
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


def create_app():
    app = Flask(__name__)

    app.config['SECRET_KEY'] = 'thisissecret'
    app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://postgres:admin@localhost:5432/mdisubd'

    db.init_app(app)

    login_manager = LoginManager()
    login_manager.login_view = 'auth.login'
    login_manager.init_app(app)

    @login_manager.user_loader
    def load_user(user_id):
        response = list(db.session.execute(f"SELECT * FROM users WHERE users.id='{user_id}'"))
        from .models import User
        user = User(response[0])

        return user

    # blueprint for auth routes in our app
    from .auth import auth as auth_blueprint
    app.register_blueprint(auth_blueprint)

    # blueprint for non-auth parts of app
    from .main import main as main_blueprint
    app.register_blueprint(main_blueprint)

    from .menu import menu as menu_blueprint
    app.register_blueprint(menu_blueprint)

    from .medicine import medicine as medicine_blueprint
    app.register_blueprint(medicine_blueprint)

    from .pharmacy import pharmacy as pharmacy_blueprint
    app.register_blueprint(pharmacy_blueprint)

    return app
