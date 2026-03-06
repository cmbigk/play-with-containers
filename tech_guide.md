# CRUD Master: Technical Guide & Development Plan

Welcome to the **CRUD Master** project! This document explains the core technologies we'll be using, why we're using them, and how we'll build the system step-by-step.

## 🚀 The Technology Stack

If you've used Python, PostgreSQL, and Postman before, you're halfway there. Here’s a breakdown of the new tools:

### 1. Vagrant (The Environment Manager)
*   **What is it?** Vagrant is a tool for building and managing virtual machine (VM) environments.
*   **Why use it?** It ensures that the project runs exactly same way on your Mac as it does on anyone else's machine. It automates the "it works on my machine" problem.
*   **In this project:** We use a `Vagrantfile` to automatically create **three separate VMs** (Gateway, Inventory, and Billing). It handles the networking and software installation for each.

### 2. Microservices (The Architecture)
*   **What is it?** Instead of one giant application (a "monolith"), we break the project into small, independent services that talk to each other.
*   **Why Virtual Machines?** We use three different VMs to **simulate a real-world distributed system**. Each service lives on its own "server," forcing them to communicate over a network (using HTTP or RabbitMQ) rather than sharing internal memory.

### 3. Flask (The Web Framework)
*   **What is it?** A lightweight Python framework for building web APIs.
*   **In this project:** 
    *   **Inventory API:** Built with Flask to handle CRUD operations for movies.
    *   **API Gateway:** Built with Flask to receive all incoming requests and route them.
    *   **Billing API:** While it mainly listens to a queue, it is also a Python application (and often built with Flask for consistency and monitoring).

### 4. RabbitMQ (The Messenger)
*   **What is it?** A "Message Broker." Think of it like a post office or a digital "To-Do" list.
*   **In this project:** When someone pays (Billing), the Gateway doesn't wait for the Billing service to finish. It just drops a message into RabbitMQ's `billing_queue`. The Billing API picks it up whenever it's ready. This is called **asynchronous communication**.

### 5. PM2 (The Guardian)
*   **What is it?** A process manager. It makes sure your Python apps stay running.
*   **In this project:** We use it to start/stop the Billing service. It helps us test **resilience**: if the Billing service is stopped (using PM2), messages will safely wait in RabbitMQ until we start it again.

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

### Phase 2: Vagrant & Provisioning
Once the Python code works, automate the setup.
1.  **Write Scripts:** Create shell scripts to install Python, Postgres, RabbitMQ, and PM2.
2.  **Configure Vagrantfile:** Define the three VMs and tell Vagrant to run your scripts when they start (`vagrant up`).

### Phase 3: Monitoring & Documentation
1.  **OpenAPI (Swagger):** Document your Gateway endpoints.
2.  **PM2 Integration:** Ensure PM2 starts your apps automatically on the VMs.
3.  **Audit Prep:** Use the `audit.md` sheet to self-test every requirement.

### Advice for Mac (UTM Users)
Since you're using **UTM** instead of VirtualBox:
*   Vagrant has a plugin for VMware/UTM, but if you prefer manual setup, you can still use the scripts meant for Vagrant to configure your UTM VMs.
*   However, if you can get the `vagrant-vmware-desktop` or a generic QEMU provider working for Vagrant, it will save you a lot of time by automating the network configuration between the three VMs.
