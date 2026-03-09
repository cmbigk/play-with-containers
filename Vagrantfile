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
    script = ""
    keys_mapping.each do |guest_key, host_key|
      value = ENV[host_key] || host_key # Fallback to literal if not in ENV
      script += "echo 'export #{guest_key}=#{value}' >> /home/vagrant/.bashrc\n"
      script += "echo '#{guest_key}=#{value}' >> /etc/environment\n"
    end
    vm.vm.provision "shell", inline: script
  end

  # -----------------------------------------------------------------
  # GATEWAY VM
  # -----------------------------------------------------------------
  config.vm.define "gateway-vm" do |gw|
    gw.vm.network "private_network", ip: "192.168.56.10"
    gw.vm.hostname = "gateway"
    gw.vm.synced_folder "./gateway", "/home/vagrant/gateway"
    gw.vm.synced_folder ".", "/home/vagrant/project", type: "rsync", rsync__exclude: [".git/", "venv/"]

    gw.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
    end

    gw.vm.provision "common", type: "shell", path: "scripts/provision_common.sh"
    gw.vm.provision "pm2", type: "shell", path: "scripts/provision_pm2.sh"
    
    # Inject variables
    set_env(gw, {
      "INVENTORY_URL" => "INVENTORY_URL",
      "RABBITMQ_HOST" => "RABBITMQ_HOST",
      "RABBITMQ_USER" => "RABBITMQ_USER",
      "RABBITMQ_PASS" => "RABBITMQ_PASS"
    })
  end

  # -----------------------------------------------------------------
  # INVENTORY VM
  # -----------------------------------------------------------------
  config.vm.define "inventory-vm" do |inv|
    inv.vm.network "private_network", ip: "192.168.56.11"
    inv.vm.hostname = "inventory"
    inv.vm.synced_folder "./inventory", "/home/vagrant/inventory"
    inv.vm.synced_folder ".", "/home/vagrant/project", type: "rsync", rsync__exclude: [".git/", "venv/"]

    inv.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
    end

    inv.vm.provision "common", type: "shell", path: "scripts/provision_common.sh"
    inv.vm.provision "db", type: "shell", path: "scripts/provision_db.sh", args: [ENV["DB_NAME_MOVIES"], ENV["DB_USER"], ENV["DB_PASS"]]
    inv.vm.provision "pm2", type: "shell", path: "scripts/provision_pm2.sh"
    
    # Inject variables (DB_HOST defaults to localhost for Inventory app connecting to its own DB)
    set_env(inv, {
      "DB_USER" => "DB_USER",
      "DB_PASS" => "DB_PASS",
      "DB_NAME" => "DB_NAME_MOVIES",
      "DB_HOST" => "localhost"
    })
  end

  # -----------------------------------------------------------------
  # BILLING VM
  # -----------------------------------------------------------------
  config.vm.define "billing-vm" do |bill|
    bill.vm.network "private_network", ip: "192.168.56.12"
    bill.vm.hostname = "billing"
    bill.vm.synced_folder "./billing", "/home/vagrant/billing"
    bill.vm.synced_folder ".", "/home/vagrant/project", type: "rsync", rsync__exclude: [".git/", "venv/"]

    bill.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
    end

    bill.vm.provision "common", type: "shell", path: "scripts/provision_common.sh"
    bill.vm.provision "db", type: "shell", path: "scripts/provision_db.sh", args: [ENV["DB_NAME_ORDERS"], ENV["DB_USER"], ENV["DB_PASS"]]
    bill.vm.provision "mq", type: "shell", path: "scripts/provision_mq.sh"
    bill.vm.provision "pm2", type: "shell", path: "scripts/provision_pm2.sh"
    
    # Inject variables (DB_HOST defaults to localhost for Billing app connecting to its own DB)
    set_env(bill, {
      "DB_USER" => "DB_USER",
      "DB_PASS" => "DB_PASS",
      "DB_NAME" => "DB_NAME_ORDERS",
      "DB_HOST" => "localhost",
      "RABBITMQ_HOST" => "localhost"
    })
  end
end
