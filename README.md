# Dockerized Microservices

This project containerizes a set of microservices including an API Gateway, Inventory App, and Billing App along with their required databases and message queues.

## Prerequisites
- Docker: 20.10+
- Docker Compose: 1.29+ (or V2)

## Architecture
- **api-gateway-app**: Entry point (Flask), routes requests.
- **inventory-app**: Manages movie database (Flask).
- **billing-app**: Processes orders from queue (Python/Pika).
- **inventory-database**: PostgreSQL for movies.
- **billing-database**: PostgreSQL for orders.
- **RabbitMQ**: Message broker for async ordering.

## Configuration
The system uses environment variables for configuration. Create or use the existing `.env` file at the root of the project with the following shape:
```env
INVENTORY_DB_NAME=movies_db
INVENTORY_DB_USER=inventory_user
INVENTORY_DB_PASSWORD=inventory_pass_123
BILLING_DB_NAME=orders_db
BILLING_DB_USER=billing_user
BILLING_DB_PASSWORD=billing_pass_123
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest
```

## Setup & Run
To build the images and start all the containers in the background, run:
```bash
docker-compose up --build -d
```

## API Endpoints

### Movies (Inventory API routed via Gateway)

#### Get all movies
```bash
curl -X GET http://localhost:3000/api/movies
```

#### Add a new movie
```bash
curl -X POST http://localhost:3000/api/movies \
-H "Content-Type: application/json" \
-d '{"title": "The Matrix", "description": "A computer hacker learns from mysterious rebels about the true nature of his reality."}'
```

#### Get a specific movie
```bash
curl -X GET http://localhost:3000/api/movies/1
```

#### Delete a movie
```bash
curl -X DELETE http://localhost:3000/api/movies/1
```

### Billing (Billing Queue routed via Gateway)

#### Submit an order
```bash
curl -X POST http://localhost:3000/api/billing \
-H "Content-Type: application/json" \
-d '{"user_id": 42, "number_of_items": 2, "total_amount": 19.99}'
```

This request will succeed and queue the message even if the `billing-app` is temporarily down.

## Teardown
To stop all services and remove the custom network and named volumes (deleting all database and queue data):
```bash
docker-compose down -v
```
### Tear Down

To stop the services and remove the networking:
```bash
docker-compose down
```

To stop services and **delete all data** (volumes):
```bash
docker-compose down -v
```

### RabbitMQ Management UI

You can view the message queue visually by opening:
[http://localhost:15672](http://localhost:15672)

**Credentials**: Use the `RABBITMQ_USER` and `RABBITMQ_PASS` from your `.env` file. (By default: `rmq_user` / `rmq_pass`)
