# TICKET-006 — Testing & Verification: Semua Skenario BUG-001

| Field | Value |
|---|---|
| **ID** | TICKET-006 |
| **Bug Ref** | BUG-001 |
| **Type** | QA / Testing |
| **Priority** | 🟠 P1 — High |
| **Status** | `TODO` |
| **Estimasi** | 30 menit |
| **Depends On** | ✅ TICKET-001, TICKET-002, TICKET-003, TICKET-004, TICKET-005 harus selesai |
| **File Target** | — (tidak ada perubahan kode) |

---

## Tujuan

Memverifikasi bahwa semua perbaikan dari TICKET-001 s/d TICKET-005 bekerja dengan benar, tidak ada regresi, dan semua acceptance criteria dari PRD.md terpenuhi.

---

## Prasyarat

Sebelum menjalankan test ini, pastikan:
- [ ] TICKET-001 sudah selesai dan di-merge
- [ ] TICKET-002 sudah selesai dan di-merge
- [ ] TICKET-003 sudah selesai dan di-merge
- [ ] TICKET-004 sudah selesai dan di-merge
- [ ] TICKET-005 sudah selesai dan di-merge
- [ ] Aplikasi dapat di-build tanpa error: `flutter build apk --debug`

---

## Jalankan Analisis Statis

```bash
# Dari root project
flutter analyze

# Expected: No issues found! (atau hanya existing warnings yang sudah ada sebelumnya)
```

---

## Skenario Test: Navigasi Drawer (Anti-Regression)

Jalankan satu per satu, tandai ✅ jika lulus, ❌ jika gagal.

| ID | Langkah | Expected Result | Status |
|---|---|---|---|
| T-01 | Buka aplikasi → lihat AppBar di Task Master | Ikon ☰ tampil di kiri atas | ⬜ |
| T-02 | Buka Drawer → tap **My Checklist** → lihat AppBar | Ikon ☰ tampil (bukan ←) | ⬜ |
| T-03 | Tap ☰ di My Checklist | Drawer terbuka normal | ⬜ |
| T-04 | Buka Drawer → tap **My Note** → lihat AppBar | Ikon ☰ tampil (bukan ←) | ⬜ |
| T-05 | Tap ☰ di My Note | Drawer terbuka normal | ⬜ |
| T-06 | Buka Drawer → tap **My Prompt** → lihat AppBar | Ikon ☰ tampil (bukan ←) | ⬜ |
| T-07 | Buka Drawer → tap **My Documents** → lihat AppBar | Ikon ☰ tampil (bukan ←) | ⬜ |
| T-08 | Navigasi ke semua halaman via Drawer, tap tombol leading di tiap halaman | Tidak ada black screen di halaman manapun | ⬜ |

---

## Skenario Test: Navigasi Detail (Sub-Route Harus Tetap Normal)

| ID | Langkah | Expected Result | Status |
|---|---|---|---|
| T-09 | Di My Checklist → tap salah satu Group | Masuk ke Checklist Detail Screen | ⬜ |
| T-10 | Di Checklist Detail → lihat AppBar | Ikon ← (panah back) tampil | ⬜ |
| T-11 | Tap ← di Checklist Detail | Kembali ke My Checklist dengan benar, tidak black screen | ⬜ |
| T-12 | Di My Note → tap salah satu Note group/card | Masuk ke Note Detail Screen | ⬜ |
| T-13 | Di Note Detail → lihat AppBar | Ikon ← (panah back) tampil | ⬜ |
| T-14 | Tap ← di Note Detail | Kembali ke My Note dengan benar, tidak black screen | ⬜ |

---

## Skenario Test: Regresi Task Master

| ID | Langkah | Expected Result | Status |
|---|---|---|---|
| T-15 | Buka aplikasi fresh → lihat Task Master → lihat AppBar | Ikon ☰ tampil (tidak regresi) | ⬜ |
| T-16 | Buka dan tutup Drawer di Task Master | Drawer berfungsi normal | ⬜ |

---

## Skenario Test: Navigasi Silang (Cross-Navigation)

| ID | Langkah | Expected Result | Status |
|---|---|---|---|
| T-17 | My Checklist → Drawer → My Note → Drawer → My Prompt → Drawer → Task Master | Setiap halaman selalu tampil ☰, tidak pernah ← | ⬜ |
| T-18 | Ulangi T-17 dalam urutan terbalik | Hasil sama, tidak ada black screen | ⬜ |

---

## Acceptance Criteria dari PRD

Verifikasi bahwa semua AC dari PRD.md terpenuhi:

| AC ID | Kriteria | Status |
|---|---|---|
| AC-01 | Semua halaman utama menampilkan ☰ setelah navigasi dari Drawer | ⬜ |
| AC-02 | Tombol ☰ membuka Drawer dengan benar | ⬜ |
| AC-03 | Layar tidak menjadi hitam setelah tap tombol leading di halaman manapun | ⬜ |
| AC-04 | Halaman Detail tetap menampilkan ← yang berfungsi normal | ⬜ |
| AC-05 | Perilaku konsisten di Android dan Linux Desktop | ⬜ |

---

## Dokumentasi Hasil

Setelah semua test dijalankan, isi bagian ini:

```
Tanggal Test  : _______________
Tester        : _______________
Build Version : _______________
Platform      : _______________

LULUS : __ dari 18 skenario
GAGAL : __ dari 18 skenario

Catatan kegagalan (jika ada):
- ...
```

---

## Definisi Selesai (DoD)

Tiket ini dianggap selesai jika:
- [ ] Semua 18 skenario test bertanda ✅
- [ ] Semua 5 AC dari PRD.md bertanda ✅
- [ ] Tidak ada black screen yang bisa direproduksi
- [ ] `flutter analyze` tidak mengeluarkan error baru
- [ ] Status PRD.md diperbarui dari `OPEN` → `RESOLVED`
