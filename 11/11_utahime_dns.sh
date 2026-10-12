#!/bin/bash
set -e

# Usage: 11_utahime_dns.sh [setup|serial]
#   setup  (default) = install BIND9 and make utahime the master of jujutsu.K-49.com
#   serial           = add a test record (tengen) and raise the serial, to prove that shoko follows
MODE=${1:-setup}
if [ "$MODE" != "setup" ] && [ "$MODE" != "serial" ]; then
    echo "Usage: $0 [setup|serial]" >&2
    exit 1
fi
ZONEFILE=/etc/bind/jujutsu/jujutsu.K-49.com

if [ "$MODE" = "setup" ]; then
    # Step 1: initial DNS so apt can resolve package mirrors
    echo "nameserver 192.168.122.1" > /etc/resolv.conf

    # Step 2: give eth0 its final address and a route out through jichi (needed to reach apt)
    ip addr show dev eth0 | grep -q "10.88.1.2/24" || ip addr add 10.88.1.2/24 dev eth0
    ip route replace default via 10.88.1.1

    # Step 3: packages (ifupdown keeps the address after a restart, bind9 is the DNS server)
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y ifupdown bind9 bind9-utils

    # Step 4: keep the address after a restart (rewritten fully, so re-running is safe)
    cat > /etc/network/interfaces <<'IFACES'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.88.1.2
    netmask 255.255.255.0
    gateway 10.88.1.1
IFACES

    # Step 5: declare the zone as master. notify + also-notify tell shoko at once when the zone changes;
    # allow-transfer lets only shoko copy the zone (module: Modul 2/DNS section 2.6).
    cat > /etc/bind/named.conf.local <<'ZONES'
zone "jujutsu.K-49.com" {
    type master;
    file "/etc/bind/jujutsu/jujutsu.K-49.com";
    notify yes;
    also-notify { 10.88.1.3; };
    allow-transfer { 10.88.1.3; };
};
ZONES

    # Step 6: the zone file. Only created if missing, so re-running never resets the serial.
    mkdir -p /etc/bind/jujutsu
    if [ ! -f "$ZONEFILE" ]; then
        cat > "$ZONEFILE" <<'ZONEDATA'
$TTL    604800          ; default cache time (seconds)
@       IN      SOA     utahime.jujutsu.K-49.com. root.jujutsu.K-49.com. (
                        2026101201 ; serial (YYYYMMDDnn), raise it on every change
                        604800     ; refresh (1 week)
                        86400      ; retry (1 day)
                        2419200    ; expire (4 weeks)
                        604800 )   ; negative cache TTL
;
@       IN      NS      utahime.jujutsu.K-49.com.
@       IN      NS      shoko.jujutsu.K-49.com.
utahime IN      A       10.88.1.2
shoko   IN      A       10.88.1.3
ZONEDATA
    fi
    chown -R root:bind /etc/bind/jujutsu
    chmod 755 /etc/bind/jujutsu
    chmod 644 "$ZONEFILE"

    # Step 7: validate the config and the zone, then (re)start named
    named-checkconf
    named-checkzone jujutsu.K-49.com "$ZONEFILE"
    service named restart
    sleep 2
    pgrep -a -x named    # the init script's status is not trusted; check the process itself

    # Step 8: ask the new server about its own zone
    dig @127.0.0.1 jujutsu.K-49.com SOA +noall +comments +answer
else
    # serial mode: add the test record if missing, raise the serial by 1, validate, reload.
    # The reload makes named send NOTIFY to shoko, which then pulls the new zone.
    grep -q "^tengen" "$ZONEFILE" || echo "tengen  IN      A       10.88.4.10" >> "$ZONEFILE"
    OLD=$(awk '/; serial/{print $1; exit}' "$ZONEFILE")
    NEW=$((OLD + 1))
    sed -i "s/^\([[:space:]]*\)$OLD\([[:space:]]*; serial\)/\1$NEW\2/" "$ZONEFILE"
    named-checkzone jujutsu.K-49.com "$ZONEFILE"
    rndc reload jujutsu.K-49.com
    echo "serial raised: $OLD -> $NEW"
    dig @127.0.0.1 jujutsu.K-49.com SOA +noall +answer
fi
