#!/bin/bash
set -e

# Step 1: initial DNS so apt can resolve package mirrors
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Step 2: packages. policy-rc.d stops apt from starting the relay before it has a config.
if [ ! -e /usr/sbin/policy-rc.d ]; then
    # the debinet image normally ships this file already; only create it if it is missing,
    # and remove it again even if the install fails (set -e would otherwise leave it behind)
    printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d
    chmod +x /usr/sbin/policy-rc.d
    trap "rm -f /usr/sbin/policy-rc.d" EXIT
fi
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y isc-dhcp-relay

# Step 3: relay config. SERVERS = the DHCP server (tengen). INTERFACES = eth2/eth3 face the
# clients, eth4 faces tengen (module: Implementasi section 5.2).
cat > /etc/default/isc-dhcp-relay <<'RELAY'
SERVERS="10.88.4.10"
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
RELAY

# Step 4: the relay is a router function, so forwarding must stay on
sysctl -w net.ipv4.ip_forward=1

# Step 5: (re)start and show status
service isc-dhcp-relay restart
service isc-dhcp-relay status
pgrep -a -x dhcrelay   # status only checks the pid file; this checks the process
