#!/bin/bash
set -e

# Step 1: initial DNS (no package is installed in this script; kept for consistency)
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Step 2: pin the MAC that tengen's lease class matches on (miwa already has ifupdown/dhclient)
cat > /etc/network/interfaces <<'IFACES'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
    hwaddress ether 02:42:de:56:8b:00
IFACES

# Step 3: release the old lease and ask again, so miwa lands in the long lease pool
ifdown eth0 || true   # fails if ifupdown has no record of eth0
ip addr flush dev eth0
ifup eth0
