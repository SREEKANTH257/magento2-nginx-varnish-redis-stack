# Magento 2 Server Setup
Magento 2 Installation & Configuration on Debian 12 with NGINX, Redis, Varnish, and SSL
##  Server Details
- **Server:** AWS `ip-172-31-27-117`  
- **User:** `test-ssh`  
- **Domain:** `test.mgt.com`  
- **phpMyAdmin:** `https://pma.mgt.com`

---

##  Stack Installed
- **OS:** Debian 12  
- **PHP:** 8.3  
- **MySQL:** 8  
- **NGINX:** 1.22  
- **Redis:** Cache & Session storage  
- **Elasticsearch:** Magento search indexing  
- **Varnish:** Full-page caching (bonus)  
- **SSL:** Self-signed certificate  

---

##  Setup Steps

### 1. Base System
```bash
sudo apt update
sudo apt install -y php8.3-fpm php8.3-mysql php8.3-curl php8.3-gd php8.3-mbstring \
nginx mysql-server redis-server elasticsearch

````

### **2. Magento Installation**

```bash
cd /var/www/
sudo wget https://github.com/magento/magento2/archive/refs/heads/2.4-develop.zip
sudo unzip 2.4-develop.zip
sudo mv magento2-2.4-develop magento
sudo chown -R test-ssh:clp /var/www/magento
sudo -u test-ssh composer install --no-dev
```

### **3. PHP-FPM Magento Pool**

```bash
sudo tee /etc/php/8.3/fpm/pool.d/magento.conf << 'EOF'
[magento]
user = test-ssh
group = clp
db-name=magento2 \
db-user=magentouser \
db-password=Admin@123 \
admin-firstname=Admin \
admin-lastname=User \
admin-email=admin@example.com \
admin-user=admin \
admin-password=Admin@123! \
language=en_US \
listen = /run/php/php8.3-fpm-magento.sock
listen.owner = test-ssh
listen.group = clp
listen.mode = 0660
pm = dynamic
pm.max_children = 20
EOF
sudo systemctl restart php8.3-fpm
```

### **4. NGINX User & Config**

```bash
sudo sed -i 's/user www-data;/user test-ssh;/' /etc/nginx/nginx.conf
sudo systemctl restart nginx
```

### **5. Redis Configuration**

```bash
sudo -u test-ssh php bin/magento setup:config:set --cache-backend=redis --cache-backend-redis-server=127.0.0.1 --cache-backend-redis-db=0
sudo -u test-ssh php bin/magento setup:config:set --page-cache=redis --page-cache-redis-server=127.0.0.1 --page-cache-redis-db=1
sudo -u test-ssh php bin/magento setup:config:set --session-save=redis --session-save-redis-host=127.0.0.1 --session-save-redis-db=2
```

### **6. HTTPS & Self-Signed Certificate**

```bash
sudo mkdir -p /etc/ssl/{certs,private}
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout /etc/ssl/private/test.mgt.com.key \
-out /etc/ssl/certs/test.mgt.com.crt \
-subj "/C=IN/ST=Telangana/L=Hyderabad/O=Magento/CN=test.mgt.com"
```

### **7. phpMyAdmin Setup**

```bash
sudo apt install phpmyadmin -y
sudo ln -sf /usr/share/phpmyadmin /var/www/magento/pma
echo "127.0.0.1 pma.mgt.com" | sudo tee -a /etc/hosts
```

### **8. Varnish**

```bash
sudo apt install varnish -y
sudo -u test-ssh php bin/magento varnish:vcl:generate > /etc/varnish/default.vcl
```

---

## **Validation Commands**

### **1. Services**

```bash
systemctl status php8.3-fpm nginx redis-server | head -20
```

### **2. Frontend**

```bash
curl -Ik https://test.mgt.com | head -15
```

### **3. HTTP → HTTPS Redirect**

```bash
curl -I http://test.mgt.com
```

### **4. Redis Cache Active**

```bash
redis-cli info keyspace
```

### **5. Processes & Users**

```bash
ps aux | grep -E 'nginx|php-fpm' | grep test-ssh
```

### **6. PHP-FPM Socket**

```bash
ls -l /run/php/php8.3-fpm-magento.sock
```

### **7. Hosts**

```bash
cat /etc/hosts | grep mgt.com
```

### **8. NGINX User**

```bash
grep "^user" /etc/nginx/nginx.conf
```

---

## **Server Access**

* **SSH:** `test-ssh@ip-172-31-27-117`
* **Magento:** `https://test.mgt.com`
* **phpMyAdmin:** `https://pma.mgt.com`

---

<p align="center"> **Magento 2 Server Setup Complete & Production Ready!**</p>
```

---
