#!/bin/bash
# Magento 2 Server Validation Script
# Validates services, frontend, HTTPS, Redis, users, sockets, hosts, NGINX user

echo "=== 1. Services ==="
systemctl status php8.3-fpm nginx redis-server | head -20

echo "=== 2. Magento Frontend ==="
curl -Ik https://test.mgt.com | head -15

echo "=== 3. HTTP → HTTPS Redirect ==="
curl -I http://test.mgt.com

echo "=== 4. Redis Keyspace ==="
redis-cli info keyspace

echo "=== 5. Processes (nginx & php-fpm for test-ssh) ==="
ps aux | grep -E 'nginx|php-fpm' | grep test-ssh

echo "=== 6. PHP-FPM Socket ==="
ls -l /run/php/php8.3-fpm-magento.sock

echo "=== 7. Hosts File ==="
cat /etc/hosts | grep mgt.com

echo "=== 8. NGINX User ==="
grep "^user" /etc/nginx/nginx.conf
ps -o user= -p $(pgrep -o nginx)
