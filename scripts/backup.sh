#!/bin/bash
# Odoo Backup Script
# Backs up PostgreSQL database and filestore

set -e

# Load environment variables from .env file
if [ -f ../.env ]; then
    export $(cat ../.env | grep -v '^#' | xargs)
fi

BACKUP_DIR="${BACKUP_DIR:-/backups/odoo}"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="${DB_NAME:-odoo_db}"
DB_USER="${DB_USER:-postgres}"
DB_HOST="${DB_HOST:-host.docker.internal}"
DB_PORT="${DB_PORT:-5432}"

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "Starting backup at $(date)"

# Backup database
echo "Backing up database..."
PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    -F c -f "$BACKUP_DIR/odoo_db_$DATE.dump"

if [ $? -eq 0 ]; then
    echo "Database backup completed: odoo_db_$DATE.dump"
else
    echo "ERROR: Database backup failed!"
    exit 1
fi

# Backup filestore
if [ -d "../filestore" ]; then
    echo "Backing up filestore..."
    tar -czf "$BACKUP_DIR/filestore_$DATE.tar.gz" -C .. filestore
    if [ $? -eq 0 ]; then
        echo "Filestore backup completed: filestore_$DATE.tar.gz"
    else
        echo "WARNING: Filestore backup failed!"
    fi
else
    echo "WARNING: Filestore directory not found, skipping..."
fi

# Remove backups older than 30 days
echo "Cleaning up old backups (older than 30 days)..."
find "$BACKUP_DIR" -name "*.dump" -mtime +30 -delete 2>/dev/null || true
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete 2>/dev/null || true

echo "Backup completed at $(date)"
echo "Backup location: $BACKUP_DIR"
