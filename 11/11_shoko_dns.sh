#!/bin/bash
set -e

# Step 1: initial DNS so apt can resolve package mirrors
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Step 2: give eth0 its final address and a route out through jichi (needed to reach apt)
ip addr show dev eth0 | grep -q "10.88.1.3/24" || ip addr add 10.88.1.3/24 dev eth0
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
    address 10.88.1.3
    netmask 255.255.255.0
    gateway 10.88.1.1
IFACES

# Step 5: declare the zone as slave of utahime. The copy is stored in /var/cache/bind, the directory
# named is allowed to write to (module: Modul 2/DNS section 2.6 uses /etc/bind, which named cannot write).
cat > /etc/bind/named.conf.local <<'ZONES'
zone "jujutsu.K-49.com" {
    type slave;
    masters { 10.88.1.2; };
    file "/var/cache/bind/db.jujutsu.K-49.com";
    masterfile-format text;
};
ZONES

# Step 6: validate the config. BIND 9.20 stores a slave's copy in a binary format by default, so remove the old
# copy; named fetches a fresh one from utahime and now writes it as readable text.
named-checkconf
rm -f /var/cache/bind/db.jujutsu.K-49.com
service named restart
sleep 2
pgrep -a -x named    # the init script's status is not trusted; check the process itself

# Step 7: wait up to 30 s for the first zone transfer from utahime; fail if it never arrives
for i in $(seq 1 30); do
    [ -s /var/cache/bind/db.jujutsu.K-49.com ] && break
    sleep 1
done
[ -s /var/cache/bind/db.jujutsu.K-49.com ] || { echo "Zone was not transferred from utahime" >&2; exit 1; }
ls -l /var/cache/bind/db.jujutsu.K-49.com
cat /var/cache/bind/db.jujutsu.K-49.com
dig @127.0.0.1 jujutsu.K-49.com SOA +noall +comments +answer
