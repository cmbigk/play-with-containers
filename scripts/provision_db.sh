#!/bin/bash

DB_NAME=$1
DB_USER=$2
DB_PASS=$3

echo ">>> Installing PostgreSQL..."
export DEBIAN_FRONTEND=noninteractive
apt-get install -y postgresql postgresql-contrib

echo ">>> Temporarily allowing all local connections for provisioning..."
cat > /etc/postgresql/*/main/pg_hba.conf <<EOF
local   all             all                                     trust
EOF
systemctl restart postgresql

echo ">>> Creating/Updating database: $DB_NAME and user: $DB_USER..."
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;" 2>/dev/null || echo "Database $DB_NAME already exists"

if [ "$DB_USER" == "postgres" ]; then
    echo "Updating password for existing postgres user..."
    sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$DB_PASS';"
else
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';" 2>/dev/null || sudo -u postgres psql -c "ALTER USER $DB_USER WITH PASSWORD '$DB_PASS';"
fi

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

echo ">>> Configuring PostgreSQL for internal and local access..."
# Apply final md5 security
cat > /etc/postgresql/*/main/pg_hba.conf <<EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     md5
host    all             all             127.0.0.1/32            md5
host    all             all             192.168.56.0/24         md5
EOF

sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf

systemctl restart postgresql

echo ">>> Database $DB_NAME created and configured."
echo ">>> NOTE: If connecting from within the VM, use: psql -U postgres -d $DB_NAME (you will be prompted for password)"
