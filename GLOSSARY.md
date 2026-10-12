# Glosarium

Istilah yang dipakai di laporan ini, dijelaskan singkat.

## DHCP dan jaringan

- **DHCP**: layanan yang membagikan alamat IP, gateway, DNS, dan pengaturan lain ke client secara otomatis.
- **DORA**: empat pesan DHCP berurutan: **D**iscover (client berteriak "ada server DHCP?"), **O**ffer (server menawarkan alamat), **R**equest (client minta alamat yang ditawarkan), **A**cknowledge (server mengiyakan dan lease dimulai).
- **isc-dhcp-server**: paket Debian untuk DHCP server buatan ISC. Programnya bernama `dhcpd`. Konfigurasi ada di `/etc/dhcp/dhcpd.conf`, interface yang didengar di `/etc/default/isc-dhcp-server`, catatan lease di `/var/lib/dhcp/dhcpd.leases`. Perintah penting: `dhcpd -t` (cek konfigurasi). Error "No subnet declaration" muncul kalau tidak ada blok `subnet` yang cocok dengan interface server.
- **DHCP relay**: perantara yang menerima broadcast DHCP di jaringan client lalu meneruskannya ke server sebagai paket unicast, karena router tidak meneruskan broadcast. Di sini `jichi`.
- **giaddr**: "gateway IP address", field di dalam paket DHCP yang diisi relay dengan alamat interface-nya yang menerima request. Server memakainya untuk memilih scope subnet dan sebagai tujuan jawaban. Di `tcpdump -vvv` tampil sebagai `Gateway-IP`. Client yang meminta langsung tanpa relay mengisinya `0.0.0.0`.
- **yiaddr**: "your IP address", alamat yang diberikan server ke client (tampil sebagai `Your-IP`).
- **xid**: transaction id. Keempat pesan DORA dalam satu proses memakai `xid` yang sama.
- **Lease**: lamanya client boleh memakai sebuah alamat, diatur `default-lease-time` dan `max-lease-time` (detik). **Renew**: client memperpanjang, otomatis di sekitar separuh waktu lease. **Release**: client mengembalikan alamat lebih awal. **Expire**: waktu habis tanpa renew atau release.
- **DHCPRELEASE**: pesan unicast ke server yang berarti "alamat ini saya kembalikan". Dikirim saat `ifdown eth0`. Bukan bagian dari DORA.
- **MAC address**: alamat perangkat keras sebuah interface, 6 byte ditulis heksadesimal berpasangan (`f2:dd:ec:51:c9:cb`). Dipakai DHCP untuk class dan static lease. MAC tetap utuh di dalam paket DHCP walau melewati relay.
- **Class dan subclass**: pengelompokan client di `dhcpd.conf`, di sini berdasarkan MAC (`match hardware`). Pool bisa dibatasi dengan `allow members of "<class>"`.
- **Static lease / fixed address**: blok `host` dengan `hardware ethernet` dan `fixed-address`, sehingga satu MAC selalu mendapat alamat yang sama.
- **NAT / MASQUERADE**: router mengganti alamat sumber paket dari jaringan internal dengan alamat interface keluarnya, supaya balasan dari internet bisa kembali.
- **IP forwarding**: pengaturan kernel (`net.ipv4.ip_forward=1`) yang membuat Linux meneruskan paket antar interface, syarat sebuah router.

## Alat dan paket

- **ifupdown**: paket yang menyediakan `ifup` dan `ifdown`. Keduanya membaca `/etc/network/interfaces` dan menaikkan interface dengan alamat yang tertulis, sehingga alamat bertahan setelah restart. Berbeda dengan `ip addr add` yang langsung berlaku tapi hilang saat restart.
- **tcpdump**: program perekam paket di sebuah interface. Opsi: `-n` (tanpa resolusi nama), `-i` (interface), `-vvv` (tampilkan semua field), `-w` (simpan ke file), `-r` (baca file). Filter DHCP: `port 67 or port 68` (server dan relay memakai UDP 67, client UDP 68).
- **dumb-init**: program kecil yang berjalan sebagai PID 1 di dalam container. Ia hanya menjalankan perintah awal dan membereskan proses anak, tidak menjalankan service.
- **policy-rc.d**: script di `/usr/sbin/policy-rc.d` yang ditanya Debian sebelum sebuah paket boleh menjalankan service. Kode keluar `0` berarti boleh, `101` berarti dilarang. Image `debinet` sudah menyertakannya (kode `101`) sehingga pemasangan paket tidak langsung menjalankan service yang belum punya konfigurasi.

## Boot di image debinet

- **Volume persisten**: folder yang disimpan GNS3 di luar container sehingga bertahan setelah restart. Di node ini hanya `/root` dan `/etc/network`.
- **Boot hook (`/root/init.sh`)**: urutan boot: GNS3 memasang volume dan menjalankan `ifup -a`, lalu `/etc/debinet-init.sh` menjalankan `/root/init.sh` kalau ada dan bisa dieksekusi. Karena tidak ada systemd, di sinilah service dinyalakan saat boot. Hook kami menulis log ke `/root/boot.log`.
- **Cek proses, bukan `status`**: `service isc-dhcp-relay status` hanya mengecek ada tidaknya file `/var/run/dhcrelay.pid`. File pid lama yang tersisa membuatnya melapor "running" padahal tidak ada proses. Gunakan `pgrep -a dhcrelay`.

## DNS

- **BIND9 / named**: server DNS yang paling banyak dipakai. Paketnya `bind9`, programnya `named`, dijalankan dengan `service named start|restart`. File: `/etc/bind/named.conf.local` (zona kita), file zona di `/etc/bind/...` (master) dan `/var/cache/bind/` (salinan slave). Alat cek: `named-checkconf`, `named-checkzone <zona> <file>`, `rndc reload <zona>`.
- **Zona**: bagian ruang nama DNS yang menjadi tanggung jawab satu server. Di sini `jujutsu.K-49.com`.
- **SOA**: record pertama zona. Berisi server primary, email admin (`root.jujutsu.K-49.com.` berarti `root@jujutsu.K-49.com`), dan timer refresh, retry, expire, serta negative-cache TTL.
- **Serial**: angka di SOA yang harus naik setiap zona berubah. Slave menyalin zona hanya kalau serial master lebih besar dari miliknya. Format yang dipakai: `YYYYMMDDnn`.
- **NS**: record yang menyebut server otoritatif untuk zona (`utahime` dan `shoko`).
- **A**: record yang memetakan nama ke alamat IPv4.
- **Titik di akhir nama** (`utahime.jujutsu.K-49.com.`): nama lengkap. Tanpa titik, nama zona ditambahkan otomatis.
- **Master dan slave**: master adalah tempat zona diubah, slave menyalinnya.
- **Zone transfer (AXFR)**: cara slave menyalin seluruh zona. `allow-transfer { 10.88.1.3; };` di master hanya mengizinkan `shoko`. Pihak lain, misalnya client, ditolak.
- **NOTIFY**: pesan dari master ke slave bahwa zona berubah (`notify yes;` dan `also-notify { ... };`). Slave langsung mengecek serial, tidak perlu menunggu waktu refresh. NOTIFY hanya memberi tahu "ada perubahan". Zona baru ditarik kalau serial master lebih tinggi.
- **dig**: perintah untuk bertanya ke server DNS dan melihat jawaban lengkap, misalnya `dig @10.88.1.3 jujutsu.K-49.com SOA`. Yang dibaca: `status` (`NOERROR` atau `NXDOMAIN`), flag `aa` (jawaban dari server otoritatif), dan bagian ANSWER.
