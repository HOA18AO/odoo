#!/bin/bash
# Odoo Entrypoint Wrapper
# - Avoids editing /etc/odoo (often not writable as non-root)
# - Copies mounted config to /tmp (writable), patches it, then starts Odoo with --config

set -e

CONFIG_FILE="/etc/odoo/odoo.conf"
TMP_CONFIG="/tmp/odoo.conf"

# Make a writable copy of the config
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$TMP_CONFIG"
else
    printf "%s\n" "[options]" > "$TMP_CONFIG"
fi

# Function to update config value (handles values with special characters)
update_config() {
    local key=$1
    local value=$2
    # Escape special characters in value for sed
    local escaped_value
    escaped_value="$(echo "$value" | sed 's/[[\.*^$()+?{|]/\\&/g')"

    if grep -q "^${key} = " "$TMP_CONFIG"; then
        # Update existing value
        sed -i "s|^${key} = .*|${key} = ${escaped_value}|" "$TMP_CONFIG"
    else
        # Add new value under [options] section
        sed -i "/^\[options\]/a ${key} = ${escaped_value}" "$TMP_CONFIG"
    fi
}

# Update database connection from environment variables
if [ -n "$DB_HOST" ]; then
    update_config "db_host" "$DB_HOST"
fi

if [ -n "$DB_PORT" ]; then
    update_config "db_port" "$DB_PORT"
fi

if [ -n "$DB_USER" ]; then
    update_config "db_user" "$DB_USER"
fi

if [ -n "$DB_PASSWORD" ]; then
    update_config "db_password" "$DB_PASSWORD"
fi

# Update admin password
if [ -n "$ADMIN_PASSWORD" ]; then
    update_config "admin_passwd" "$ADMIN_PASSWORD"
fi

# Update performance settings
if [ -n "$WORKERS" ]; then
    update_config "workers" "$WORKERS"
fi

if [ -n "$LIMIT_MEMORY_SOFT" ]; then
    update_config "limit_memory_soft" "$LIMIT_MEMORY_SOFT"
fi

if [ -n "$LIMIT_MEMORY_HARD" ]; then
    update_config "limit_memory_hard" "$LIMIT_MEMORY_HARD"
fi

if [ -n "$LIMIT_REQUEST" ]; then
    update_config "limit_request" "$LIMIT_REQUEST"
fi

if [ -n "$LIMIT_TIME_CPU" ]; then
    update_config "limit_time_cpu" "$LIMIT_TIME_CPU"
fi

if [ -n "$LIMIT_TIME_REAL" ]; then
    update_config "limit_time_real" "$LIMIT_TIME_REAL"
fi

if [ -n "$LIMIT_TIME_REAL_CRON" ]; then
    update_config "limit_time_real_cron" "$LIMIT_TIME_REAL_CRON"
fi

if [ -n "$MAX_CRON_THREADS" ]; then
    update_config "max_cron_threads" "$MAX_CRON_THREADS"
fi

# Start Odoo using the patched config
if [ "$#" -eq 0 ]; then
    set -- odoo
fi

# If the image CMD is "odoo", keep it but force our config path
if [ "$1" = "odoo" ]; then
    shift
    exec odoo --config="$TMP_CONFIG" "$@"
fi

# Otherwise, just run whatever command was provided
exec "$@"
