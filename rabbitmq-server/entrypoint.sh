#!/bin/sh
set -e

chown -R rabbitmq:rabbitmq /var/lib/rabbitmq /var/log/rabbitmq

echo "Starting RabbitMQ in the background..."
gosu rabbitmq rabbitmq-server -detached

echo "Waiting for RabbitMQ to start..."
while ! rabbitmqctl status > /dev/null 2>&1; do
    sleep 1
done

echo "Configuring RabbitMQ user..."
rabbitmqctl add_user "$RABBITMQ_USER" "$RABBITMQ_PASS" 2>/dev/null || rabbitmqctl change_password "$RABBITMQ_USER" "$RABBITMQ_PASS"
rabbitmqctl set_user_tags "$RABBITMQ_USER" administrator
rabbitmqctl set_permissions -p / "$RABBITMQ_USER" ".*" ".*" ".*"

echo "Stopping background RabbitMQ..."
rabbitmqctl stop

echo "Starting RabbitMQ in foreground..."
exec gosu rabbitmq rabbitmq-server
