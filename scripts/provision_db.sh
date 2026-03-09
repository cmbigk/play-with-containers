#!/bin/bash

DB_NAME=$1
DB_USER=$2
DB_PASS=$3

echo ">>> Installing PostgreSQL..."
export DEBIAN_FRONTEND=noninteractive
apt-get install -y postgresql postgresql-contrib

echo ">>> Configuring PostgreSQL for internal access..."
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf
echo "host    all             all             192.168.56.0/24         md5" >> /etc/postgresql/*/main/pg_hba.conf

systemctl restart postgresql

echo ">>> Creating database: $DB_NAME and user: $DB_USER..."
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

echo ">>> Database $DB_NAME created and configured."
