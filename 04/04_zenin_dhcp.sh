#!/bin/bash
set -e

# Step 1: initial DNS so apt can resolve package mirrors
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Step 2: bootstrap. No DHCP client is installed yet, so give eth0 a temporary address
# (outside the DHCP ranges) and a route through jichi, only if eth0 has none.
if ! ip -4 addr show dev eth0 | grep -q "inet "; then
    ip addr add 10.88.2.200/24 dev eth0
    ip route replace default via 10.88.2.1
fi

# Step 3: packages (ifupdown for /etc/network/interfaces, dhclient to ask for a lease)
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y ifupdown isc-dhcp-client

# Step 4: eth0 uses DHCP. hwaddress pins the MAC that tengen's pool class matches on,
# so it stays the same even if GNS3 resets the node (module: Implementasi section 8.3).
cat > /etc/network/interfaces <<'IFACES'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
    hwaddress ether 02:42:0c:37:22:00
IFACES

# Step 5: drop the temporary address, then ask for a lease (through the relay on jichi)
ifdown eth0 || true   # fails if ifupdown has no record of eth0 yet
ip addr flush dev eth0
ifup eth0
