#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
MASTER_IP=${1:?pakai: bash 13_inumaki_db.sh <IP yaga>}
REPL_USER='repl'; REPL_PASS='K49repl'

apt-get update -qq
apt-get install -y -qq mariadb-server

mkdir -p /var/log/mysql && chown mysql:mysql /var/log/mysql
cat > /etc/mysql/mariadb.conf.d/99-replication.cnf <<EOF
[mysqld]
bind-address = 0.0.0.0
skip-name-resolve
server-id    = 2
relay_log    = /var/log/mysql/relay-bin
read_only    = 1
EOF

service mariadb restart || service mysql restart
sleep 3

mysql <<EOF
STOP SLAVE;
RESET SLAVE ALL;
CHANGE MASTER TO
  MASTER_HOST='$MASTER_IP',
  MASTER_USER='$REPL_USER',
  MASTER_PASSWORD='$REPL_PASS',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=4;
START SLAVE;
EOF

sleep 3
mysql -e "SHOW SLAVE STATUS\G" | grep -E "Master_Host|Slave_IO_Running|Slave_SQL_Running|Seconds_Behind|Last_.*Error"
