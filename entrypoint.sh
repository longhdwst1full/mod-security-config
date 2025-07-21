#!/bin/bash

# Start cron
service cron start

# Run logrotate immediately (optional)
logrotate -f /etc/logrotate.d/modsec

# Ensure Nginx log directory exists and has correct permissions
mkdir -p /var/log/nginx
chown -R www-data:www-data /var/log/nginx
chmod 755 /var/log/nginx

# Ensure ModSecurity log directory exists and has correct permissions
mkdir -p /var/log/modsec # Đảm bảo thư mục này được tạo
chown -R www-data:www-data /var/log/modsec # Cấp quyền sở hữu cho user Nginx
chmod 755 /var/log/modsec # THAY ĐỔI TỪ 775 SANG 755: Chỉ user www-data có quyền ghi. Group và Others chỉ đọc.

# Fix permissions for /var/log/modsec to avoid logrotate warnings
# if [ -d /var/log/modsec ]; then
#   chmod o-w /var/log/modsec # Dòng này có thể gây ra vấn đề nếu bạn muốn Promtail đọc
# fi

# Start nginx
exec /usr/local/nginx/sbin/nginx -g "daemon off;"