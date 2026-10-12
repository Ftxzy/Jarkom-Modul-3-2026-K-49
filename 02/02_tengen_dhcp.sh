#!/bin/bash
set -e

# Step 1: initial DNS so apt can resolve package mirrors
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Step 2: give eth0 its final address and a route out through jichi (needed to reach apt)
ip addr show dev eth0 | grep -q "10.88.4.10/24" || ip addr add 10.88.4.10/24 dev eth0
ip route replace default via 10.88.4.1

# Step 3: packages. policy-rc.d stops apt from starting the server before it has a config
# (it would fail with "No subnet declaration" and break the install).
if [ ! -e /usr/sbin/policy-rc.d ]; then
    # the debinet image normally ships this file already; only create it if it is missing,
    # and remove it again even if the install fails (set -e would otherwise leave it behind)
    printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d
    chmod +x /usr/sbin/policy-rc.d
    trap "rm -f /usr/sbin/policy-rc.d" EXIT
fi
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y ifupdown isc-dhcp-server

# Step 4: keep the address after a restart (rewritten fully, so re-running is safe)
cat > /etc/network/interfaces <<'IFACES'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.88.4.10
    netmask 255.255.255.0
    gateway 10.88.4.1
IFACES

# Step 5: listen for DHCP requests on eth0 only (Network 4)
cat > /etc/default/isc-dhcp-server <<'DEFAULTS'
INTERFACESv4="eth0"
INTERFACESv6=""
DEFAULTS

# Step 6: DHCP configuration
cat > /etc/dhcp/dhcpd.conf <<'DHCPD'
default-lease-time 600;
max-lease-time 3600;
authoritative;

# Network 4: tengen's own network. Declared so dhcpd starts, but no pool: nothing is handed out here.
subnet 10.88.4.0 netmask 255.255.255.0 {
}

# Network 2 scope (reached through the relay on jichi)
subnet 10.88.2.0 netmask 255.255.255.0 {
    range 10.88.2.10 10.88.2.100;
    option routers 10.88.2.1;
}

# Network 3 scope (reached through the relay on jichi)
subnet 10.88.3.0 netmask 255.255.255.0 {
    range 10.88.3.10 10.88.3.100;
    option routers 10.88.3.1;
}
DHCPD

# Step 7: validate the config, then (re)start the service
dhcpd -t -cf /etc/dhcp/dhcpd.conf
service isc-dhcp-server restart
service isc-dhcp-server status
