# CRUD Master: Technical Guide & Development Plan

Welcome to the **CRUD Master** project! This document explains the core technologies we'll be using, why we're using them, and how we'll build the system step-by-step.

## 🚀 The Technology Stack

If you've used Python, PostgreSQL, and Postman before, you're halfway there. Here’s a breakdown of the new tools:

### 1. Docker & Docker Compose (The Environment Manager)
*   **What is it?** Docker is a platform for developing, shipping, and running applications in isolated environments called containers. Docker Compose lets us define and run multi-container applications.
*   **Why use it?** It ensures that the project runs the exact same way on your Mac as it does on anyone else's machine. It solves the "it works on my machine" problem.
*   **In this project:** We use a `docker-compose.yml` to automatically create **six separate containers** (Gateway, Inventory, Billing, their two databases, and RabbitMQ). It handles the networking so they can all communicate over a custom bridge network called `app-network`.

### 2. Microservices (The Architecture)
*   **What is it?** Instead of one giant application (a "monolith"), we break the project into small, independent services that talk to each other.
*   **Why Containers?** We use containers to **simulate a real-world distributed system**. Each service lives in its own isolated environment, forcing them to communicate over a network (using HTTP or RabbitMQ) rather than sharing internal memory.

### 3. Flask (The Web Framework)
*   **What is it?** A lightweight Python framework for building web APIs.
*   **In this project:** 
    *   **Inventory API:** Built with Flask to handle CRUD operations for movies.
    *   **API Gateway:** Built with Flask to receive all incoming requests and route them.
    *   **Billing API:** While it mainly listens to a queue, it is also a Python application (and often built with Flask for consistency and monitoring).

### 4. RabbitMQ (The Messenger)
*   **What is it?** A "Message Broker." Think of it like a post office or a digital "To-Do" list.
*   **In this project:** When someone pays (Billing), the Gateway doesn't wait for the Billing service to finish. It just drops a message into RabbitMQ's `billing_queue`. The Billing API picks it up whenever it's ready. This is called **asynchronous communication**.

### 5. Docker Restart Policies (The Guardian)
*   **What is it?** A configuration in Docker that dictates what happens when a container exits or crashes.
*   **In this project:** We use `restart: on-failure` to ensure our APIs stay running. It helps us test **resilience**: if the Billing service container is stopped, messages will safely wait in RabbitMQ until we start it again, and if a service fails, Docker automatically brings it back up.

---

## 🛠 Project Structure & Logic

| Component | Role | Communication |
| :--- | :--- | :--- |
| **Gateway** | The Entry Point | Receives client requests. Sends HTTP to Inventory, RabbitMQ to Billing. |
| **Inventory** | The Catalog | Manages movie data in a `movies_db` (Postgres). |
| **Billing** | The Accountant | Processes orders from a queue and saves to `billing_db`. |

---

## 📋 Development Plan

Here is the strategy to build this without getting overwhelmed:

### Phase 1: Local Development (Single Machine)
Before jumping into VMs, build the logic locally.
1.  **Inventory API:** Create the Flask app, set up SQLAlchemy, and test CRUD endpoints with Postman.
2.  **Billing API:** Create the consumer script (using `pika`) that listens to RabbitMQ and saves to Postgres.
3.  **API Gateway:** Build the router that forwards HTTP requests to Inventory and publishes messages to RabbitMQ.

### Phase 2: Dockerization (Containers)
Once the Python code works, automate the environment.
1.  **Write Dockerfiles:** Create `Dockerfile`s to install Python, Postgres, and RabbitMQ in isolated alpine/debian environments.
2.  **Configure docker-compose.yml:** Define the containers, volumes, and `app-network`.

### Phase 3: Monitoring & Documentation
1.  **OpenAPI (Swagger):** Document your Gateway endpoints.
2.  **Docker Logs:** Ensure you know how to monitor your containers using `docker logs`.
3.  **Audit Prep:** Use the `audit.md` sheet to self-test every requirement.

### 🍏 Advice for Desktop Environments
With Docker Desktop or OrbStack, Docker seamlessly handles networking and volume mounting.
1.  **Docker Desktop:** Ensure you are using a modern version. 
2.  **Architecture (ARM64 vs AMD64):** Because Docker handles cross-compilation and Alpine/Debian base images support multiple architectures out of the box, `docker-compose up --build` works optimally regardless of your Mac's chip architecture constraint (M1/M2/M3 vs Intel).
