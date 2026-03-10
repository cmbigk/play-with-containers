# Infrastructure Explainer: Vagrantfile & Provisioning Scripts

This document explains how the project's infrastructure is defined and automated, for anyone unfamiliar with Vagrant, PM2, or RabbitMQ.

---

## What Is Vagrant?

Vagrant is a command-line tool for creating and managing virtual machines (VMs) in a reproducible, automated way. Instead of manually installing an OS and configuring software by hand, you write a **`Vagrantfile`** — a configuration file written in Ruby — and Vagrant does the rest.

The key benefit: anyone on the team runs `vagrant up` and gets an *identical* environment, regardless of their host OS.

---

## The Three VMs

The `Vagrantfile` defines three VMs, each on a private network with a fixed IP address:

| VM Name | IP | Role |
|---|---|---|
| `gateway-vm` | `192.168.56.10` | API Gateway — the only public entry point |
| `inventory-vm` | `192.168.56.11` | Inventory service + Movies database |
| `billing-vm` | `192.168.56.12` | Billing worker + Orders database + RabbitMQ |

All three VMs run Ubuntu 24.04 (ARM64) and share the same base box.

---

## How `vagrant up` Works (Step by Step)

When you run `vagrant up` for the first time, Vagrant works through a sequence of **provisioners** for each VM. A provisioner is just a shell script (or inline command) that Vagrant runs inside the VM after it boots. They run in the order they are declared in the `Vagrantfile`.

Here is the sequence for each VM:

### 1. `provision_common.sh` — System Dependencies (`run: once`)

Runs `apt-get update` and installs Python 3, pip, venv, git, and curl. This is the baseline that all three services need.

### 2. `provision_db.sh` — PostgreSQL (`run: once`, Inventory & Billing VMs only)

- Installs PostgreSQL
- Creates the database (`movies_db` or `orders_db`) and a database user
- Applies connection permissions so the Flask app can authenticate

### 3. `provision_mq.sh` — RabbitMQ (`run: once`, Billing VM only)

- Installs RabbitMQ (the message broker)
- Enables the web management plugin
- Creates the configured user and grants them full permissions
- Enables remote access (needed for the Gateway to publish messages to it)

### 4. `provision_pm2.sh` — Node.js & PM2 (`run: once`)

- Installs Node.js (required to install PM2, which is a Node.js tool)
- Installs PM2 globally
- Runs `pm2 startup systemd` — **this is the critical step** that registers PM2 as a systemd service, so it automatically relaunches after every VM reboot

### 5. Environment Variables — `set_env` helper (`run: always`)

Before the services start, the environment variables from the host's `.env` file are written into `/etc/profile.d/app_env.sh` inside the VM. This makes credentials (DB passwords, RabbitMQ host, etc.) available to the application processes.

This runs on **every boot**, so any `.env` change is picked up when you re-provision.

### 6. `start_service.sh` — Deploy the App via PM2 (`run: always`)

This is the main deployment script. It:
1. Checks if a Python virtual environment (`venv`) already exists and is valid
2. Creates a fresh `venv` if needed
3. Installs Python dependencies from `requirements.txt`
4. Tells PM2 to (re)start the Flask app or worker, using the venv's Python interpreter
5. Runs `pm2 save` — persists the list of running processes so PM2 can restore them on the next boot

This provisioner runs on **every boot** so services always come back up after a `vagrant halt` / `vagrant up`.

---

## What `run: "once"` vs `run: "always"` Means

| Setting | When does it run? |
|---|---|
| `run: "once"` | Only on the very first `vagrant up`. Skipped on subsequent boots or `vagrant reload`. |
| `run: "always"` | Every time the VM boots, and also when `vagrant provision` is called manually. |

Installation steps (Postgres, RabbitMQ, PM2) use `run: "once"` because those only need to happen once. Starting the services uses `run: "always"` so a `vagrant halt` + `vagrant up` cycle always restores the running state.

---

## What Is PM2?

PM2 is a **process manager** for applications. In this project we use it to run Python Flask apps and workers, even though PM2 was originally designed for Node.js — it supports any interpreter.

Key properties relevant here:

- **Auto-restart on crash**: If a service crashes (exception, OOM), PM2 restarts it automatically after a short delay.
- **`pm2 save` + `pm2 startup`**: Together, these two commands make PM2's process list survive a reboot. `pm2 startup` installs a systemd unit that starts PM2itself on boot; `pm2 save` writes the list of apps PM2 should launch back to disk.
- **`pm2 logs`**: All stdout/stderr from the services is captured and viewable with `pm2 logs <service-name>`.

---

## What Is RabbitMQ?

RabbitMQ is a **message broker** — an intermediary that decouples services that need to communicate asynchronously.

In this project:
- The **Gateway** publishes an order message to a RabbitMQ queue when `POST /api/billing` is called. It does not wait for the order to be processed; it gets an immediate success response.
- The **Billing worker** (`worker.py`) is a long-running process that continuously listens on that queue. When a message arrives, it processes the order and writes it to the `orders_db` database.

This pattern means the Gateway stays responsive even if the Billing service is slow or temporarily down — orders queue up and are processed when the worker comes back.

The RabbitMQ web dashboard is accessible at `http://192.168.56.12:15672` while the VMs are running.

---

## What Is Pika?

Pika is the specialized **Python library** used by both the Gateway and the Billing worker to talk to RabbitMQ. While RabbitMQ is the "post office," Pika is the "delivery truck" that knows the specific protocol (AMQP) required to send and receive messages accurately.

- **In the Gateway**: Pika is used to **publish** order data to the `billing_queue`.
- **In the Billing Worker**: Pika is used to **subscribe** to the queue and "listen" for incoming messages in real-time.

---

## Environment Variables and the `.env` File

Secrets and configuration (database credentials, service IPs) are never hardcoded. They live in a `.env` file on the host machine (not committed to git). The `Vagrantfile` reads this file at startup and the `set_env` helper injects each variable into the VM's global environment during provisioning.

The `set_env` helper writes to `/etc/profile.d/app_env.sh`, which is automatically loaded for interactive shells and is explicitly sourced by `start_service.sh` before it launches the application. This ensures that the Python programs can access credentials via `os.environ`.

---

## Synced Folders

Each VM mounts two directories from the host using rsync:

- `./gateway` (or `./inventory`, `./billing`) → `/home/vagrant/<service>/` — the application code
- `.` (the whole project root) → `/home/vagrant/project/` — gives access to the shared `scripts/` directory

`rsync` mode means files are copied in at `vagrant up` time. If you change application code, re-run `vagrant provision <vm-name>` to sync the changes and restart the service.
