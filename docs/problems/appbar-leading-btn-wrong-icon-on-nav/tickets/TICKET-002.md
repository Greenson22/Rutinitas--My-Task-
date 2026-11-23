# TICKET-002 — Screen Fix: `checklist_screen.dart`

| Field | Value |
|---|---|
| **ID** | TICKET-002 |
| **Bug Ref** | BUG-001 |
| **Type** | Bug Fix — Screen Level |
| **Priority** | 🟠 P1 — High |
| **Status** | `TODO` |
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

- [ ] `GroupedSectionLayout` di `DailyScreen` menerima `forceShowMenu: true`
- [ ] Setelah navigasi dari Drawer ke My Checklist, AppBar menampilkan ikon ☰ (menu)
- [ ] Menekan ☰ membuka Drawer dengan benar
- [ ] Navigasi ke detail checklist (tap group) masih berfungsi normal dengan ikon ←

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
