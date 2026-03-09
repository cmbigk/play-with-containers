#!/bin/bash

echo ">>> Installing Node.js and PM2..."
export DEBIAN_FRONTEND=noninteractive
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

npm install -g pm2

echo ">>> PM2 installed."
