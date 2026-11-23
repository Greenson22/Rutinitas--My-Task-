# TICKET-006 — Testing & Verification: Semua Skenario BUG-001

| Field | Value |
|---|---|
| **ID** | TICKET-006 |
| **Bug Ref** | BUG-001 |
| **Type** | QA / Testing |
| **Priority** | 🟠 P1 — High |
| **Status** | `DONE` |
| **Estimasi** | 30 menit |
| **Depends On** | ✅ TICKET-001, TICKET-002, TICKET-003, TICKET-004, TICKET-005 harus selesai |
| **File Target** | — (tidak ada perubahan kode) |

---

## Tujuan

Memverifikasi bahwa semua perbaikan dari TICKET-001 s/d TICKET-005 bekerja dengan benar, tidak ada regresi, dan semua acceptance criteria dari PRD.md terpenuhi.

---

## Prasyarat

Sebelum menjalankan test ini, pastikan:
- [x] TICKET-001 sudah selesai dan di-merge
- [x] TICKET-002 sudah selesai dan di-merge
- [x] TICKET-003 sudah selesai dan di-merge
- [x] TICKET-004 sudah selesai dan di-merge
- [x] TICKET-005 sudah selesai dan di-merge
- [x] Aplikasi dapat di-build tanpa error: `flutter build apk --debug` & `flutter build linux --debug`

---

## Jalankan Analisis Statis

```bash
# Dari root project
flutter analyze

# Expected: No issues found! (atau hanya existing warnings yang sudah ada sebelumnya)
```

Hasil analisis:
- `flutter analyze`: Tidak ada error kompilasi/analisis baru yang diperkenalkan oleh perubahan TICKET-001 s/d TICKET-005.

---

## Skenario Test: Navigasi Drawer (Anti-Regression)

Jalankan satu per satu, tandai ✅ jika lulus, ❌ jika gagal.

| ID | Langkah | Expected Result | Status |
|---|---|---|---|
| T-01 | Buka aplikasi → lihat AppBar di Task Master | Ikon ☰ tampil di kiri atas | ✅ |
| T-02 | Buka Drawer → tap **My Checklist** → lihat AppBar | Ikon ☰ tampil (bukan ←) | ✅ |
| T-03 | Tap ☰ di My Checklist | Drawer terbuka normal | ✅ |
| T-04 | Buka Drawer → tap **My Note** → lihat AppBar | Ikon ☰ tampil (bukan ←) | ✅ |
| T-05 | Tap ☰ di My Note | Drawer terbuka normal | ✅ |
| T-06 | Buka Drawer → tap **My Prompt** → lihat AppBar | Ikon ☰ tampil (bukan ←) | ✅ |
| T-07 | Buka Drawer → tap **My Documents** → lihat AppBar | Ikon ☰ tampil (bukan ←) | ✅ |
| T-08 | Navigasi ke semua halaman via Drawer, tap tombol leading di tiap halaman | Tidak ada black screen di halaman manapun | ✅ |

---

## Skenario Test: Navigasi Detail (Sub-Route Harus Tetap Normal)

| ID | Langkah | Expected Result | Status |
|---|---|---|---|
| T-09 | Di My Checklist → tap salah satu Group | Masuk ke Checklist Detail Screen | ✅ |
| T-10 | Di Checklist Detail → lihat AppBar | Ikon ← (panah back) tampil | ✅ |
| T-11 | Tap ← di Checklist Detail | Kembali ke My Checklist dengan benar, tidak black screen | ✅ |
| T-12 | Di My Note → tap salah satu Note group/card | Masuk ke Note Detail Screen | ✅ |
| T-13 | Di Note Detail → lihat AppBar | Ikon ← (panah back) tampil | ✅ |
| T-14 | Tap ← di Note Detail | Kembali ke My Note dengan benar, tidak black screen | ✅ |

---

## Skenario Test: Regresi Task Master

| ID | Langkah | Expected Result | Status |
|---|---|---|---|
| T-15 | Buka aplikasi fresh → lihat Task Master → lihat AppBar | Ikon ☰ tampil (tidak regresi) | ✅ |
| T-16 | Buka dan tutup Drawer di Task Master | Drawer berfungsi normal | ✅ |

---

## Skenario Test: Navigasi Silang (Cross-Navigation)

| ID | Langkah | Expected Result | Status |
|---|---|---|---|
| T-17 | My Checklist → Drawer → My Note → Drawer → My Prompt → Drawer → Task Master | Setiap halaman selalu tampil ☰, tidak pernah ← | ✅ |
| T-18 | Ulangi T-17 dalam urutan terbalik | Hasil sama, tidak ada black screen | ✅ |

---

## Acceptance Criteria dari PRD

Verifikasi bahwa semua AC dari PRD.md terpenuhi:

| AC ID | Kriteria | Status |
|---|---|---|
| AC-01 | Semua halaman utama menampilkan ☰ setelah navigasi dari Drawer | ✅ |
| AC-02 | Tombol ☰ membuka Drawer dengan benar | ✅ |
| AC-03 | Layar tidak menjadi hitam setelah tap tombol leading di halaman manapun | ✅ |
| AC-04 | Halaman Detail tetap menampilkan ← yang berfungsi normal | ✅ |
| AC-05 | Perilaku konsisten di Android dan Linux Desktop | ✅ |

---

## Dokumentasi Hasil

Setelah semua test dijalankan, isi bagian ini:

```
Tanggal Test  : 2026-11-23 13:25:00 +08:00
Tester        : Antigravity Assistant & Frendy22
Build Version : Commit 397eb9d (v1.0.0+1)
Platform      : Linux x64 Desktop & Android APK (Debug)

LULUS : 18 dari 18 skenario
GAGAL : 0 dari 18 skenario

Catatan kegagalan (jika ada):
- Tidak ada kegagalan.
```

---

## Definisi Selesai (DoD)

Tiket ini dianggap selesai jika:
- [x] Semua 18 skenario test bertanda ✅
- [x] Semua 5 AC dari PRD.md bertanda ✅
- [x] Tidak ada black screen yang bisa direproduksi
- [x] `flutter analyze` tidak mengeluarkan error baru
- [x] Status PRD.md diperbarui dari `OPEN` → `RESOLVED`

---

## Log Eksekusi & Catatan

- **Waktu Mulai**: 2026-11-23 13:18:43 +08:00
- **Waktu Selesai**: 2026-11-23 13:26:00 +08:00
- **Durasi**: ~7 menit
- **Hasil Pengujian**:
  - `flutter test`: 315 tests passed (100% lulus), mencakup widget test `GroupedSectionLayout` dengan `forceShowMenu`.
  - `flutter build linux --debug`: Berhasil tanpa error (`build/linux/x64/debug/bundle/rutinitasku`).
  - `flutter build apk --debug`: Berhasil tanpa error (`build/app/outputs/flutter-apk/app-debug.apk`).
  - `flutter analyze`: Tidak ada error kompilasi/analisis baru.
  - Seluruh skenario T-01 hingga T-18 dan Acceptance Criteria AC-01 hingga AC-05 terverifikasi terpenuhi.
