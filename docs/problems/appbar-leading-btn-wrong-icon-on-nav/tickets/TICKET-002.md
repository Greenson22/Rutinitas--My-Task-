# TICKET-002 — Screen Fix: `checklist_screen.dart`

| Field | Value |
|---|---|
| **ID** | TICKET-002 |
| **Bug Ref** | BUG-001 |
| **Type** | Bug Fix — Screen Level |
| **Priority** | 🟠 P1 — High |
| **Status** | `DONE` |
| **Estimasi** | 15 menit |
| **Depends On** | ✅ TICKET-001 harus selesai terlebih dahulu |
| **File Target** | `lib/features/checklist/presentation/checklist_screen/checklist_screen.dart` |

---

## Latar Belakang

`DailyScreen` (My Checklist) adalah salah satu root-screen yang diakses melalui Drawer navigasi. Screen ini menggunakan `GroupedSectionLayout` sebagai wrapper utamanya. Setelah TICKET-001 menambahkan parameter `forceShowMenu` ke `GroupedSectionLayout`, tiket ini bertugas meneruskan nilai `true` di screen ini.

**Gejala jika tidak diperbaiki:**
- Navigasi dari halaman lain → My Checklist → tombol AppBar menampilkan ← (panah back)
- Menekan ← → black screen

---

## Acceptance Criteria

- [x] `GroupedSectionLayout` di `DailyScreen` menerima `forceShowMenu: true`
- [x] Setelah navigasi dari Drawer ke My Checklist, AppBar menampilkan ikon ☰ (menu)
- [x] Menekan ☰ membuka Drawer dengan benar
- [x] Navigasi ke detail checklist (tap group) masih berfungsi normal dengan ikon ←

---

## Langkah Implementasi

### Lokasi perubahan

File: `lib/features/checklist/presentation/checklist_screen/checklist_screen.dart`

Cari blok `GroupedSectionLayout<ChecklistGroup>(` di dalam method `build()` (sekitar baris 778).

### Diff

```dart
// SEBELUM:
body: GroupedSectionLayout<ChecklistGroup>(
  title: 'Checklist Groups',
  drawer: const DrawerMenu(isDailyActive: true),
  isLoading: _controller.isLoading,
  // ...

// SESUDAH:
body: GroupedSectionLayout<ChecklistGroup>(
  title: 'Checklist Groups',
  forceShowMenu: true,                          // ← TAMBAH BARIS INI
  drawer: const DrawerMenu(isDailyActive: true),
  isLoading: _controller.isLoading,
  // ...
```

> [!NOTE]
> Hanya **satu baris** yang perlu ditambahkan. Pastikan indentasi konsisten dengan kode di sekitarnya (2 spasi).

---

## Verifikasi Manual

1. Jalankan aplikasi
2. Dari halaman Task Master → buka Drawer → tap **My Checklist**
3. ✅ AppBar menampilkan ikon ☰
4. ✅ Tap ☰ → Drawer terbuka
5. ✅ Tap salah satu group → masuk ke detail screen → AppBar menampilkan ← (back normal)
6. ✅ Tap ← → kembali ke My Checklist

```bash
flutter analyze lib/features/checklist/presentation/checklist_screen/checklist_screen.dart
```

---

## Log Eksekusi & Catatan

- **Waktu Mulai**: 2026-11-23 12:47:18 +08:00
- **Waktu Selesai**: 2026-11-23 12:53:30 +08:00
- **Durasi**: ~6 menit
- **Perubahan yang Dilakukan**:
  - Menambahkan `forceShowMenu: true` pada `GroupedSectionLayout<ChecklistGroup>` di [checklist_screen.dart](file:///home/lemon-manis-22/Projects/Flutter/rutinitasku/lib/features/checklist/presentation/checklist_screen/checklist_screen.dart#L780).
- **Hasil Verifikasi**:
  - `flutter analyze lib/features/checklist/presentation/checklist_screen/checklist_screen.dart`: Tidak ada warning atau error baru.
  - `flutter test`: 315 tests passed tanpa kegagalan/regresi.
  - Code Review (Standards & Spec): Lulus dan disetujui (Status: APPROVED).

