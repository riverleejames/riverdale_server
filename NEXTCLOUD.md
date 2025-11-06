# Nextcloud AIO (All-in-One) Setup Guide

Nextcloud AIO is a complete Nextcloud deployment that includes the mastercontainer which automatically manages all necessary containers (Nextcloud, database, Redis, Cron, etc.).

## Quick Start

### 1. Configure Environment Variables

Add Nextcloud settings to your `.env` file:

```bash
# Copy from .env.example or add these lines:
NEXTCLOUD_AIO_PORT=8080           # Admin interface port
NEXTCLOUD_PORT=8443               # Nextcloud web interface (HTTPS)
NEXTCLOUD_SKIP_DOMAIN_VALIDATION=false
```

### 2. Start Nextcloud AIO

```bash
# Option 1: Use the setup script (recommended)
./scripts/nextcloud-setup.sh

# Option 2: Manual start
docker compose -f docker-compose.nextcloud.yml up -d
```

### 3. Get Initial Admin Password

The setup script will display it automatically, or run:

```bash
docker logs nextcloud-aio-mastercontainer 2>&1 | grep "Initial password"
```

### 4. Access the Admin Interface

Open your browser and navigate to:
```
https://YOUR_SERVER_IP:8080
```

You'll see a security warning because it uses a self-signed certificate. Accept it to continue.

### 5. Complete Setup

1. Enter the initial admin password
2. Configure your domain or IP address
3. Select which containers to enable (Nextcloud Office, Talk, etc.)
4. Click "Start containers"
5. Wait for all containers to start (this may take several minutes)

### 6. Access Nextcloud

Once setup is complete, access your Nextcloud instance at:
```
https://YOUR_SERVER_IP:8443
```

## Port Configuration

By default, Nextcloud AIO uses:
- **8080**: Admin interface (AIO mastercontainer)
- **8443**: Nextcloud web interface (HTTPS)

You can change these in your `.env` file:
```bash
NEXTCLOUD_AIO_PORT=8080
NEXTCLOUD_PORT=8443
```

## Data Storage

### Default (Docker Volume)

By default, all data is stored in a Docker volume named `nextcloud_aio_mastercontainer`. This is the recommended approach for most users.

### Custom Data Directory

If you want to store data on a specific disk/partition:

1. Stop Nextcloud if running:
   ```bash
   docker compose -f docker-compose.nextcloud.yml down
   ```

2. Edit your `.env` file and uncomment:
   ```bash
   NEXTCLOUD_DATADIR=/mnt/media-storage/nextcloud-data
   ```

3. Create the directory and set permissions:
   ```bash
   sudo mkdir -p /mnt/media-storage/nextcloud-data
   sudo chown -R 33:0 /mnt/media-storage/nextcloud-data
   sudo chmod -R 750 /mnt/media-storage/nextcloud-data
   ```

4. Uncomment the NEXTCLOUD_DATADIR line in `docker-compose.nextcloud.yml`

5. Start Nextcloud:
   ```bash
   docker compose -f docker-compose.nextcloud.yml up -d
   ```

## Backup Configuration

### Using Built-in Backups

Nextcloud AIO includes built-in backup functionality:

1. Access the admin interface at `https://YOUR_SERVER_IP:8080`
2. Navigate to the "Backup and restore" section
3. Configure backup location and schedule

### Custom Backup Location

Edit your `.env` file:
```bash
NEXTCLOUD_BACKUP_DIR=/mnt/media-storage/nextcloud-backups
```

Then:
```bash
sudo mkdir -p /mnt/media-storage/nextcloud-backups
sudo chown -R 33:0 /mnt/media-storage/nextcloud-backups
```

## Mounting Additional Directories

To make your media files or other directories available in Nextcloud:

1. Edit `.env`:
   ```bash
   NEXTCLOUD_MOUNT=/mnt/media-storage/media
   ```

2. Uncomment the line in `docker-compose.nextcloud.yml`

3. Restart Nextcloud:
   ```bash
   docker compose -f docker-compose.nextcloud.yml restart
   ```

The mounted directory will be available in Nextcloud as "External Storage".

## Available Containers

Nextcloud AIO can deploy these containers (selected during setup):

- **Nextcloud**: Main application
- **Database**: PostgreSQL
- **Redis**: Caching
- **Apache**: Web server
- **Cron**: Background jobs
- **Nextcloud Office**: Built-in office suite (optional)
- **Talk**: Video conferencing (optional)
- **Talk Recording**: Recording server for Talk (optional)
- **Imaginary**: Image processing (optional)
- **Fulltextsearch**: Full-text search (optional)
- **ClamAV**: Antivirus scanner (optional)

## Common Operations

### View All Nextcloud Containers

```bash
docker ps | grep nextcloud
```

### View Mastercontainer Logs

```bash
docker logs -f nextcloud-aio-mastercontainer
```

### View Nextcloud Application Logs

```bash
docker logs -f nextcloud-aio-nextcloud
```

### Restart Nextcloud

```bash
docker compose -f docker-compose.nextcloud.yml restart
```

### Stop All Nextcloud Containers

You can stop from the admin interface at `https://YOUR_SERVER_IP:8080`, or:

```bash
docker compose -f docker-compose.nextcloud.yml down
```

### Start Nextcloud

```bash
docker compose -f docker-compose.nextcloud.yml up -d
```

### Update Nextcloud AIO

Nextcloud AIO can update itself through the admin interface:

1. Go to `https://YOUR_SERVER_IP:8080`
2. Click "Check for updates"
3. Follow the update prompts

Or manually:
```bash
docker compose -f docker-compose.nextcloud.yml pull
docker compose -f docker-compose.nextcloud.yml up -d
```

## Domain Configuration

### Local Network (IP Only)

If you're only using Nextcloud on your local network, you can skip domain validation:

```bash
NEXTCLOUD_SKIP_DOMAIN_VALIDATION=true
```

### Using a Domain Name

For production use with a proper domain:

1. Set `NEXTCLOUD_SKIP_DOMAIN_VALIDATION=false` in `.env`
2. During AIO setup, enter your domain (e.g., `nextcloud.yourdomain.com`)
3. Point your domain's DNS to your server's IP
4. AIO will automatically handle SSL certificates via Let's Encrypt

### Reverse Proxy (Advanced)

If you want to use Traefik or another reverse proxy:

1. Nextcloud AIO needs special configuration for reverse proxies
2. See the [official documentation](https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md)
3. You'll need to configure the `APACHE_PORT` and potentially use a different network setup

## Troubleshooting

### Cannot Access Admin Interface

1. Check if the container is running:
   ```bash
   docker ps | grep nextcloud-aio-mastercontainer
   ```

2. Check logs:
   ```bash
   docker logs nextcloud-aio-mastercontainer
   ```

3. Verify port is not in use:
   ```bash
   sudo netstat -tulpn | grep 8080
   ```

### Forgot Admin Password

View it in the logs:
```bash
docker logs nextcloud-aio-mastercontainer 2>&1 | grep "Initial password"
```

### Containers Not Starting

1. Check the admin interface for error messages
2. Ensure you have enough disk space
3. Check Docker logs for specific containers:
   ```bash
   docker logs nextcloud-aio-nextcloud
   docker logs nextcloud-aio-database
   ```

### SSL Certificate Errors

If using a domain:
1. Ensure your domain points to your server
2. Ensure ports 80 and 443 are accessible from the internet
3. Check the Apache logs: `docker logs nextcloud-aio-apache`

### Performance Issues

1. Ensure adequate resources (RAM, CPU)
2. Consider disabling optional containers you don't need
3. Use Redis for caching (enabled by default)
4. Configure PHP memory limits in the admin interface

## Backup and Restore

### Creating a Backup

1. Go to `https://YOUR_SERVER_IP:8080`
2. Click "Backup and restore"
3. Click "Create backup"
4. Wait for the backup to complete

### Restoring a Backup

1. Go to the admin interface
2. Click "Backup and restore"
3. Select the backup to restore
4. Click "Restore"

### Manual Backup (Advanced)

All data is in Docker volumes:
```bash
# List volumes
docker volume ls | grep nextcloud

# Backup a volume
docker run --rm -v nextcloud_aio_mastercontainer:/data -v $(pwd):/backup ubuntu tar czf /backup/nextcloud-backup.tar.gz /data
```

## Security Recommendations

1. **Change Default Ports**: Use non-standard ports if exposed to the internet
2. **Enable 2FA**: Enable two-factor authentication for all users
3. **Regular Updates**: Keep Nextcloud and containers updated
4. **Strong Passwords**: Use strong, unique passwords
5. **Firewall**: Use a firewall to restrict access
6. **Fail2ban**: Consider using fail2ban for brute-force protection
7. **Regular Backups**: Schedule automatic backups

## Resources

- [Nextcloud AIO GitHub](https://github.com/nextcloud/all-in-one)
- [Nextcloud Documentation](https://docs.nextcloud.com/)
- [Nextcloud Community](https://help.nextcloud.com/)

## Useful Admin Interface Features

Access at `https://YOUR_SERVER_IP:8080`:

- **Start/Stop Containers**: Manage all containers from one place
- **Update**: Check for and apply updates
- **Backup/Restore**: Manage backups
- **Logs**: View container logs
- **Container Configuration**: Enable/disable optional containers
- **Performance Metrics**: Monitor resource usage
