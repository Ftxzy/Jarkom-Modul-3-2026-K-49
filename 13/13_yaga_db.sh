#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
DB='db_shibuya_K-49'
APP_USER='jujutsu'; APP_PASS='K49app'
REPL_USER='repl';   REPL_PASS='K49repl'
MYIP=$(ip -4 -o addr show eth0 | awk '{print $4}' | cut -d/ -f1)

apt-get update -qq
apt-get install -y -qq mariadb-server

mkdir -p /var/log/mysql && chown mysql:mysql /var/log/mysql
cat > /etc/mysql/mariadb.conf.d/99-replication.cnf <<EOF
[mysqld]
bind-address = 0.0.0.0
skip-name-resolve
server-id    = 1
log_bin      = /var/log/mysql/mysql-bin
EOF

service mariadb restart || service mysql restart
sleep 3

mysql <<EOF
CREATE DATABASE IF NOT EXISTS \`$DB\`;
CREATE TABLE IF NOT EXISTS \`$DB\`.request_logs (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  hostname    VARCHAR(64),
  client_ip   VARCHAR(45),
  request_uri VARCHAR(255),
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE USER IF NOT EXISTS '$APP_USER'@'10.88.4.%' IDENTIFIED BY '$APP_PASS';
GRANT ALL PRIVILEGES ON \`$DB\`.* TO '$APP_USER'@'10.88.4.%';
CREATE USER IF NOT EXISTS '$REPL_USER'@'10.88.4.%' IDENTIFIED BY '$REPL_PASS';
GRANT REPLICATION SLAVE ON *.* TO '$REPL_USER'@'10.88.4.%';
FLUSH PRIVILEGES;
EOF

echo "=== yaga: $MYIP ==="
mysql -e "SHOW MASTER STATUS;"
mysql -e "SHOW DATABASES; SHOW TABLES FROM \`$DB\`;"
echo ">>> Di inumaki jalankan:  bash /root/13_inumaki_db.sh $MYIP"
