from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from flask_socketio import SocketIO, emit, join_room
from werkzeug.security import generate_password_hash, check_password_hash
import os

app = Flask(__name__)
CORS(app)

app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///chat.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)
socketio = SocketIO(app, cors_allowed_origins="*")

# ---------------- MODELS ----------------

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(200), nullable=False)

class Message(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    sender_id = db.Column(db.Integer)
    receiver_id = db.Column(db.Integer)
    message = db.Column(db.Text)

# ---------------- AUTH ----------------

@app.route("/register", methods=["POST"])
def register():
    data = request.json

    name = data.get("name")
    email = data.get("email")
    password = data.get("password")

    if not name or not email or not password:
        return jsonify({"message": "Missing fields"}), 400

    # ❌ check email
    if User.query.filter_by(email=email).first():
        return jsonify({"message": "Email already registered"}), 409

    # ❌ check name
    if User.query.filter_by(name=name).first():
        return jsonify({"message": "Name already taken"}), 409

    user = User(
        name=name,
        email=email,
        password=generate_password_hash(password)
    )

    db.session.add(user)
    db.session.commit()

    return jsonify({"message": "Registered successfully"}), 201


@app.route("/login", methods=["POST"])
def login():
    data = request.json
    user = User.query.filter_by(email=data["email"]).first()

    if not user or not check_password_hash(user.password, data["password"]):
        return jsonify({"message": "Invalid credentials"}), 401

    return jsonify({
        "user": {
            "id": user.id,
            "name": user.name,
            "email": user.email
        }
    }), 200

# ---------------- USERS ----------------

@app.route("/users", methods=["GET"])
def users():
    users = User.query.all()
    return jsonify([
        {"id": u.id, "name": u.name, "email": u.email}
        for u in users
    ])

@app.route("/search", methods=["GET"])
def search_users():
    name = request.args.get("name", "")
    users = User.query.filter(User.name.ilike(f"%{name}%")).all()
    return jsonify([
        {"id": u.id, "name": u.name, "email": u.email}
        for u in users
    ])

# ---------------- SOCKET ----------------

@socketio.on("join")
def join(data):
    join_room(data["room"])

@socketio.on("send_message")
def send_message(data):
    msg = Message(
        sender_id=data["sender_id"],
        receiver_id=data["receiver_id"],
        message=data["message"]
    )
    db.session.add(msg)
    db.session.commit()
    emit("receive_message", data, room=data["room"])

# ---------------- RUN ----------------

if __name__ == "__main__":
    with app.app_context():
        db.create_all()

    port = int(os.environ.get("PORT", 10000))
    socketio.run(app, host="0.0.0.0", port=port)
