---

# Scripts – Magento 2 Server Automation

This directory contains **automation and validation scripts** used to install, configure, and verify a Magento 2 server stack on **Debian 12 (Bookworm)** running on AWS.

---

##  Directory Contents

```
scripts/
├── setup.sh      # Automated Magento 2 server setup
└── validate.sh   # Post-setup validation checks
```

---

## 1. `setup.sh` – Server Setup Script

### Purpose

Automates the **end-to-end installation and configuration** of a Magento 2 server including:

* PHP 8.3 & PHP-FPM
* Nginx
* MySQL
* Redis
* Varnish
* phpMyAdmin
* Magento 2 application
* SSL (self-signed)

### Key Actions Performed

1. Installs core packages:

   * PHP 8.3 extensions
   * Nginx
   * MySQL Server
   * Redis
   * Elasticsearch
   * Varnish
   * phpMyAdmin
2. Downloads and installs Magento 2 (2.4 develop branch)
3. Configures a **dedicated PHP-FPM pool** for Magento
4. Updates Nginx to run as user `test-ssh`
5. Configures Redis for:

   * Default cache
   * Page cache
   * Sessions
6. Generates self-signed SSL certificates
7. Sets up phpMyAdmin access
8. Generates Varnish VCL for Magento

### Usage

```bash
cd magento-server-setup/scripts
chmod +x setup.sh
./setup.sh
```

⚠️ **Note:**

* Must be run as a user with `sudo` privileges.
* Assumes Magento root path: `/var/www/magento`
* Domain used: `test.mgt.com`

---

## 2. `validate.sh` – Validation Script

### Purpose

Performs **post-installation validation checks** to confirm that the Magento server is correctly configured and running.

### Validation Checks

* PHP-FPM, Nginx, Redis service status
* Magento frontend availability (HTTPS)
* HTTP → HTTPS redirect
* Redis keyspace usage
* Nginx & PHP-FPM running under correct user
* PHP-FPM socket existence & permissions
* `/etc/hosts` domain entries
* Nginx configured user

### Usage

```bash
cd magento-server-setup/scripts
chmod +x validate.sh
./validate.sh
```

### Expected Outcome

* All services show as **active (running)**
* HTTPS returns **HTTP/2 200**
* Redis keyspaces populated
* PHP-FPM socket owned by `test-ssh:clp`
* Nginx user correctly set

---

## 3. Requirements & Assumptions

* OS: Debian 12 (Bookworm)
* User: `test-ssh`
* Group: `clp`
* Magento Domain: `test.mgt.com`
* phpMyAdmin Domain: `pma.mgt.com`
* Internet access required for package installation

---

## 4. Best Practices

* Run `setup.sh` only once on a fresh server.
* Always run `validate.sh` after configuration changes.
* Review scripts before running in production environments.
* Replace self-signed SSL with Let’s Encrypt for production use.

---

## 5. Troubleshooting

* Check logs:

  * PHP-FPM: `/var/log/php8.3-fpm.log`
  * Nginx: `/var/log/nginx/error.log`
  * Magento: `/var/www/magento/var/log/`
* Re-run `validate.sh` after fixes to confirm resolution.

---
