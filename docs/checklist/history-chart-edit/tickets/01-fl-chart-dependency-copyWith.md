# 01: Tambah `fl_chart` & `DailyLogEntry.copyWith`

**What to build:** Dua persiapan fondasi yang dibutuhkan oleh semua tiket lain.

1. Tambahkan dependency `fl_chart: ^0.69.0` (atau versi terbaru stabil) ke `pubspec.yaml` dan jalankan `flutter pub get`.
2. Tambahkan method `copyWith` ke class `DailyLogEntry` di `lib/features/checklist/data/models/daily_model.dart`.

**Blocked by:** —

**Status:** done

- [x] `fl_chart` ditambahkan ke `pubspec.yaml` di bawah blok `dependencies`.
- [x] `flutter pub get` sukses tanpa error.
- [x] `DailyLogEntry.copyWith` ditambahkan dengan semua field: `itemName`, `progress`, `itemType`, `currentValue`, `targetValue`, `children`.
- [x] `DailyLogEntry.copyWith` mengembalikan instance baru; field yang tidak diberikan menggunakan nilai lama.
- [x] Unit test: `copyWith` tanpa argumen menghasilkan object yang sama nilainya.
- [x] Unit test: `copyWith` dengan satu field berbeda hanya mengubah field itu.
- [x] Seluruh test suite lama tetap lulus 100% setelah penambahan ini.

---

## Catatan implementasi

- Ditambahkan dependency `fl_chart: ^0.69.0` pada `pubspec.yaml` dan dependensi ter-resolve tanpa error (`fl_chart` v0.69.2 terpasang).
- Ditambahkan method `copyWith(...)` pada class `DailyLogEntry` di `lib/features/checklist/data/models/daily_model.dart` yang meng-cover seluruh 6 properti: `itemName`, `progress`, `itemType`, `currentValue`, `targetValue`, dan `children`.
- Ditambahkan unit test di `test/features/checklist/data/models/daily_model_test.dart` menguji `copyWith` tanpa argumen dan dengan satu per satu argumen termodifikasi.
- Seluruh test suite (366 test cases) lulus 100% tanpa regresi.
- Waktu selesai: 2026-11-24T09:05:00+08:00.
