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

# Options sent to every client: the two DNS servers in the DMZ and the search domain
option domain-name-servers 10.88.1.2, 10.88.1.3;
option domain-search "K-49.com";

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

# Client groups on Network 3, matched by MAC address
class "short-lease" {
    match hardware;
}
subclass "short-lease" 1:f2:dd:ec:51:c9:cb;   # ino
subclass "short-lease" 1:02:42:c1:a0:d0:00;   # kusakabe

class "long-lease" {
    match hardware;
}
subclass "long-lease" 1:02:42:de:56:8b:00;    # miwa

# Network 4: tengen's own network. Declared so dhcpd starts, but no pool: nothing is handed out here.
subnet 10.88.4.0 netmask 255.255.255.0 {
}

# Network 2: two pools, each only for its own class. 10.88.2.36 - 10.88.2.69 is never handed out.
subnet 10.88.2.0 netmask 255.255.255.0 {
    option routers 10.88.2.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.88.2.255;

    pool {
        allow members of "pool1";
        range 10.88.2.10 10.88.2.35;
    }

    pool {
        allow members of "pool2";
        range 10.88.2.70 10.88.2.95;
    }
}

# Network 3: short lease pool (30 minutes) and long lease pool (12 hours)
subnet 10.88.3.0 netmask 255.255.255.0 {
    option routers 10.88.3.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.88.3.255;

    pool {
        allow members of "short-lease";
        range 10.88.3.10 10.88.3.89;
        default-lease-time 1800;
        max-lease-time 1800;
    }

    pool {
        allow members of "long-lease";
        range 10.88.3.100 10.88.3.199;
        default-lease-time 43200;
        max-lease-time 43200;
    }
}
# Static lease: kugisaki always gets 10.88.3.99, matched by its MAC address.
# It is outside both Network 3 pools (short .10-.89, long .100-.199).
host kugisaki {
    hardware ethernet 02:42:2e:c0:2b:00;
    fixed-address 10.88.3.99;
}
DHCPD

# Step 4: validate the config, then restart the service
dhcpd -t -cf /etc/dhcp/dhcpd.conf
service isc-dhcp-server restart
service isc-dhcp-server status
