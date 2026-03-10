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

## 🛠 Vagrant Management

### Starting the VMs

```bash
vagrant up
```

This command will:
1. Create and boot all 3 VMs (if not already created)
2. Run all provisioners automatically to install dependencies
3. Configure databases and message queues
4. Start all services via PM2

### Stopping the VMs

To gracefully shut down all VMs and free up system resources:

```bash
vagrant halt
```

To stop a specific VM:

```bash
vagrant halt <vm-name>    # e.g., vagrant halt billing-vm
```

### Other Useful Commands

- **Access a VM**: `vagrant ssh <vm-name>` (e.g., `vagrant ssh billing-vm`)
- **Check VM Status**: `vagrant status`
- **Reload VM**: `vagrant reload <vm-name>` (restart VM, add `--provision` to re-provision)
- **Re-run provisioners**: `vagrant provision` or `vagrant provision <vm-name>` — useful after editing `.env`, application code, or provisioning scripts
- **Destroy VMs**: `vagrant destroy` (removes VMs completely, you'll need to run `vagrant up` again)

### Process Management (Inside VMs)

The services are managed by **PM2** inside the VMs. After SSH-ing into a VM:

```bash
pm2 list              # List all running services
pm2 logs <service>    # View logs for a specific service
pm2 stop <service>    # Stop a service
pm2 start <service>   # Start a service
pm2 restart <service> # Restart a service
```

Service names:
- `gateway-service` (on gateway-vm)
- `inventory-service` (on inventory-vm)
- `billing-service` (on billing-vm)

## 📖 API Documentation

### OpenAPI/Swagger Specification

The API Gateway is fully documented using the **OpenAPI 3.0** specification. The documentation file is located at:

**📄 [`openapi.yaml`](openapi.yaml)**

This documentation provides:
- Complete endpoint descriptions for all Gateway routes
- Request/response schemas with examples
- HTTP methods and status codes
- Authentication requirements (if any)
- Error response formats

### Viewing the Documentation

You can view the OpenAPI documentation using any of these tools:

1. **Swagger Editor** (Online):
   - Visit [https://editor.swagger.io/](https://editor.swagger.io/)
   - Copy and paste the contents of `openapi.yaml`
   - View interactive documentation with "Try it out" feature

2. **VS Code Extension**:
   - Install the "OpenAPI (Swagger) Editor" extension
   - Open `openapi.yaml` in VS Code
   - Preview the documentation

### API Endpoints Summary

#### Movies (Inventory)
- `GET /api/movies` - Retrieve all movies (with optional title filter)
- `POST /api/movies` - Create a new movie
- `DELETE /api/movies` - Delete all movies
- `GET /api/movies/{id}` - Get a specific movie
- `PUT /api/movies/{id}` - Update a specific movie
- `DELETE /api/movies/{id}` - Delete a specific movie

#### Billing (Orders)
- `POST /api/billing` - Submit an order to the billing queue

**Gateway URL**: `http://192.168.56.10:5000` (or `http://localhost:8080` if port-forwarded)

## 🧪 Testing

For detailed instructions on testing the endpoints with Postman, inspecting PostgreSQL databases, and monitoring RabbitMQ, refer to the [Testing & Inspection Guide](testing_guide.md).

## 📖 Infrastructure Deep-Dive

For a detailed explanation of how the `Vagrantfile` and provisioning scripts work — including what Vagrant, PM2, and RabbitMQ do and why — see the [Infrastructure Explainer](infrastructure_explainer.md).

## 📐 Design Choices

- **Asynchronous Billing**: We use RabbitMQ for billing to ensure the Gateway remains responsive even if the Billing service is under heavy load or temporarily down (resilience).
- **Network Isolation**: Each service has a static IP on a private network (`192.168.56.0/24`) to enforce clear boundaries.
- **Automated Provisioning**: Shell scripts in the `scripts/` directory handle the "Heavy Lifting" of installing system dependencies, ensuring the environment is identical across different host machines.
- **Process Resilience**: PM2 is utilized to keep the Python applications running and handle automatic restarts on failure.
