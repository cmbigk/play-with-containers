#!/bin/sh
set -e

chown -R postgres:postgres "$PGDATA"

if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "Initializing database..."
    su-exec postgres initdb -D "$PGDATA"
    
    echo "Configuring network access..."
    echo "host all all 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"
    echo "listen_addresses='*'" >> "$PGDATA/postgresql.conf"
    
    echo "Starting PostgreSQL temporarily to create user and database..."
    su-exec postgres pg_ctl -D "$PGDATA" -w start
    
    echo "Creating user and database..."
    su-exec postgres psql -v ON_ERROR_STOP=1 --username postgres <<-EOSQL
        CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';
        CREATE DATABASE $DB_NAME OWNER $DB_USER;
        GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOSQL
    
    echo "Stopping temporary PostgreSQL..."
    su-exec postgres pg_ctl -D "$PGDATA" -m fast -w stop
fi

echo "Starting PostgreSQL..."
exec su-exec postgres postgres -D "$PGDATA"
