# TICKET-001 — Core Fix: Tambah Parameter `forceShowMenu` ke `GroupedSectionLayout`

| Field | Value |
|---|---|
| **ID** | TICKET-001 |
| **Bug Ref** | BUG-001 |
| **Type** | Bug Fix — Core Widget |
| **Priority** | 🔴 P0 — Blocker |
| **Status** | `DONE` |
| **Estimasi** | 30 menit |
| **Depends On** | — (tidak ada prasyarat) |
| **Diblokir Oleh** | TICKET-002, TICKET-003, TICKET-004, TICKET-005 |
| **File Target** | `lib/core/presentation/widgets/grouped_section_layout.dart` |

---

## Latar Belakang

`GroupedSectionLayout` adalah widget wrapper yang digunakan oleh semua root-screen utama aplikasi (Checklist, Notes, Prompt, Documents). Di dalamnya terdapat `BaseDetailAppBar` yang memiliki logika:

```dart
final bool canPop = Navigator.canPop(context) && !forceShowMenu;
```

Saat ini `GroupedSectionLayout` **tidak meneruskan** nilai `forceShowMenu` ke `BaseDetailAppBar`, sehingga nilainya selalu `false` (default). Akibatnya, ketika `Navigator.canPop()` mengembalikan `true` (terjadi karena `pushReplacement` tidak membersihkan stack), tombol leading AppBar menjadi panah balik ← dan menyebabkan **black screen** jika ditekan.

---

## Acceptance Criteria

- [x] `GroupedSectionLayout` memiliki field dan parameter `forceShowMenu` bertipe `bool`
- [x] Default value `forceShowMenu = true` (aman karena semua caller saat ini adalah root-screen)
- [x] Nilai `forceShowMenu` diteruskan ke `BaseDetailAppBar` di method `build()`
- [x] Widget dapat di-compile tanpa error
- [x] `flutter analyze` tidak mengeluarkan warning/error baru

---

## Langkah Implementasi

### 1. Tambah field di class

```dart
// FILE: lib/core/presentation/widgets/grouped_section_layout.dart

class GroupedSectionLayout<T> extends StatefulWidget {
  final String title;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final bool isLoading;
  final bool isEmpty;
  final String emptyMessage;
  final Widget? emptyStateView;
  final bool isSelectMode;
  final int selectedItemsCount;
  final VoidCallback onClearSelection;
  final bool enableSearch;
  final bool enableMultiSelect;
  final VoidCallback? onMoveMassive;
  final VoidCallback? onDeleteMassive;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onAddPressed;
  final Widget? additionalAction;
  final Widget? appBarTrailingAction;
  final bool forceShowMenu;   // ← TAMBAH FIELD INI
  final List<String> sectionKeys;
  // ... dst
```

### 2. Tambah ke constructor

```dart
  const GroupedSectionLayout({
    super.key,
    required this.title,
    this.drawer,
    this.floatingActionButton,
    required this.isLoading,
    required this.isEmpty,
    this.emptyMessage = 'Belum ada data.',
    this.emptyStateView,
    required this.isSelectMode,
    required this.selectedItemsCount,
    required this.onClearSelection,
    this.enableSearch = true,
    this.enableMultiSelect = true,
    this.onMoveMassive,
    this.onDeleteMassive,
    this.onSearchChanged,
    this.onAddPressed,
    this.additionalAction,
    this.appBarTrailingAction,
    this.forceShowMenu = true,  // ← TAMBAH DI SINI (default true)
    required this.sectionKeys,
    // ... dst
  });
```

### 3. Teruskan ke `BaseDetailAppBar` di method `build()`

Lokasi: di dalam `_GroupedSectionLayoutState.build()`, pada blok `appBar: BaseDetailAppBar(...)`.

```dart
// SEBELUM:
appBar: BaseDetailAppBar(
  pageTitle: widget.title,
  isSelectMode: widget.isSelectMode,
  // ...

// SESUDAH:
appBar: BaseDetailAppBar(
  pageTitle: widget.title,
  forceShowMenu: widget.forceShowMenu,  // ← TAMBAH BARIS INI
  isSelectMode: widget.isSelectMode,
  // ...
```

---

## Verifikasi

```bash
# Dari root project
flutter analyze lib/core/presentation/widgets/grouped_section_layout.dart
```

Expected output: `No issues found!` (atau hanya info yang sudah ada sebelumnya)

---

## Catatan

> [!WARNING]
> Jika di masa depan ada sub-rute (non-root screen) yang menggunakan `GroupedSectionLayout`, pastikan meneruskan `forceShowMenu: false` secara eksplisit agar tombol ← tetap tampil dengan benar.

> [!NOTE]
> `base_detail_app_bar.dart` **tidak perlu diubah** — logika `forceShowMenu` di sana sudah benar. Hanya `grouped_section_layout.dart` yang perlu dimodifikasi di tiket ini.

---

## Log Eksekusi & Catatan

- **Waktu Mulai**: 2026-11-23 12:34:38 +08:00
- **Waktu Selesai**: 2026-11-23 12:41:30 +08:00
- **Durasi**: ~7 menit
- **Perubahan yang Dilakukan**:
  - Menambahkan properti `final bool forceShowMenu;` pada `GroupedSectionLayout` di [grouped_section_layout.dart](file:///home/lemon-manis-22/Projects/Flutter/rutinitasku/lib/core/presentation/widgets/grouped_section_layout.dart).
  - Menambahkan parameter `this.forceShowMenu = true` ke constructor `GroupedSectionLayout`.
  - Meneruskan `forceShowMenu: widget.forceShowMenu` ke `BaseDetailAppBar` di dalam `_GroupedSectionLayoutState.build()`.
  - Menambahkan unit/widget test di [grouped_section_layout_test.dart](file:///home/lemon-manis-22/Projects/Flutter/rutinitasku/test/core/presentation/widgets/grouped_section_layout_test.dart) untuk memverifikasi default `forceShowMenu == true` dan saat di-override `forceShowMenu == false`.
- **Hasil Verifikasi**:
  - `flutter analyze lib/core/presentation/widgets/grouped_section_layout.dart`: Tidak ada warning/error baru.
  - `flutter test test/core/presentation/widgets/grouped_section_layout_test.dart`: 2/2 tests passed.
  - `flutter test` (Full test suite): 315 tests passed.
  - Code Review (Standards & Spec): Lulus tanpa temuan.
