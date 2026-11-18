# 17: Passthrough field tak dikenal di model legacy

**What to build:** Modul Task Master lama tidak lagi menghapus data yang tidak dikenalnya saat menyimpan. Semua key JSON yang tidak dipahami model kategori dan tugas disimpan lalu ditulis kembali apa adanya, sehingga riwayat harian, jenis tugas, urutan, dan pengaturan tampil tetap utuh ketika pengguna memakai modul lama.

**Blocked by:** None (can start immediately).

**Status:** done

- [x] Kategori lama menyimpan seluruh key JSON yang tidak dikenalnya dan menuliskannya kembali saat menyimpan.
- [x] Tugas lama menyimpan seluruh key JSON yang tidak dikenalnya dan menuliskannya kembali saat menyimpan.
- [x] Passthrough hanya menyalin key; nilai tidak diubah, dikonversi, atau diurutkan ulang.
- [x] Key yang dikenali model lama tetap ditulis dari field model, bukan dari salinan mentah, sehingga perubahan yang dilakukan pengguna tidak tertimpa.
- [x] Field `history`, `kind`, `sortOrder`, `todayVisibility`, dan `showInToday` bertahan setelah simpan-muat-simpan berulang.
- [x] Field tak dikenal pada kategori dan tugas tidak saling bercampur.
- [x] File lama tanpa field tambahan tetap menghasilkan JSON yang setara saat disimpan.
- [x] Unit test round-trip: JSON dengan key tak dikenal → model lama → JSON, isinya sama.
- [x] Unit test regresi: mengubah field yang dikenali (mis. nama atau hitungan) tidak menghapus key tak dikenal.
- [x] `flutter analyze` tidak memunculkan issue baru dan seluruh test lulus.

---

## Catatan implementasi

**Mulai:** 2026-11-18 12:41 WITA
**Selesai:** 2026-11-18 12:56 WITA
**Durasi:** ±15 menit

### Perubahan

- `lib/features/task_master/data/models/task_model.dart`
  - `TaskCategory` dan `TaskItem` kini punya field `unknownFields` (default `const {}`).
  - `fromJson` mengumpulkan semua key di luar daftar key yang dikenali model lama ke `unknownFields`, tanpa menyentuh nilainya.
  - `toJson` menulis `unknownFields` lebih dulu, lalu field yang dikenali dari model, sehingga perubahan pengguna pada field yang dikenali selalu menang dan key yang tidak dikenal tetap ikut tersimpan. Nilai `unknownFields` disalin sebagai referensi apa adanya (tidak dikonversi/diurutkan).
  - Ditambahkan `TaskCategory.copyWith` yang membawa `unknownFields`, dipakai saat kategori diganti nama/ikon.
- `lib/features/task_master/presentation/controllers/task_master_controller.dart`
  - `updateCategory` tidak lagi membuat `TaskCategory` baru dari nol (yang membuang passthrough), melainkan memakai `copyWith` pada kategori lama.

### Pengujian

- Test baru: `test/features/task_master/data/task_model_test.dart` (9 test).
  - Round-trip kategori dan tugas mempertahankan key tak dikenal, termasuk `history`, `kind`, `sortOrder`, `todayVisibility`, `showInToday`.
  - Simpan-muat-simpan berulang (3x) tetap utuh, untuk kategori maupun tugas.
  - Perubahan nama kategori dan nama/hitungan tugas tidak menghapus key tak dikenal.
  - Key kategori dan tugas tidak saling bocor.
  - File lama tanpa field tambahan menghasilkan JSON yang setara.
- Test regresi jalur edit kategori: `test/features/task_master/presentation/task_master_controller_test.dart`.
  - `updateCategory` (nama + ikon) mempertahankan key tak dikenal kategori dan tugas. Ini menutup jalur produksi yang sebelumnya membangun ulang `TaskCategory` dari nol.
- `flutter test`: seluruh test lulus (223 test).
- `flutter analyze` pada file yang diubah: tidak ada issue baru. Satu info `non_constant_identifier_names` di `task_master_controller.dart:410` sudah ada sebelumnya.

### Catatan review

- Review Standards: tidak ada pelanggaran standar terdokumentasi (repo tidak punya file standar). Duplikasi ekstraksi key tak dikenal dirapikan menjadi helper `_unknownFieldsOf`; `copyWith` dipersempit ke `name`/`icon` sesuai pemakaian; fixture test dirapikan.
- Review Spec: seluruh kriteria tiket terpenuhi. Temuan di luar cakupan tiket: key tak dikenal di level root file (mis. `schemaVersion`) masih belum dipertahankan oleh `saveAllCategoriesToFile`, karena tiket membatasi passthrough pada level kategori dan tugas. Perilaku ini tidak diubah di tiket ini.

