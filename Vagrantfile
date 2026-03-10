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
  # Using an ARM64 box for Apple Silicon M3 (Ubuntu 24.04 Noble)
  config.vm.box = "hashicorp-education/ubuntu-24-04"

  # Helper to set environment variables in guest OS
  def set_env(vm, keys_mapping)
    script = "echo \"# Auto-generated environmental variables\" > /etc/profile.d/app_env.sh\n"
    keys_mapping.each do |guest_key, host_key|
      value = ENV[host_key] || host_key
      script += "echo \"export #{guest_key}=#{value}\" >> /etc/profile.d/app_env.sh\n"
      # Also add to /etc/environment for global access (sudo, etc)
      script += "grep -q \"^#{guest_key}=\" /etc/environment && sed -i \"s|^#{guest_key}=.*|#{guest_key}=#{value}|\" /etc/environment || echo \"#{guest_key}=#{value}\" >> /etc/environment\n"
    end
    script += "chmod +x /etc/profile.d/app_env.sh\n"
    vm.vm.provision "shell", inline: script, run: "always"
  end

  # -----------------------------------------------------------------
  # GATEWAY VM
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

    gw.vm.provision "common", type: "shell", path: "scripts/provision_common.sh", run: "once"
    gw.vm.provision "pm2", type: "shell", path: "scripts/provision_pm2.sh", run: "once"

    # Inject variables (must run before start_service so app_env.sh exists)
    set_env(gw, {
      "INVENTORY_URL" => "INVENTORY_URL",
      "RABBITMQ_HOST" => "RABBITMQ_HOST",
      "RABBITMQ_USER" => "RABBITMQ_USER",
      "RABBITMQ_PASS" => "RABBITMQ_PASS"
    })

    # Start Services (runs on every boot to ensure services are up)
    gw.vm.provision "shell", inline: "chmod +x /home/vagrant/project/scripts/*.sh", run: "always"
    gw.vm.provision "start-gateway", type: "shell", path: "scripts/start_service.sh", args: ["/home/vagrant/gateway", "gateway-service", "app.py"], run: "always"
  end

  # -----------------------------------------------------------------
  # INVENTORY VM
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

    inv.vm.provision "common", type: "shell", path: "scripts/provision_common.sh", run: "once"
    inv.vm.provision "db", type: "shell", path: "scripts/provision_db.sh", args: [ENV["DB_NAME_MOVIES"], ENV["DB_USER"], ENV["DB_PASS"]], run: "once"
    inv.vm.provision "pm2", type: "shell", path: "scripts/provision_pm2.sh", run: "once"

    # Inject variables (must run before start_service so app_env.sh exists)
    # DB_HOST defaults to localhost for Inventory app connecting to its own DB
    set_env(inv, {
      "DB_USER" => "DB_USER",
      "DB_PASS" => "DB_PASS",
      "DB_NAME" => "DB_NAME_MOVIES",
      "DB_HOST" => "localhost"
    })

    # Start Services (runs on every boot to ensure services are up)
    inv.vm.provision "shell", inline: "chmod +x /home/vagrant/project/scripts/*.sh", run: "always"
    inv.vm.provision "start-inventory", type: "shell", path: "scripts/start_service.sh", args: ["/home/vagrant/inventory", "inventory-service", "app.py"], run: "always"
  end

  # -----------------------------------------------------------------
  # BILLING VM
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

    bill.vm.provision "common", type: "shell", path: "scripts/provision_common.sh", run: "once"
    bill.vm.provision "db", type: "shell", path: "scripts/provision_db.sh", args: [ENV["DB_NAME_ORDERS"], ENV["DB_USER"], ENV["DB_PASS"]], run: "once"
    bill.vm.provision "mq", type: "shell", path: "scripts/provision_mq.sh", args: [ENV["RABBITMQ_USER"], ENV["RABBITMQ_PASS"]], run: "once"
    bill.vm.provision "pm2", type: "shell", path: "scripts/provision_pm2.sh", run: "once"

    # Inject variables (must run before start_service so app_env.sh exists)
    # DB_HOST defaults to localhost for Billing app connecting to its own DB
    set_env(bill, {
      "DB_USER" => "DB_USER",
      "DB_PASS" => "DB_PASS",
      "DB_NAME" => "DB_NAME_ORDERS",
      "DB_HOST" => "localhost",
      "RABBITMQ_HOST" => "localhost"
    })

    # Start Services (runs on every boot to ensure services are up)
    bill.vm.provision "shell", inline: "chmod +x /home/vagrant/project/scripts/*.sh", run: "always"
    bill.vm.provision "start-billing", type: "shell", path: "scripts/start_service.sh", args: ["/home/vagrant/billing", "billing-service", "worker.py"], run: "always"
  end
end
