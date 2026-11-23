# PRD — AppBar Leading Button Menampilkan Ikon Salah Saat Navigasi Antar Halaman

**Nomor Masalah:** BUG-001  
**Tanggal Dibuat:** 2026-11-23  
**Status:** `OPEN`  
**Prioritas:** `HIGH` — Menyebabkan layar hitam (black screen) & UX rusak  
**Reporter:** User  
**Feature Area:** Navigation / AppBar / Drawer Menu  

---

## 1. Latar Belakang

Aplikasi **rutinitasku** menggunakan pola navigasi flat berbasis `Drawer` untuk berpindah antar halaman utama (Task Master, My Checklist, My Note, Activity Journal, My Prompt, My Documents, dll.).

Semua halaman utama menggunakan widget `BaseDetailAppBar` sebagai AppBar standar, di mana tombol leading (kiri atas) berfungsi sebagai:
- **Ikon menu (hamburger ☰ / `Icons.menu`)** → membuka Drawer navigasi, ketika pengguna berada di halaman root (tidak ada halaman sebelumnya di stack)
- **Ikon panah balik (← / `Icons.arrow_back`)** → kembali ke halaman sebelumnya, ketika ada rute di bawah halaman ini di navigation stack

---

## 2. Deskripsi Masalah

### 2.1 Gejala yang Diamati

Ketika pengguna **berpindah halaman** melalui Drawer (misalnya dari **Task Master → My Checklist**, atau **My Checklist → My Note**), tombol leading di AppBar halaman tujuan menampilkan **ikon panah balik (←)** alih-alih **ikon menu hamburger (☰)**.

Jika pengguna menekan tombol panah balik tersebut:
1. Aplikasi mencoba melakukan `Navigator.pop(context)`
2. Karena rute di bawahnya adalah halaman-halaman lama yang sebenarnya tidak valid lagi (sudah di-replace tapi entry-nya masih ada di stack), layar menjadi **hitam (black screen)** atau UI tidak ter-render dengan benar
3. Pengguna "terjebak" tanpa bisa kembali ke kondisi normal kecuali menutup dan membuka ulang aplikasi

### 2.2 Langkah Reproduksi

1. Buka aplikasi — berada di halaman **Task Master**
2. Buka Drawer, tap **My Checklist** → navigasi ke halaman My Checklist
3. Perhatikan tombol leading di AppBar My Checklist → **menampilkan ← (panah balik)**
4. Tap tombol ← tersebut → **layar menjadi hitam**

Varian lain:
- Task Master → My Note → tap ← → layar hitam
- My Checklist → My Note → tap ← → layar hitam
- Halaman manapun → halaman lain via Drawer → tap ← → layar hitam

### 2.3 Halaman yang Terdampak

| Halaman | Widget Utama | Menggunakan `forceShowMenu` |
|---|---|---|
| Task Master | `HomeScreen` / `BaseDetailAppBar` langsung | ✅ Ya (`forceShowMenu: true`) |
| My Checklist | `GroupedSectionLayout` | ❌ **Tidak** |
| My Note | `GroupedSectionLayout` | ❌ **Tidak** |
| Activity Journal | (belum dikonfirmasi) | ❌ **Tidak** |
| My Prompt | `GroupedSectionLayout` | ❌ **Tidak** |
| My Documents | `GroupedSectionLayout` | ❌ **Tidak** |
| Random Generator | (belum dikonfirmasi) | ❌ **Tidak** |
| Data Center | (belum dikonfirmasi) | ❌ **Tidak** |

---

## 3. Dampak Bisnis & Pengguna

### 3.1 Dampak UX
- **Sangat mengganggu** — Pengguna secara natural akan menekan tombol di kiri atas AppBar untuk membuka menu/navigasi
- Tombol yang terlihat seperti "back" tetapi menyebabkan layar hitam menimbulkan kesan **aplikasi crash**
- Pengguna tidak dapat kembali ke halaman normal tanpa menutup paksa aplikasi

### 3.2 Dampak Reputasi
- Bug terlihat pada interaksi pertama pengguna dengan fitur navigasi — kesan pertama buruk
- Dapat menyebabkan uninstall oleh pengguna baru

### 3.3 Frekuensi Kejadian
- **Sangat tinggi** — Bug terpicu setiap kali user berpindah halaman lewat Drawer (alur navigasi utama aplikasi)

---

## 4. Tujuan & Keberhasilan

### 4.1 Tujuan Produk

1. Tombol leading AppBar **selalu menampilkan ikon menu (☰)** ketika halaman adalah root navigation (halaman utama yang dicapai via Drawer)
2. Layar tidak pernah menjadi hitam akibat `Navigator.pop()` yang salah
3. Navigasi antar halaman utama berjalan mulus dan konsisten

### 4.2 Kriteria Penerimaan (Acceptance Criteria)

| ID | Kriteria | Priority |
|---|---|---|
| AC-01 | Semua halaman utama (Checklist, Note, Prompt, Docs, dll.) menampilkan ikon ☰ setelah navigasi dari Drawer | Must Have |
| AC-02 | Tombol ☰ membuka Drawer dengan benar | Must Have |
| AC-03 | Layar tidak menjadi hitam setelah tap tombol leading di halaman manapun | Must Have |
| AC-04 | Halaman Detail (sub-halaman yang dipush via `Navigator.push`) tetap menampilkan ← (panah back) yang berfungsi normal | Must Have |
| AC-05 | Perilaku konsisten di semua platform yang didukung (Android, Linux Desktop) | Should Have |

---

## 5. Ruang Lingkup

### 5.1 Dalam Ruang Lingkup (In Scope)
- Perbaikan logika `canPop` di `BaseDetailAppBar`
- Penambahan `forceShowMenu` parameter ke `GroupedSectionLayout`
- Propagasi parameter ke semua screen yang menggunakan `GroupedSectionLayout`
- Validasi bahwa halaman detail (sub-rute) masih berfungsi normal

### 5.2 Di Luar Ruang Lingkup (Out of Scope)
- Refactor sistem navigasi ke GoRouter/AutoRoute
- Perubahan desain visual AppBar
- Fitur animasi transisi antar halaman

---

## 6. Risiko

| Risiko | Kemungkinan | Dampak | Mitigasi |
|---|---|---|---|
| Halaman detail kehilangan tombol back | Sedang | Tinggi | Test manual di semua sub-rute setelah fix |
| Regresi di halaman yang sudah benar (Task Master) | Rendah | Sedang | Task Master sudah pakai `forceShowMenu: true`, tidak perlu diubah |
| Bug tersembunyi di halaman yang belum dikonfirmasi | Sedang | Sedang | Audit semua halaman yang pakai `BaseDetailAppBar` |

---

## 7. Timeline

| Fase | Deskripsi | Estimasi |
|---|---|---|
| Analysis | Sudah selesai — root cause teridentifikasi | ✅ Done |
| Implementation | Fix `GroupedSectionLayout` + screen-level propagation | 1–2 jam |
| Testing | Manual test semua navigasi scenario | 30 menit |
| Release | Merge & deploy | Segera |
