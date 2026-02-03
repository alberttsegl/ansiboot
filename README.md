# Ansiboot
Automated Ansible Bootstrap Tool atau Ansiboot adalah tool Command Line Interface berbasis Pure Bash yang dirancang untuk melakukan bootstrap dan manajemen awal environment Ansible pada server atau virtual machine yang masih kosong (fresh server).

Dengan satu perintah, engineer dapat menyiapkan Ansible pada server yang baru bisa diakses via SSH tanpa playbook YAML, tanpa scripting Python tambahan, dan tanpa dependency kompleks.

---

# Problem Statement
Dalam praktik DevOps dan System Administration, setup awal Ansible sering menemui kendala :
- Perbedaan distribusi Linux antar server
- Proses instalasi Ansible yang manual dan berulang
- Konfigurasi SSH yang tidak konsisten
- Inventory yang tidak terstandarisasi
- Tidak adanya validasi awal sebelum Ansible digunakan

Dampaknya :
- Setup lebih lama
- Potensi human error
- Environment tidak konsisten

---

# Solution
Ansiboot menyelesaikan masalah tersebut dengan pendekatan :
- Pure Bash Implementation - Dapat dijalankan di hampir semua Linux environment, termasuk server minimal.
- Native Ansible CLI Usage - Tidak menggantikan Ansible, hanya mempermudah bootstrap awal.
- Modular Architecture - Setiap fungsi dipisahkan ke dalam modul Bash yang jelas.
- Safe-by-default & Idempotent - Aman dijalankan berulang, dengan logging dan validasi.

---

## Installation
### Clone Repository
```bash
git clone https://github.com/alberttsegl/Ansiboot
cd ansiboot
```

### Beri Permission Eksekusi
```bash
chmod +x ansiboot.sh
```

### Tambahkan ke PATH
```bash
sudo ln -s $(pwd)/ansiboot.sh /usr/local/bin/ansiboot
```

---

## Quick Start
### Bootstrap Ansible di Server Lokal atau Remote
```bash
./ansiboot.sh init
```

### Setup Inventory
```bash
./ansiboot.sh inventory init
```

### Setup SSH Key ke Host
```bash
./ansiboot.sh init./ansiboot.sh ssh setup root@[IP]
```

### Test Konektivitas
```bash
./ansiboot.sh ping
```

### Jalankan adhoc Command
```bash
./ansiboot.sh run "uptime"
```