```bash
#!/bin/bash
echo "nameserver 192.168.122.1" > /etc/resolv.conf
apt-get update
apt-get install -y nginx

rm -f /etc/nginx/sites-enabled/default

cat > /etc/nginx/sites-available/api-lb <<'EOT'
upstream api_cluster {
    server 10.88.4.41 weight=3 max_fails=2 fail_timeout=5s;   # nanami
    server 10.88.4.42 weight=1 max_fails=2 fail_timeout=5s;   # todo
    server 10.88.4.43 backup;                                 # kirara
}
server {
    listen 80 default_server;
    server_name jujutsu.K-49.com www.jujutsu.K-49.com;

    location /api {
        proxy_pass http://api_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOT

ln -sf /etc/nginx/sites-available/api-lb /etc/nginx/sites-enabled/api-lb
nginx -t && (service nginx start || nginx -s reload)

grep -q "service nginx start" /root/init.sh 2>/dev/null || echo "service nginx start" >> /root/init.sh
```