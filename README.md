Magento 2 Server Setup
Project Overview
Project Name: Magento Server Setup
Environment: Development / Staging
Maintainer: test-ssh
Date: 2025-12-30
This repository contains all configurations, scripts, and documentation for setting up a Magento 2 server on Debian 12 (Bookworm) running on AWS t m7i-flex.large instance.

1. Server Details
	• Server IP: ip-172-31-27-117
	• SSH User: test-ssh
	• Domains:
		○ Magento frontend: https://test.mgt.com
		○ phpMyAdmin: https://pma.mgt.com

2. Core Stack
Operating System
	• OS: Debian 12 (Bookworm)
	• Package Manager: APT (.deb packages)
Web Server
	• Nginx Version: 1.22.1
	• Nginx User: test-ssh
	• Config Path: /etc/nginx/sites-available/magento.conf
PHP
	• Version: 8.3
	• FPM Pools: magento, www
	• Socket Path: /run/php/php8.3-fpm-magento.sock
	• Pool Config:
user = test-ssh
group = clp
listen = /run/php/php8.3-fpm-magento.sock
listen.owner = test-ssh
listen.group = clp
listen.mode = 0660
pm = dynamic
pm.max_children = 20
Database
	• MySQL Version: 8.0.44
	• Databases Configured: magento
Cache & Queue
	• Redis Version: 7.0.15
		○ db0: keys=144, expires=48
		○ db1: keys=25, expires=1
		○ db2: keys=1, expires=1
	• Varnish Version: 7.1.1
	• Status: Running
Magento
	• Version: Magento CLI 2.4.8-p3
	• Root Path: /var/www/magento

3. Infrastructure (AWS t m7i-flex.large)
	Fill actual numbers with commands like nproc, free -h, df -h, and AWS metadata queries.
	• vCPUs: <fill-in>
	• RAM: <fill-in> GB
	• Disk Size: <fill-in> GB
	• Region / AZ: <fill-in>
	• AMI: <fill-in>
	• Public IP: <fill-in>
	• Private IP: <fill-in>

4. Setup Scripts & Project Structure
magento-server-setup/
├── hosts
├── infrastructure-info.txt
├── magento-setup.docx
├── magento.conf
├── nginx.conf
├── scripts/
│   ├── setup.sh
│   └── validate.sh
├── test.mgt.com
└── validations.txt


5. Installation / Setup Steps
Step 1: Base System
sudo apt update && sudo apt install -y php8.3-fpm php8.3-mysql php8.3-curl php8.3-gd php8.3-mbstring nginx mysql-server redis-server elasticsearch
Step 2: Magento Installation
cd /var/www/
sudo wget https://github.com/magento/magento2/archive/refs/heads/2.4-develop.zip
sudo unzip 2.4-develop.zip
sudo mv magento2-2.4-develop magento
sudo chown -R test-ssh:clp /var/www/magento
sudo -u test-ssh cd /var/www/magento && composer install --no-dev
Step 3: PHP-FPM Pool for Magento
sudo tee /etc/php/8.3/fpm/pool.d/magento.conf << 'EOF'
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
Step 4: Nginx User & Config
sudo sed -i 's/user www-data;/user test-ssh;/' /etc/nginx/nginx.conf
sudo systemctl restart nginx
Step 5: Redis Configuration
sudo -u test-ssh php bin/magento setup:config:set --cache-backend=redis --cache-backend-redis-server=127.0.0.1 --cache-backend-redis-db=0
sudo -u test-ssh php bin/magento setup:config:set --page-cache=redis --page-cache-redis-server=127.0.0.1 --page-cache-redis-db=1
sudo -u test-ssh php bin/magento setup:config:set --session-save=redis --session-save-redis-host=127.0.0.1 --session-save-redis-db=2
Step 6: HTTPS + Self-Signed Cert
sudo mkdir -p /etc/ssl/{certs,private}
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/test.mgt.com.key \
    -out /etc/ssl/certs/test.mgt.com.crt \
    -subj "/C=IN/ST=Telangana/L=Hyderabad/O=Magento/CN=test.mgt.com"
Step 7: phpMyAdmin
sudo apt install phpmyadmin -y
sudo ln -sf /usr/share/phpmyadmin /var/www/magento/pma
echo "127.0.0.1 pma.mgt.com" | sudo tee -a /etc/hosts
Step 8: Varnish
sudo apt install varnish -y
sudo -u test-ssh php bin/magento varnish:vcl:generate > /etc/varnish/default.vcl

6. Validation Commands
Run these commands to verify setup:
echo "=== 1. Services ==="; systemctl status php8.3-fpm nginx redis-server | head -20
echo "=== 2. Frontend ==="; curl -Ik https://test.mgt.com | head -15
echo "=== 3. Redirect ==="; curl -I http://test.mgt.com
echo "=== 4. Redis ==="; redis-cli info keyspace
echo "=== 5. Processes ==="; ps aux | grep -E 'nginx|php-fpm' | grep test-ssh
echo "=== 6. Socket ==="; ls -l /run/php/php8.3-fpm-magento.sock
echo "=== 7. Hosts ==="; cat /etc/hosts | grep mgt.com
echo "=== 8. NGINX User ==="; grep "^user" /etc/nginx/nginx.conf

7. Server Access
	• SSH: test-ssh@ip-172-31-27-117
	• HTTP → HTTPS Redirect: http://test.mgt.com
	• Magento Frontend: https://test.mgt.com
	• phpMyAdmin: https://pma.mgt.com

8. Notes
	• Redis caching and Varnish enabled.
	• Custom PHP-FPM pool configured.
	• Correct file and socket permissions.
	• Self-signed SSL certificate configured.
Debian 12 (Bookworm) OS verified.<img width="912" height="3560" alt="image" src="https://github.com/user-attachments/assets/64489794-ed4a-482f-81c3-0db01ef07e23" />
