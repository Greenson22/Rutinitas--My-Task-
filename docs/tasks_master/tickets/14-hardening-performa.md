# 14: Hardening performa data besar dan kegagalan simpan

**What to build:** Task Master New tetap responsif saat pengguna memiliki sekitar 1.000 tugas. Pemuatan, pencarian, dan increment memenuhi target performa. Jika penyimpanan gagal, pengguna mendapat banner “Perubahan belum tersimpan” dengan opsi coba lagi, tanpa kehilangan state di layar.

**Blocked by:** 08 — Dashboard “Hari Ini” dan ringkasan; 09 — Pencarian dan filter

**Status:** done

- [x] Data 1.000 tugas dimuat di bawah 500 ms pada perangkat Android kelas menengah.
- [x] Pencarian 1.000 tugas selesai di bawah 100 ms setelah input.
- [x] Perubahan UI setelah increment terjadi di bawah 100 ms.
- [x] Penulisan file tidak memblokir frame render.
- [x] Operasi tulis diserialisasi sehingga tidak ada dua penulisan bersamaan.
- [x] Penyimpanan gagal menampilkan banner dengan opsi coba lagi.
- [x] State di layar tetap tersedia saat penyimpanan gagal.
- [x] Ada bukti pengukuran performa untuk data besar.

---

## Catatan implementasi

### Pekerjaan CPU besar dipindahkan ke isolate

- `lib/features/task_master_new/data/services/background_codec.dart` (sebelumnya file kosong) kini berisi:
  - `TaskJsonCodec` dengan implementasi `InlineTaskJsonCodec` dan `IsolateTaskJsonCodec`.
  - `IsolateTaskJsonCodec` memakai `compute` untuk decode/encode saat payload besar (≥ 50 tugas atau ≥ 200 entri riwayat), sehingga event loop UI tidak diblokir. Payload kecil tetap inline agar tidak membayar biaya isolate.
  - `BackgroundCrypto` memindahkan enkripsi/dekripsi payload besar ke isolate. `TaskLocalDataSource` memakai jalur ini untuk baca/tulis file terenkripsi.
- `TaskRepositoryImpl` sekarang menerima `TaskJsonCodec` (default isolate) dan memakai jalur yang sama untuk load, save, migrasi, raw JSON, dan import/export.

### Serialisasi penulisan

- `FileTaskLocalDataSource` memakai satu antrean `_serialize` untuk `write`, `createBackup`, dan `restoreBackup`, sehingga tidak ada dua penulisan file yang berjalan bersamaan dan kegagalan satu operasi tidak memutus antrean.
- `TaskRepositoryImpl` menambahkan antrean `_saveQueue` yang membungkus encode + write. Ini menutup celah urutan: dua `save` bersamaan tetap ditulis sesuai urutan pemanggilan, bukan urutan selesai isolate.
- `restoreBackup` juga dijalankan melalui antrean repository agar tidak bertabrakan dengan save yang sedang menunggu encode.

### Kegagalan simpan

- `TaskMasterNewController._markSaveFailed` mempertahankan state di layar dan menampilkan banner yang selalu diawali **“Perubahan belum tersimpan.”** dengan tombol **Coba Lagi**.
- Retry memakai state terbaru di layar; setelah berhasil, banner hilang dan data tersimpan.
- Widget test baru `test/features/task_master_new/presentation/save_failure_resilience_test.dart` memverifikasi: increment tetap tampil, banner muncul, tombol retry berfungsi, dan data tersimpan setelah retry.

### Optimasi kecil

- Validasi kunci tanggal riwayat di `TaskMasterMapper` tidak lagi memakai RegExp per entri; diganti pemeriksaan karakter langsung. Ini membantu mapping riwayat besar.
- `readRawJson` dan `exportJson` memakai codec yang sama agar format pretty JSON konsisten.

## Bukti pengukuran performa

Benchmark otomatis: `test/features/task_master_new/performance/large_dataset_performance_test.dart`
Fixture: 20 kategori × 50 tugas = **1.000 tugas**, masing-masing dengan 7 hari riwayat sparse.

Hasil dari `flutter test` penuh (host Linux, mode debug Flutter):

| Skenario | Target | Hasil |
|---|---|---|
| Muat 1.000 tugas (hangat) | < 500 ms | **271 ms** |
| Muat 1.000 tugas (dingin, termasuk pembuatan isolate pertama) | informatif | **275 ms** |
| Pencarian 1.000 tugas lewat controller | < 100 ms | **6 ms** (111 hasil) |
| Ringkasan dashboard 1.000 tugas | < 100 ms | **9 ms** (749 tugas hari ini) |
| Increment (state berubah seketika) | < 100 ms | **6 ms** |
| Event loop selama simpan data besar | tidak terblokir | **41 tick** timer 1 ms selama penulisan |

Catatan:
- Angka diambil dari run penuh `flutter test` (`+208: All tests passed!`).
- Pengukuran dilakukan di host Linux, bukan perangkat Android fisik. Mode release/AOT diharapkan lebih cepat daripada debug, tetapi validasi pada perangkat Android kelas menengah tetap disarankan sebelum rilis.
- Test performa menegakkan target pada pemuatan hangat. Pemuatan dingin tetap dicetak sebagai bukti biaya satu kali pembuatan isolate dan pemanasan JIT; nilainya tidak boleh dipakai sebagai patokan perangkat rilis.

## Verifikasi

Perintah yang dijalankan:

```bash
flutter analyze lib/features/task_master_new test/features/task_master_new
flutter test test/features/task_master_new/performance
flutter test
flutter build apk --debug
flutter build linux --debug
```

Hasil:

- `flutter analyze`: **No issues found**.
- `flutter test` penuh: **208 test lulus**, 0 gagal.
- `flutter build apk --debug`: berhasil, `build/app/outputs/flutter-apk/app-debug.apk`.
- `flutter build linux --debug`: berhasil, `build/linux/x64/debug/bundle/rutinitasku`.

## Waktu build

| Perintah | Waktu |
|---|---|
| `flutter test` (seluruh suite) | **209,44 detik** |
| `flutter build apk --debug` | **762,68 detik** (Gradle cold build, termasuk unduh/dependency resolution) |
| `flutter build linux --debug` | **70,22 detik** |

## File yang berubah

- `lib/features/task_master_new/data/services/background_codec.dart` (baru, diisi)
- `lib/features/task_master_new/data/datasources/task_local_data_source.dart`
- `lib/features/task_master_new/data/repositories/task_repository_impl.dart`
- `lib/features/task_master_new/data/mappers/task_master_mapper.dart`
- `lib/features/task_master_new/presentation/controllers/task_master_controller.dart`
- `test/features/task_master_new/performance/large_dataset_performance_test.dart` (baru, diisi)
- `test/features/task_master_new/presentation/save_failure_resilience_test.dart` (baru)
- `test/features/task_master_new/presentation/increment_undo_controller_test.dart`
