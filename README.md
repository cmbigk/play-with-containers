# Dockerized Microservices

This project containerizes a set of microservices including an API Gateway, Inventory App, and Billing App along with their required databases and message broker.

## Prerequisites

Before setting up the project, ensure you have the following installed on your machine:

- **Docker**: Version 20.10+
- **Docker Compose**: Version 1.29+ (or Docker Compose V2 included with Docker Desktop)

## Architecture

The system consists of the following 6 services:

- **api-gateway-app**: Entry point (Flask), routes requests and publishes billing orders.
- **inventory-app**: Manages movie catalog (Flask), connects to movies database.
- **billing-app**: Consumes order messages from RabbitMQ and saves them to a database.
- **inventory-database**: PostgreSQL database storing movie data.
- **billing-database**: PostgreSQL database storing billing orders.
- **RabbitMQ**: Message broker managing asynchronous order processing.

## Configuration

The system is configured using an environment file. Use the existing `.env` file at the root of the project or create one with the following variables:

```env
# Inventory Database
INVENTORY_DB_NAME=movies_db
INVENTORY_DB_USER=******
INVENTORY_DB_PASSWORD=******

# Billing Database
BILLING_DB_NAME=orders_db
BILLING_DB_USER=******
BILLING_DB_PASSWORD=******

# RabbitMQ
RABBITMQ_USER=******
RABBITMQ_PASSWORD=******
```

> [!IMPORTANT]
> Ensure the `.env` file is present before running the setup commands.

## Setup & Run

Follow these steps to build and launch the infrastructure:

1. **Build and Start**:
   ```bash
   docker-compose up --build -d
   ```
2. **Verify Services**:
   Check that all 6 containers are running:
   ```bash
   docker-compose ps
   ```

## Usage

All API requests should be sent to the API Gateway at `http://localhost:3000`.

### Inventory Management

- **Get all movies**: `GET http://localhost:3000/api/movies`
- **Add a movie**: `POST http://localhost:3000/api/movies`
  ```json
  {"title": "The Matrix", "description": "Welcome to the real world."}
  ```
- **Delete a movie**: `DELETE http://localhost:3000/api/movies/1`

### Billing Orders

- **Submit an order**: `POST http://localhost:3000/api/billing`
  ```json
  {"user_id": "22", "number_of_items": "10", "total_amount": "50"}
  ```

## Management & Inspection

### Monitoring Logs
View the activity of the billing worker:
```bash
docker logs -f billing-app
```

### Visual Queue Management
Open the RabbitMQ Management UI in your browser:
- **URL**: [http://localhost:15672](http://localhost:15672)
- **Login**: Use the `RABBITMQ_USER` and `RABBITMQ_PASSWORD` from your `.env`.

### Database Access
Access the movies database directly:
```bash
docker exec -it inventory-database psql -U inventory_user -d movies_db
```

## Teardown

To stop the services and remove the networking:
```bash
docker-compose down
```

To stop services and **delete all persistent data** (volumes):
```bash
docker-compose down -v
```
