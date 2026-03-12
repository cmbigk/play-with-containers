import os
import time
import pika
import json
from sqlalchemy import create_engine, Column, Integer, Float, DateTime
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy.exc import OperationalError as SAOperationalError
from datetime import datetime
import sys

# Configure Database
DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_PORT = os.environ.get("DB_PORT", "5432")
DB_USER = os.environ.get("DB_USER", os.environ.get("USER", "postgres"))
DB_PASS = os.environ.get("DB_PASS", "")
DB_NAME = os.environ.get("DB_NAME", "orders_db")

db_url = f"postgresql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# pool_pre_ping tests each connection before use and discards stale ones,
# preventing "SSL connection closed unexpectedly" errors after Postgres restarts.
engine = create_engine(db_url, pool_pre_ping=True)
Session = sessionmaker(bind=engine)
Base = declarative_base()


class Order(Base):
    """Order model for storing customer orders in the billing database."""

    __tablename__ = "orders"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, nullable=False)
    number_of_items = Column(Integer, nullable=False)
    total_amount = Column(Float, nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow)


# Retry table creation so transient Postgres startup errors don't crash the worker.
for attempt in range(10):
    try:
        Base.metadata.create_all(engine)
        break
    except SAOperationalError as e:
        print(f" [!] DB not ready yet (attempt {attempt + 1}/10): {e}")
        time.sleep(5)

# RabbitMQ Configuration
RABBITMQ_HOST = os.environ.get("RABBITMQ_HOST", "localhost")
RABBITMQ_USER = os.environ.get("RABBITMQ_USER", "guest")
RABBITMQ_PASS = os.environ.get("RABBITMQ_PASS", "guest")
QUEUE_NAME = "billing_queue"


def process_message(ch, method, properties, body):
    """Process a message from the billing queue and persist it to the database."""
    try:
        data = json.loads(body)
        print(f" [x] Received order: {data}")

        session = Session()
        new_order = Order(
            user_id=data.get("user_id"),
            number_of_items=data.get("number_of_items"),
            total_amount=data.get("total_amount"),
        )
        session.add(new_order)
        session.commit()
        print(f" [x] Successfully stored order for user {data.get('user_id')}")
        session.close()

        # Acknowledge the message only on success
        ch.basic_ack(delivery_tag=method.delivery_tag)
    except Exception as e:
        print(f" [!] Error processing message: {e}")
        # Reject the message and requeue it so it isn't lost
        ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)


def connect_with_retry(max_attempts=20, delay=5):
    """Attempt to connect to RabbitMQ, retrying until it is ready."""
    credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASS)
    params = pika.ConnectionParameters(
        host=RABBITMQ_HOST,
        credentials=credentials,
        connection_attempts=1,
    )
    for attempt in range(1, max_attempts + 1):
        try:
            print(f" [*] Connecting to RabbitMQ at {RABBITMQ_HOST} (attempt {attempt}/{max_attempts})...")
            return pika.BlockingConnection(params)
        except pika.exceptions.AMQPConnectionError as e:
            if attempt == max_attempts:
                raise
            print(f" [!] RabbitMQ not ready, retrying in {delay}s: {e}")
            time.sleep(delay)


def main():
    """Start the RabbitMQ consumer to process billing messages."""
    connection = connect_with_retry()
    channel = connection.channel()

    # Declare the queue (durable=True so messages survive broker restarts)
    channel.queue_declare(queue=QUEUE_NAME, durable=True)

    # Fetch 1 message at a time
    channel.basic_qos(prefetch_count=1)

    channel.basic_consume(queue=QUEUE_NAME, on_message_callback=process_message)

    print(" [*] Waiting for messages. To exit press CTRL+C")
    channel.start_consuming()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("Interrupted")
        try:
            sys.exit(0)
        except SystemExit:
            os._exit(0)
