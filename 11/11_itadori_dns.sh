#!/bin/bash
set -e

# Usage: 11_itadori_dns.sh [extra-name]     e.g. 11_itadori_dns.sh tengen.jujutsu.K-49.com
EXTRA=${1:-}
ZONE=jujutsu.K-49.com
MASTER=10.88.1.2
SLAVE=10.88.1.3

# Step 1: install dig if it is missing. apt needs a working DNS, so use the initial DNS and then
# put back the resolv.conf that DHCP gave this client.
if ! command -v dig > /dev/null; then
    cp -f /etc/resolv.conf /root/resolv.conf.saved
    echo "nameserver 192.168.122.1" > /etc/resolv.conf
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y bind9-dnsutils
    cp -f /root/resolv.conf.saved /etc/resolv.conf
fi

# Step 2: ask both servers the same questions. In the SOA answer look at the flags ("aa" = authoritative
# answer) and compare the serial. NS and A answers are printed short.
hdr()   { dig @"$1" "$2" "$3" +norecurse +time=3 +tries=1 +noall +comments +answer +authority | grep -E "^;; (->>HEADER|flags)|[[:space:]]IN[[:space:]]" || echo "no answer from $1"; }
short() { dig @"$1" "$2" "$3" +norecurse +time=3 +tries=1 +short; }
for SERVER in $MASTER $SLAVE; do
    echo "===== @$SERVER ====="
    echo "--- SOA of $ZONE";     hdr $SERVER $ZONE SOA
    echo "--- NS of $ZONE";      short $SERVER $ZONE NS
    echo "--- A of utahime";     short $SERVER utahime.$ZONE A
    echo "--- A of shoko";       short $SERVER shoko.$ZONE A
    if [ -n "$EXTRA" ]; then
        echo "--- A of $EXTRA";  hdr $SERVER $EXTRA A
    fi
done

# Step 3: a client must not be able to copy the zone; only the slave is allowed to
echo "===== zone transfer requested from this client (must be refused) ====="
dig @$MASTER $ZONE AXFR +time=3 +tries=1 || true   # expected to fail: allow-transfer only lists shoko
