# CRUD Master

A microservices-based movie streaming platform architecture using **Vagrant**, **RabbitMQ**, **PM2**, **Flask**, and **PostgreSQL**.

This project demonstrates a distributed system where services are isolated in independent virtual machines (VMs) to simulate a production environment, emphasizing resilience and automation.

---

## 🏗 Architecture & Design

The system is designed as a set of decoupled services, each running in its own VM to ensure strict boundary isolation.

### Component Overview
1.  **Gateway VM (`192.168.56.10`)**: The entry point. It handles request routing. Movie metadata requests are proxied via HTTP to the Inventory service, while billing orders are enqueued into RabbitMQ to be processed asynchronously.
2.  **Inventory VM (`192.168.56.11`)**: A CRUD service managing the movie catalog, backed by a PostgreSQL database (`movies_db`).
3.  **Billing VM (`192.168.56.12`)**: An asynchronous worker that consumes order messages from RabbitMQ and persists them to a PostgreSQL database (`orders_db`).

### Key Design Choices
-   **Asynchronous Processing**: Using RabbitMQ for billing ensures the Gateway remains highly responsive. Even if the Billing service is under heavy load or temporarily down, orders are safely queued and processed later (Resilience).
-   **Network Isolation**: Services communicate over a controlled private network (`192.168.56.0/24`). This simulates a real-world VPC environment and enforces clear data flow boundaries (Security).
-   **Automated Infrastructure**: The entire environment is defined as code. Vagrant handles VM orchestration, while shell scripts in `scripts/` automate the installation of Node.js, Python, PostgreSQL, and RabbitMQ (Portability).
-   **Process Management**: We use PM2 to manage the Python application life cycle, providing automatic restarts and centralized logging (System Reliability).

---

## 🚀 Getting Started

### 1. Prerequisites (macOS Apple Silicon)
- **VirtualBox 7.0+** (Developer Preview for Arm64)
- **Vagrant 2.3.4+** 
- **Environment**: A Terminal and basic knowledge of the command line.

### 2. Configuration
Create a `.env` file in the root directory to manage credentials and service locations. This file is injected into the VMs during provisioning.

**Required `.env` Variables:**
```env
DB_USER=********
DB_PASS=********
DB_NAME_MOVIES=movies_db
DB_NAME_ORDERS=orders_db
RABBITMQ_HOST=192.168.56.12
RABBITMQ_USER=********
RABBITMQ_PASS=********
INVENTORY_URL=http://192.168.56.11:5001
```

### 3. Spin up the Cluster
Simply run:
```bash
vagrant up
```
*This command creates 3 VMs, installs all system dependencies, configures databases, and starts the services automatically. It usually takes 4-6 minutes on the first run.*

---

## 🛠 Operation & Management

### Cluster Management
- **Check Status**: `vagrant status`
- **Graceful Shutdown**: `vagrant halt`
- **Access a VM**: `vagrant ssh <vm-name>` (e.g., `vagrant ssh gateway-vm`)
- **Apply Changes**: `vagrant provision` (useful after editing code or `.env`)
- **Destroy Cluster**: `vagrant destroy -f` (deletes VMs completely)

### Service Management (Via PM2)
Once inside a VM via `vagrant ssh`, use these commands to manage the application process:
```bash
pm2 list              # List all running services
pm2 logs <service>    # View real-time logs
pm2 restart <service> # Restart the service
```
*Service names are: `gateway-service`, `inventory-service`, and `billing-service`.*

---

## 📖 API & Documentation

### OpenAPI Specification
The API Gateway is documented using **OpenAPI 3.0**. You can find the full schema in [openapi.yaml](openapi.yaml). 
- To view interactively, paste the content into the [Swagger Editor](https://editor.swagger.io/).
- **Gateway Endpoint**: `http://192.168.56.10:5000`

### Endpoints Summary
- `GET /api/movies` — List all movies (optional `?title=` filter)
- `POST /api/movies` — Add a new movie
- `DELETE /api/movies` — Delete all movies
- `GET /api/movies/{id}` — Get movie details
- `PUT /api/movies/{id}` - Update a specific movie
- `DELETE /api/movies/{id}` - Delete a specific movie
- `POST /api/billing` — Submit an order to the queue

---

## 🧪 Testing & Deep-Dive

- **Testing Guide**: See [testing_guide.md](testing_guide.md) for Postman collections, database inspection queries, and RabbitMQ monitoring steps.
- **Infrastructure Explainer**: See [infrastructure_explainer.md](infrastructure_explainer.md) for a technical breakdown of how Vagrant, PM2, and the provisioning scripts work.

