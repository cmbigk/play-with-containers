#!/bin/bash

RABBITMQ_USER=${1:-guest}
RABBITMQ_PASS=${2:-guest}

echo ">>> Installing RabbitMQ..."
export DEBIAN_FRONTEND=noninteractive
apt-get install -y rabbitmq-server

echo ">>> Configuring RabbitMQ..."
# Enable the web management UI
rabbitmq-plugins enable rabbitmq_management

# Create user (if not using the default guest account)
if [ "$RABBITMQ_USER" != "guest" ]; then
    rabbitmqctl add_user "$RABBITMQ_USER" "$RABBITMQ_PASS" 2>/dev/null || \
        rabbitmqctl change_password "$RABBITMQ_USER" "$RABBITMQ_PASS"
    rabbitmqctl set_user_tags "$RABBITMQ_USER" administrator
fi

rabbitmqctl set_permissions -p / "$RABBITMQ_USER" ".*" ".*" ".*"

# Allow connections from other VMs (not just localhost)
echo "loopback_users = none" > /etc/rabbitmq/rabbitmq.conf

# Start RabbitMQ with all configuration applied
systemctl enable rabbitmq-server
systemctl restart rabbitmq-server

echo ">>> RabbitMQ installed, user '$RABBITMQ_USER' configured."
