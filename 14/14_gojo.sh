```bash
#!/bin/bash
echo "nameserver 192.168.122.1" > /etc/resolv.conf
apt-get update
apt-get install -y nginx

rm -f /etc/nginx/sites-enabled/default

cat > /etc/nginx/sites-available/web-proxy <<'EOT'
upstream web_workers {
    server 10.88.4.31;   # maki
    server 10.88.4.32;   # panda
}
server {
    listen 80 default_server;
    server_name jujutsu.K-49.com www.jujutsu.K-49.com;

    location / {
        proxy_pass http://web_workers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    location /api {
        proxy_pass http://10.88.4.20;   # geto
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOT

ln -sf /etc/nginx/sites-available/web-proxy /etc/nginx/sites-enabled/web-proxy
nginx -t && (service nginx start || nginx -s reload)

grep -q "service nginx start" /root/init.sh 2>/dev/null || echo "service nginx start" >> /root/init.sh
```