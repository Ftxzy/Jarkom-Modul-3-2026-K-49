# PRAKTIKUM JARKOM MODUL 3 KELOMPOK K-49 - 2026

## Anggota Kelompok

| Nama | NRP | Dikerjakan |
| ---- | --- | ---------- |
| Khalifa Suryadinarta | 5027251104 | Soal 1 sampai 11 |
|  |  |  |

> Ini laporan sementara, baru sampai soal 11. Baris kosong di tabel atas dan bagian [Bagian Anggota Kedua](#bagian-anggota-kedua) di paling bawah disiapkan untuk pengerjaan teman satu kelompok (soal 12 dan seterusnya).

## Topologi

![Topologi GNS3](topology/topologi-gns3.png)

`jichi` adalah router di tengah. `eth0` ke NAT, sedangkan `eth1` sampai `eth4` masing-masing ke satu jaringan. Semua node memakai image `ardhptr21/debinet:latest`.

### Pemetaan jaringan

| Jaringan | Interface `jichi` | Subnet | Gateway | Isi |
| -------- | ----------------- | ------ | ------- | --- |
| WAN | `eth0` | `192.168.122.0/24` | `192.168.122.1` | alamat dari NAT (DHCP) |
| 1 (DMZ) | `eth1` | `10.88.1.0/24` | `10.88.1.1` | `utahime` `.2` dan `shoko` `.3` (statis), `gojo` |
| 2 (Divisi A) | `eth2` | `10.88.2.0/24` | `10.88.2.1` | `itadori`, `fushiguro` (pool 1), `zenin`, `okkotsu` (pool 2) |
| 3 (Divisi B) | `eth3` | `10.88.3.0/24` | `10.88.3.1` | `ino`, `kusakabe` (short lease), `miwa` (long lease), `kugisaki` (fixed `.99`) |
| 4 (Data Center) | `eth4` | `10.88.4.0/24` | `10.88.4.1` | `tengen` `.10` (statis), `geto`, para worker, database |

Prefix IP kelompok kami `10.88`, grup `K-49`, domain `K-49.com`, subnet mask `/24` di semua jaringan.

### Console tiap node

Akses lewat `telnet 10.4.89.250:<port>` (jaringan atau VPN ITS).

| Node | Port | Node | Port | Node | Port |
| ---- | ---- | ---- | ---- | ---- | ---- |
| `jichi` | 5027 | `utahime` | 5099 | `geto` | 5104 |
| `tengen` | 5110 | `shoko` | 5098 | `maki` | 5105 |
| `itadori` | 5100 | `gojo` | 5097 | `panda` | 5106 |
| `fushiguro` | 5101 | `ino` | 5113 | `nanami` | 5107 |
| `zenin` | 5102 | `kusakabe` | 5114 | `todo` | 5108 |
| `okkotsu` | 5103 | `miwa` | 5116 | `kirara` | 5109 |
| `yaga` | 5111 | `kugisaki` | 5115 | `inumaki` | 5112 |

### Kebijakan DHCP di `tengen` (kondisi akhir)

| Kelompok | Client | Rentang | Lease (default / max) |
| -------- | ------ | ------- | --------------------- |
| Pool 1 | `itadori`, `fushiguro` | `10.88.2.10` - `10.88.2.35` | 600 s / 3600 s |
| Pool 2 | `zenin`, `okkotsu` | `10.88.2.70` - `10.88.2.95` | 600 s / 3600 s |
| Tidak boleh dipakai |  | `10.88.2.36` - `10.88.2.69` |  |
| Short lease | `ino`, `kusakabe` | `10.88.3.10` - `10.88.3.89` | 1800 s / 1800 s |
| Long lease | `miwa` | `10.88.3.100` - `10.88.3.199` | 43200 s / 43200 s |
| Fixed | `kugisaki` | `10.88.3.99` (di luar semua pool) | berdasarkan MAC `02:42:2e:c0:2b:00` |

Semua client juga menerima: mask `255.255.255.0`, gateway (`10.88.2.1` atau `10.88.3.1`), broadcast (`10.88.2.255` atau `10.88.3.255`), DNS `10.88.1.2` dan `10.88.1.3`, serta domain-search `K-49.com`.

## Status pengerjaan

| Soal | Isi | Node | Status |
| ---- | --- | ---- | ------ |
| [1](#soal-1) | Router, NAT, forwarding | `jichi` | `jichi` terbukti. Ping tiap host ke gateway ditunjukkan saat demo |
| [2](#soal-2) | DHCP server | `tengen` | Selesai |
| [3](#soal-3) | DHCP relay | `jichi`, client | Selesai |
| [4](#soal-4) | Dua pool di Network 2 | `tengen`, client | Selesai |
| [5](#soal-5) | Lease time dan DHCP option | `tengen`, client | Selesai |
| [6](#soal-6) | Fixed address `kugisaki` | `tengen`, `kugisaki` | Selesai |
| [7](#soal-7) | Pengecekan konfigurasi semua client | `tengen`, client | Selesai |
| [8](#soal-8) | Packet capture DHCP | `tengen` | Selesai |
| [9](#soal-9) | Relay mati lalu dipulihkan | `jichi`, `itadori` | Selesai |
| [10](#soal-10) | Bertahan setelah restart | `tengen`, `jichi` | Server terbukti. Pengecekan client ditunjukkan saat demo |
| [11](#soal-11) | DNS master dan slave | `utahime`, `shoko` | Selesai |
| 12 dst. |  |  | Teman satu kelompok |

## Panduan mengecek hasil

### 1. Menaruh script di node

Semua script ditaruh di `/root` pada node yang dikonfigurasi. Dari komputer yang bisa menjangkau host GNS3:

```bash
tools/push-script.sh 01/01_jichi_router.sh 5027    # salin ke /root/01_jichi_router.sh lalu cocokkan checksum
```

Atau tempel langsung di console node:

```bash
cat > /root/01_jichi_router.sh <<'EOF'
# isi script
EOF
chmod +x /root/01_jichi_router.sh
```

Setiap script diawali `#!/bin/bash` dan `set -e`, memasang paket yang dibutuhkan lebih dulu (pakai DNS `192.168.122.1`), aman dijalankan dua kali, dan berhenti kalau ada langkah penting yang gagal. Komentar di dalam script memakai bahasa Inggris.

### 2. Urutan menjalankan

Script server bersifat kumulatif: `04`, `05`, `06`, dan `07` masing-masing menulis ulang seluruh `dhcpd.conf`, jadi konfigurasi akhir ada di `07_tengen_options.sh`. Kalau mau membangun dari awal, jalankan berurutan seperti ini (script client dijalankan di client yang namanya tertulis di file):

| Langkah | Node | Script | Hasil yang diharapkan |
| ------- | ---- | ------ | --------------------- |
| 1 | `jichi` | `01/01_jichi_router.sh` | `eth0` dari NAT, `eth1`-`eth4` = `10.88.N.1/24`, forwarding aktif, aturan NAT |
| 2 | `tengen` | `02/02_tengen_dhcp.sh` | `10.88.4.10/24`, `dhcpd` berjalan |
| 3 | `jichi` | `03/03_jichi_relay.sh` | `dhcrelay` berjalan menuju `10.88.4.10` |
| 4 | `tengen` | `04/04_tengen_pools.sh` | pool dan class MAC untuk Network 2 |
| 5 | `itadori`, `fushiguro`, `zenin` | `04/04_<node>_dhcp.sh` | client DHCP siap, dapat alamat dari pool-nya |
| 6 | `okkotsu` | `03/03_okkotsu_dhcp.sh`, lalu `04/04_okkotsu_renew.sh` | alamat dari pool 2 |
| 7 | `tengen` | `05/05_tengen_leases.sh` | pool short dan long lease, option DNS |
| 8 | `ino`, `kusakabe` | `05/05_<node>_dhcp.sh` | short lease |
| 9 | `miwa` | `03/03_miwa_dhcp.sh`, lalu `05/05_miwa_renew.sh` | long lease |
| 10 | `tengen` | `06/06_tengen_fixed.sh` | menambah reservasi `kugisaki` |
| 11 | `kugisaki` | `06/06_kugisaki_dhcp.sh` | dapat `10.88.3.99` |
| 12 | `tengen` | `07/07_tengen_options.sh` | menambah option mask dan broadcast (konfigurasi akhir) |
| 13 | `tengen`, `jichi` | `10/10_tengen_autostart.sh`, `10/10_jichi_autostart.sh` | boot hook `/root/init.sh` |
| 14 | `utahime` | `11/11_utahime_dns.sh` | master zona `jujutsu.K-49.com` |
| 15 | `shoko` | `11/11_shoko_dns.sh` | slave, zona tersalin |

Soal 8 dan 9 adalah pengujian, bukan konfigurasi. Scriptnya hanya dijalankan saat pembuktian.

### 3. Cek cepat semua soal

```bash
# jichi
ip -4 a; ip route; cat /proc/sys/net/ipv4/ip_forward; iptables -t nat -L POSTROUTING -n
pgrep -a dhcrelay                       # pakai ini, bukan "service ... status" (lihat catatan)
# tengen
service isc-dhcp-server status; dhcpd -t -cf /etc/dhcp/dhcpd.conf
grep -E "^lease|binding state|hardware|client-hostname" /var/lib/dhcp/dhcpd.leases
# client mana saja
ip -4 a show eth0; ip route; cat /etc/resolv.conf
# DNS, dari client
dig @10.88.1.2 jujutsu.K-49.com SOA +short; dig @10.88.1.3 jujutsu.K-49.com SOA +short
```

### 4. Kalau ada yang tidak jalan

Periksa berurutan dari lapisan paling bawah: interface, IP dan subnet, gateway dan routing, status service dan tes konfigurasi, relay dan `net.ipv4.ip_forward`, client, lalu DNS. Ubah satu hal dalam satu waktu.

### 5. Catatan

- **Tidak ada systemd.** Image `debinet` memakai `dumb-init` sebagai PID 1, jadi `systemctl enable` yang ada di modul tidak bisa dipakai. Service dijalankan dengan `service <nama> ...` dan dinyalakan saat boot lewat `/root/init.sh` (lihat [soal 10](#soal-10)).
- **`service isc-dhcp-relay status` bisa menipu.** Script init relay hanya mengecek ada tidaknya file pid, jadi setelah restart bisa tertulis "running" padahal prosesnya tidak ada. Script dan boot hook kami mengecek proses langsung dengan `pgrep -x dhcrelay`.
- **Client memakai `debinet`**, bukan `alpinet`, sehingga DHCP di client memakai `ifup` dan `dhclient`, bukan `udhcpc`.
- **Peringatan `Not live until ...` dari `apt`** muncul di `jichi` dan `tengen` karena jam node tertinggal beberapa menit. Tidak berpengaruh ke hasil.
- Istilah yang dipakai dijelaskan di [`GLOSSARY.md`](GLOSSARY.md). Modul acuan: <https://github.com/lab-kcks/modul-komdat-jarkom-2026> (`Modul 3/Implementasi`, `Modul 3/DHCP`, `Modul 2/DNS`).

---

# Laporan

## Soal 1

**Penyampaian ulang:** `jichi` dijadikan router. `eth0` mengambil WAN dari NAT, `eth1` sampai `eth4` menjadi gateway Network 1 sampai 4, IPv4 forwarding dan source NAT diaktifkan, host infrastruktur diberi IP statis, lalu konektivitas host ke gateway dan ke luar harus dibuktikan.

### Maksud soal

Semua jaringan dihubungkan lewat satu router dan diberi jalan keluar ke internet. Tanpa ini node lain tidak bisa saling bicara dan tidak bisa mengunduh paket untuk soal berikutnya.

### Cara mengerjakan

1. `eth0` diatur `dhcp`, sedangkan `eth1`-`eth4` diatur statis `10.88.1.1` sampai `10.88.4.1` /24 di `/etc/network/interfaces`.
2. `net.ipv4.ip_forward=1` dinyalakan dan disimpan di `/etc/sysctl.d/99-forward.conf`.
3. Aturan `iptables -t nat ... -o eth0 -j MASQUERADE` ditaruh sebagai `post-up` di `eth0`, supaya ikut aktif setiap interface naik.
4. Node belum punya DHCP client, jadi script memberi `eth0` alamat sementara dulu, memasang `ifupdown` dan `isc-dhcp-client`, lalu pindah ke DHCP.
5. IP statis host lain diatur di script masing-masing: `tengen` `10.88.4.10` (soal 2), `utahime` `10.88.1.2` dan `shoko` `10.88.1.3` (soal 11).

Script:

- [`01_jichi_router.sh`](01/01_jichi_router.sh)

### Cara melakukan validasi

```bash
ip -4 a                                  # eth0 192.168.122.x dynamic; eth1-eth4 = 10.88.N.1/24
ip route                                 # default via 192.168.122.1 dan empat jaringan terhubung
cat /proc/sys/net/ipv4/ip_forward        # 1
iptables -t nat -L POSTROUTING -n        # ada MASQUERADE
ping -c 2 8.8.8.8
```

`jichi`: ping 8.8.8.8, `ip -4 a`, aturan MASQUERADE, dan `ip_forward` bernilai 1

![`jichi`: ping 8.8.8.8, `ip -4 a`, aturan MASQUERADE, dan `ip_forward` bernilai 1](01/proof/01_jichi_interfaces-nat-forwarding-ping_172815.png)

> Ping client ke gateway dan ke `8.8.8.8` juga terlihat di hasil soal 3 sampai 9 (misalnya `okkotsu` dan `miwa`). Tangkapan layar ping untuk host lain ditunjukkan saat demo.

---

## Soal 2

**Penyampaian ulang:** `tengen` dipasangi `isc-dhcp-server` di `10.88.4.10`. Network 4 dideklarasikan sebagai subnet lokal tanpa pool dinamis, scope disiapkan untuk Network 2 dan 3, dan service harus aktif tanpa error "No subnet declaration".

### Maksud soal

DHCP server harus punya setidaknya satu subnet yang cocok dengan interface-nya, kalau tidak `dhcpd` menolak jalan. Network 4 adalah jaringan `tengen` sendiri, jadi dideklarasikan kosong (tanpa `range`) supaya server hidup tapi tidak membagikan alamat di situ. Network 2 dan 3 disiapkan scope-nya untuk client yang datang lewat relay.

### Cara mengerjakan

1. `tengen` diberi `10.88.4.10/24` dengan gateway `10.88.4.1`.
2. `isc-dhcp-server` dipasang, dan `/etc/default/isc-dhcp-server` diisi `INTERFACESv4="eth0"`.
3. `dhcpd.conf` berisi tiga blok `subnet`: Network 4 kosong, Network 2 dan Network 3 dengan `range` dan `option routers`.
4. `dhcpd -t` dijalankan dulu. Kalau lolos, service di-restart.

Script:

- [`02_tengen_dhcp.sh`](02/02_tengen_dhcp.sh)

### Cara melakukan validasi

```bash
ip -4 a show eth0                     # 10.88.4.10/24
ping -c 2 10.88.4.1
dhcpd -t -cf /etc/dhcp/dhcpd.conf     # hanya banner, tanpa error
service isc-dhcp-server status        # dhcpd is running.
cat /etc/dhcp/dhcpd.conf              # tiga subnet, blok Network 4 tanpa range
```

`tengen`: status service, `dhcpd -t`, isi `dhcpd.conf`, dan ping ke gateway

![`tengen`: status service, `dhcpd -t`, isi `dhcpd.conf`, dan ping ke gateway](02/proof/02_tengen_status-config-ping_174941.png)

---

## Soal 3

**Penyampaian ulang:** `jichi` dijadikan DHCP relay menuju `tengen` (`10.88.4.10`) lewat `eth2` untuk Network 2 dan `eth3` untuk Network 3, lalu dibuktikan bahwa client dari kedua subnet mendapat lease lewat relay.

### Maksud soal

Permintaan DHCP berupa broadcast, dan router tidak meneruskan broadcast. Client di Network 2 dan 3 tidak akan pernah menjangkau `tengen` di Network 4. Relay di `jichi` mendengar broadcast itu, lalu mengirimkannya ke `tengen` sebagai paket unicast.

### Cara mengerjakan

1. `isc-dhcp-relay` dipasang di `jichi`.
2. `/etc/default/isc-dhcp-relay` diisi `SERVERS="10.88.4.10"` dan `INTERFACES="eth2 eth3 eth4"`. Seperti di modul, interface yang menghadap server (`eth4`) ikut dimasukkan.
3. Service di-restart. IP forwarding dicek tetap `1`.
4. Dua client uji diatur `iface eth0 inet dhcp`: `okkotsu` (Network 2) dan `miwa` (Network 3).

Script:

- [`03_jichi_relay.sh`](03/03_jichi_relay.sh)
- [`03_miwa_dhcp.sh`](03/03_miwa_dhcp.sh)
- [`03_okkotsu_dhcp.sh`](03/03_okkotsu_dhcp.sh)

### Cara melakukan validasi

```bash
# jichi
pgrep -a dhcrelay                    # dhcrelay -q -i eth2 -i eth3 -i eth4 10.88.4.10
cat /etc/default/isc-dhcp-relay
# client
ip -4 a show eth0; ip route          # 10.88.2.x atau 10.88.3.x, default via .1 yang sesuai
# tengen
grep -E "^lease|hardware|client-hostname" /var/lib/dhcp/dhcpd.leases
```

`jichi`: status relay dan isi `/etc/default/isc-dhcp-relay`

![`jichi`: status relay dan isi `/etc/default/isc-dhcp-relay`](03/proof/03_jichi_relay-status_184032.png)

`okkotsu` (Network 2) mendapat 10.88.2.10 (dynamic)

![`okkotsu` (Network 2) mendapat 10.88.2.10 (dynamic)](03/proof/03_okkotsu_ip_184242.png)

`miwa` (Network 3) mendapat 10.88.3.10 (dynamic)

![`miwa` (Network 3) mendapat 10.88.3.10 (dynamic)](03/proof/03_miwa_ip_184335.png)

`tengen`: `dhcpd.leases` berisi kedua lease

![`tengen`: `dhcpd.leases` berisi kedua lease](03/proof/03_tengen_leases_184558.png)

---

## Soal 4

**Penyampaian ulang:** Network 2 dibagi menjadi dua pool: pool 1 `10.88.2.10`-`.35` untuk `itadori` dan `fushiguro`, pool 2 `10.88.2.70`-`.95` untuk `zenin` dan `okkotsu`. Rentang `10.88.2.36`-`.69` tidak boleh dialokasikan. Karena semua client satu subnet, pemisahnya memakai DHCP class berdasarkan MAC address.

### Maksud soal

Rentang alamat tidak bisa membedakan siapa meminta, karena semua client ada di subnet yang sama. Yang dipakai untuk membedakan adalah MAC address: setiap client dimasukkan ke sebuah class, lalu setiap pool hanya boleh dipakai oleh satu class.

### Cara mengerjakan

1. Ambil MAC tiap client dengan `cat /sys/class/net/eth0/address`.
2. Di `dhcpd.conf` dibuat `class "pool1"` dan `class "pool2"` dengan `match hardware;`, lalu tiap MAC didaftarkan lewat `subclass`.
3. Di `subnet 10.88.2.0` dibuat dua blok `pool`, masing-masing `allow members of "pool1"` atau `"pool2"` dengan `range`-nya sendiri. Karena `.36`-`.69` tidak masuk `range` mana pun, rentang itu tidak pernah dibagikan.
4. Di sisi client, `hwaddress ether <MAC>` ditulis di `/etc/network/interfaces` supaya MAC tetap sama kalau node di-reset GNS3.
5. `okkotsu` sebelumnya sudah dapat `.10` dari soal 3, jadi dia melepas lease lama dan meminta ulang supaya masuk pool 2.

Class dan beberapa pool tidak ada di modul. Bagian ini diambil dari dokumentasi `dhcpd.conf`.

Script:

- [`04_fushiguro_dhcp.sh`](04/04_fushiguro_dhcp.sh)
- [`04_itadori_dhcp.sh`](04/04_itadori_dhcp.sh)
- [`04_okkotsu_renew.sh`](04/04_okkotsu_renew.sh)
- [`04_tengen_pools.sh`](04/04_tengen_pools.sh)
- [`04_zenin_dhcp.sh`](04/04_zenin_dhcp.sh)

### Cara melakukan validasi

```bash
ip -4 a show eth0                     # di tiap client: itadori/fushiguro .10-.35, zenin/okkotsu .70-.95
dhcpd -t -cf /etc/dhcp/dhcpd.conf     # di tengen
grep -E "^lease|hardware|client-hostname" /var/lib/dhcp/dhcpd.leases
```

`itadori`: 10.88.2.11 (pool 1)

![`itadori`: 10.88.2.11 (pool 1)](04/proof/04_itadori_ip_190522.png)

`fushiguro`: 10.88.2.12 (pool 1)

![`fushiguro`: 10.88.2.12 (pool 1)](04/proof/04_fushiguro_ip_191159.png)

`zenin`: 10.88.2.71 (pool 2)

![`zenin`: 10.88.2.71 (pool 2)](04/proof/04_zenin_ip_191355.png)

`okkotsu`: 10.88.2.70 (pool 2)

![`okkotsu`: 10.88.2.70 (pool 2)](04/proof/04_okkotsu_ip_191433.png)

`tengen`: daftar lease (bagian 1)

![`tengen`: daftar lease (bagian 1)](04/proof/04_tengen_leases-a_191755.png)

`tengen`: daftar lease (bagian 2)

![`tengen`: daftar lease (bagian 2)](04/proof/04_tengen_leases-b_191810.png)

`tengen`: `dhcpd.conf` (bagian 1)

![`tengen`: `dhcpd.conf` (bagian 1)](04/proof/04_tengen_conf-a_191950.png)

`tengen`: `dhcpd.conf` (bagian 2)

![`tengen`: `dhcpd.conf` (bagian 2)](04/proof/04_tengen_conf-b_191940.png)

`tengen`: `dhcpd -t` dan status service

![`tengen`: `dhcpd -t` dan status service](04/proof/04_tengen_check-status_192029.png)

---

## Soal 5

**Penyampaian ulang:** di Network 3, `ino` dan `kusakabe` mendapat short lease 1800 detik dari pool `10.88.3.10`-`.89`, `miwa` mendapat long lease 43200 detik dari pool `10.88.3.100`-`.199`. `default-lease-time` dan `max-lease-time` disesuaikan per class. Semua client juga menerima DNS `10.88.1.2` dan `10.88.1.3` serta domain-search `K-49.com`.

### Maksud soal

Tiap tim lapangan punya lama kerja yang berbeda, jadi lama pinjam alamatnya juga berbeda. Lease pendek mengembalikan alamat lebih cepat, lease panjang cocok untuk client yang menetap. Option DNS dan domain-search membuat client otomatis tahu ke mana bertanya nama.

### Cara mengerjakan

1. Dibuat class `short-lease` (MAC `ino` dan `kusakabe`) dan `long-lease` (MAC `miwa`).
2. Di `subnet 10.88.3.0` dibuat dua blok `pool`. Lease time ditulis di dalam blok pool itu sendiri: 1800/1800 untuk short, 43200/43200 untuk long.
3. `option domain-name-servers 10.88.1.2, 10.88.1.3;` dan `option domain-search "K-49.com";` ditaruh di bagian atas file, supaya berlaku untuk semua client.
4. Client memakai script yang sama dengan soal 4 (pasang `ifupdown` dan `isc-dhcp-client`, kunci MAC, minta lease). `miwa` sudah punya alatnya, jadi cukup minta lease baru.

Script:

- [`05_ino_dhcp.sh`](05/05_ino_dhcp.sh)
- [`05_kusakabe_dhcp.sh`](05/05_kusakabe_dhcp.sh)
- [`05_miwa_renew.sh`](05/05_miwa_renew.sh)
- [`05_tengen_leases.sh`](05/05_tengen_leases.sh)

### Cara melakukan validasi

```bash
ip -4 a show eth0        # ino/kusakabe: valid_lft sekitar 1800sec; miwa: sekitar 43200sec
cat /etc/resolv.conf     # search K-49.com. / nameserver 10.88.1.2 / nameserver 10.88.1.3
```

`ino`: 10.88.3.11, lease sekitar 1800 detik

![`ino`: 10.88.3.11, lease sekitar 1800 detik](05/proof/05_ino_ip_194436.png)

`kusakabe`: 10.88.3.12, lease sekitar 1800 detik

![`kusakabe`: 10.88.3.12, lease sekitar 1800 detik](05/proof/05_kusakabe_ip_194533.png)

`miwa`: proses DHCP lengkap lewat relay, `bound to 10.88.3.100`

![`miwa`: proses DHCP lengkap lewat relay, `bound to 10.88.3.100`](05/proof/05_miwa_renew-output_194628.png)

`miwa`: 10.88.3.100, lease sekitar 43200 detik

![`miwa`: 10.88.3.100, lease sekitar 43200 detik](05/proof/05_miwa_ip_195131.png)

`ino`: `resolv.conf`

![`ino`: `resolv.conf`](05/proof/05_ino_resolv_194733.png)

`kusakabe`: `resolv.conf`

![`kusakabe`: `resolv.conf`](05/proof/05_kusakabe_resolv_194711.png)

`miwa`: `resolv.conf`

![`miwa`: `resolv.conf`](05/proof/05_miwa_resolv_194648.png)

`tengen`: daftar lease (bagian 1)

![`tengen`: daftar lease (bagian 1)](05/proof/05_tengen_leases-a_194807.png)

`tengen`: daftar lease (bagian 2)

![`tengen`: daftar lease (bagian 2)](05/proof/05_tengen_leases-b_194819.png)

`tengen`: `dhcpd.conf` (bagian 1)

![`tengen`: `dhcpd.conf` (bagian 1)](05/proof/05_tengen_conf-a_194845.png)

`tengen`: `dhcpd.conf` (bagian 2)

![`tengen`: `dhcpd.conf` (bagian 2)](05/proof/05_tengen_conf-b_194855.png)

`tengen`: `dhcpd.conf` (bagian 3)

![`tengen`: `dhcpd.conf` (bagian 3)](05/proof/05_tengen_conf-c_194859.png)

`tengen`: `dhcpd -t` dan status service

![`tengen`: `dhcpd -t` dan status service](05/proof/05_tengen_check-status_195108.png)

---

## Soal 6

**Penyampaian ulang:** `kugisaki` harus selalu mendapat alamat yang sama. Dibuat static lease berdasarkan MAC dengan fixed address `10.88.3.99` yang berada di luar semua pool dinamis, konfigurasi divalidasi, lease di-renew, lalu dibuktikan alamat yang diterima sama dengan reservasi.

### Maksud soal

Client VIP tetap meminta lewat DHCP, tapi server selalu menjawab dengan alamat yang sama karena MAC-nya terdaftar. Alamatnya harus di luar pool supaya tidak pernah diberikan ke client lain.

### Cara mengerjakan

1. MAC `kugisaki` (`02:42:2e:c0:2b:00`) dibaca dari node.
2. Di `dhcpd.conf` ditambahkan blok:

   ```
   host kugisaki {
       hardware ethernet 02:42:2e:c0:2b:00;
       fixed-address 10.88.3.99;
   }
   ```

   `.99` berada di celah antara pool short (`.10`-`.89`) dan pool long (`.100`-`.199`).
3. `dhcpd -t`, lalu restart service.
4. Di `kugisaki`: `ifdown eth0; ifup eth0` untuk renew lease.

Static lease tidak ditulis ke `dhcpd.leases`, jadi buktinya ada di sisi client dan di konfigurasi.

Script:

- [`06_kugisaki_dhcp.sh`](06/06_kugisaki_dhcp.sh)
- [`06_tengen_fixed.sh`](06/06_tengen_fixed.sh)

### Cara melakukan validasi

```bash
# kugisaki
ip -4 a show eth0; ifdown eth0; ifup eth0; ip -4 a show eth0     # 10.88.3.99 sebelum dan sesudah
# tengen
grep -A4 "^host" /etc/dhcp/dhcpd.conf
dhcpd -t -cf /etc/dhcp/dhcpd.conf; service isc-dhcp-server status
```

`kugisaki`: 10.88.3.99 sebelum dan sesudah renew, offer dan ack untuk .99

![`kugisaki`: 10.88.3.99 sebelum dan sesudah renew, offer dan ack untuk .99](06/proof/06_kugisaki_renew_200829.png)

`tengen`: `dhcpd -t` dan status service

![`tengen`: `dhcpd -t` dan status service](06/proof/06_tengen_check-status_201051.png)

`tengen`: blok `host kugisaki`, `.99` di luar kedua pool

![`tengen`: blok `host kugisaki`, `.99` di luar kedua pool](06/proof/06_tengen_conf-host_201352.png)

---

## Soal 7

**Penyampaian ulang:** setiap client harus menerima konfigurasi sesuai wilayahnya (mask /24, gateway, broadcast, DNS, domain-search). IP dan routing seluruh client Divisi A dan B diperiksa, lease dicocokkan dengan `dhcpd.leases` di `tengen`, dan tidak boleh ada alamat bentrok atau di luar kebijakan pool.

### Maksud soal

Ini soal pemeriksaan: apakah semua aturan dari soal 2 sampai 6 benar-benar sampai ke client, dan apakah catatan server sama dengan kenyataan di client.

### Cara mengerjakan

1. Broadcast tadinya hanya dihitung sendiri oleh client. Supaya benar-benar dikirim server, `option subnet-mask` dan `option broadcast-address` ditambahkan di kedua subnet.
2. Kedelapan client melakukan renew, lalu option diperiksa langsung di file lease client (`/var/lib/dhcp/dhclient.eth0.leases`).
3. Jurnal lease di `tengen` dibaca (catatan terbaru tiap alamat) dan dicocokkan dengan rentang pool.

Hasilnya 7 lease aktif, semuanya di dalam pool masing-masing, tanpa alamat atau MAC ganda. `kugisaki` tidak ada di daftar itu karena static lease.

Script:

- [`07_tengen_options.sh`](07/07_tengen_options.sh)

### Cara melakukan validasi

```bash
# tiap client
ifdown eth0; ifup eth0
grep "broadcast-address" /var/lib/dhcp/dhclient.eth0.leases | tail -n 1
ip -4 a show eth0; ip route; cat /etc/resolv.conf
# tengen
grep -n "broadcast\|subnet-mask" /etc/dhcp/dhcpd.conf
grep -E "^lease|binding state|hardware|client-hostname" /var/lib/dhcp/dhcpd.leases
```

`tengen`: option mask dan broadcast untuk Network 2 dan 3

![`tengen`: option mask dan broadcast untuk Network 2 dan 3](07/proof/07_tengen_grep-options_205136.png)

`itadori`: renew 10.88.2.11, menerima broadcast 10.88.2.255

![`itadori`: renew 10.88.2.11, menerima broadcast 10.88.2.255](07/proof/07_itadori_renew-broadcast_205227.png)

`fushiguro`: 10.88.2.12, 10.88.2.255

![`fushiguro`: 10.88.2.12, 10.88.2.255](07/proof/07_fushiguro_renew-broadcast_205313.png)

`zenin`: 10.88.2.71, 10.88.2.255

![`zenin`: 10.88.2.71, 10.88.2.255](07/proof/07_zenin_renew-broadcast_205529.png)

`okkotsu`: 10.88.2.70, 10.88.2.255

![`okkotsu`: 10.88.2.70, 10.88.2.255](07/proof/07_okkotsu_renew-broadcast_205559.png)

`ino`: 10.88.3.11, 10.88.3.255

![`ino`: 10.88.3.11, 10.88.3.255](07/proof/07_ino_renew-broadcast_205641.png)

`kusakabe`: 10.88.3.12, 10.88.3.255

![`kusakabe`: 10.88.3.12, 10.88.3.255](07/proof/07_kusakabe_renew-broadcast_205716.png)

`miwa`: 10.88.3.100, 10.88.3.255

![`miwa`: 10.88.3.100, 10.88.3.255](07/proof/07_miwa_renew-broadcast_205744.png)

`kugisaki`: 10.88.3.99, 10.88.3.255

![`kugisaki`: 10.88.3.99, 10.88.3.255](07/proof/07_kugisaki_renew-broadcast_205816.png)

`itadori`: `ip route` (default via 10.88.2.1)

![`itadori`: `ip route` (default via 10.88.2.1)](07/proof/07_itadori_route_211241.png)

`kugisaki`: `ip route` (default via 10.88.3.1)

![`kugisaki`: `ip route` (default via 10.88.3.1)](07/proof/07_kugisaki_route_211232.png)

`tengen`: jurnal lease (bagian 1)

![`tengen`: jurnal lease (bagian 1)](07/proof/07_tengen_leases-a_205957.png)

`tengen`: jurnal lease (bagian 2)

![`tengen`: jurnal lease (bagian 2)](07/proof/07_tengen_leases-b_210004.png)

`tengen`: jurnal lease (bagian 3)

![`tengen`: jurnal lease (bagian 3)](07/proof/07_tengen_leases-c_210009.png)

`tengen`: `dhcpd -t` dan status service setelah perubahan

![`tengen`: `dhcpd -t` dan status service setelah perubahan](07/proof/07_tengen_check-status_211421.png)

Alamat dan broadcast tiap client juga terlihat di tangkapan layar `ip -4 a show eth0` pada soal 4, 5, dan 6.

---

## Soal 8

**Penyampaian ulang:** dibuktikan dengan `tcpdump` di `tengen` bahwa pemberian alamat berjalan sesuai protokol: DHCPDISCOVER, DHCPOFFER, DHCPREQUEST, DHCPACK. Harus terlihat alamat server, alamat yang diberikan, lease time, dan field `giaddr`, dan nilai `giaddr` harus sama dengan interface `jichi` yang menerima request dari subnet client.

### Maksud soal

Sampai soal 7 kita hanya melihat hasil akhirnya (client dapat IP). Di sini yang dilihat adalah prosesnya: empat pesan DHCP berurutan, dan field `giaddr` yang diisi relay dengan alamat interface tempat request masuk. Dengan `giaddr` itulah `tengen` tahu harus memakai scope Network 2 atau Network 3, dan ke mana jawabannya dikirim.

### Cara mengerjakan

1. `08_tengen_capture.sh <MAC-client> <detik>` menjalankan `tcpdump` di `eth0` `tengen`. Filternya membaca MAC client yang ada di dalam paket DHCP (field `chaddr`), yang tidak diubah oleh relay, sehingga hanya paket satu client yang tertangkap.
2. Hasil disimpan ke file `.pcap`, lalu ditampilkan penuh (`-vvv`) dan sebagai ringkasan satu baris per paket.
3. Selama capture berjalan, client meminta lease baru (`08_itadori_renew.sh` atau `08_ino_renew.sh`).
4. Capture dilakukan untuk `itadori` (Network 2) dan `ino` (Network 3).

Script:

- [`08_ino_renew.sh`](08/08_ino_renew.sh)
- [`08_itadori_renew.sh`](08/08_itadori_renew.sh)
- [`08_tengen_capture.sh`](08/08_tengen_capture.sh)

### Cara melakukan validasi

```bash
# tengen: jalankan capture lebih dulu
/root/08_tengen_capture.sh 02:42:11:d9:ac:00 40      # itadori (Network 2); MAC ino: f2:dd:ec:51:c9:cb
# dalam 40 detik, di client
/root/08_itadori_renew.sh
# capture yang tersimpan bisa dibaca lagi
/root/08_tengen_capture.sh 02:42:11:d9:ac:00 0
```

Hasil:

| Jaringan | Client | Server | Alamat diberikan (`yiaddr`) | Lease | `giaddr` | Interface `jichi` |
| -------- | ------ | ------ | --------------------------- | ----- | -------- | ----------------- |
| 2 | `itadori` | `10.88.4.10` | `10.88.2.11` | 600 s | `10.88.2.1` | `eth2` |
| 3 | `ino` | `10.88.4.10` | `10.88.3.11` | 1800 s | `10.88.3.1` | `eth3` |

Keempat pesan dalam satu proses memakai transaction id (`xid`) yang sama. Offer dan ACK dikirim ke alamat `giaddr`, itulah cara jawaban kembali ke relay. Paket `Release` sebelum tiap proses berasal dari `ifdown` dan bukan bagian dari empat langkah itu.

Network 2 (`itadori`): ringkasan per paket, `giaddr` 10.88.2.1

![Network 2 (`itadori`): ringkasan per paket, `giaddr` 10.88.2.1](08/proof/08_tengen_summary-net2_212922.png)

Network 3 (`ino`): decode lengkap ACK dan ringkasan, `giaddr` 10.88.3.1

![Network 3 (`ino`): decode lengkap ACK dan ringkasan, `giaddr` 10.88.3.1](08/proof/08_tengen_summary-net3_214510.png)

Network 2: capture dimulai, client meminta lease (pendukung)

![Network 2: capture dimulai, client meminta lease (pendukung)](08/proof/08_tengen-itadori_capture-start-net2_212600.png)

Network 2: decode lengkap ACK (pendukung)

![Network 2: decode lengkap ACK (pendukung)](08/proof/08_tengen-itadori_capture-fulldecode-net2_212642.png)

---

## Soal 9

**Penyampaian ulang:** service DHCP relay di `jichi` dihentikan, satu client dipaksa meminta lease baru dan gejalanya dicatat. Setelah relay dipulihkan, permintaan diulang dan harus terbukti client kembali mendapat alamat dari pool yang benar dengan gateway semula.

### Maksud soal

Menirukan gangguan jalur relay: apa yang terlihat dari sisi client dan dari sisi data center, dan memastikan pemulihannya benar.

### Cara mengerjakan

1. `09_jichi_relay.sh stop` mematikan relay dan memastikan prosesnya benar-benar hilang. `start` menjalankannya lagi dengan konfigurasi dari soal 3.
2. `09_itadori_renew.sh outage` melepas lease, menghapus alamat, lalu meminta lagi. Semua keluaran disimpan di `/root/09_itadori_outage.log`. Mode `restore` melakukan hal yang sama setelah relay hidup, log di `/root/09_itadori_restore.log`.
3. Selama gangguan, capture dijalankan di `tengen` (skrip soal 8).

Gejala saat relay mati: `DHCPRELEASE`, enam kali `DHCPDISCOVER` dengan jeda makin lama, lalu `No DHCPOFFERS received`. Alamat dan default route di client hilang. Capture di `tengen` tidak melihat Discover maupun Offer sama sekali. Yang sampai hanya satu paket renew dan paket Release dari client, karena paket unicast tetap dirouting biasa, sedangkan Discover (broadcast) bergantung pada relay.

Setelah relay hidup: `DHCPOFFER ... from 10.88.2.1`, `bound to 10.88.2.11` (pool 1), `default via 10.88.2.1`, sama seperti sebelum gangguan.

Script:

- [`09_itadori_renew.sh`](09/09_itadori_renew.sh)
- [`09_jichi_relay.sh`](09/09_jichi_relay.sh)

### Cara melakukan validasi

Tiga console dibuka: `jichi`, `tengen`, `itadori`.

```bash
ip -4 a show eth0; ip route                        # itadori: kondisi awal
/root/09_jichi_relay.sh stop                       # jichi
/root/08_tengen_capture.sh 02:42:11:d9:ac:00 90    # tengen
/root/09_itadori_renew.sh outage                   # itadori: tidak ada offer, tidak ada alamat dan route
/root/09_jichi_relay.sh start                      # jichi
/root/09_itadori_renew.sh restore                  # itadori: DORA lagi, alamat pool 1, default via 10.88.2.1
```

relay `jichi` dihentikan, kondisi awal `itadori`, lalu gejala gangguan

![relay `jichi` dihentikan, kondisi awal `itadori`, lalu gejala gangguan](09/proof/09_jichi-itadori_stop-baseline-symptom_221354.png)

log gejala di `itadori` dan capture `tengen`: tidak ada Discover atau Offer yang sampai

![log gejala di `itadori` dan capture `tengen`: tidak ada Discover atau Offer yang sampai](09/proof/09_itadori-tengen_symptom-capture_221359.png)

relay dijalankan lagi, `itadori` mendapat DORA, 10.88.2.11, default via 10.88.2.1

![relay dijalankan lagi, `itadori` mendapat DORA, 10.88.2.11, default via 10.88.2.1](09/proof/09_jichi-itadori_restore-recovery_221705.png)

---

## Soal 10

**Penyampaian ulang:** DHCP server di `tengen` dan DHCP relay di `jichi` harus menyala sendiri setelah node di-restart. Status layanan, IP, gateway, lease, dan konektivitas client Network 2 dan 3 diverifikasi, dan kebijakan pool 1, pool 2, short lease, long lease, dan fixed address harus tetap berlaku.

### Maksud soal

Konfigurasi yang benar tidak berguna kalau hilang saat node mati lalu hidup lagi. Proses `dhcpd` dan `dhcrelay` tidak ikut hidup sendiri, jadi harus ada mekanisme yang menjalankannya saat boot.

### Cara mengerjakan

Image `debinet` tidak memakai systemd, jadi `systemctl enable` dari modul tidak bisa dipakai. Setelah diperiksa, image menjalankan `/etc/debinet-init.sh` setiap node start, dan script itu menjalankan `/root/init.sh` kalau ada. `/root` adalah volume yang disimpan GNS3, sehingga isinya tetap ada. Karena itu boot hook ditulis di `/root/init.sh`:

- `tengen`: menunggu `eth0` berisi `10.88.4.10`, lalu menjalankan `isc-dhcp-server` kalau belum berjalan.
- `jichi`: menunggu `eth2`-`eth4`, menyalakan lagi `net.ipv4.ip_forward` (sebelumnya hanya pengaturan runtime), memastikan aturan NAT ada, menghapus file pid relay yang basi, lalu menjalankan relay kalau **prosesnya** belum ada.

Kedua hook menulis ke `/root/boot.log`, jadi setiap boot meninggalkan satu bagian bertanda waktu.

Temuan saat pengujian: setelah restart pertama `jichi`, relay ternyata tidak berjalan padahal `service isc-dhcp-relay status` mengembalikan 0. Script init relay hanya mengecek keberadaan file pid, dan file pid lama ikut tersimpan setelah restart. Hook diubah supaya mengecek proses dengan `pgrep -x dhcrelay` dan menghapus file pid yang basi. Restart kedua (di bawah) membuktikan perbaikannya.

Script:

- [`10_jichi_autostart.sh`](10/10_jichi_autostart.sh)
- [`10_tengen_autostart.sh`](10/10_tengen_autostart.sh)

### Cara melakukan validasi

Restart node dari GNS3, tunggu sekitar 30 detik, lalu:

```bash
# tengen
cat /root/boot.log; service isc-dhcp-server status; ip -4 a show eth0; ip route
dhcpd -t -cf /etc/dhcp/dhcpd.conf
# jichi
cat /root/boot.log; pgrep -a dhcrelay; cat /proc/sys/net/ipv4/ip_forward
ip -4 a; ip route; iptables -t nat -L POSTROUTING -n
# client: ifdown eth0; ifup eth0; lalu ip -4 a show eth0; ip route; ping gateway dan 8.8.8.8
```

Bukti bahwa hook jalan sendiri: di `boot.log` ada bagian `boot hook` baru dengan waktu baru setelah restart.

kedua hook terpasang dan dijalankan sekali

![kedua hook terpasang dan dijalankan sekali](10/proof/10_jichi-tengen_autostart-scripts-run_224106.png)

`cat /root/init.sh` di `jichi` dan `tengen`

![`cat /root/init.sh` di `jichi` dan `tengen`](10/proof/10_jichi-tengen_cat-init-sh_224124.png)

setelah restart pertama: `boot.log` `tengen`, status, `ip`, `dhcpd -t`

![setelah restart pertama: `boot.log` `tengen`, status, `ip`, `dhcpd -t`](10/proof/10_tengen-jichi_after-restart-first_224732.png)

setelah restart pertama: interface dan route `jichi` (relay belum jalan)

![setelah restart pertama: interface dan route `jichi` (relay belum jalan)](10/proof/10_tengen-jichi_after-restart-routes_224834.png)

setelah restart pertama: aturan NAT `jichi`

![setelah restart pertama: aturan NAT `jichi`](10/proof/10_tengen-jichi_after-restart-nat_224840.png)

restart kedua `jichi`: `boot.log`, bagian hook baru menjalankan relay

![restart kedua `jichi`: `boot.log`, bagian hook baru menjalankan relay](10/proof/10_jichi_second-restart-bootlog_225210.png)

restart kedua `jichi`: proses `dhcrelay`, `ip_forward`, `ip -4 a`

![restart kedua `jichi`: proses `dhcrelay`, `ip_forward`, `ip -4 a`](10/proof/10_jichi_second-restart-pgrep-ipfwd-ipa_225216.png)

restart kedua `jichi`: route dan MASQUERADE

![restart kedua `jichi`: route dan MASQUERADE](10/proof/10_jichi_second-restart-route-nat_225220.png)

> Pengecekan client setelah restart (semua pool, kedua lease time, dan fixed address) ditunjukkan saat demo. Perintahnya sama dengan soal 7, dan hasil client sebelum restart ada di [soal 7](#soal-7).

---

## Soal 11

**Penyampaian ulang:** `utahime` menjadi DNS master dan `shoko` DNS slave untuk zona `jujutsu.K-49.com`, dengan record SOA, NS untuk kedua server, dan `allow-transfer` dari master ke slave. Zona harus tersalin otomatis ke `shoko` saat serial di `utahime` dinaikkan, dibuktikan dengan `dig` ke kedua server dari satu client.

### Maksud soal

Dua server DNS menyimpan zona yang sama supaya pencarian nama tetap jalan kalau satu server mati. Master adalah tempat zona diubah, slave hanya menyalin. Slave tahu zona berubah dari nomor serial di SOA, dan master memberi tahu slave lewat NOTIFY.

### Cara mengerjakan (modul `Modul 2/DNS`, bagian 2.6)

1. `utahime` diberi `10.88.1.2/24` dan `shoko` diberi `10.88.1.3/24`, gateway `10.88.1.1`, lalu BIND9 dipasang di keduanya.
2. Di `utahime`, zona dideklarasikan sebagai master:

   ```
   zone "jujutsu.K-49.com" {
       type master;
       file "/etc/bind/jujutsu/jujutsu.K-49.com";
       notify yes;
       also-notify { 10.88.1.3; };
       allow-transfer { 10.88.1.3; };
   };
   ```

   File zona berisi SOA (primary `utahime.jujutsu.K-49.com.`, serial `2026101201`), NS untuk `utahime` dan `shoko`, serta A record keduanya. `named-checkconf` dan `named-checkzone` dijalankan sebelum restart.
3. Di `shoko`, zona dideklarasikan sebagai slave dengan `masters { 10.88.1.2; };`. Salinan disimpan sebagai teks di `/var/cache/bind` (folder yang boleh ditulis `named`; modul memakai `/etc/bind`).
4. Untuk menguji, record `tengen` ditambahkan di `utahime` dan serial dinaikkan menjadi `2026101202` lalu zona di-reload. `utahime` mengirim NOTIFY dan `shoko` menarik zona baru sendiri.
5. `11_itadori_dns.sh` bertanya ke kedua server dari client, dan juga mencoba zone transfer dari client, yang harus ditolak.

Script:

- [`11_itadori_dns.sh`](11/11_itadori_dns.sh)
- [`11_shoko_dns.sh`](11/11_shoko_dns.sh)
- [`11_utahime_dns.sh`](11/11_utahime_dns.sh)

### Cara melakukan validasi

```bash
/root/11_utahime_dns.sh                           # utahime: setup (cek zona, restart named, dig)
/root/11_shoko_dns.sh                             # shoko: setup, menunggu transfer pertama
/root/11_itadori_dns.sh tengen.jujutsu.K-49.com   # client, sebelum: NXDOMAIN untuk tengen di kedua server
/root/11_utahime_dns.sh serial                    # utahime: tambah tengen -> 10.88.4.10, serial 2026101201 -> 2026101202
/root/11_itadori_dns.sh tengen.jujutsu.K-49.com   # client, sesudah: kedua server serial 2026101202 dan 10.88.4.10
```

Hasil:

| | Sebelum (serial `2026101201`) | Sesudah (serial `2026101202`) |
| --- | --- | --- |
| `@10.88.1.2` `utahime` | `NXDOMAIN` untuk `tengen` | `NOERROR`, `tengen` = `10.88.4.10` |
| `@10.88.1.3` `shoko` | `NXDOMAIN` untuk `tengen` | `NOERROR`, `tengen` = `10.88.4.10` |

`shoko` tidak disentuh di antara dua pengujian itu. Zone transfer yang diminta dari client berakhir `Transfer failed.`, jadi `allow-transfer` memang hanya mengizinkan `shoko`.

Keluaran pengujian "sesudah" di `itadori` (teks terminal):

```text
===== @10.88.1.2 =====
--- SOA of jujutsu.K-49.com
;; flags: qr aa; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3
jujutsu.K-49.com.  604800  IN  SOA  utahime.jujutsu.K-49.com. root.jujutsu.K-49.com. 2026101202 604800 86400 2419200 604800
--- A of tengen.jujutsu.K-49.com
;; ->>HEADER<<- opcode: QUERY, status: NOERROR
tengen.jujutsu.K-49.com. 604800  IN  A  10.88.4.10
===== @10.88.1.3 =====
--- SOA of jujutsu.K-49.com
;; flags: qr aa; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3
jujutsu.K-49.com.  604800  IN  SOA  utahime.jujutsu.K-49.com. root.jujutsu.K-49.com. 2026101202 604800 86400 2419200 604800
--- A of tengen.jujutsu.K-49.com
;; ->>HEADER<<- opcode: QUERY, status: NOERROR
tengen.jujutsu.K-49.com. 604800  IN  A  10.88.4.10
===== zone transfer requested from this client (must be refused) =====
; Transfer failed.
```

`utahime`: cek zona OK (serial 2026101201), `named` berjalan, SOA

![`utahime`: cek zona OK (serial 2026101201), `named` berjalan, SOA](11/proof/11_utahime_setup-soa_233841.png)

`shoko`: zona tersalin dari `utahime`, SOA serial 2026101201

![`shoko`: zona tersalin dari `utahime`, SOA serial 2026101201](11/proof/11_shoko_setup-transfer-soa_233910.png)

`shoko`: salinan zona dalam bentuk teks

![`shoko`: salinan zona dalam bentuk teks](11/proof/11_shoko_text-copy-of-zone_234625.png)

`itadori`: kedua server menjawab, zone transfer dari client ditolak

![`itadori`: kedua server menjawab, zone transfer dari client ditolak](11/proof/11_itadori_dig-both-axfr-refused_233937.png)

`itadori`, sebelum: kedua server serial 2026101201 dan NXDOMAIN untuk `tengen` (bagian 1)

![`itadori`, sebelum: kedua server serial 2026101201 dan NXDOMAIN untuk `tengen` (bagian 1)](11/proof/11_itadori_before-serial-visible-a_235143.png)

`itadori`, sebelum: bagian 2

![`itadori`, sebelum: bagian 2](11/proof/11_itadori_before-serial-visible-b_235203.png)

`utahime`: serial dinaikkan 2026101201 -> 2026101202, zona di-reload

![`utahime`: serial dinaikkan 2026101201 -> 2026101202, zona di-reload](11/proof/11_utahime_serial-raised_235440.png)

> Tangkapan layar pengujian "sesudah" ditunjukkan saat demo. Hasilnya saat ini baru berupa teks terminal di atas.

---

## Bagian Anggota Kedua

<!-- Disiapkan untuk teman satu kelompok. Soal 12 dan seterusnya. -->

| Keterangan | Isi |
| ---------- | --- |
| Nama |  |
| NRP |  |
| Soal |  |

|  |
| --- |
|  |
|  |
|  |

---

## Struktur repository

```text
.
├── README.md              laporan ini
├── GLOSSARY.md            penjelasan istilah
├── topology/              gambar topologi GNS3
├── tools/push-script.sh   menyalin script ke /root node dan mengecek checksum
└── 01 ... 11/             satu folder per soal
    ├── NN_<node>_<kata>.sh    script soal tersebut
    └── proof/                 tangkapan layar soal tersebut
```
