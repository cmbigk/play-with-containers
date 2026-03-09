#!/bin/bash

echo ">>> Installing RabbitMQ..."
export DEBIAN_FRONTEND=noninteractive
apt-get install -y rabbitmq-server

echo ">>> Starting RabbitMQ..."
systemctl enable rabbitmq-server
systemctl start rabbitmq-server

echo ">>> Configuring RabbitMQ users and permissions..."
# Enable management plugin
rabbitmq-plugins enable rabbitmq_management

# Create/Update user from environment variables or defaults
RABBITMQ_USER=${1:-guest}
RABBITMQ_PASS=${2:-guest}

# If it's not guest, we create it. If it is guest, we just ensure permissions.
if [ "$RABBITMQ_USER" != "guest" ]; then
    rabbitmqctl add_user "$RABBITMQ_USER" "$RABBITMQ_PASS" 2>/dev/null || rabbitmqctl change_password "$RABBITMQ_USER" "$RABBITMQ_PASS"
    rabbitmqctl set_user_tags "$RABBITMQ_USER" administrator
fi

rabbitmqctl set_permissions -p / "$RABBITMQ_USER" ".*" ".*" ".*"

# Allow guest user (and others) to connect remotely (for testing/setup simplicity)
echo "loopback_users = none" > /etc/rabbitmq/rabbitmq.conf

# Restart to apply everything
systemctl restart rabbitmq-server

echo ">>> RabbitMQ installed, user '$RABBITMQ_USER' configured, and remote access enabled."
