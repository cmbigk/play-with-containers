#!/bin/bash

echo ">>> Installing RabbitMQ..."
export DEBIAN_FRONTEND=noninteractive
apt-get install -y rabbitmq-server

echo ">>> Starting RabbitMQ..."
systemctl enable rabbitmq-server
systemctl start rabbitmq-server

echo ">>> Configuring RabbitMQ users..."
# Enable management plugin
rabbitmq-plugins enable rabbitmq_management

# Restart to apply plugin
systemctl restart rabbitmq-server

echo ">>> RabbitMQ installed and management UI enabled on port 15672."
