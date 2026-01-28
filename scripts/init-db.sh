#!/bin/bash
# Odoo Database Initialization Helper
# Initializes a new Odoo database

set -e

# Load environment variables from .env file
if [ -f ../.env ]; then
    export $(cat ../.env | grep -v '^#' | xargs)
fi

DB_NAME="${1:-odoo_db}"
DB_USER="${DB_USER:-postgres}"
DB_HOST="${DB_HOST:-host.docker.internal}"
DB_PORT="${DB_PORT:-5432}"

echo "Initializing Odoo database: $DB_NAME"
echo "Host: $DB_HOST:$DB_PORT"
echo "User: $DB_USER"

# Check if database exists
DB_EXISTS=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -lqt | cut -d \| -f 1 | grep -w "$DB_NAME" | wc -l)

if [ "$DB_EXISTS" -eq 1 ]; then
    echo "WARNING: Database '$DB_NAME' already exists!"
    read -p "Do you want to continue? This will initialize the existing database. (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Initialize database via Odoo
echo "Running Odoo initialization..."
docker-compose run --rm odoo odoo -d "$DB_NAME" --init=base --stop-after-init

if [ $? -eq 0 ]; then
    echo "Database '$DB_NAME' initialized successfully!"
    echo "You can now access Odoo at http://localhost:8069"
else
    echo "ERROR: Database initialization failed!"
    exit 1
fi
