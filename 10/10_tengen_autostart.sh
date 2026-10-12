#!/bin/bash
set -e

# Step 1: initial DNS so apt can resolve package mirrors
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Step 2: package (already installed from number 2; this keeps the script safe to run alone)
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y isc-dhcp-server

# Step 3: make sure the server listens on eth0 (same as number 2), so it can start from the boot hook
cat > /etc/default/isc-dhcp-server <<'DEFAULTS'
INTERFACESv4="eth0"
INTERFACESv6=""
DEFAULTS

# Step 4: the boot hook. This image has no systemd, so nothing reads the /etc/rc2.d links.
# /etc/debinet-init.sh runs /root/init.sh at every start of the node, and /root is persistent.
# GNS3 has already brought eth0 up from /etc/network/interfaces by then.
cat > /root/init.sh <<'INIT'
#!/bin/sh
{
    echo "===== $(date '+%F %T') boot hook (tengen) ====="
    # wait up to 30 s for eth0 to have its address
    i=0
    while [ $i -lt 30 ]; do
        ip -4 addr show dev eth0 | grep -q "10.88.4.10/24" && break
        i=$((i + 1))
        sleep 1
    done
    ip -4 -br addr show dev eth0
    # start the DHCP server only if it is not already running
    service isc-dhcp-server status > /dev/null 2>&1 || service isc-dhcp-server start
    service isc-dhcp-server status
} >> /root/boot.log 2>&1
INIT
chmod +x /root/init.sh

# Step 5: validate the config, then run the hook once now to prove it works (it must end with the service running)
dhcpd -t -cf /etc/dhcp/dhcpd.conf
/root/init.sh
tail -n 6 /root/boot.log
