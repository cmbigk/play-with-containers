# Infrastructure Explainer: Docker & Docker Compose

This document explains how the project's infrastructure is defined and automated, utilizing Docker and Docker Compose for robust containerization. 

---

## What Is Docker?

Docker is a tool for creating, deploying, and running applications in isolated environments called containers. Instead of manually installing an OS and configuring software by hand, you write a **`Dockerfile`** — a text document containing all the commands to assemble an image — and Docker builds and isolates the application. 

The key benefit: anyone on the team runs `docker-compose up` and gets an *identical* environment.

---

## The Six Containers

The `docker-compose.yml` defines six containers, all placed on a custom private network `app-network`:

| Container Name | Ports | Role |
|---|---|---|
| `api-gateway` | `3000:3000` | API Gateway — the only public entry point |
| `inventory-app` | (Internal) | Inventory service REST API |
| `billing-app` | (Internal) | Billing worker (RabbitMQ Consumer) |
| `inventory-database` | (Internal) | PostgreSQL database storing movie data |
| `billing-database` | (Internal) | PostgreSQL database storing billing orders |
| `rabbitmq-server` | (Internal) | RabbitMQ acting as our message broker |

---

## How `docker-compose up` Works (Step by Step)

When you run `docker-compose up --build`, Docker works through a sequence of steps to establish your services.

1. **Network Initialization**: A custom bridge network `app-network` is created.
2. **Volume Initialization**: Three named volumes (`inventory-database`, `billing-database`, `api-gateway`) are established so data survives container restarts.
3. **Image Building**: Docker parses the individual `Dockerfile` for each of the 6 services and installs its dependencies (Python, PostgreSQL, RabbitMQ) precisely over a minimal Alpine/Debian base image. 
4. **Environment Application**: Docker Compose injects everything from your `.env` file natively into the containers. 
5. **Orchestration**: Docker starts `rabbitmq-server`, `inventory-database`, and `billing-database`. Because we defined `depends_on`, the Node.js/Python apps wait safely for the infrastructure to establish itself before attempting connection.

---

## What Is Docker Restart Policy?

Docker has a **restart policy** mechanism. In this project we use `restart: on-failure`. 

- **Auto-restart on crash**: If a service crashes (exception, OOM), Docker engine instantly restarts the container gracefully.

---

## What Is RabbitMQ?

RabbitMQ is a **message broker** — an intermediary that decouples services that need to communicate asynchronously.

In this project:
- The **Gateway** publishes an order message to a RabbitMQ queue when `POST /api/billing` is called. It does not wait for the order to be processed; it gets an immediate success response.
- The **Billing worker** (`worker.py`) is a long-running process that continuously listens on that queue. When a message arrives, it processes the order and writes it to the `orders_db` database.

This pattern means the Gateway stays responsive even if the Billing service is slow or temporarily down — orders queue up and are processed when the worker comes back.

---

## What Is Pika?

Pika is the specialized **Python library** used by both the Gateway and the Billing worker to talk to RabbitMQ. While RabbitMQ is the "post office," Pika is the "delivery truck" that knows the specific protocol (AMQP) required to send and receive messages accurately.

- **In the Gateway**: Pika is used to **publish** order data to the `billing_queue`.
- **In the Billing Worker**: Pika is used to **subscribe** to the queue and "listen" for incoming messages in real-time.

---

## Environment Variables and the `.env` File

Secrets and configuration (database credentials, service IPs) are never hardcoded. They live in a `.env` file on your machine (not committed to git). `docker-compose.yml` detects the file seamlessly and mounts these tokens securely into the environment (`process.env` / `os.environ`) for each specific container mapping.
