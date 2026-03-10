#!/bin/bash

APP_DIR=$1
SERVICE_NAME=$2
START_FILE=$3

echo ">>> Setting up $SERVICE_NAME in $APP_DIR..."

# Ensure provisioning scripts are executable (rsync may reset permissions)
chmod +x /home/vagrant/project/scripts/*.sh

cd $APP_DIR

# 1. Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating new virtual environment..."
    python3 -m venv venv
    chown -R vagrant:vagrant venv
fi

# 2. Install Python dependencies
echo "Installing dependencies..."
sudo -u vagrant ./venv/bin/pip install -r requirements.txt

# 3. Start the app with PM2 (delete first to pick up fresh env vars)
echo "Deploying $SERVICE_NAME with PM2..."
sudo -u vagrant bash -c "source /etc/profile.d/app_env.sh && pm2 delete $SERVICE_NAME 2>/dev/null || true"
sudo -u vagrant bash -c "source /etc/profile.d/app_env.sh && pm2 start $START_FILE --name $SERVICE_NAME --interpreter ./venv/bin/python --restart-delay 3000"

# 4. Save PM2 state so it survives reboots
sudo -u vagrant bash -c "pm2 save"

echo ">>> $SERVICE_NAME deployment finished."
