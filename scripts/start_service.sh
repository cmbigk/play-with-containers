#!/bin/bash

APP_DIR=$1
SERVICE_NAME=$2
START_FILE=$3

echo ">>> Setting up $SERVICE_NAME in $APP_DIR..."

# Ensure we are in the app directory
cd $APP_DIR

# 1. Clean up broken or host-synced venvs
if [ -d "venv" ]; then
    echo "Found existing venv, checking if it's valid..."
    # If the interpreter inside venv is invalid, purge it
    if ! ./venv/bin/python --version > /dev/null 2>&1; then
        echo "Venv is broken (likely synced from host), recreating..."
        rm -rf venv
    fi
fi

# 2. Create venv as vagrant user if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating new virtual environment..."
    python3 -m venv venv
    chown -R vagrant:vagrant venv
fi

# 3. Install requirements
echo "Installing dependencies..."
sudo -u vagrant ./venv/bin/pip install -r requirements.txt

# 4. Start or Restart with PM2 as vagrant user
echo "Starting/Restarting $SERVICE_NAME with PM2..."
if sudo -u vagrant pm2 list | grep -q "$SERVICE_NAME"; then
    echo "$SERVICE_NAME already exists in PM2, restarting..."
    sudo -u vagrant pm2 restart "$SERVICE_NAME"
else
    echo "Starting new PM2 process for $SERVICE_NAME..."
    sudo -u vagrant pm2 start "$START_FILE" --name "$SERVICE_NAME" --interpreter ./venv/bin/python --restart-delay 3000
fi

# 5. Save PM2 state for vagrant user
sudo -u vagrant pm2 save

echo ">>> $SERVICE_NAME deployment finished."
