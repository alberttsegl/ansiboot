# Ansiboot Command Reference
**Dokumen** ini berisi daftar lengkap command Ansiboot, termasuk deskripsi, fungsi, dan modul internal yang terlibat.
Gunakan dokumen ini sebagai referensi resmi CLI, bukan panduan step-by-step.

---

## Command Format
Semua command dijalankan melalui :
```bash
ansiboot <command> [subcommand] [options]
```

Jika belum masuk PATH
```bash
./ansiboot.sh <command>
```

---

## Global Commands
```bash
ansiboot --help
```
Menampilkan daftar command yang tersedia beserta ringkasan singkat

```bash
ansiboot --version
```
Menampilkan versi Ansiboot yang sedang digunakan

```bash
ansiboot init
```
Melakukan bootstrap awal environment Ansible

```bash
ansiboot validate
```
Melakukan pre-flight check sebelum Ansible digunakan

```bash
ansiboot inventory init
```
Membuat inventory awal Ansiboot

```bash
ansiboot inventory add
```
Menambahkan host atau group ke inventory

```bash
ansiboot inventory list
```
Menampilkan inventory yang sedang aktif

```bash
ansiboot ssh setup <user@host>
```
Menyiapkan SSH key-based authentication ke target host

```bash
ansiboot ssh test
```
Menyiapkan SSH key-based authentication ke target host

```bash
ansiboot ping
```
Menjalankan ansible all -m ping ke seluruh host

```bash
ansiboot run "<command>"
```
Menjalankan perintah ad-hoc Ansible ke seluruh host

```bash
ansiboot --dry-run <command>
```
Menjalankan command dalam mode simulasi

```bash
ansiboot self-check
```
Melakukan pengecekan kesehatan environment Ansiboot

```bash
ansiboot uninstall
```
Menghapus Ansiboot dari sistem