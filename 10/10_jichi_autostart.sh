#!/bin/bash
set -e

# Step 1: initial DNS so apt can resolve package mirrors
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Step 2: packages (already installed from numbers 1 and 3; this keeps the script safe to run alone)
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y isc-dhcp-relay iptables

# Step 3: relay config (same as number 3), so the hook can start the relay
cat > /etc/default/isc-dhcp-relay <<'RELAY'
SERVERS="10.88.4.10"
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
RELAY

# Step 4: the boot hook. This image has no systemd, so nothing reads the /etc/rc2.d links.
# /etc/debinet-init.sh runs /root/init.sh at every start of the node, and /root is persistent.
# GNS3 has already run ifup -a (interfaces and the NAT rule on eth0) by then.
# IP forwarding is only a runtime setting here, so the hook turns it on again at every boot.
cat > /root/init.sh <<'INIT'
#!/bin/sh
{
    echo "===== $(date '+%F %T') boot hook (jichi) ====="
    # wait up to 30 s for eth2, eth3 and eth4 to have their gateway addresses
    i=0
    while [ $i -lt 30 ]; do
        n=$(ip -4 -br addr show | grep -cE "^eth[234] .*10\.88\.[234]\.1/24")
        [ "$n" -eq 3 ] && break
        i=$((i + 1))
        sleep 1
    done
    ip -4 -br addr show | grep -v "^lo"
    sysctl -w net.ipv4.ip_forward=1
    # NAT rule (also set by /etc/network/interfaces; -C checks first so it is never added twice)
    iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2> /dev/null || iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    # start the relay only if the process is not running. The init script's "status" only tests
    # whether the pid file exists, and a stale pid file survives a restart, so check the process itself.
    if ! pgrep -x dhcrelay > /dev/null; then
        rm -f /var/run/dhcrelay.pid
        service isc-dhcp-relay start
        sleep 1
    fi
    # last command: the hook ends with a failure if the relay is still not running
    pgrep -a -x dhcrelay
} >> /root/boot.log 2>&1
INIT
chmod +x /root/init.sh

# Step 5: run the hook once now to prove it works (it must end with the relay running)
/root/init.sh
tail -n 8 /root/boot.log
