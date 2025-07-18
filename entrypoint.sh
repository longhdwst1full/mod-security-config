#!/bin/bash

# Start cron
service cron start

# Run logrotate immediately (optional)
logrotate -f /etc/logrotate.d/modsec

# Ensure Nginx log directory exists and has correct permissions
mkdir -p /var/log/nginx
chown -R www-data:www-data /var/log/nginx
chmod 755 /var/log/nginx

# Fix permissions for /var/log/modsec to avoid logrotate warnings
if [ -d /var/log/modsec ]; then
  chmod o-w /var/log/modsec
fi

# Start nginx
exec /usr/local/nginx/sbin/nginx -g "daemon off;"
