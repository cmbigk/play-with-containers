# -*- mode: ruby -*-
# vi: set ft=ruby :

# Load .env variables
if File.exist?(".env")
  File.foreach(".env") do |line|
    next if line.start_with?("#") || line.strip.empty?
    key, value = line.strip.split("=")
    ENV[key] = value if key && value
  end
end

Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp-education/ubuntu-24-04"

  # -----------------------------------------------------------------
  # GATEWAY VM — API gateway that routes requests to other services
  # -----------------------------------------------------------------
  config.vm.define "gateway-vm" do |gw|
    gw.vm.network "private_network", ip: "192.168.56.10"
    gw.vm.hostname = "gateway"
    gw.vm.synced_folder "./gateway", "/home/vagrant/gateway", type: "rsync", rsync__exclude: [".git/", "venv/"]
    gw.vm.synced_folder ".", "/home/vagrant/project", type: "rsync", rsync__exclude: [".git/", "venv/", ".vagrant/"]

    gw.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
    end

    # One-time provisioning: install Python, Node/PM2
    gw.vm.provision "common", type: "shell", path: "scripts/provision_common.sh", run: "once"
    gw.vm.provision "pm2", type: "shell", path: "scripts/provision_pm2.sh", run: "once"

    # Set environment variables (runs on every boot so they stay current)
    gw.vm.provision "env", type: "shell", run: "always", inline: <<-SHELL
      cat > /etc/profile.d/app_env.sh <<'EOF'
export INVENTORY_URL=#{ENV["INVENTORY_URL"]}
export RABBITMQ_HOST=#{ENV["RABBITMQ_HOST"]}
export RABBITMQ_USER=#{ENV["RABBITMQ_USER"]}
export RABBITMQ_PASS=#{ENV["RABBITMQ_PASS"]}
EOF
      chmod +x /etc/profile.d/app_env.sh
    SHELL

    # Start the gateway service (runs on every boot)
    gw.vm.provision "start-gateway", type: "shell", path: "scripts/start_service.sh",
      args: ["/home/vagrant/gateway", "gateway-service", "app.py"], run: "always"
  end

  # -----------------------------------------------------------------
  # INVENTORY VM — CRUD service for movies, backed by PostgreSQL
  # -----------------------------------------------------------------
  config.vm.define "inventory-vm" do |inv|
    inv.vm.network "private_network", ip: "192.168.56.11"
    inv.vm.hostname = "inventory"
    inv.vm.synced_folder "./inventory", "/home/vagrant/inventory", type: "rsync", rsync__exclude: [".git/", "venv/"]
    inv.vm.synced_folder ".", "/home/vagrant/project", type: "rsync", rsync__exclude: [".git/", "venv/", ".vagrant/"]

    inv.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
    end

    # One-time provisioning: install Python, PostgreSQL, Node/PM2
    inv.vm.provision "common", type: "shell", path: "scripts/provision_common.sh", run: "once"
    inv.vm.provision "db", type: "shell", path: "scripts/provision_db.sh",
      args: [ENV["DB_NAME_MOVIES"], ENV["DB_USER"], ENV["DB_PASS"]], run: "once"
    inv.vm.provision "pm2", type: "shell", path: "scripts/provision_pm2.sh", run: "once"

    # Set environment variables (runs on every boot)
    inv.vm.provision "env", type: "shell", run: "always", inline: <<-SHELL
      cat > /etc/profile.d/app_env.sh <<'EOF'
export DB_USER=#{ENV["DB_USER"]}
export DB_PASS=#{ENV["DB_PASS"]}
export DB_NAME=#{ENV["DB_NAME_MOVIES"]}
export DB_HOST=localhost
EOF
      chmod +x /etc/profile.d/app_env.sh
    SHELL

    # Start the inventory service (runs on every boot)
    inv.vm.provision "start-inventory", type: "shell", path: "scripts/start_service.sh",
      args: ["/home/vagrant/inventory", "inventory-service", "app.py"], run: "always"
  end

  # -----------------------------------------------------------------
  # BILLING VM — Order processing via RabbitMQ, backed by PostgreSQL
  # -----------------------------------------------------------------
  config.vm.define "billing-vm" do |bill|
    bill.vm.network "private_network", ip: "192.168.56.12"
    bill.vm.hostname = "billing"
    bill.vm.synced_folder "./billing", "/home/vagrant/billing", type: "rsync", rsync__exclude: [".git/", "venv/"]
    bill.vm.synced_folder ".", "/home/vagrant/project", type: "rsync", rsync__exclude: [".git/", "venv/", ".vagrant/"]

    bill.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
    end

    # One-time provisioning: install Python, PostgreSQL, RabbitMQ, Node/PM2
    bill.vm.provision "common", type: "shell", path: "scripts/provision_common.sh", run: "once"
    bill.vm.provision "db", type: "shell", path: "scripts/provision_db.sh",
      args: [ENV["DB_NAME_ORDERS"], ENV["DB_USER"], ENV["DB_PASS"]], run: "once"
    bill.vm.provision "mq", type: "shell", path: "scripts/provision_mq.sh",
      args: [ENV["RABBITMQ_USER"], ENV["RABBITMQ_PASS"]], run: "once"
    bill.vm.provision "pm2", type: "shell", path: "scripts/provision_pm2.sh", run: "once"

    # Set environment variables (runs on every boot)
    bill.vm.provision "env", type: "shell", run: "always", inline: <<-SHELL
      cat > /etc/profile.d/app_env.sh <<'EOF'
export DB_USER=#{ENV["DB_USER"]}
export DB_PASS=#{ENV["DB_PASS"]}
export DB_NAME=#{ENV["DB_NAME_ORDERS"]}
export DB_HOST=localhost
export RABBITMQ_HOST=localhost
EOF
      chmod +x /etc/profile.d/app_env.sh
    SHELL

    # Start the billing worker (runs on every boot)
    bill.vm.provision "start-billing", type: "shell", path: "scripts/start_service.sh",
      args: ["/home/vagrant/billing", "billing-service", "worker.py"], run: "always"
  end
end
