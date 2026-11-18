# Rollback Task Master ke modul lama

Dokumen ini dipakai bila Task Master New perlu dinonaktifkan setelah switch
navigasi (tiket 15). Modul lama tetap ada di `lib/features/task_master/` dan
hanya berfungsi sebagai fallback baca-saja selama saklar baru aktif.

## Ringkasan saklar

Semua keputusan rollout ada di `lib/core/config/task_master_rollout.dart`:

```dart
const bool taskMasterUseNewModule = true;
const bool taskMasterLegacyWritesEnabled = !taskMasterUseNewModule;
```

- `taskMasterUseNewModule` menentukan layar yang dibuka oleh `main.dart` dan
  `DrawerMenu` melalui `TaskMasterEntry`.
- `taskMasterLegacyWritesEnabled` diturunkan dari saklar pertama. Saat
  `false`, penyimpanan kategori, reset file, penulisan Jurnal, dan editor JSON
  mentah modul lama diblokir.

## Prosedur rollback aplikasi

1. Hentikan aplikasi.
2. Ubah satu konstanta:

   ```dart
   const bool taskMasterUseNewModule = false;
   ```

   `taskMasterLegacyWritesEnabled` otomatis menjadi `true`.

3. Jalankan `flutter pub get`, lalu build ulang aplikasi.
4. Buka Task Master. Modul lama sekarang menjadi layar utama dan kembali boleh
   menulis.
5. Pastikan hanya satu versi yang berjalan. Jangan membuka Task Master New dan
   modul lama secara bersamaan pada perangkat yang sama.
6. Setelah yakin, jalankan `flutter analyze` dan `flutter test` untuk memastikan
   tidak ada perubahan tak terduga.

## Pemulihan data

File data tetap `my_tasks.json` di folder basis yang dipilih pengguna, sehingga
rollback navigasi tidak memindahkan data.

1. Buka Task Master lalu area **Advanced** (versi baru) atau menu Task Master
   lama untuk melihat lokasi file.
2. Backup migrasi disimpan di area data Task Master dengan timestamp. Pilih
   backup dari sebelum migrasi bila data hasil migrasi bermasalah.
3. Di Task Master New, gunakan **Pulihkan backup** pada layar error atau dari
   Data Center. Di modul lama, pulihkan file backup secara manual ke
   `my_tasks.json` hanya saat aplikasi tertutup.
4. Setelah memulihkan, buka Task Master dan periksa kategori, tugas, riwayat,
   serta durasi Jurnal hari ini.
5. Jangan mengedit `my_tasks.json` saat aplikasi berjalan. Gunakan editor JSON
   Advanced yang memakai validasi dan atomic write.

## Verifikasi setelah rollback

- Task Master membuka layar lama tanpa error.
- Tambah/ubah kategori dan increment tugas bertahan setelah aplikasi dibuka
  ulang.
- Data Center masih dapat mengekspor dan mengimpor `my_tasks.json`.
- Jurnal dan Checklist masih membaca kategori/tugas yang sama.
- Bila enkripsi aktif, file tetap dapat dibaca dan ditulis dengan PIN sesi.

## Kembali ke Task Master New

Ulangi langkah 1–4 dengan nilai:

```dart
const bool taskMasterUseNewModule = true;
```

`taskMasterLegacyWritesEnabled` otomatis kembali `false`.

Migrasi bersifat idempoten, sehingga membuka file yang sudah v2 tidak
menggandakan data.
