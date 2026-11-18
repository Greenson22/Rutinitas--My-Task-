# Parity dan QA Task Master New

Dokumen ini menjadi checklist parity fitur Task Master lama dengan modul
`task_master_new` sebelum dan sesudah switch navigasi (tiket 15).

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
| Riwayat harian dan streak | Ada, sparse maksimal 365 hari | `task_history_test.dart`, `streak_calculator_test.dart` |
| Dashboard ringkasan hari ini | Ada, empat kartu + daftar Hari Ini | `dashboard_test.dart` |
| Layout desktop dua panel dan mobile push | Ada | `adaptive_layout_test.dart` |
| Keyboard desktop (`Ctrl+F`, `Ctrl+N`, `Esc`) | Ada | `adaptive_layout_test.dart` |
| Enkripsi dan file korup | Baca/tulis terenkripsi, PIN, restore backup, buat baru | `recovery_test.dart`, `task_local_data_source_contract_test.dart` |
| Editor JSON dan pengaturan folder | Ada di area Advanced | `recovery_test.dart` |
| Data Center export/import | Ada, round-trip setara | `task_repository_contract_test.dart` |
| Kompatibilitas Checklist dan Jurnal | File yang sama, field legacy dipertahankan | `task_master_mapper_test.dart`, build penuh |

## QA manual Android

Status environment implementasi: smoke test dijalankan pada perangkat fisik
RMX3951 (Android 16) dalam mode portrait dan landscape. Aplikasi terbuka ke
Task Master New, data lama tampil, drawer hanya punya satu menu Task Master,
dan Checklist membaca data yang sama. Tidak ada exception Flutter di logcat.
Skenario data baru dan enkripsi belum dijalankan pada perangkat agar data uji
yang ada tidak diubah, sehingga matriks di bawah tetap perlu diulang lengkap
sebelum rilis.

| Skenario | Langkah | Hasil yang diharapkan |
|---|---|---|
| Data baru | Hapus/rename data uji, buat kategori dan tiga jenis tugas, increment, undo | Dashboard, detail, dan riwayat konsisten setelah buka ulang |
| Data lama | Siapkan `my_tasks.json` legacy, buka Task Master | Migrasi otomatis, backup dibuat, data tidak ganda |
| Enkripsi | Aktifkan enkripsi, buat data, tutup dan buka aplikasi | File terbaca, increment tersimpan terenkripsi |
| Rotasi layar | Buka dashboard dan detail, putar portrait/landscape | Tidak overflow, state pencarian/filter tidak hilang |
| Jurnal | Increment tugas tertaut dan tidak tertaut | Durasi bertambah sesuai template atau fallback 30 menit |
| Checklist | Buka Checklist setelah migrasi | Kategori dan tugas terbaca |
| Data Center | Ekspor lalu impor kembali | Data setara setelah round-trip |

## QA manual Linux desktop

| Skenario | Langkah | Hasil yang diharapkan |
|---|---|---|
| Resize window | Ubah lebar melewati 600 dan 1024 dp | Mobile/tablet satu panel, desktop dua panel tanpa overflow |
| Keyboard | `Ctrl+F`, `Ctrl+N`, `Esc` di dashboard dan detail | Pencarian fokus, form terbuka, dialog/detail tertutup |
| Mouse | Klik kategori di sidebar, increment dari dashboard | Panel kanan berubah, hitungan langsung terlihat |
| Data besar | Muat 1.000 tugas | Tetap responsif, pencarian cepat |
| Enkripsi | Buka file terenkripsi dengan PIN | Data tampil dan dapat ditulis kembali |

## Catatan switch

Sebelum switch, aplikasi menampilkan dua menu Task Master. Setelah switch hanya
ada satu menu **Task Master** yang membuka `task_master_new` melalui
`TaskMasterEntry`. Modul lama tetap ada di disk sebagai fallback, tetapi semua
jalur tulisnya diblokir oleh `taskMasterLegacyWritesEnabled = false`.
