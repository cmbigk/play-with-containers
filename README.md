# CRUD Master

A microservices-based movie streaming platform architecture using **Vagrant**, **RabbitMQ**, **PM2**, **Flask**, and **PostgreSQL**.

This project demonstrates a distributed system where services are isolated in independent virtual machines (VMs) to simulate a production environment.

## 🏗 Architecture Overview

The system is composed of three main microservices:

1.  **Gateway VM (`192.168.56.10`)**: The entry point. Routes movie requests via HTTP to Inventory and enqueues billing orders via RabbitMQ.
2.  **Inventory VM (`192.168.56.11`)**: Manages the movie catalog using a PostgreSQL database (`movies_db`).
3.  **Billing VM (`192.168.56.12`)**: Processes orders asynchronously from RabbitMQ and persists them to a PostgreSQL database (`orders_db`).

## 🍏 Prerequisites (macOS Apple Silicon)

- **VirtualBox 7.0+** (Developer Preview for Arm64)
- **Vagrant 2.3.4+**
- **Homebrew** (optional, for local tools)

## 🚀 Quick Start (Vagrant)

The entire environment is automated. Simply follow these steps to spin up the cluster:

1.  **Environment Configuration**: Create a `.env` file in the root directory (see [Configuration](#configuration) below).
2.  **Start the Cluster**:
    ```bash
    vagrant up
    ```
    *This will create 3 VMs, install all dependencies, and configure the databases/queues automatically.*

3.  **Verify Status**:
    ```bash
    vagrant status
    ```

## ⚙️ Configuration

The project uses a `.env` file to manage credentials and service locations. This file is injected into the VMs during provisioning.

**Required `.env` Variables:**
```env
DB_USER=postgres
DB_PASS=postgres
DB_NAME_MOVIES=movies_db
DB_NAME_ORDERS=orders_db
RABBITMQ_HOST=192.168.56.12
RABBITMQ_USER=guest
RABBITMQ_PASS=guest
INVENTORY_URL=http://192.168.56.11:5001
```

## 🛠 Manual Management

You can interact with individual VMs using Vagrant commands:

- **Access a VM**: `vagrant ssh <vm-name>` (e.g., `vagrant ssh billing-vm`)
- **Process Management**: The services are managed by **PM2** inside the VMs.
  - List services: `pm2 list`
  - Stop/Start: `pm2 stop all` / `pm2 start all`

## 🧪 Testing

For detailed instructions on testing the endpoints using Postman, refer to the [Postman Test Guide](postman_instructions.md).

## 📐 Design Choices

- **Asynchronous Billing**: We use RabbitMQ for billing to ensure the Gateway remains responsive even if the Billing service is under heavy load or temporarily down (resilience).
- **Network Isolation**: Each service has a static IP on a private network (`192.168.56.0/24`) to enforce clear boundaries.
- **Automated Provisioning**: Shell scripts in the `scripts/` directory handle the "Heavy Lifting" of installing system dependencies, ensuring the environment is identical across different host machines.
- **Process Resilience**: PM2 is utilized to keep the Python applications running and handle automatic restarts on failure.
