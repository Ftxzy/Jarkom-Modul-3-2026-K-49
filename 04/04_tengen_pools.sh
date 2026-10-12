#!/bin/bash
set -e

# Step 1: initial DNS so apt can resolve package mirrors
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Step 2: package (already installed from the earlier setup; this keeps the script safe to run alone)
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y isc-dhcp-server

# Step 3: DHCP configuration (rewritten fully, so re-running is safe)
cat > /etc/dhcp/dhcpd.conf <<'DHCPD'
default-lease-time 600;
max-lease-time 3600;
authoritative;

# Client groups on Network 2, matched by MAC address (hardware type 1 = ethernet)
class "pool1" {
    match hardware;
}
subclass "pool1" 1:02:42:11:d9:ac:00;   # itadori
subclass "pool1" 1:02:42:96:46:1f:00;   # fushiguro

class "pool2" {
    match hardware;
}
subclass "pool2" 1:02:42:0c:37:22:00;   # zenin
subclass "pool2" 1:02:42:17:4d:fe:00;   # okkotsu

# Network 4: tengen's own network. Declared so dhcpd starts, but no pool: nothing is handed out here.
subnet 10.88.4.0 netmask 255.255.255.0 {
}

# Network 2: two pools, each only for its own class. 10.88.2.36 - 10.88.2.69 is never handed out.
subnet 10.88.2.0 netmask 255.255.255.0 {
    option routers 10.88.2.1;

    pool {
        allow members of "pool1";
        range 10.88.2.10 10.88.2.35;
    }

    pool {
        allow members of "pool2";
        range 10.88.2.70 10.88.2.95;
    }
}

# Network 3 scope (reached through the relay on jichi)
subnet 10.88.3.0 netmask 255.255.255.0 {
    range 10.88.3.10 10.88.3.100;
    option routers 10.88.3.1;
}
DHCPD

# Step 4: validate the config, then restart the service
dhcpd -t -cf /etc/dhcp/dhcpd.conf
service isc-dhcp-server restart
service isc-dhcp-server status
