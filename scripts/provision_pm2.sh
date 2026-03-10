#!/bin/bash

echo ">>> Installing Node.js and PM2..."
export DEBIAN_FRONTEND=noninteractive
# Using Node.js 22 (LTS)
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# Update npm to latest to avoid "new version available" notices
npm install -g npm@latest
npm install -g pm2

echo ">>> Registering PM2 as a systemd startup service for vagrant user..."
# Generate the startup script and execute it so PM2 is launched on every boot
sudo -u vagrant bash -c "pm2 startup systemd -u vagrant --hp /home/vagrant" | tail -1 | bash

echo ">>> PM2 installed and registered with systemd."
