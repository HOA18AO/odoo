# Odoo Docker Deployment with External PostgreSQL

A production-ready self-hosted Odoo deployment using Docker with external PostgreSQL database support.

## Project Summary

This project provides a complete Docker-based setup for running Odoo (Enterprise Resource Planning system) with the following features:

- **Docker Compose** orchestration for easy deployment
- **External PostgreSQL** database support (self-hosted, not containerized)
- **Custom addons/modules** support with volume mounting
- **Nginx reverse proxy** with SSL support
- **Production-ready** configuration with security best practices
- **Backup scripts** for database and filestore
- **Helper scripts** for database initialization and upgrades

## Directory Structure

```
odoo/
├── docker-compose.yml          # Docker Compose orchestration file
├── .env                        # Environment variables (gitignored - create from .env.example)
├── .env.example                # Environment variables template
├── .gitignore                  # Git ignore rules
├── README.md                   # This file
│
├── config/
│   └── odoo.conf              # Odoo configuration file
│
├── addons/
│   └── custom/                # Custom Odoo modules (place your modules here)
│       └── README.md
│
├── filestore/                 # Odoo filestore (data files, attachments)
│
├── logs/                      # Odoo application logs
│
├── nginx/
│   ├── nginx.conf             # Nginx reverse proxy configuration
│   ├── ssl/                   # SSL certificates (gitignored)
│   └── logs/                  # Nginx logs (gitignored)
│
└── scripts/
    ├── backup.sh              # Database and filestore backup script
    ├── init-db.sh             # Database initialization helper
    └── upgrade.sh             # Safe upgrade wrapper script
```

## Prerequisites

Before starting, ensure you have:

- **Docker** and **Docker Compose** installed
- **PostgreSQL** database server running (version 12+ recommended)
- **PostgreSQL user** with appropriate privileges (see setup instructions below)
- **Network access** from Docker container to PostgreSQL server

## Getting Started

### Step 1: Setup PostgreSQL Database

**On your PostgreSQL server**, create a database and user for Odoo. You can use either the command-line method or a GUI tool like DBeaver.

#### Method 1: Using Command Line (psql)

```sql
-- Connect to PostgreSQL as superuser
psql -U postgres

-- Create dedicated user for Odoo (do NOT use the built-in 'postgres' role)
CREATE USER odoo_user WITH PASSWORD 'your_secure_password';

-- Grant necessary privileges
-- CREATEDB is needed if you want Odoo to create databases from the UI
ALTER USER odoo_user WITH CREATEDB;

-- Create database (optional - Odoo can create it automatically)
CREATE DATABASE odoo_db 
    OWNER odoo_user 
    ENCODING 'UTF8' 
    LC_COLLATE 'en_US.UTF-8' 
    LC_CTYPE 'en_US.UTF-8'
    TEMPLATE template0;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE odoo_db TO odoo_user;
```

#### Method 2: Using DBeaver (GUI Tool)

**Step 1: Connect to PostgreSQL**
1. Open DBeaver
2. Click **New Database Connection** (plug icon) or `File → New → Database Connection`
3. Select **PostgreSQL** from the list
4. Enter connection details:
   - **Host**: `localhost` (or your PostgreSQL server IP)
   - **Port**: `5432`
   - **Database**: `postgres` (default database)
   - **Username**: `postgres` (or your superuser)
   - **Password**: Enter your PostgreSQL superuser password
5. Click **Test Connection** to verify
6. Click **Finish** to save the connection

**Step 2: Create Odoo User**
1. Right-click on your PostgreSQL connection → **SQL Editor → New SQL Script**
2. Execute the following SQL:
   ```sql
   -- Create dedicated user for Odoo
   CREATE USER odoo_user WITH PASSWORD 'your_secure_password';
   
   -- Grant necessary privileges
   -- CREATEDB is needed if you want Odoo to create databases from the UI
   ALTER USER odoo_user WITH CREATEDB;
   ```
3. Click **Execute SQL Script** (or press `Ctrl+Enter`)

**Step 3: Create Odoo Database**
1. In DBeaver, right-click on **Databases** → **Create New → Database**
2. Fill in the database properties:
   - **Database name**: `odoo_db`
   - **Owner**: Select `odoo_user` from dropdown
   - **Encoding**: `UTF8`
   - **Template**: `template0`
   - **Collation**: `en_US.UTF-8`
   - **Ctype**: `en_US.UTF-8`
3. Click **OK** to create the database

**Step 4: Grant Privileges (if needed)**
1. Open a new SQL script
2. Execute:
   ```sql
   GRANT ALL PRIVILEGES ON DATABASE odoo_db TO odoo_user;
   ```

**Alternative: Create Database via SQL Script**
If you prefer using SQL in DBeaver:
1. Right-click on your connection → **SQL Editor → New SQL Script**
2. Execute:
   ```sql
   CREATE DATABASE odoo_db 
       OWNER odoo_user 
       ENCODING 'UTF8' 
       LC_COLLATE 'en_US.UTF-8' 
       LC_CTYPE 'en_US.UTF-8'
       TEMPLATE template0;
   
   GRANT ALL PRIVILEGES ON DATABASE odoo_db TO odoo_user;
   ```

**Verification in DBeaver:**
- Expand your PostgreSQL connection → **Databases** → You should see `odoo_db`
- Expand **Users** → You should see `odoo_user`
- Right-click on `odoo_db` → **Edit Database** → Verify owner is `odoo_user`

**For localhost PostgreSQL on Windows:**

1. Edit `postgresql.conf` (usually in `C:\Program Files\PostgreSQL\<version>\data\`):
   ```ini
   listen_addresses = '*'
   port = 5432
   ```

2. Edit `pg_hba.conf` (same directory):
   ```ini
   host    all    all    0.0.0.0/0    md5
   ```

3. Restart PostgreSQL service:
   ```powershell
   # Run as Administrator
   Restart-Service postgresql-x64-<version>
   ```

### Step 2: Configure Environment Variables

**Create `.env` file** in the project root directory (`r:\HOA18AO\odoo\.env`):

```bash
# Copy the example file
cp .env.example .env

# Edit .env with your actual values
```

**Update the following variables in `.env`:**

```bash
# PostgreSQL Connection
DB_HOST=host.docker.internal    # For localhost on Windows
                                # Use IP/hostname for remote PostgreSQL
DB_PORT=5432
DB_USER=odoo_user               # PostgreSQL username
DB_PASSWORD=your_postgres_password

# Odoo Admin Password
ADMIN_PASSWORD=your_odoo_admin_password

# Performance Settings (optional, defaults provided)
WORKERS=2
LIMIT_MEMORY_SOFT=2147483648
LIMIT_MEMORY_HARD=2684354560
LIMIT_REQUEST=8192
LIMIT_TIME_CPU=600
LIMIT_TIME_REAL=1200
LIMIT_TIME_REAL_CRON=1800
MAX_CRON_THREADS=2
```

**Important Notes:**
- For **localhost PostgreSQL on Windows**, use `DB_HOST=host.docker.internal`
- For **remote PostgreSQL**, use the server hostname or IP address
- Never commit `.env` file to version control (it's gitignored)

### Step 3: Update Odoo Configuration (Optional)

**Is this necessary?** **NO** - This step is **optional** and can be skipped for basic setup.

**Why it's optional:**
- The entrypoint script (`scripts/entrypoint.sh`) automatically reads environment variables from `.env` and updates `config/odoo.conf` when the container starts
- Your database connection settings from Step 2 (`.env` file) are automatically applied
- Default configuration works for most use cases

**When you DO need this step:**
Only edit `config/odoo.conf` directly if you need to customize advanced settings that aren't in `.env`:
- Email/SMTP server configuration (for sending emails from Odoo)
- Custom logging levels or log file locations
- Additional performance tuning beyond what's in `.env`
- Proxy settings, session management, or other Odoo-specific configurations

**For most users:** You can skip this step entirely and proceed to Step 4.

### Step 4: Create Required Directories

**Is this necessary?** **YES** - This step is **required** before starting Odoo.

**Why it's necessary:**
Odoo needs these directories to store:
- **filestore/**: All uploaded files, attachments, and documents
- **logs/**: Application logs for debugging
- **addons/custom/**: Your custom Odoo modules
- **nginx/ssl/**: SSL certificates (if using HTTPS)
- **nginx/logs/**: Nginx access/error logs

**Note:** If you're on Windows and the directories don't exist, Docker Compose will create them automatically when you start. However, it's better to create them explicitly to ensure proper permissions.

**Create directories:**

**On Windows (PowerShell):**
```powershell
New-Item -ItemType Directory -Force -Path addons\custom, filestore, logs, nginx\ssl, nginx\logs
```

**On Linux/Mac:**
```bash
mkdir -p addons/custom filestore logs nginx/ssl nginx/logs
chmod -R 755 filestore logs
```

**Verification:** After creating, you should see these directories in your project root. If they already exist from a previous setup, you can skip this step.

### Step 5: Start Odoo

```bash
# Start all services
docker-compose up -d

# Check container status
docker-compose ps

# View logs
docker-compose logs -f odoo
```

### Step 6: Access Odoo Web Interface

1. Open browser: `http://localhost:8069`

2. **First-time setup:**
   - If database doesn't exist, Odoo will show database creation form
   - Enter database name (e.g., `odoo_db`)
   - Enter admin email and password
   - Select language
   - Wait for initialization (5-10 minutes)

3. **Login** with the admin credentials you created

### Step 7: Install Custom Modules (Optional)

1. Place your custom modules in `addons/custom/` directory
2. Restart Odoo: `docker-compose restart odoo`
3. In Odoo UI: **Settings → Apps → Update Apps List**
4. Search and install your custom modules

## Common Commands

### Start/Stop Services

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose stop

# Restart services
docker-compose restart

# View logs
docker-compose logs -f odoo
```

### Database Operations

```bash
# Initialize database (if not created via web UI)
./scripts/init-db.sh odoo_db

# Backup database and filestore
./scripts/backup.sh

# Upgrade Odoo modules
./scripts/upgrade.sh odoo_db all
```

### Module Management

```bash
# Install module via CLI
docker exec -it odoo_app odoo -d odoo_db -i module_name --stop-after-init

# Upgrade module via CLI
docker exec -it odoo_app odoo -d odoo_db -u module_name --stop-after-init

# Update module list
docker exec -it odoo_app odoo -d odoo_db --update=all --stop-after-init
```

## Troubleshooting

### Database Connection Issues

**Error: "Connection refused" to host.docker.internal:5432**

This means PostgreSQL is not accepting connections from Docker. See **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** for detailed steps.

**Quick fixes:**

1. **Check PostgreSQL is running:**
   ```powershell
   Get-Service | Where-Object {$_.Name -like "*postgres*"}
   ```

2. **Verify PostgreSQL configuration:**
   - `postgresql.conf`: `listen_addresses = '*'`
   - `pg_hba.conf`: Add `host all all 0.0.0.0/0 md5`
   - Restart PostgreSQL service

3. **Test connection from Windows:**
   ```powershell
   Test-NetConnection -ComputerName localhost -Port 5432
   ```

4. **Verify database user exists:**
   ```sql
   psql -U postgres
   \du  -- List users
   ```

5. **Test from Docker container:**
   ```powershell
   docker run --rm -it postgres:15 psql -h host.docker.internal -U odoo_user -d postgres
   ```

**Password mismatch:**
- Ensure `DB_PASSWORD` in `.env` matches the PostgreSQL user password
- The entrypoint script automatically syncs `.env` → `odoo.conf`, but if you edited `odoo.conf` directly, restart the container

**Other common issues:**
- Verify `DB_HOST` in `.env` (use `host.docker.internal` for localhost on Windows)
- Check firewall isn't blocking port 5432
- Ensure `odoo_user` exists and has `CREATEDB` privilege

### Module Not Found

- Ensure modules are in `addons/custom/` directory
- Restart Odoo container: `docker-compose restart odoo`
- Update Apps List in Odoo UI
- Check `addons_path` in `config/odoo.conf`

### Permission Errors

- Ensure filestore directory has correct permissions
- On Linux: `chown -R 101:101 filestore` (Odoo runs as UID 101)

## Production Considerations

- **Security**: Never commit `.env` file, use strong passwords, enable SSL
- **Backups**: Schedule regular backups using `scripts/backup.sh` with cron
- **Monitoring**: Set up health checks and monitoring for production
- **Updates**: Always backup before upgrading Odoo or modules
- **Performance**: Adjust worker count and memory limits based on server resources

## Additional Resources

- [Odoo Documentation](https://www.odoo.com/documentation/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## License

This project is provided as-is for deployment purposes.
