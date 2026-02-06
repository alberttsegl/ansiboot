# Ansiboot Troubleshooting Guide

Dokumen ini berisi panduan solusi masalah umum saat menggunakan Ansiboot, baik di server lokal maupun remote. Gunakan ini untuk mempercepat debugging dan memastikan environment Ansible tetap konsisten.

---

## Ansiboot Tidak Bisa Dieksekusi
### Masalah
```bash
bash: ./ansiboot.sh: Permission denied
```

### Solusi
Pastikan file memiliki permission eksekusi
```bash
chmod +x ansiboot.sh
```

Jika sudah ditambahkan ke PATH, pastikan symlink benar
```bash
sudo ln -s $(pwd)/ansiboot.sh /usr/local/bin/ansiboot
```

Periksa apakah $PATH termasuk /usr/local/bin
```bash
echo $PATH
```

## SSH Key Setup Gagal
### Masalah
```bash
Permission denied (publickey)
```

### Solusi
Pastikan user target memiliki folder .ssh dengan permission benar (700) dan file authorized_keys (600)
```bash
ssh user@host 'mkdir -p ~/.ssh && chmod 700 ~/.ssh'
ssh-copy-id user@host
```

Periksa apakah ssh-agent aktif dan kunci sudah dimuat
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```

Gunakan opsi verbose untuk debugging
```bash
ssh -vvv user@host
```

## Inventory Tidak Terbaca
### Masalah
```bash
ansiboot inventory list #Tidak menampilkan host
```

### Solusi
Pastikan host sudah ditambahkan dengan benar
```bash
ansiboot inventory add
```

Pastikan host sudah ditambahkan dengan benar
```bash
ansiboot inventory add
```

Periksa format file inventory (inventory/hosts.yml) apakah valid YAML
Jalankan Validasi
```bash
ansiboot validate
```
