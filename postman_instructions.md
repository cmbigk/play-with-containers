# Postman Testing Guide (Multi-VM Setup)

This guide provides step-by-step instructions on how to test the microservices running inside the Vagrant virtual machines.

## Prerequisites

Before testing with Postman, ensure the VMs are up and services are started:
1.  **Vagrant VMs**: Run `vagrant status` to confirm `gateway-vm`, `inventory-vm`, and `billing-vm` are all `running`.
2.  **Services**: Services are automatically started by PM2 during provisioning. To manually check status, run:
    ```bash
    vagrant ssh <vm-name> -c "sudo -u vagrant pm2 status"
    ```

*Note: All Postman requests should be sent to the **API Gateway VM** IP: `192.168.56.10:5000`.*

---

## 1. Test: Add a Movie (POST Request)

This test verifies that the Gateway successfully forwards an HTTP POST request to the Inventory API VM.

*   **Method**: `POST`
*   **Target URL**: `http://192.168.56.10:5000/api/movies`
*   **Body Type**: Select `raw` and choose `JSON` from the dropdown.
*   **Request Body**:
    ```json
    {
      "title": "Inception",
      "description": "A thief who steals corporate secrets through the use of dream-sharing technology."
    }
    ```
*   **Expected Response**: `201 Created` with the movie JSON including its database `id`.

---

## 2. Test: Get All Movies (GET Request)

*   **Method**: `GET`
*   **Target URL**: `http://192.168.56.10:5000/api/movies`
*   **Expected Response**: `200 OK` with a JSON array containing all movies.

---

## 3. Test: Place an Order (POST Request into Message Queue)

This test verifies that the Gateway publishes a message to RabbitMQ on the `billing-vm`.

*   **Method**: `POST`
*   **Target URL**: `http://192.168.56.10:5000/api/billing`
*   **Body Type**: Select `raw` and choose `JSON` from the dropdown.
*   **Request Body**:
    ```json
    {
      "user_id": 99,
      "number_of_items": 3,
      "total_amount": 45.50
    }
    ```
*   **Expected Response**: `200 OK` with:
    ```json
    {
      "message": "Order successfully submitted to billing queue"
    }
    ```

**Verification**: Run `vagrant ssh billing-vm -c "sudo -u vagrant pm2 logs billing-service"` to see the received order.

---

## 4. Test: Update a Movie (PUT Request)

*   **Method**: `PUT`
*   **Target URL**: `http://192.168.56.10:5000/api/movies/1`
*   **Request Body**:
    ```json
    {
      "title": "Inception (Updated)",
      "description": "Updated description."
    }
    ```
*   **Expected Response**: `200 OK` with the updated movie JSON.

---

## 5. Test: Delete All Movies (DELETE Request)

*   **Method**: `DELETE`
*   **Target URL**: `http://192.168.56.10:5000/api/movies`
*   **Expected Response**: `200 OK` with `{"message": "All movies deleted"}`.

---

## Inspecting the Infrastructure (Inside VMs)

Since the databases and message broker are inside VMs, you must connect to them via `vagrant ssh`.

### 1. Inspecting PostgreSQL Data
The password for the `postgres` user in both VMs is specified in your `.env` file (Default: `password`).

**To check Movies (`inventory-vm`):**
1. Run: `vagrant ssh inventory-vm`
2. Run: `psql -U postgres -d movies_db` (Enter password when prompted)
3. SQL: `SELECT * FROM movies;`

**To check Orders (`billing-vm`):**
1. Run: `vagrant ssh billing-vm`
2. Run: `psql -U postgres -d orders_db` (Enter password when prompted)
3. SQL: `SELECT * FROM orders;`

### 2. Inspecting RabbitMQ
The RabbitMQ management UI is enabled on the `billing-vm`.

1. **Web Dashboard**: Access it at `http://192.168.56.12:15672`
2. **Credentials**: Use the `RABBITMQ_USER` and `RABBITMQ_PASS` from your `.env` (Default: `user` / `password`).
3. **CLI Check**: `vagrant ssh billing-vm -c "sudo rabbitmqctl list_queues"`
