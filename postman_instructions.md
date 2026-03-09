# Postman Testing Guide (Phase 1)

This guide provides step-by-step instructions on how to test the locally running API Gateway, Inventory API, and Billing Worker using Postman.

## Prerequisites

Before testing with Postman, ensure all services are running locally:
1.  **PostgreSQL & RabbitMQ**: Running via Homebrew (`brew services start postgresql@14` & `brew services start rabbitmq`).
2.  **Inventory API**: Running on port `5001`.
3.  **Billing Worker**: Running in the background.
4.  **API Gateway**: Running on port `5000`.

*Note: All Postman requests should be sent to the **API Gateway (Port 5000)**, which acts as the router.*

---

## 1. Test: Add a Movie (POST Request)

This test verifies that the Gateway successfully forwards an HTTP POST request to the Inventory API, and saves it to the database.

*   **Method**: `POST`
*   **Target URL**: `http://localhost:5000/api/movies`
*   **Body Type**: Select `raw` and choose `JSON` from the dropdown.
*   **Request Body**:
    ```json
    {
      "title": "Inception",
      "description": "A thief who steals corporate secrets through the use of dream-sharing technology."
    }
    ```
*   **Expected Response**: `201 Created` with the JSON object of the newly created movie (including its database `id`).

---

## 2. Test: Get All Movies (GET Request)

This test verifies that the Gateway successfully fetches the list of movies from the Inventory API.

*   **Method**: `GET`
*   **Target URL**: `http://localhost:5000/api/movies`
*   **Expected Response**: `200 OK` with a JSON array containing all movies you have added. Example:
    ```json
    [
      {
        "id": 1,
        "title": "Inception",
        "description": "A thief who steals corporate secrets through the use of dream-sharing technology."
      }
    ]
    ```

---

## 3. Test: Place an Order (POST Request into Message Queue)

This test verifies that the Gateway successfully takes an order and publishes it as a message to RabbitMQ, which the Billing Worker then picks up and processes.

*   **Method**: `POST`
*   **Target URL**: `http://localhost:5000/api/orders`
*   **Body Type**: Select `raw` and choose `JSON` from the dropdown.
*   **Request Body**:
    ```json
    {
      "user_id": 99,
      "number_of_items": 3,
      "total_amount": 45.50
    }
    ```
*   **Expected Response**: `202 Accepted` with the message:
    ```json
    {
      "message": "Order successfully submitted to billing queue"
    }
    ```

**To Verify Complete Success:** Check your terminal running the `billing/worker.py` script. You should immediately see a log confirming the order was received and saved for user `99`. 

---

## 4. Test: Get a Single Movie (GET Request)

*   **Method**: `GET`
*   **Target URL**: `http://localhost:5000/api/movies/1` *(Replace '1' with a valid movie ID)*
*   **Expected Response**: `200 OK` with the JSON details of that specific movie.

---

## 5. Test: Delete a Movie (DELETE Request)

*   **Method**: `DELETE`
*   **Target URL**: `http://localhost:5000/api/movies/1` *(Replace '1' with a valid movie ID)*
*   **Expected Response**: `200 OK` with the message:
    ```json
    {
      "message": "Movie deleted"
    }
    ```

---

## Inspecting the Infrastructure

To ensure that the API actions actually resulted in physical changes to the system, you can manually inspect your local PostgreSQL and RabbitMQ instances.

### 1. Inspecting PostgreSQL Data
You can use `psql` (the command-line interface for PostgreSQL) to directly query the tables.

**To check the Inventory Database (`movies_db`):**
1. Open a terminal.
2. Run: `psql -d movies_db`
3. Inside the `psql` prompt, run:
   ```sql
   SELECT * FROM movies;
   ```
4. Type `\q` to exit.

**To check the Billing Database (`billing_db`):**
1. Open a terminal.
2. Run: `psql -d billing_db`
3. Inside the `psql` prompt, run:
   ```sql
   SELECT * FROM orders;
   ```
4. Type `\q` to exit.

### 2. Inspecting RabbitMQ Queues

We can verify the `billing_queue` exists and see its current status via the rabbitmq tools or its built-in management interface.

**Option A: Using the CLI**
Because Homebrew installs these tools in its `sbin` (system binaries) folder, they might not be in your default terminal PATH. You must run them by giving the full path:
```bash
/opt/homebrew/sbin/rabbitmqctl list_queues
```
*(You should see `billing_queue` in the list, though the message count should be `0` if the worker script already consumed your test order).*

**Option B: Enabling the Web Dashboard**
RabbitMQ has an excellent visual UI that makes tracking queues easy.
1. Enable the management plugin by running:
   ```bash
   /opt/homebrew/sbin/rabbitmq-plugins enable rabbitmq_management
   ```
2. Open your web browser and navigate to: `http://localhost:15672`
3. Log in with the default credentials:
   * **Username:** `guest`
   * **Password:** `guest`
4. Click the **"Queues"** tab at the top to see the `billing_queue` and monitor its traffic in real time!
