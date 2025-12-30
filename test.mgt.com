# HTTP → HTTPS redirect
server {
    listen 8080;
    server_name test.mgt.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS Magento (main)
server {
    listen 443 ssl http2;
    server_name test.mgt.com;
    
    ssl_certificate /etc/ssl/certs/test.mgt.com.crt;
    ssl_certificate_key /etc/ssl/private/test.mgt.com.key;
    
    root /var/www/magento/pub;
    index index.php;
    
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    
    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.3-fpm-magento.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
    }
    
    # phpMyAdmin
    location /pma/ {
        alias /var/www/magento/pma/;
        index index.php;
        location ~ ^/pma/(.+\.php)$ {
            fastcgi_pass unix:/run/php/php8.3-fpm-magento.sock;
            fastcgi_param SCRIPT_FILENAME $request_filename;
            include fastcgi_params;
        }
    }
}
