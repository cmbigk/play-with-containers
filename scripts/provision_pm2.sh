#!/bin/bash

echo ">>> Installing Node.js and PM2..."
export DEBIAN_FRONTEND=noninteractive
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

npm install -g pm2

echo ">>> Registering PM2 as a systemd startup service for vagrant user..."
# Generate the startup script and execute it so PM2 is launched on every boot
sudo -u vagrant bash -c "pm2 startup systemd -u vagrant --hp /home/vagrant" | tail -1 | bash

echo ">>> PM2 installed and registered with systemd."
