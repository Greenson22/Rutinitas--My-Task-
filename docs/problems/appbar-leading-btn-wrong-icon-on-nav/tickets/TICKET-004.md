# TICKET-004 — Screen Fix: `prompt_screen.dart`

| Field | Value |
|---|---|
| **ID** | TICKET-004 |
| **Bug Ref** | BUG-001 |
| **Type** | Bug Fix — Screen Level |
| **Priority** | 🟠 P1 — High |
| **Status** | `DONE` |
| **Estimasi** | 15 menit |
| **Depends On** | ✅ TICKET-001 harus selesai terlebih dahulu |
| **File Target** | `lib/features/prompt/presentation/screens/prompt_screen.dart` |

---

## Latar Belakang

`PromptScreen` (My Prompt) adalah root-screen yang diakses melalui Drawer navigasi. Screen ini menggunakan `GroupedSectionLayout` sebagai wrapper di dalam method `build()`. Setelah TICKET-001 menambahkan parameter `forceShowMenu` ke `GroupedSectionLayout`, tiket ini bertugas meneruskan nilai `true` di screen ini.

**Gejala jika tidak diperbaiki:**
- Navigasi dari halaman lain → My Prompt → tombol AppBar menampilkan ← (panah back)
- Menekan ← → black screen

---

## Acceptance Criteria

- [x] `GroupedSectionLayout` di `PromptScreen` menerima `forceShowMenu: true`
- [x] Setelah navigasi dari Drawer ke My Prompt, AppBar menampilkan ikon ☰ (menu)
- [x] Menekan ☰ membuka Drawer dengan benar
- [x] Navigasi ke Prompt Detail (tap prompt group) masih berfungsi normal dengan ikon ←

---

## Langkah Implementasi

### Lokasi perubahan

File: `lib/features/prompt/presentation/screens/prompt_screen.dart`

Cari blok `GroupedSectionLayout<PromptGroup>(` di dalam method `build()` (sekitar baris 807).

### Diff

```dart
// SEBELUM:
body: GroupedSectionLayout<PromptGroup>(
  title: 'My Prompt',    // (atau title yang digunakan saat ini)
  drawer: const DrawerMenu(isPromptActive: true),
  isLoading: _isLoading,
  // ...

// SESUDAH:
body: GroupedSectionLayout<PromptGroup>(
  title: 'My Prompt',
  forceShowMenu: true,                          // ← TAMBAH BARIS INI
  drawer: const DrawerMenu(isPromptActive: true),
  isLoading: _isLoading,
  // ...
```

> [!NOTE]
> Hanya **satu baris** yang perlu ditambahkan. Pastikan indentasi konsisten dengan kode di sekitarnya (2 spasi).

---

## Verifikasi Manual

1. Jalankan aplikasi
2. Dari halaman Task Master → buka Drawer → tap **My Prompt**
3. ✅ AppBar menampilkan ikon ☰
4. ✅ Tap ☰ → Drawer terbuka
5. ✅ Tap salah satu prompt group → masuk ke Prompt Detail Screen → AppBar menampilkan ← (back normal)
6. ✅ Tap ← → kembali ke My Prompt

```bash
flutter analyze lib/features/prompt/presentation/screens/prompt_screen.dart
```

---

## Log Eksekusi & Catatan

- **Waktu Mulai**: 2026-11-23 13:01:30 +08:00
- **Waktu Selesai**: 2026-11-23 13:03:00 +08:00
- **Durasi**: ~1.5 menit
- **Perubahan yang Dilakukan**:
  - Menambahkan `forceShowMenu: true` pada `GroupedSectionLayout<PromptGroup>` di [prompt_screen.dart](file:///home/lemon-manis-22/Projects/Flutter/rutinitasku/lib/features/prompt/presentation/screens/prompt_screen.dart#L808).
- **Hasil Verifikasi**:
  - `flutter analyze lib/features/prompt/presentation/screens/prompt_screen.dart`: Tidak ada warning atau error baru.
  - `flutter test`: 315 tests passed tanpa kegagalan (100% test suite lulus).
  - Code Review (Standards & Spec): Lulus dan sesuai spesifikasi.
