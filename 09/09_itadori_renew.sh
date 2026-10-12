#!/bin/bash
set -e
set -o pipefail

# Usage: 09_itadori_renew.sh outage|restore
#   outage  = ask for a lease while the relay is down; failing to get one is the expected symptom
#   restore = ask for a lease after the relay is back; this must succeed
MODE=${1:-}
if [ "$MODE" != "outage" ] && [ "$MODE" != "restore" ]; then
    echo "Usage: $0 outage|restore" >&2
    exit 1
fi
LOG=/root/09_itadori_${MODE}.log

# Step 1: initial DNS (no package is installed in this script; kept for consistency)
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Step 2: release the old lease and drop the address, then ask again. Everything is logged to $LOG.
{
    echo "===== $(date '+%F %T') mode=$MODE ====="
    ifdown eth0 || true   # fails if ifupdown has no record of eth0
    ip addr flush dev eth0
    if [ "$MODE" = "outage" ]; then
        # dhclient gives up after about a minute without an offer; that failure is the symptom we want to log
        ifup eth0 || echo "RESULT: no lease obtained (expected while the relay is down)"
    else
        ifup eth0
    fi
    echo "----- ip -4 a show eth0 -----"
    ip -4 a show eth0
    echo "----- ip route -----"
    ip route
} 2>&1 | tee "$LOG"
echo "Log saved to $LOG"
