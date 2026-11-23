# TICKET-005 — Screen Fix: `document_screen.dart`

| Field | Value |
|---|---|
| **ID** | TICKET-005 |
| **Bug Ref** | BUG-001 |
| **Type** | Bug Fix — Screen Level |
| **Priority** | 🟠 P1 — High |
| **Status** | `TODO` |
| **Estimasi** | 15 menit |
| **Depends On** | ✅ TICKET-001 harus selesai terlebih dahulu |
| **File Target** | `lib/features/documents/presentation/screens/document_screen.dart` |

---

## Latar Belakang

`MyDocumentsScreen` (My Documents) adalah root-screen yang diakses melalui Drawer navigasi. Screen ini menggunakan `GroupedSectionLayout` sebagai wrapper di dalam method `build()`. Setelah TICKET-001 menambahkan parameter `forceShowMenu` ke `GroupedSectionLayout`, tiket ini bertugas meneruskan nilai `true` di screen ini.

**Gejala jika tidak diperbaiki:**
- Navigasi dari halaman lain → My Documents → tombol AppBar menampilkan ← (panah back)
- Menekan ← → black screen

---

## Acceptance Criteria

- [ ] `GroupedSectionLayout` di `MyDocumentsScreen` menerima `forceShowMenu: true`
- [ ] Setelah navigasi dari Drawer ke My Documents, AppBar menampilkan ikon ☰ (menu)
- [ ] Menekan ☰ membuka Drawer dengan benar
- [ ] Navigasi ke Document Detail (jika ada) masih berfungsi normal dengan ikon ←

---

## Langkah Implementasi

### Lokasi perubahan

File: `lib/features/documents/presentation/screens/document_screen.dart`

Cari blok `GroupedSectionLayout<DocumentGroup>(` di dalam method `build()` (sekitar baris 412).

### Diff

```dart
// SEBELUM:
body: GroupedSectionLayout<DocumentGroup>(
  title: 'My Documents',    // (atau title yang digunakan saat ini)
  drawer: const DrawerMenu(isDocumentsActive: true),
  isLoading: _isLoading,
  // ...

// SESUDAH:
body: GroupedSectionLayout<DocumentGroup>(
  title: 'My Documents',
  forceShowMenu: true,                              // ← TAMBAH BARIS INI
  drawer: const DrawerMenu(isDocumentsActive: true),
  isLoading: _isLoading,
  // ...
```

> [!NOTE]
> Hanya **satu baris** yang perlu ditambahkan. Pastikan indentasi konsisten dengan kode di sekitarnya (2 spasi).

---

## Verifikasi Manual

1. Jalankan aplikasi
2. Dari halaman Task Master → buka Drawer → tap **My Documents**
3. ✅ AppBar menampilkan ikon ☰
4. ✅ Tap ☰ → Drawer terbuka
5. ✅ Tap salah satu document group (jika ada) → AppBar sub-halaman menampilkan ← (back normal)
6. ✅ Tap ← → kembali ke My Documents

```bash
flutter analyze lib/features/documents/presentation/screens/document_screen.dart
```
