#!/bin/bash
# Odoo Upgrade Helper Script
# Safely upgrades Odoo database and modules

set -e

# Load environment variables from .env file
if [ -f ../.env ]; then
    export $(cat ../.env | grep -v '^#' | xargs)
fi

DB_NAME="${1:-odoo_db}"
MODULES="${2:-all}"

echo "=========================================="
echo "Odoo Upgrade Script"
echo "=========================================="
echo "Database: $DB_NAME"
echo "Modules: $MODULES"
echo ""

# Confirm before proceeding
read -p "Have you backed up the database? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please backup your database first using: ./scripts/backup.sh"
    exit 1
fi

# Stop Odoo container
echo "Stopping Odoo container..."
docker-compose stop odoo

# Upgrade database
echo "Upgrading database..."
if [ "$MODULES" = "all" ]; then
    docker-compose run --rm odoo odoo -d "$DB_NAME" -u all --stop-after-init
else
    docker-compose run --rm odoo odoo -d "$DB_NAME" -u "$MODULES" --stop-after-init
fi

if [ $? -eq 0 ]; then
    echo "Upgrade completed successfully!"
    echo "Starting Odoo..."
    docker-compose up -d
    echo "Odoo is now running. Check logs with: docker-compose logs -f odoo"
else
    echo "ERROR: Upgrade failed!"
    echo "Please check the logs and restore from backup if necessary."
    exit 1
fi
