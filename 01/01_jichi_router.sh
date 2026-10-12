#!/bin/bash
set -e

# Step 1: initial DNS so apt can resolve package mirrors
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Step 2: bootstrap eth0. No DHCP client is installed yet, so without an address
# apt cannot download one. Give eth0 a temporary NAT address only if it has none.
if ! ip -4 addr show dev eth0 | grep -q "inet "; then
    ip addr add 192.168.122.10/24 dev eth0
    ip route replace default via 192.168.122.1
fi

# Step 3: packages (ifupdown reads /etc/network/interfaces, dhclient lets eth0 ask the NAT for an address,
# iptables does the NAT)
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y ifupdown isc-dhcp-client iptables

# Step 4: enable IPv4 forwarding now and persistently
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-forward.conf

# Step 5: persistent interface config (rewritten fully, so re-running is safe)
cat > /etc/network/interfaces <<'IFACES'
auto lo
iface lo inet loopback

# WAN side: address comes from the NAT node via DHCP
auto eth0
iface eth0 inet dhcp
    # Masquerade everything leaving eth0 (-C checks first, so no duplicate rule)
    post-up iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE || iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# LAN side: jichi is the gateway of each network
auto eth1
iface eth1 inet static
    address 10.88.1.1
    netmask 255.255.255.0

auto eth2
iface eth2 inet static
    address 10.88.2.1
    netmask 255.255.255.0

auto eth3
iface eth3 inet static
    address 10.88.3.1
    netmask 255.255.255.0

auto eth4
iface eth4 inet static
    address 10.88.4.1
    netmask 255.255.255.0
IFACES

# Step 6: apply the config. Flush first so the temporary eth0 address and any old
# addresses do not stay next to the new ones.
for i in eth0 eth1 eth2 eth3 eth4; do
    ifdown $i || true   # fails if ifupdown has no record of this interface yet
    ip addr flush dev $i
    ifup $i
done

# Step 7: make sure the NAT rule exists right now
iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE || iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
