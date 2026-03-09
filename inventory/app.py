import os
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)

# Configure Database
DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_PORT = os.environ.get("DB_PORT", "5432")
DB_USER = os.environ.get("DB_USER", os.environ.get("USER", "postgres"))
DB_PASS = os.environ.get("DB_PASS", "")
DB_NAME = os.environ.get("DB_NAME", "movies_db")

app.config["SQLALCHEMY_DATABASE_URI"] = (
    f"postgresql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db = SQLAlchemy(app)


# Models
class Movie(db.Model):
    __tablename__ = "movies"
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    description = db.Column(db.String(255), nullable=True)

    def to_dict(self):
        return {"id": self.id, "title": self.title, "description": self.description}


# Routes
@app.route("/movies", methods=["GET"])
def get_movies():
    title = request.args.get("title")
    if title:
        movies = Movie.query.filter(Movie.title.ilike(f"%{title}%")).all()
    else:
        movies = Movie.query.all()
    return jsonify([movie.to_dict() for movie in movies]), 200


@app.route("/movies", methods=["DELETE"])
def delete_all_movies():
    db.session.query(Movie).delete()
    db.session.commit()
    return jsonify({"message": "All movies deleted"}), 200


@app.route("/movies", methods=["POST"])
def add_movie():
    data = request.get_json()
    if not data or not data.get("title"):
        return jsonify({"error": "Title is required"}), 400

    new_movie = Movie(title=data["title"], description=data.get("description", ""))
    db.session.add(new_movie)
    db.session.commit()
    return jsonify(new_movie.to_dict()), 201


@app.route("/movies/<int:movie_id>", methods=["GET"])
def get_movie(movie_id):
    movie = Movie.query.get(movie_id)
    if not movie:
        return jsonify({"error": "Movie not found"}), 404
    return jsonify(movie.to_dict()), 200


@app.route("/movies/<int:movie_id>", methods=["PUT"])
def update_movie(movie_id):
    movie = Movie.query.get(movie_id)
    if not movie:
        return jsonify({"error": "Movie not found"}), 404

    data = request.get_json()
    if not data:
        return jsonify({"error": "Invalid data"}), 400

    if "title" in data:
        movie.title = data["title"]
    if "description" in data:
        movie.description = data["description"]

    db.session.commit()
    return jsonify(movie.to_dict()), 200


@app.route("/movies/<int:movie_id>", methods=["DELETE"])
def delete_movie(movie_id):
    movie = Movie.query.get(movie_id)
    if not movie:
        return jsonify({"error": "Movie not found"}), 404
    db.session.delete(movie)
    db.session.commit()
    return jsonify({"message": "Movie deleted"}), 200


def init_db():
    with app.app_context():
        db.create_all()


if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=5001)
