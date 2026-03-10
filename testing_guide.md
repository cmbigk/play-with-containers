# Testing & Inspection Guide

This guide covers how to test the API with Postman and how to inspect the internal state of the databases and message broker running inside the Vagrant VMs.

## Prerequisites

Before testing, confirm the VMs and services are running:

```bash
vagrant status
```

All three VMs (`gateway-vm`, `inventory-vm`, `billing-vm`) should show `running`. To check PM2 service status inside a VM:

```bash
vagrant ssh <vm-name> -c "pm2 status"
```

> All API requests go to the **Gateway VM** at `http://192.168.56.10:5000`.

---

## 1. Postman — API Tests

Import the collection from the `postman/` folder, or create requests manually as described below.

### Add a Movie

- **Method**: `POST`
- **URL**: `http://192.168.56.10:5000/api/movies`
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
- **URL**: `http://192.168.56.10:5000/api/movies`
- **Expected**: `200 OK` with a JSON array of all movies.

---

### Get a Single Movie

- **Method**: `GET`
- **URL**: `http://192.168.56.10:5000/api/movies/1`
- **Expected**: `200 OK` with the movie JSON for id `1`.

---

### Update a Movie

- **Method**: `PUT`
- **URL**: `http://192.168.56.10:5000/api/movies/1`
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
- **URL**: `http://192.168.56.10:5000/api/movies/1`
- **Expected**: `200 OK`.

---

### Delete All Movies

- **Method**: `DELETE`
- **URL**: `http://192.168.56.10:5000/api/movies`
- **Expected**: `200 OK` with `{"message": "All movies deleted"}`.

---

### Place a Billing Order

This publishes a message to the RabbitMQ queue on `billing-vm`. The response is immediate; processing happens asynchronously.

- **Method**: `POST`
- **URL**: `http://192.168.56.10:5000/api/billing`
- **Body** (`raw` / `JSON`):
  ```json
  {
    "user_id": 99,
    "number_of_items": 3,
    "total_amount": 45.50
  }
  ```
- **Expected**: `200 OK` with `{"message": "Order successfully submitted to billing queue"}`.

To confirm the order was processed, check PM2 logs on `billing-vm`:

```bash
vagrant ssh billing-vm -c "pm2 logs billing_app --nostream --lines 20"
```

---

## 2. Databases — PostgreSQL

The databases live inside their respective VMs. Connect via `vagrant ssh`.

### Movies DB (on `inventory-vm`)

```bash
vagrant ssh inventory-vm
psql -U postgres -d movies_db
```

Useful SQL:

```sql
SELECT * FROM movies;
\q
```

### Orders DB (on `billing-vm`)

```bash
vagrant ssh billing-vm
psql -U postgres -d orders_db
```

Useful SQL:

```sql
SELECT * FROM orders;
\q
```

> The PostgreSQL password is whatever you set as `DB_PASS` in your `.env` file (default: `postgres`).

---

## 3. RabbitMQ — Message Broker

RabbitMQ runs on `billing-vm` (`192.168.56.12`). Credentials are set by `RABBITMQ_USER` / `RABBITMQ_PASS` in `.env` (defaults: `guest` / `guest`).

### Web Management UI

Open in your browser:

```
http://192.168.56.12:15672
```

Here you can inspect queues, messages, connections, and exchanges.

### CLI — List Queues

```bash
vagrant ssh billing-vm -c "sudo rabbitmqctl list_queues"
```
