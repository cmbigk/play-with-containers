# crud-master

VMs and micro services with Vagrant, RabbitMQ, PM2 and Flask

This project consists of three main Python microservices:
1. **Gateway**: Acts as the API gateway for routing client requests.
2. **Inventory**: Manages movie data.
3. **Billing**: Processes orders by consuming messages from RabbitMQ and writing to PostgreSQL.

## Prerequisites

Ensure you have the following installed on your system before proceeding:
- **Python 3.8+**
- **RabbitMQ**: Used as the message broker between the Gateway and Billing service.
- **PostgreSQL**: Used by the Billing service as its backend database. Ensure a database named `orders_db` is created.

## Infrastructure Setup (macOS)

It is assumed you have [Homebrew](https://brew.sh/) installed.

### 1. Install & Start PostgreSQL
```bash
brew install postgresql@14
brew services start postgresql@14
```

### 2. Create Required Databases
Once PostgreSQL is running, create the databases needed for the microservices:
```bash
psql -d postgres -c "CREATE DATABASE movies_db;"
psql -d postgres -c "CREATE DATABASE orders_db;"
```

### 3. Install & Start RabbitMQ
```bash
brew install rabbitmq
# Add RabbitMQ to your PATH (if brew doesn't do it automatically)
export PATH=$PATH:/usr/local/sbin
# Start the RabbitMQ service
brew services start rabbitmq
```

## Installation

You will need to install the dependencies for each microservice separately. It is recommended to use virtual environments.

### 1. Gateway Setup
```bash
cd gateway
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 2. Inventory Setup
```bash
cd inventory
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 3. Billing Setup
```bash
cd billing
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Running the Services

To run the full stack, you need to start each service in its own terminal window (or manage them via a process manager like **PM2**). 
*Note: Make sure RabbitMQ and PostgreSQL are running before starting the services.*

### Start Gateway
```bash
cd gateway
source venv/bin/activate
FLASK_APP=app.py flask run --port=5000
# Alternatively: python app.py
```

### Start Inventory
```bash
cd inventory
source venv/bin/activate
FLASK_APP=app.py flask run --port=5001
# Alternatively: python app.py
```

### Start Billing Worker
```bash
cd billing
source venv/bin/activate
python worker.py
```

## Testing

For instructions on how to test the APIs and the message queue using Postman, please refer to the [Postman Test Guide](postman_instructions.md).
