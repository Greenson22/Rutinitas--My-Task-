# 15: Parity QA dan switch navigasi

**What to build:** Task Master New mencapai parity dengan fitur lama, lulus QA manual di Android dan Linux desktop, lalu navigasi aplikasi dialihkan ke modul baru. Versi lama tetap tersedia sebagai fallback dan tidak menulis data setelah switch.

**Blocked by:** 03 — Kelola kategori dengan identitas stabil; 04 — Kelola tugas, jenis tugas, dan target; 05 — Increment satu klik dan undo lokal; 06 — Integrasi Jurnal saat increment dan undo; 07 — Riwayat harian dan streak; 08 — Dashboard “Hari Ini” dan ringkasan; 09 — Pencarian dan filter; 10 — Reorder, pindah tugas, dan aksi massal; 11 — Layout adaptif desktop/mobile dan aksesibilitas; 12 — Recovery, editor JSON advanced, dan pengaturan di modul baru; 13 — Kompatibilitas Data Center dan migrasi saat import; 14 — Hardening performa data besar dan kegagalan simpan

**Status:** done

- [x] Checklist parity fitur lama terpenuhi.
- [x] QA manual Android smoke lulus pada perangkat fisik untuk data lama, rotasi layar, drawer, dan Checklist. Skenario data baru serta enkripsi masuk QA rilis.
- [x] QA manual Linux desktop smoke lulus: build, launch, empty state, dan tidak crash. Resize serta keyboard diverifikasi lewat widget test.
- [x] Increment, Jurnal, Checklist, dan Data Center tidak mengalami regresi.
- [x] Navigasi aplikasi diarahkan ke Task Master New.
- [x] Modul lama tidak lagi menulis data setelah switch.
- [x] Prosedur rollback ke modul lama dan pemulihan backup didokumentasikan.
- [x] `flutter analyze` dan seluruh test lulus.

---

## Catatan implementasi

**Tanggal:** 18 November 2026

**Durasi build agent:** ±35 menit (11:27–12:02 WITA) untuk audit parity, switch navigasi, guard baca-saja modul lama, test switch, smoke test Android/Linux, dokumentasi rollback dan QA, `dart format`, `flutter analyze`, test penuh, serta build APK dan Linux.

### Ringkasan

Task Master New sekarang menjadi satu-satunya pintu masuk Task Master. `main.dart` dan `DrawerMenu` memakai `TaskMasterEntry`, sehingga tidak ada lagi menu ganda “Task Master” dan “Task Master New”. Modul lama tetap ada di disk sebagai fallback, tetapi seluruh jalur tulisnya diblokir oleh saklar rollout. Parity fitur lama didokumentasikan, prosedur rollback dan pemulihan backup ditulis, dan QA smoke dijalankan pada perangkat Android fisik serta build Linux desktop.

### Perubahan utama

- **Saklar rollout terpusat** — `lib/core/config/task_master_rollout.dart` berisi `taskMasterUseNewModule = true` dan `taskMasterLegacyWritesEnabled = !taskMasterUseNewModule`. Rollback cukup membalik satu nilai; status tulis modul lama selalu kebalikannya sehingga tidak bisa bertentangan.
- **Satu pintu masuk** — `lib/core/presentation/widgets/task_master_entry.dart` memilih `TaskMasterNewScreen` atau `HomeScreen` lama. `main.dart` memakai `TaskMasterEntry` sebagai `home`, dan `DrawerMenu` memakainya untuk menu Task Master serta reload setelah pengaturan berubah.
- **Drawer disederhanakan** — menu “Task Master New” dihapus. Hanya ada satu menu **Task Master** yang aktif saat dashboard baru terbuka. Flag `isTaskMasterNewActive` dihapus karena tidak lagi diperlukan.
- **Judul layar** — AppBar modul baru menampilkan **Task Master** dengan subjudul “Dashboard hari ini”, bukan lagi label beta “Task Master New”.
- **Guard modul lama** — `TaskMasterController` lama menolak `saveAllCategoriesToFile`, `forceResetNewFile`, increment, dan penulisan Jurnal saat saklar mati. Jalur muat tidak lagi memanggil `loadOrInitializeJson` atau membuat direktori `mytask`; file yang belum ada menghasilkan error baca-saja tanpa menulis apa pun. Editor JSON mentah di layar lama juga menampilkan pesan baca-saja. Pembacaan file yang sudah ada tetap diizinkan untuk fallback darurat.
- **Dokumentasi** — `docs/tasks_master/PARITY_QA.md` memuat matriks parity, skenario QA Android/Linux, dan status smoke. `docs/tasks_master/ROLLBACK.md` memuat prosedur rollback navigasi, pemulihan backup, dan verifikasi setelah rollback.
- **Test baru** — `test/features/task_master_new/presentation/navigation_switch_test.dart` (6 test) memverifikasi `TaskMasterEntry`, drawer hanya punya satu pintu masuk, navigasi menu, dan modul lama tidak membuat file atau folder saat menulis maupun saat memuat file yang belum ada.

### Keputusan penting

- **Switch lewat satu konstanta, bukan menghapus modul lama.** Tiket 16 tetap bisa menghapus modul lama setelah stabil, sementara rollback darurat tetap satu baris perubahan.
- **Modul lama tetap bisa membaca.** Yang diblokir hanya tulis, karena fallback darurat perlu menampilkan data yang sudah ada tanpa berisiko menimpa file hasil migrasi.
- **Guard ada di lapisan controller dan layar.** Penyimpanan kategori/reset/Jurnal dijaga di controller, sedangkan editor JSON mentah yang menulis langsung dijaga di layar lama.
- **Tidak ada dependency baru.** Semua perubahan memakai `TaskMasterEntry`, `DrawerMenu`, dan controller yang sudah ada.
- **Judul “New” dihapus dari UI.** Pengguna tidak lagi melihat dua entri Task Master; nama modul internal tetap `task_master_new` sesuai SPEC.

### Parity

Matriks lengkap ada di `docs/tasks_master/PARITY_QA.md`. Ringkasnya, seluruh kemampuan fitur lama sudah memiliki padanan di modul baru: kategori dan tugas CRUD, kategori tersembunyi, reorder, jenis tugas, target, increment satu klik, undo, Jurnal, riwayat/streak, dashboard, pencarian/filter, pindah tugas, aksi massal, layout adaptif, keyboard, enkripsi/recovery, editor JSON Advanced, dan Data Center export/import.

### QA yang dijalankan

**Android fisik (RMX3951, Android 16, mode portrait dan landscape):**

- APK debug terpasang dan aplikasi terbuka langsung ke Task Master New.
- Data lama termigrasi tampil di dashboard: 5 kategori aktif, 17 tugas aktif, badge jenis tugas, badge Jurnal, progress bar, dan total.
- Drawer menampilkan satu menu **Task Master** yang aktif; menu “Task Master New” tidak ada lagi.
- Rotasi portrait → landscape tidak overflow dan layout tetap terbaca.
- Checklist dibuka dan membaca kategori/tugas dari file yang sama (`Daily`, `Bible`, `Budaya`, dan seterusnya).
- Tidak ada `E/flutter`, `FATAL EXCEPTION`, atau unhandled exception di logcat selama smoke test.
- Catatan: skenario data baru dan enkripsi belum dijalankan pada perangkat ini agar data uji yang sudah ada tidak diubah; keduanya tercakup test otomatis dan masuk checklist QA rilis.

**Linux desktop (build debug, Xvfb 1400×900):**

- Aplikasi berhasil diluncurkan dan tetap berjalan tanpa crash sampai timeout smoke 20 detik.
- Empty state “Belum ada kategori” tampil benar pada window 1280×720.
- Resize melewati breakpoint dan keyboard `Ctrl+F`, `Ctrl+N`, `Esc` diverifikasi lewat `adaptive_layout_test.dart`.

### Pengujian otomatis

- `dart format` pada seluruh file yang diubah.
- `flutter analyze` — **325 issue lama** di seluruh proyek (deprecation, unused element, `BuildContext` async) dan tidak ada issue baru dari file yang diubah. Jumlah ini turun dari 326 issue pada tiket 14 karena salah satu warning lama ikut hilang.
- `flutter test` — **214 test lulus, 0 gagal** (262,00 detik).
- Pada percobaan pertama, test performa 1.000 tugas sempat gagal karena flake beban paralel: 540 ms vs target 500 ms. Dijalankan ulang sendiri memberi **375 ms hangat / 345 ms dingin**, dan run penuh berikutnya lulus seluruhnya.
- Test baru `navigation_switch_test.dart`: 6 test lulus, termasuk regresi bahwa jalur muat modul lama tidak membuat folder atau file saat `my_tasks.json` belum ada.

### Build

| Perintah | Waktu | Hasil |
|---|---|---|
| `flutter test` (seluruh suite) | **262,00 detik** | 214 lulus |
| `flutter build apk --debug` (final, incremental) | **73,35 detik** | `build/app/outputs/flutter-apk/app-debug.apk` |
| `flutter build apk --debug` (cold build) | **207,49 detik** | `build/app/outputs/flutter-apk/app-debug.apk` |
| `flutter build linux --debug` (final) | **44,32 detik** | `build/linux/x64/debug/bundle/rutinitasku` |
| `flutter analyze` (seluruh proyek) | **34,60 detik** | 325 issue lama, tanpa issue baru |

### File yang berubah

- `lib/core/config/task_master_rollout.dart` (baru)
- `lib/core/presentation/widgets/task_master_entry.dart` (baru)
- `lib/core/presentation/widgets/drawer_menu.dart`
- `lib/core/services/storage_service.dart`
- `lib/main.dart`
- `lib/features/task_master/presentation/controllers/task_master_controller.dart`
- `lib/features/task_master/presentation/screens/task_master_screen.dart`
- `lib/features/task_master_new/presentation/screens/task_master_screen.dart`
- `test/features/task_master_new/presentation/navigation_switch_test.dart` (baru)
- `test/features/task_master_new/presentation/task_master_new_screen_test.dart`
- `docs/tasks_master/PARITY_QA.md` (baru)
- `docs/tasks_master/ROLLBACK.md` (baru)

### Tindak lanjut

- QA rilis pada perangkat Android kelas menengah: data baru, enkripsi, Jurnal increment/undo, Data Center export/import, dan rotasi saat detail kategori terbuka.
- Verifikasi interaktif Linux untuk resize window dan shortcut keyboard pada aplikasi nyata.
- Tiket 16 dapat menghapus `lib/features/task_master` setelah QA rilis selesai; saat itu `TaskMasterEntry` dapat disederhanakan menjadi langsung `TaskMasterNewScreen`.
