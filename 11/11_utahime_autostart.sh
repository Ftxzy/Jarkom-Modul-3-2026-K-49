#!/bin/bash
set -e

# Step 1: initial DNS so apt can resolve package mirrors
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Step 2: package (already installed by the DNS setup script; this keeps the script safe to run alone)
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9-utils

# Step 3: the boot hook. This image has no systemd, so nothing starts named at boot.
# /etc/debinet-init.sh runs /root/init.sh at every start of the node, and /root is persistent.
# GNS3 has already brought eth0 up from /etc/network/interfaces by then.
cat > /root/init.sh <<'INIT'
#!/bin/sh
{
    echo "===== $(date '+%F %T') boot hook (utahime) ====="
    # wait up to 30 s for eth0 to have its address
    i=0
    while [ $i -lt 30 ]; do
        ip -4 addr show dev eth0 | grep -q "10.88.1.2/24" && break
        i=$((i + 1))
        sleep 1
    done
    ip -4 -br addr show dev eth0
    # start named only if the process is not running. Do not trust "service status": check the process,
    # and remove a stale pid file left from before the restart.
    if ! pgrep -x named > /dev/null; then
        rm -f /var/run/named/named.pid
        service named start
        sleep 2
    fi
    # last command: the hook ends with a failure if named is still not running
    pgrep -a -x named
} >> /root/boot.log 2>&1
INIT
chmod +x /root/init.sh

# Step 4: validate the DNS config, run the hook once now to prove it works, and show the log
named-checkconf
/root/init.sh
tail -n 5 /root/boot.log
