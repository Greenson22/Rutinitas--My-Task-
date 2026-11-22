# Parity dan QA Task Master New

Dokumen ini menjadi checklist parity fitur Task Master lama dengan modul
`task_master_new` sebelum dan sesudah switch navigasi (tiket 15 dan tiket 19).

## Matriks parity

| Kemampuan fitur lama | Task Master New | Bukti otomatis |
|---|---|---|
| Kategori: tambah, ubah nama/ikon, hapus dengan konfirmasi | Ada | `category_management_test.dart`, `task_repository_category_contract_test.dart` |
| Kategori tersembunyi dan tampilkan tersembunyi | Ada | `dashboard_test.dart`, `category_management_test.dart` |
| Urutan kategori | Ada, drag handle + tombol panah | `task_repository_reorder_contract_test.dart`, `reorder_bulk_actions_test.dart` |
| Tugas: tambah, ubah, hapus, aktif/nonaktif | Ada | `task_management_test.dart`, `task_repository_task_contract_test.dart` |
| Jenis tugas biasa/progress | Dipetakan ke `habit`, `counter`, `progress` | `task_master_mapper_test.dart`, `task_management_test.dart` |
| Target harian, target total, total hitungan | Ada, dengan validasi | `task_management_test.dart`, `task_master_mapper_test.dart` |
| Increment satu klik | Ada, tanpa dialog konfirmasi | `increment_undo_test.dart`, `increment_undo_controller_test.dart` |
| Undo increment terakhir | Ada, SnackBar 5 detik | `increment_undo_test.dart` |
| Integrasi Jurnal saat increment/undo | Ada melalui `JournalGateway`, fallback 30 menit, rollback best-effort | `journal_integration_test.dart`, `journal_gateway_contract_test.dart` |
| Pencarian kategori dan tugas | Ada, dikelompokkan per kategori, debounce | `search_filter_test.dart` |
| Filter aktif/nonaktif/target hari ini | Ada | `search_filter_test.dart` |
| Pindah tugas antar kategori | Ada, `id` dipertahankan | `reorder_bulk_actions_test.dart` |
| Aksi massal aktif/nonaktif/hapus | Ada, long press + konfirmasi hapus | `reorder_bulk_actions_test.dart` |
| Visibilitas Hari Ini (tri-state) | Ada (Otomatis, Selalu, Sembunyikan) | `today_visibility_matrix_test.dart`, `today_visibility_widget_test.dart` |
| Riwayat harian dan streak | Ada, sparse maksimal 365 hari | `task_history_test.dart`, `streak_calculator_test.dart` |
| Dashboard ringkasan hari ini | Ada, empat kartu + daftar Hari Ini | `dashboard_test.dart` |
| Layout desktop dua panel dan mobile push | Ada | `adaptive_layout_test.dart` |
| Keyboard desktop (`Ctrl+F`, `Ctrl+N`, `Esc`) | Ada | `adaptive_layout_test.dart` |
| Enkripsi dan file korup | Baca/tulis terenkripsi, PIN, restore backup, buat baru | `recovery_test.dart`, `task_local_data_source_contract_test.dart` |
| Editor JSON dan recovery | Ada di area Advanced | `recovery_test.dart` |
| Data Center export/import | Ada, round-trip setara | `task_repository_contract_test.dart` |
| Kompatibilitas Checklist dan Jurnal | File yang sama, field legacy dipertahankan | `task_master_mapper_test.dart`, build penuh |

## QA manual Android

Status environment implementasi: smoke test dijalankan pada perangkat fisik
RMX3951 (Android 16) dalam mode portrait dan landscape. Aplikasi terbuka ke
Task Master New, data lama tampil, drawer hanya punya satu menu Task Master,
dan Checklist membaca data yang sama. Tidak ada exception Flutter di logcat.

| Skenario | Langkah | Hasil yang diharapkan |
|---|---|---|
| Data baru | Hapus/rename data uji, buat kategori dan tiga jenis tugas, increment, undo | Dashboard, detail, dan riwayat konsisten setelah buka ulang |
| Data lama | Siapkan `my_tasks.json` legacy, buka Task Master | Migrasi otomatis, backup dibuat, data tidak ganda |
| Enkripsi | Aktifkan enkripsi, buat data, tutup dan buka aplikasi | File terbaca, increment tersimpan terenkripsi |
| Rotasi layar | Buka dashboard dan detail, putar portrait/landscape | Tidak overflow, state pencarian/filter tidak hilang |
| Jurnal | Increment tugas tertaut dan tidak tertaut | Durasi bertambah sesuai template atau fallback 30 menit |
| Checklist | Buka Checklist setelah migrasi | Kategori dan tugas terbaca |
| Data Center | Ekspor lalu impor kembali | Data setara setelah round-trip |
| Ganti modul lewat Settings | Buka Settings → Fitur Eksperimental → ubah saklar Task Master New, konfirmasi dialog, restart | Modul berganti sesuai saklar, notifikasi restart tampil, status satu penulis terjaga |

## QA manual Linux desktop

| Skenario | Langkah | Hasil yang diharapkan |
|---|---|---|
| Resize window | Ubah lebar melewati 600 dan 1024 dp | Mobile/tablet satu panel, desktop dua panel tanpa overflow |
| Keyboard | `Ctrl+F`, `Ctrl+N`, `Esc` di dashboard dan detail | Pencarian fokus, form terbuka, dialog/detail tertutup |
| Mouse | Klik kategori di sidebar, increment dari dashboard | Panel kanan berubah, hitungan langsung terlihat |
| Data besar | Muat 1.000 tugas | Tetap responsif, pencarian cepat |
| Enkripsi | Buka file terenkripsi dengan PIN | Data tampil dan dapat ditulis kembali |
| Ganti modul & restart | Buka Settings dialog, ubah saklar Task Master New, konfirmasi, tutup dan jalankan ulang | Modul berganti ke legacy / new secara bersih tanpa data hilang |

## Catatan switch dan aturan satu penulis

Aplikasi menyediakan satu pintu menu **Task Master** di DrawerMenu melalui `TaskMasterEntry`.
Pemilihan modul dikontrol oleh saklar runtime di Settings → Fitur Eksperimental (`task_master_use_new_module`):

- **Default (saklar mati)**: Aplikasi fresh install membuka modul lama `features/task_master` sebagai penulis aktif.
- **Saklar hidup**: Membuka modul baru `features/task_master_new` sebagai satu-satunya penulis. Semua jalur tulis modul lama (penyimpanan kategori, increment, integrasi Jurnal, reset file, editor raw JSON) diblokir secara ketat di lapisan logika (`isTaskMasterLegacyWritesEnabled`).
- Model modul lama mempertahankan semua field skema v2 melalui *passthrough*, sehingga pergantian modul bolak-balik aman dari risiko kehilangan riwayat atau visibilitas Hari Ini.
