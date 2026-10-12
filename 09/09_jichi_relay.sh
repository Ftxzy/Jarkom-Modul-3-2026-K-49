#!/bin/bash
set -e

# Usage: 09_jichi_relay.sh stop|start
#   stop  = simulate the outage (relay service down)
#   start = restore the relay service
ACTION=${1:-}
if [ "$ACTION" != "stop" ] && [ "$ACTION" != "start" ]; then
    echo "Usage: $0 stop|start" >&2
    exit 1
fi

# Step 1: initial DNS so apt can resolve package mirrors
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Step 2: package (already installed from number 3; this keeps the script safe to run alone)
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y isc-dhcp-relay

if [ "$ACTION" = "stop" ]; then
    # Step 3a: stop the relay. Stopping a service that is not running fails, which is fine here.
    service isc-dhcp-relay stop || true
    # the init script only sends the stop signal and returns, so wait for the process to exit (up to 10 s)
    for i in 1 2 3 4 5 6 7 8 9 10; do
        pgrep dhcrelay > /dev/null || break
        sleep 1
    done
    if pgrep dhcrelay > /dev/null; then
        echo "dhcrelay is still running" >&2
        exit 1
    fi
    echo "Relay is DOWN. Clients on Network 2 and 3 can no longer reach tengen."
    service isc-dhcp-relay status || true   # status exits non-zero when the service is not running
else
    # Step 3b: restore the relay with the same config as number 3, then it must be running
    cat /etc/default/isc-dhcp-relay
    sysctl -w net.ipv4.ip_forward=1
    service isc-dhcp-relay restart
    service isc-dhcp-relay status
    pgrep -a dhcrelay
    echo "Relay is UP again."
fi
