```bash
#!/bin/bash
apt-get update
apt-get install -y nginx php-fpm

# halaman yang menampilkan hostname
cat > /var/www/html/index.php <<'EOF'
<?php echo gethostname(); ?>
EOF

# virtual host
cat > /etc/nginx/sites-available/web <<'EOF'
# akses tanpa domain (lewat IP) ditutup
server {
    listen 80 default_server;
    return 444;
}
# akses dengan domain dilayani
server {
    listen 80;
    server_name jujutsu.K-49.com www.jujutsu.K-49.com;
    root /var/www/html;
    index index.php;

    location / {
        try_files $uri $uri/ =404;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/web /etc/nginx/sites-enabled/web

service php8.4-fpm start
nginx -t && (service nginx start || nginx -s reload)
```