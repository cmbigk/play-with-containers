# Testing & Inspection Guide

This guide covers how to test the API with Postman and how to inspect the internal state of the databases and message broker running inside the Vagrant VMs.

## Prerequisites

Before testing, confirm the Docker containers and services are running:

```bash
docker-compose ps
```

All 6 containers (`api-gateway`, `inventory-app`, `billing-app`, `inventory-database`, `billing-database`, `rabbitmq-server`) should show up as running. To view the logs for the billing app specifically:

```bash
docker logs billing-app
```

> All API requests go to the **Gateway Container** which is mapped to `http://localhost:3000`.

---

## 1. Postman — API Tests

Import the collection from the `postman/` folder, or create requests manually as described below.

### Add a Movie

- **Method**: `POST`
- **URL**: `http://localhost:3000/api/movies`
- **Body** (`raw` / `JSON`):
  ```json
  {
    "title": "Inception",
    "description": "A thief who steals corporate secrets through the use of dream-sharing technology."
  }
  ```
- **Expected**: `201 Created` with the new movie JSON including its `id`.

---

### Get All Movies

- **Method**: `GET`
- **URL**: `http://localhost:3000/api/movies`
- **Expected**: `200 OK` with a JSON array of all movies.

---

### Get a Single Movie

- **Method**: `GET`
- **URL**: `http://localhost:3000/api/movies/1`
- **Expected**: `200 OK` with the movie JSON for id `1`.

---

### Update a Movie

- **Method**: `PUT`
- **URL**: `http://localhost:3000/api/movies/1`
- **Body** (`raw` / `JSON`):
  ```json
  {
    "title": "Inception (Updated)",
    "description": "Updated description."
  }
  ```
- **Expected**: `200 OK` with the updated movie JSON.

---

### Delete a Movie

- **Method**: `DELETE`
- **URL**: `http://localhost:3000/api/movies/1`
- **Expected**: `200 OK`.

---

### Delete All Movies

- **Method**: `DELETE`
- **URL**: `http://localhost:3000/api/movies`
- **Expected**: `200 OK` with `{"message": "All movies deleted"}`.

---

### Place a Billing Order

This publishes a message to the RabbitMQ queue on `rabbitmq-server`. The response is immediate; processing happens asynchronously automatically by `billing-app`.

- **Method**: `POST`
- **URL**: `http://localhost:3000/api/billing`
- **Body** (`raw` / `JSON`):
  ```json
  {
    "user_id": 99,
    "number_of_items": 3,
    "total_amount": 45.50
  }
  ```
- **Expected**: `200 OK` with `{"message": "Order successfully submitted to billing queue"}`.

To confirm the order was processed, check the logs on the `billing-app` container:

```bash
docker logs billing-app --tail 20
```

---

### Test Queue Resilience

To verify that RabbitMQ safely holds messages when the billing service is temporarily down:

1. Stop the billing container:
   ```bash
   docker stop billing-app
   ```
2. Send a few orders using the `POST /api/billing` request above. You should still get a `200 OK` response.
3. Check the RabbitMQ queue to see the messages waiting:
   ```bash
   docker exec -it rabbitmq-server rabbitmqctl list_queues
   ```
4. Start the billing container back up:
   ```bash
   docker start billing-app
   ```
5. Check the logs to see the safely queued messages get processed immediately:
   ```bash
   docker logs billing-app --tail 20
   ```

---

## 2. Databases — PostgreSQL

The databases live inside their respective containers. Connect via `docker exec`.

### Movies DB (on `inventory-database`)

```bash
docker exec -it inventory-database psql -U inventory_user -d movies_db
```

Useful SQL:

```sql
SELECT * FROM movies;
\q
```

### Orders DB (on `billing-database`)

```bash
docker exec -it billing-database psql -U billing_user -d orders_db
```

Useful SQL:

```sql
SELECT * FROM orders;
\q
```

> The PostgreSQL passwords are whatever you set as DB passwords in your `.env` file.

---

## 3. RabbitMQ — Message Broker

RabbitMQ runs on the `rabbitmq-server` container. Credentials are set by `RABBITMQ_USER` / `RABBITMQ_PASS` in `.env`.

### CLI — List Queues

```bash
docker exec -it rabbitmq-server rabbitmqctl list_queues
```
