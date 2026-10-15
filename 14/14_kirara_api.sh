```bash
#!/bin/bash
set -e

hostname kirara
echo "nameserver 192.168.122.1" > /etc/resolv.conf

apt update
apt install -y nginx php-fpm php-mysql curl

PHPV=$(ls /etc/php/ | head -n1)
echo "Versi PHP: $PHPV"
service php${PHPV}-fpm restart

mkdir -p /var/www/api
cat > /var/www/api/index.php <<'EOF'
<?php
header('Content-Type: application/json');
mysqli_report(MYSQLI_REPORT_OFF);

$worker = gethostname();
$method = $_SERVER['REQUEST_METHOD'];
$uri    = $_SERVER['REQUEST_URI'];
$path   = parse_url($uri, PHP_URL_PATH);
$client = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'];

$db = @new mysqli('10.88.4.51', 'api', 'jarkom', 'db_shibuya_K-49');
if ($db->connect_errno) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'db' => $db->connect_error]);
    exit;
}

if ($path === '/logs') {
    $rows = [];
    $res = $db->query("SELECT id, worker, method, path, client_ip, created_at FROM request_logs ORDER BY id DESC LIMIT 10");
    while ($r = $res->fetch_assoc()) { $rows[] = $r; }
    echo json_encode(['status' => 'ok', 'worker' => $worker, 'logs' => $rows]);
    exit;
}

$st = $db->prepare("INSERT INTO request_logs (hostname, client_ip, request_uri, worker, method, path) VALUES (?,?,?,?,?,?)");
$st->bind_param('ssssss', $worker, $client, $uri, $worker, $method, $path);
$ok = $st->execute();

echo json_encode([
    'status' => $ok ? 'ok' : 'error',
    'worker' => $worker,
    'logged' => $ok,
    'method' => $method,
    'path'   => $path,
    'client' => $client,
]);
EOF

cat > /etc/nginx/sites-available/api <<'EOF'
server {
    listen 80 default_server;
    server_name _;
    return 444;
}

server {
    listen 80;
    server_name api.jujutsu.K-49.com;
    root /var/www/api;
    index index.php;

    location / {
        try_files $uri /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/phpPHPVER-fpm.sock;
    }
}
EOF
sed -i "s/PHPVER/$PHPV/" /etc/nginx/sites-available/api

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/api /etc/nginx/sites-enabled/api
nginx -t
service nginx restart

echo "===== TES 1: kirim request ke API (harus status ok, worker kirara) ====="
curl -H "Host: api.jujutsu.K-49.com" http://127.0.0.1/ping
echo
echo "===== TES 2: lihat log terakhir dari database yaga ====="
curl -H "Host: api.jujutsu.K-49.com" http://127.0.0.1/logs
echo
echo "===== TES 3: tanpa domain (harus ditolak/kosong) ====="
curl -i http://127.0.0.1 || true
```