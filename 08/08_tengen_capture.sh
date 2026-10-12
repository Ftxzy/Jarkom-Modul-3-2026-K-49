#!/bin/bash
set -e

# Usage: 08_tengen_capture.sh [client-MAC] [seconds]   (seconds = 0: do not capture, only re-read the saved file)
#   Network 2 sample (itadori): 02:42:11:d9:ac:00   Network 3 sample (ino): f2:dd:ec:51:c9:cb
MAC=${1:-02:42:11:d9:ac:00}
DURATION=${2:-40}
PCAP=/root/dhcp-${MAC//:/}.pcap

# Step 1: initial DNS so apt can resolve package mirrors
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Step 2: package (tcpdump is already installed; this keeps the script safe to run alone)
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y tcpdump

# Step 3: build a filter that keeps only DHCP packets whose client hardware address (chaddr) is $MAC.
# chaddr starts 28 bytes into the BOOTP payload, i.e. byte 36 of the UDP packet, so this matches
# the client's packets even after jichi has relayed them.
if ! [[ $MAC =~ ^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$ ]]; then
    echo "Bad MAC address: $MAC" >&2
    exit 1
fi
HEX=${MAC//:/}
FILTER="udp and (port 67 or port 68) and udp[36:4] = 0x${HEX:0:8} and udp[40:2] = 0x${HEX:8:4}"

# Step 4: capture for $DURATION seconds. Start the lease renewal on the client now.
if [ "$DURATION" -gt 0 ]; then
    echo "Capturing DHCP for $MAC on eth0 for $DURATION seconds."
    echo ">>> On the client run: ifdown eth0; ifup eth0"
    rc=0
    timeout "$DURATION" tcpdump -n -i eth0 -s 0 -U -w "$PCAP" "$FILTER" 2>/dev/null || rc=$?
    if [ "$rc" -ne 0 ] && [ "$rc" -ne 124 ]; then   # 124 = timeout stopped tcpdump on purpose
        echo "tcpdump failed (exit $rc)" >&2
        exit "$rc"
    fi
fi
if [ ! -f "$PCAP" ]; then
    echo "No saved capture $PCAP. Run again with a capture time." >&2
    exit 1
fi

# Step 5: show the result. Full decode first, then a one-line-per-packet summary.
COUNT=$(tcpdump -n -r "$PCAP" 2>/dev/null | wc -l)
if [ "$COUNT" -eq 0 ]; then
    echo "No DHCP packets seen for $MAC. Renew the lease on the client while the capture is running." >&2
    exit 1
fi
echo "===== FULL DECODE ($COUNT packets) ====="
tcpdump -n -r "$PCAP" -vvv 2>/dev/null
echo "===== SUMMARY (one line per packet) ====="
# giaddr is printed by tcpdump as Gateway-IP; yiaddr (the address given) as Your-IP
tcpdump -n -r "$PCAP" -vvv 2>/dev/null | awk '
function flush() { if (t != "") printf "%-15s %-27s %-9s xid=%-10s yiaddr=%-12s giaddr=%-10s server-id=%-10s lease=%s\n", t, ad, ty, xid, yi, gi, sid, ls }
/^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]\.[0-9]+ IP / { flush(); t=$1; ad=""; ty=""; xid=""; yi="-"; gi="0.0.0.0"; sid="-"; ls="-"; next }
/BOOTP\/DHCP/ { ad=$1" > "$3; sub(/:$/,"",ad); for (i=1;i<=NF;i++) if ($i=="xid") { xid=$(i+1); sub(/,$/,"",xid) } next }
/Your-IP/      { yi=$2; next }
/Gateway-IP/   { gi=$2; next }
/DHCP-Message \(53\)/ { ty=$NF; next }
/Server-ID \(54\)/    { sid=$NF; next }
/Lease-Time \(51\)/   { ls=$NF; next }
END { flush() }'
