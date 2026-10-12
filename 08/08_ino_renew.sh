#!/bin/bash
set -e

# Step 1: initial DNS (no package is installed in this script; kept for consistency)
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Step 2: release the lease and ask again, so the capture on tengen sees a full DISCOVER, OFFER, REQUEST, ACK.
# Start 08_tengen_capture.sh on tengen first.
ifdown eth0 || true   # fails if ifupdown has no record of eth0
ip addr flush dev eth0
ifup eth0
