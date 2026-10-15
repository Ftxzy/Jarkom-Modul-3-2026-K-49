```bash
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
GETO_IP=${1:-10.88.4.20}
DB_HOST=10.88.4.51

apt-get update -qq
apt-get install -y -qq nginx php-fpm php-mysql curl

FPM_SVC=$(basename $(ls /etc/init.d/php*-fpm | head -n1))
service $FPM_SVC restart
sleep 2
SOCK=$(ls /run/php/php*-fpm.sock | head -n1)

mkdir -p /var/www/api
cat > /var/www/api/index.php <<'EOF'
<?php
header('Content-Type: application/json');
mysqli_report(MYSQLI_REPORT_OFF);
$host = gethostname();
$ip = $_SERVER['REMOTE_ADDR'];
if (!empty($_SERVER['HTTP_X_REAL_IP']) && filter_var($_SERVER['HTTP_X_REAL_IP'], FILTER_VALIDATE_IP)) {
    $ip = $_SERVER['HTTP_X_REAL_IP'];
}
$uri = $_SERVER['REQUEST_URI'];
$logged = false;
$db = @new mysqli('__DB__', 'jujutsu', 'K49app', 'db_shibuya_K-49');
if (!$db->connect_errno) {
    $st = $db->prepare("INSERT INTO request_logs (hostname, client_ip, request_uri) VALUES (?,?,?)");
    $st->bind_param('sss', $host, $ip, $uri);
    $logged = $st->execute();
}
echo json_encode(['service' => 'api', 'hostname' => $host, 'client_ip' => $ip, 'logged' => $logged]);
EOF
sed -i "s#__DB__#$DB_HOST#" /var/www/api/index.php
chown -R www-data:www-data /var/www/api

rm -f /etc/nginx/sites-enabled/default
cat > /etc/nginx/sites-available/api <<'EOF'
server {
    listen 80 default_server;
    server_name jujutsu.K-49.com www.jujutsu.K-49.com;

    # hanya geto yang boleh masuk
    allow __GETO__;
    allow 127.0.0.1;
    deny all;

    location /api {
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME /var/www/api/index.php;
        fastcgi_pass unix:__SOCK__;
    }
}
EOF
sed -i "s#__GETO__#$GETO_IP#; s#__SOCK__#$SOCK#" /etc/nginx/sites-available/api
ln -sf /etc/nginx/sites-available/api /etc/nginx/sites-enabled/api

nginx -t
service nginx restart
sleep 1
echo "=== $(hostname): $(ip -4 -o addr show eth0 | awk '{print $4}' | cut -d/ -f1) ==="
curl -s http://127.0.0.1/api
```