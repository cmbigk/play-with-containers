import os
import requests
import pika
import json
from flask import Flask, request, jsonify

app = Flask(__name__)

INVENTORY_URL = os.environ.get("INVENTORY_URL", "http://localhost:5001")
RABBITMQ_HOST = os.environ.get("RABBITMQ_HOST", "localhost")
RABBITMQ_USER = os.environ.get("RABBITMQ_USER", "guest")
RABBITMQ_PASS = os.environ.get("RABBITMQ_PASS", "guest")
QUEUE_NAME = "billing_queue"


@app.route("/api/movies", methods=["GET", "POST", "DELETE"], strict_slashes=False)
def proxy_movies():
    """Proxy requests related to the movies collection to the Inventory service."""
    try:
        if request.method == "GET":
            # Pass any query parameters like ?title=name
            resp = requests.get(f"{INVENTORY_URL}/movies", params=request.args)
            return jsonify(resp.json()), resp.status_code

        if request.method == "POST":
            resp = requests.post(f"{INVENTORY_URL}/movies", json=request.get_json())
            return jsonify(resp.json()), resp.status_code

        if request.method == "DELETE":
            resp = requests.delete(f"{INVENTORY_URL}/movies")
            return jsonify(resp.json()), resp.status_code
    except requests.exceptions.RequestException as e:
        return (
            jsonify({"error": "Inventory service unavailable", "details": str(e)}),
            503,
        )


@app.route(
    "/api/movies/<int:movie_id>", methods=["GET", "PUT", "DELETE"], strict_slashes=False
)
def proxy_movie(movie_id):
    """Proxy requests related to a specific movie to the Inventory service."""
    try:
        if request.method == "GET":
            resp = requests.get(f"{INVENTORY_URL}/movies/{movie_id}")
            return jsonify(resp.json()), resp.status_code

        if request.method == "PUT":
            resp = requests.put(
                f"{INVENTORY_URL}/movies/{movie_id}", json=request.get_json()
            )
            return jsonify(resp.json()), resp.status_code

        if request.method == "DELETE":
            resp = requests.delete(f"{INVENTORY_URL}/movies/{movie_id}")
            return jsonify(resp.json()), resp.status_code
    except requests.exceptions.RequestException as e:
        return (
            jsonify({"error": "Inventory service unavailable", "details": str(e)}),
            503,
        )


@app.route("/api/billing", methods=["POST"], strict_slashes=False)
def create_billing_order():
    """Receive order requests and publish them to the billing queue."""
    data = request.get_json()
    if (
        not data
        or not data.get("user_id")
        or not data.get("number_of_items")
        or not data.get("total_amount")
    ):
        return (
            jsonify(
                {
                    "error": "Missing required fields: user_id, number_of_items, total_amount"
                }
            ),
            400,
        )

    order_payload = {
        "user_id": data["user_id"],
        "number_of_items": data["number_of_items"],
        "total_amount": data["total_amount"],
    }

    try:
        publish_to_billing(order_payload)
        return (
            jsonify({"message": "Order successfully submitted to billing queue"}),
            200,
        )
    except Exception as e:
        print(f"Failed to publish message: {e}")
        return jsonify({"error": "Billing service queue unavailable"}), 503


def publish_to_billing(order_data):
    """Publish an order payload to the RabbitMQ billing queue."""
    credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASS)
    connection = pika.BlockingConnection(
        pika.ConnectionParameters(host=RABBITMQ_HOST, credentials=credentials)
    )
    channel = connection.channel()
    channel.queue_declare(queue=QUEUE_NAME, durable=True)

    channel.basic_publish(
        exchange="",
        routing_key=QUEUE_NAME,
        body=json.dumps(order_data),
        properties=pika.BasicProperties(
            delivery_mode=2,  # make message persistent
        ),
    )
    connection.close()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
