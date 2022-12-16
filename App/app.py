from flask import Blueprint

main = Blueprint('main', __name__)

@main.route('/')
def index():
    return 'Index'

@main.route('/profile')
def profile():
    return 'Profile'

if __name__ == '__main__':
    main.run()
