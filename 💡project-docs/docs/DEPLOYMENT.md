# Homie File Organizer - Production Deployment Guide

## Containerized Backend Deployment

The backend is designed to be deployed as a Docker container, providing a consistent and isolated environment. This process is managed by the `homie-devops` MCP server.

### Building the Docker Image

The `backend/Dockerfile` uses a multi-stage build to create a slim and secure final image. It leverages `uv` for fast dependency installation and sets up a virtual environment within the container.

To build the image, use the `docker_build_image` tool via the `homie-devops` server.

**Example AI Prompt:**
> Use the DevOps tools to build a Docker image for the backend. Name it `homie-backend` and tag it as `1.0.0`.

### Running the Container

Once the image is built, you can run it using the standard `docker run` command. You'll need to map the container's exposed port (8000) to a port on your host machine.

```bash
docker run -p 8000:8000 homie-backend:1.0.0
```

The server will then be accessible at `http://localhost:8000`.

## 🚀 Overview

This guide covers the complete production deployment process for Homie File Organizer, including backend services, frontend applications, and infrastructure requirements.

## 📋 Prerequisites

### System Requirements

#### Backend Server
- **OS**: Linux (Ubuntu 20.04+ recommended), macOS, or Windows Server
- **RAM**: Minimum 2GB, Recommended 4GB+
- **Storage**: 10GB+ available space
- **Python**: 3.11 or higher
- **Network**: HTTPS capability, WebSocket support

#### Frontend Hosting
- **Web Server**: Apache, Nginx, or similar
- **HTTPS**: SSL certificate required for PWA features
- **Bandwidth**: CDN recommended for global deployment

### Required Services
- **AI Service**: Google Gemini API key
- **Analytics**: Optional analytics service (Google Analytics, Mixpanel, etc.)
- **Error Reporting**: Optional Sentry or similar service
- **Monitoring**: Optional APM service

## 🔧 Backend Deployment

### 1. Server Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Python and dependencies
sudo apt install python3.11 python3.11-venv python3.11-dev build-essential -y

# Install system dependencies
sudo apt install sqlite3 nginx certbot python3-certbot-nginx -y

# Create application user
sudo useradd -m -s /bin/bash homie
sudo usermod -aG sudo homie
```

### 2. Application Setup

```bash
# Switch to application user
sudo su - homie

# Clone repository
git clone https://github.com/yourusername/homie.git
cd homie

# Set up backend
cd backend
python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Configure environment
cp .env.example .env
nano .env  # Configure your settings
```

### 3. Environment Configuration

Create `/home/homie/homie/backend/.env`:

```bash
# Required Configuration
GEMINI_API_KEY=your_gemini_api_key_here
FLASK_ENV=production
SECRET_KEY=your_super_secret_key_here

# Database Configuration
DATABASE_PATH=/home/homie/data
BACKUP_PATH=/home/homie/backups

# Security Configuration
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
CORS_ENABLED=true
RATE_LIMITING_ENABLED=true

# Optional Services
ANALYTICS_KEY=your_analytics_key
SENTRY_DSN=your_sentry_dsn
ERROR_REPORTING_ENABLED=true

# Server Configuration
HOST=127.0.0.1
PORT=8000
WORKERS=4
DEBUG=false

# Logging Configuration
LOG_LEVEL=INFO
LOG_FILE=/home/homie/logs/homie.log
```

### 4. Database Setup

```bash
# Create data directories
mkdir -p /home/homie/data/modules
mkdir -p /home/homie/logs
mkdir -p /home/homie/backups

# Set permissions
chmod 700 /home/homie/data
chmod 750 /home/homie/logs
chmod 700 /home/homie/backups

# Initialize database
cd /home/homie/homie/backend
source venv/bin/activate
python -c "
from core.shared_services import SharedServices
services = SharedServices()
services.initialize_databases()
print('Databases initialized successfully')
"
```

### 5. Systemd Service

Create `/etc/systemd/system/homie-backend.service`:

```ini
[Unit]
Description=Homie File Organizer Backend
After=network.target

[Service]
Type=simple
User=homie
Group=homie
WorkingDirectory=/home/homie/homie/backend
Environment=PATH=/home/homie/homie/backend/venv/bin
ExecStart=/home/homie/homie/backend/venv/bin/python main.py
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
SyslogIdentifier=homie-backend

# Security settings
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/home/homie/data /home/homie/logs /home/homie/backups

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable homie-backend
sudo systemctl start homie-backend
sudo systemctl status homie-backend
```

### 6. Reverse Proxy Setup (Nginx)

Create `/etc/nginx/sites-available/homie`:

```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Security Headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload";
    add_header Referrer-Policy "strict-origin-when-cross-origin";

    # Frontend static files
    location / {
        root /var/www/homie;
        try_files $uri $uri/ /index.html;
        
        # Cache static assets
        location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # Backend API
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # WebSocket endpoint
    location /socket.io/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/homie /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 7. SSL Certificate

```bash
# Get SSL certificate
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Set up auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 🎨 Frontend Deployment

### Linux Desktop Notes
- Use the provided Wayland scripts for Linux desktop: `./start_homie.sh` or `./start_file_organizer.sh`.
- Fullscreen/maximize can be enabled by setting `FLUTTER_FULLSCREEN=true` (handled in `mobile_app/linux/runner/my_application.cc`).
- Hot reload is available via `./start_file_organizer.sh --hot-reload` but is experimental; for this app on Linux desktop it is NOT supported—prefer the normal script and full restarts.

### 1. Build Production Frontend

```bash
cd mobile_app

# Install dependencies
flutter pub get

# Build for production
./scripts/build_production.sh \
  --backend-url https://yourdomain.com \
  --analytics-key your_analytics_key \
  --sentry-dsn your_sentry_dsn \
  --version 1.0.0 \
  --build-number $(date +%s) \
  --clean
```

### 2. Deploy to Web Server

```bash
# Extract build
tar -xzf build/homie-file-organizer-*.tar.gz

# Deploy to web server
sudo mkdir -p /var/www/homie
sudo cp -r web/* /var/www/homie/
sudo chown -R www-data:www-data /var/www/homie
sudo chmod -R 755 /var/www/homie
```

### 3. Verify Deployment

```bash
# Test local backend
curl http://localhost:8000/api/health

# Test frontend access
curl -I https://yourdomain.com

# Test API through proxy
curl https://yourdomain.com/api/health
```

## 📊 Monitoring & Logging

### 1. Backend Monitoring

```bash
# View logs
sudo journalctl -u homie-backend -f

# Monitor performance
htop
sudo iotop
sudo netstat -tlnp | grep :8000
```

### 2. Application Monitoring

Create `/home/homie/scripts/health_check.sh`:

```bash
#!/bin/bash
# Health check script

BACKEND_URL="http://localhost:8000/api/health"
FRONTEND_URL="https://yourdomain.com"

# Check backend
if curl -f -s $BACKEND_URL > /dev/null; then
    echo "$(date): Backend OK"
else
    echo "$(date): Backend FAILED"
    # Restart service
    sudo systemctl restart homie-backend
fi

# Check frontend
if curl -f -s $FRONTEND_URL > /dev/null; then
    echo "$(date): Frontend OK"
else
    echo "$(date): Frontend FAILED"
    # Could restart nginx or notify admin
fi
```

Add to crontab:

```bash
# Run health check every 5 minutes
*/5 * * * * /home/homie/scripts/health_check.sh >> /home/homie/logs/health_check.log 2>&1
```

### 3. Log Rotation

Create `/etc/logrotate.d/homie`:

```
/home/homie/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    notifempty
    create 0644 homie homie
    postrotate
        systemctl reload homie-backend
    endscript
}
```

## 💾 Backup Strategy

### 1. Database Backup

Create `/home/homie/scripts/backup.sh`:

```bash
#!/bin/bash
# Backup script for Homie File Organizer

BACKUP_DIR="/home/homie/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="homie_backup_$DATE"

# Create backup directory
mkdir -p "$BACKUP_DIR/$BACKUP_NAME"

# Backup databases
cp -r /home/homie/data "$BACKUP_DIR/$BACKUP_NAME/"

# Backup configuration
cp /home/homie/homie/backend/.env "$BACKUP_DIR/$BACKUP_NAME/"

# Create archive
cd "$BACKUP_DIR"
tar -czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME"
rm -rf "$BACKUP_NAME"

# Keep only last 30 backups
ls -t *.tar.gz | tail -n +31 | xargs -r rm

echo "Backup completed: $BACKUP_NAME.tar.gz"
```

Add to crontab:

```bash
# Daily backup at 2 AM
0 2 * * * /home/homie/scripts/backup.sh >> /home/homie/logs/backup.log 2>&1
```

### 2. Remote Backup

```bash
# Optional: Upload to cloud storage
# Add to backup.sh after local backup:

# Upload to S3 (requires aws-cli configuration)
aws s3 cp "$BACKUP_DIR/$BACKUP_NAME.tar.gz" s3://your-backup-bucket/homie/

# Or upload via rsync to remote server
rsync -av "$BACKUP_DIR/$BACKUP_NAME.tar.gz" backup-server:/backups/homie/
```

## 🔄 Updates & Maintenance

### 1. Application Updates

Create `/home/homie/scripts/update.sh`:

```bash
#!/bin/bash
# Update script for Homie File Organizer

set -e

echo "Starting Homie File Organizer update..."

# Backup current installation
/home/homie/scripts/backup.sh

# Stop services
sudo systemctl stop homie-backend

# Update code
cd /home/homie/homie
git fetch origin
git checkout main
git pull origin main

# Update backend dependencies
cd backend
source venv/bin/activate
pip install -r requirements.txt

# Run any database migrations
python -c "
from core.shared_services import SharedServices
services = SharedServices()
services.run_migrations()
print('Database migrations completed')
"

# Build and deploy frontend
cd ../mobile_app
./scripts/build_production.sh \
  --backend-url https://yourdomain.com \
  --version $(git describe --tags --always) \
  --build-number $(date +%s)

# Deploy frontend
sudo cp -r build/web/* /var/www/homie/
sudo chown -R www-data:www-data /var/www/homie

# Start services
sudo systemctl start homie-backend

# Verify deployment
sleep 5
curl -f http://localhost:8000/api/health

echo "Update completed successfully!"
```

### 2. System Updates

```bash
# Monthly system updates
sudo apt update && sudo apt upgrade -y
sudo systemctl restart homie-backend
```

### 3. SSL Certificate Renewal

```bash
# Test renewal
sudo certbot renew --dry-run

# Automatic renewal is handled by cron
```

## 🔒 Security Checklist

### Pre-Deployment Security

- [ ] Change all default passwords and secrets
- [ ] Configure firewall (UFW or iptables)
- [ ] Enable fail2ban for SSH protection
- [ ] Set up SSL/TLS certificates
- [ ] Configure security headers
- [ ] Enable CORS protection
- [ ] Set up rate limiting
- [ ] Configure secure file permissions
- [ ] Enable database encryption if needed
- [ ] Set up VPN access for administration

### Post-Deployment Security

- [ ] Monitor access logs
- [ ] Regular security updates
- [ ] Backup verification
- [ ] Penetration testing
- [ ] SSL certificate monitoring
- [ ] Error log monitoring
- [ ] User access reviews

## 📈 Performance Optimization

### 1. Backend Optimization

```bash
# Tune Python performance
export PYTHONOPTIMIZE=2
export MALLOC_ARENA_MAX=2

# Database optimization
sqlite3 /home/homie/data/homie_users.db "PRAGMA optimize;"
```

### 2. Frontend Optimization

- Enable gzip compression in Nginx
- Set up CDN for static assets
- Optimize images and assets
- Enable browser caching
- Monitor Core Web Vitals

### 3. System Optimization

```bash
# Tune system for web server
echo 'net.core.somaxconn = 1024' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_max_syn_backlog = 1024' >> /etc/sysctl.conf
sysctl -p
```

## 🚨 Troubleshooting

### Common Issues

#### Backend Won't Start
```bash
# Check logs
sudo journalctl -u homie-backend -n 50

# Check Python dependencies
cd /home/homie/homie/backend
source venv/bin/activate
pip check

# Check database permissions
ls -la /home/homie/data/
```

#### Frontend Not Loading
```bash
# Check Nginx configuration
sudo nginx -t

# Check file permissions
ls -la /var/www/homie/

# Check SSL certificate
sudo certbot certificates
```

#### Database Issues
```bash
# Check database integrity
sqlite3 /home/homie/data/homie_users.db "PRAGMA integrity_check;"

# Restore from backup
cd /home/homie/backups
tar -xzf homie_backup_YYYYMMDD_HHMMSS.tar.gz
cp -r homie_backup_*/data/* /home/homie/data/
```

#### Performance Issues
```bash
# Monitor system resources
htop
iotop
netstat -i

# Check database locks
lsof | grep database

# Analyze slow queries
# Enable SQL logging in development
```

## 📞 Support & Maintenance

### Regular Maintenance Tasks

**Daily:**
- [ ] Check service status
- [ ] Review error logs
- [ ] Monitor disk space

**Weekly:**
- [ ] Review access logs
- [ ] Check backup integrity
- [ ] Monitor performance metrics

**Monthly:**
- [ ] System updates
- [ ] Security scan
- [ ] Backup cleanup
- [ ] SSL certificate check

### Emergency Contacts

- **System Administrator**: [Contact Info]
- **Developer Team**: [Contact Info]
- **Hosting Provider**: [Contact Info]
- **Domain Registrar**: [Contact Info]

### Documentation

- **API Documentation**: https://yourdomain.com/api/docs
- **User Guide**: https://yourdomain.com/help
- **Admin Panel**: https://yourdomain.com/admin
- **Monitoring**: https://monitoring.yourdomain.com

---

## 📝 Deployment Checklist

### Pre-Deployment
- [ ] Server provisioned and secured
- [ ] Domain configured with DNS
- [ ] SSL certificate obtained
- [ ] Environment variables configured
- [ ] Database initialized
- [ ] Backup strategy implemented

### Deployment
- [ ] Backend service deployed and running
- [ ] Frontend built and deployed
- [ ] Reverse proxy configured
- [ ] SSL/TLS enabled
- [ ] Monitoring configured
- [ ] Health checks passing

### Post-Deployment
- [ ] Full functionality testing
- [ ] Performance testing
- [ ] Security scan completed
- [ ] Backup tested and verified
- [ ] Documentation updated
- [ ] Team notified of deployment

---

**Last Updated**: [Date]  
**Version**: 1.0.0  
**Maintainer**: [Your Name/Team]
<!-- Last updated: 2025-10-01 21:57 - Reason: Added instructions for the new Docker-based deployment workflow. -->
