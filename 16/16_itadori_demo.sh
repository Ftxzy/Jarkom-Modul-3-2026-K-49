```bash
#!/bin/bash
ip addr flush dev eth0
ip addr add 10.88.2.12/24 dev eth0
ip route add default via 10.88.2.1
printf "nameserver 10.88.1.2\nnameserver 10.88.1.3\n" > /etc/resolv.conf
which curl >/dev/null || apt install -y curl || apk add curl
clear
ip -4 a show eth0 | grep inet; ip r | grep default
echo "== DNS"
getent hosts jujutsu.K-49.com
echo "== WEB / (harus maki dan panda bergantian)"
for i in 1 2 3 4 5 6; do curl -s http://jujutsu.K-49.com/ | grep -o "panda\|maki"; done
echo "== WEB www"
curl -s http://www.jujutsu.K-49.com/ | grep -o "panda\|maki"
echo "== API /api (harus nanami / todo)"
for i in 1 2 3 4 5 6 7 8; do curl -s http://jujutsu.K-49.com/api | grep -o '"worker":"[a-z]*"'; done
```