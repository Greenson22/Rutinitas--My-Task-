# 01: Tambah `fl_chart` & `DailyLogEntry.copyWith`

**What to build:** Dua persiapan fondasi yang dibutuhkan oleh semua tiket lain.

1. Tambahkan dependency `fl_chart: ^0.69.0` (atau versi terbaru stabil) ke `pubspec.yaml` dan jalankan `flutter pub get`.
2. Tambahkan method `copyWith` ke class `DailyLogEntry` di `lib/features/checklist/data/models/daily_model.dart`.

**Blocked by:** —

**Status:** todo

- [ ] `fl_chart` ditambahkan ke `pubspec.yaml` di bawah blok `dependencies`.
- [ ] `flutter pub get` sukses tanpa error.
- [ ] `DailyLogEntry.copyWith` ditambahkan dengan semua field: `itemName`, `progress`, `itemType`, `currentValue`, `targetValue`, `children`.
- [ ] `DailyLogEntry.copyWith` mengembalikan instance baru; field yang tidak diberikan menggunakan nilai lama.
- [ ] Unit test: `copyWith` tanpa argumen menghasilkan object yang sama nilainya.
- [ ] Unit test: `copyWith` dengan satu field berbeda hanya mengubah field itu.
- [ ] Seluruh test suite lama tetap lulus 100% setelah penambahan ini.

---

## Catatan implementasi

_Diisi oleh agent setelah implementasi selesai._
