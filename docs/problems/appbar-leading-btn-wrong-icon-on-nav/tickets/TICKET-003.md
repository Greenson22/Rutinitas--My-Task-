# TICKET-003 — Screen Fix: `note_screen.dart`

| Field | Value |
|---|---|
| **ID** | TICKET-003 |
| **Bug Ref** | BUG-001 |
| **Type** | Bug Fix — Screen Level |
| **Priority** | 🟠 P1 — High |
| **Status** | `TODO` |
| **Estimasi** | 15 menit |
| **Depends On** | ✅ TICKET-001 harus selesai terlebih dahulu |
| **File Target** | `lib/features/notes/presentation/screens/note_screen.dart` |

---

## Latar Belakang

`NotesScreen` (My Note) adalah root-screen yang diakses melalui Drawer navigasi. Screen ini menggunakan `GroupedSectionLayout` sebagai wrapper di dalam method `build()`. Setelah TICKET-001 menambahkan parameter `forceShowMenu` ke `GroupedSectionLayout`, tiket ini bertugas meneruskan nilai `true` di screen ini.

**Gejala jika tidak diperbaiki:**
- Navigasi dari halaman lain → My Note → tombol AppBar menampilkan ← (panah back)
- Menekan ← → black screen

---

## Acceptance Criteria

- [ ] `GroupedSectionLayout` di `NotesScreen` menerima `forceShowMenu: true`
- [ ] Setelah navigasi dari Drawer ke My Note, AppBar menampilkan ikon ☰ (menu)
- [ ] Menekan ☰ membuka Drawer dengan benar
- [ ] Navigasi ke Note Detail (tap note card) masih berfungsi normal dengan ikon ←

---

## Langkah Implementasi

### Lokasi perubahan

File: `lib/features/notes/presentation/screens/note_screen.dart`

Cari blok `GroupedSectionLayout<NoteGroup>(` di dalam method `build()` (sekitar baris 1088).

### Diff

```dart
// SEBELUM:
body: GroupedSectionLayout<NoteGroup>(
  title: 'My Notes',    // (atau title yang digunakan saat ini)
  drawer: const DrawerMenu(isNotesActive: true),
  isLoading: _isLoading,
  // ...

// SESUDAH:
body: GroupedSectionLayout<NoteGroup>(
  title: 'My Notes',
  forceShowMenu: true,                          // ← TAMBAH BARIS INI
  drawer: const DrawerMenu(isNotesActive: true),
  isLoading: _isLoading,
  // ...
```

> [!NOTE]
> Hanya **satu baris** yang perlu ditambahkan. Pastikan indentasi konsisten dengan kode di sekitarnya (2 spasi).

---

## Verifikasi Manual

1. Jalankan aplikasi
2. Dari halaman Task Master → buka Drawer → tap **My Note**
3. ✅ AppBar menampilkan ikon ☰
4. ✅ Tap ☰ → Drawer terbuka
5. ✅ Tap salah satu note card → masuk ke Note Detail Screen → AppBar menampilkan ← (back normal)
6. ✅ Tap ← → kembali ke My Note

```bash
flutter analyze lib/features/notes/presentation/screens/note_screen.dart
```
