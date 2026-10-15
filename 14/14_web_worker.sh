```bash
#!/bin/bash
set -e
PROXY_IP="10.88.1.10"
DOMAIN="jujutsu.K-49.com"

echo "nameserver 192.168.122.1" > /etc/resolv.conf
apt-get update
apt-get install -y nginx php-fpm curl

PHPV=$(ls /etc/php | sort -V | tail -n1)
SOCK="/run/php/php${PHPV}-fpm.sock"

mkdir -p /var/www/web
cat > /var/www/web/index.php <<'EOF'
<?php
echo "<h1>Jujutsu High</h1>\n";
echo "<p>Served by: <b>" . gethostname() . "</b></p>\n";
EOF

cat > /etc/nginx/sites-available/web <<EOF
server {
    listen 80 default_server;
    server_name ${DOMAIN} www.${DOMAIN};
    root /var/www/web;
    index index.php;

    allow ${PROXY_IP};
    deny all;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${SOCK};
    }
}
EOF

ln -sf /etc/nginx/sites-available/web /etc/nginx/sites-enabled/web
rm -f /etc/nginx/sites-enabled/default
nginx -t
service php${PHPV}-fpm restart
service nginx restart

[ -f /root/init.sh ] || { echo '#!/bin/bash' > /root/init.sh; chmod +x /root/init.sh; }
grep -q "# soal14" /root/init.sh || cat >> /root/init.sh <<EOF
```