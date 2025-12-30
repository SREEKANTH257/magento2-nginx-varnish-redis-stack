#!/bin/bash
# Magento 2 Server Setup Automation
# Server: AWS ip-your-ip-27-117
# User: test-ssh
# Domain: test.mgt.com

set -e

echo "=== 1. Update & Install Core Stack ==="
sudo apt update
sudo apt install -y php8.3-fpm php8.3-mysql php8.3-curl php8.3-gd php8.3-mbstring \
                   nginx mysql-server redis-server elasticsearch unzip wget composer phpmyadmin varnish

echo "=== 2. Magento Installation ==="
cd /var/www/
sudo wget https://github.com/magento/magento2/archive/refs/heads/2.4-develop.zip
sudo unzip 2.4-develop.zip
sudo mv magento2-2.4-develop magento
sudo chown -R test-ssh:clp /var/www/magento
sudo -u test-ssh composer install --no-dev -d /var/www/magento

echo "=== 3. PHP-FPM Magento Pool ==="
sudo tee /etc/php/8.3/fpm/pool.d/magento.conf > /dev/null << 'EOF'
[magento]
user = test-ssh
group = clp
listen = /run/php/php8.3-fpm-magento.sock
listen.owner = test-ssh
listen.group = clp
listen.mode = 0660
pm = dynamic
pm.max_children = 20
EOF
sudo systemctl restart php8.3-fpm

echo "=== 4. NGINX User & Config ==="
sudo sed -i 's/user www-data;/user test-ssh;/' /etc/nginx/nginx.conf
sudo systemctl restart nginx

echo "=== 5. Redis Configuration for Magento ==="
sudo -u test-ssh php /var/www/magento/bin/magento setup:config:set \
  --cache-backend=redis --cache-backend-redis-server=127.0.0.1 --cache-backend-redis-db=0

sudo -u test-ssh php /var/www/magento/bin/magento setup:config:set \
  --page-cache=redis --page-cache-redis-server=127.0.0.1 --page-cache-redis-db=1

sudo -u test-ssh php /var/www/magento/bin/magento setup:config:set \
  --session-save=redis --session-save-redis-host=127.0.0.1 --session-save-redis-db=2

echo "=== 6. HTTPS + Self-Signed SSL ==="
sudo mkdir -p /etc/ssl/{certs,private}
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/test.mgt.com.key \
  -out /etc/ssl/certs/test.mgt.com.crt \
  -subj "/C=IN/ST=Telangana/L=Hyderabad/O=Magento/CN=test.mgt.com"

echo "=== 7. phpMyAdmin Configuration ==="
sudo ln -sf /usr/share/phpmyadmin /var/www/magento/pma
echo "127.0.0.1 pma.mgt.com" | sudo tee -a /etc/hosts

echo "=== 8. Varnish Setup ==="
sudo -u test-ssh php /var/www/magento/bin/magento varnish:vcl:generate > /etc/varnish/default.vcl

echo "=== Magento 2 Server Setup Complete! ==="
