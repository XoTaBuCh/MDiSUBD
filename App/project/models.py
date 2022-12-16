# models.py

from flask_login import UserMixin
from . import db


class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255))
    number = db.Column(db.String(255))
    email = db.Column(db.String(255), unique=True)
    password = db.Column(db.String)
    status = db.Column(db.String(255))

    def is_active(self):
        if self.status == "Active":
            return True

    def get_id(self):
        return self.id

    def __init__(self, response):
        self.id = response[0]
        self.name = response[1]
        self.number = response[2]
        self.email = response[3]
        self.password = response[4]
        self.status = response[5]
