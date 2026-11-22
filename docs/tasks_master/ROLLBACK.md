# Rollback Task Master ke modul lama

Dokumen ini dipakai bila Task Master New perlu dinonaktifkan. Sejak implementasi
tiket 19 (Saklar Eksperimental Task Master New), modul tidak lagi dipilih lewat
konstanta build, melainkan lewat saklar runtime di antarmuka Settings aplikasi
tanpa perlu build ulang.

Modul lama tetap ada di `lib/features/task_master/` dan berfungsi sebagai fallback
aman dengan aturan satu penulis.

## Ringkasan saklar runtime

Konfigurasi rollout dikelola terpusat di `lib/core/config/task_master_rollout.dart`:

- Preferensi disimpan di SharedPreferences dengan kunci `task_master_use_new_module` (default `false`).
- Status penulis diturunkan dari preferensi tersebut:
  - **Saat saklar mati (`false`)**: Modul lama (`features/task_master`) menjadi penulis aktif; modul baru dilarang menulis file data.
  - **Saat saklar hidup (`true`)**: Modul baru (`features/task_master_new`) menjadi satu-satunya penulis; seluruh jalur tulis modul lama (penyimpanan kategori, increment, integrasi Jurnal, reset file, editor raw JSON) diblokir pada lapisan logika.
- Status penulis dievaluasi secara dinamis saat operasi berlangsung, bukan dari salinan statis.

## Prosedur rollback lewat Settings (Tanpa Build Ulang)

1. Buka aplikasi Rutinitasku.
2. Buka menu samping (Drawer / Sidebar), lalu pilih **Pengaturan Folder Data** (Settings).
3. Gulir ke section **Fitur Eksperimental**.
4. Matikan switch **Task Master New**.
5. Dialog konfirmasi akan muncul menjelaskan:
   - Riwayat baru tersimpan dalam file v2; modul lama dapat membacanya tetapi tidak menampilkannya.
   - Detail tertentu (seperti riwayat hari ini) bisa tidak sinkron bila data diubah dari modul lama.
6. Tekan tombol **Nonaktifkan**.
7. Preferensi tersimpan seketika di SharedPreferences. Muncul pemberitahuan bahwa perubahan akan berlaku setelah restart.
8. Tutup dan mulai ulang (restart) aplikasi.
9. Buka Task Master dari menu navigasi. Modul lama (`HomeScreen`) kini menjadi tampilan utama dan boleh menulis kembali.

## Pemulihan data

File data tetap `my_tasks.json` di direktori `mytask/` pada folder basis pengguna, sehingga rollback navigasi tidak memindahkan file data.

1. Model modul lama telah dilengkapi kemampuan *passthrough* field tak dikenal (tiket 17), sehingga field skema v2 (`history`, `kind`, `sortOrder`, `todayVisibility`) tetap terjaga dan tidak hilang saat pengguna mengedit data lewat modul lama.
2. File terenkripsi tetap dapat dibuka dan ditulis dengan PIN sesi yang aktif di kedua modul.
3. Backup migrasi otomatis tersimpan di folder data Task Master dengan timestamp. Bila diperlukan pemulihan manual, salin file backup ke `my_tasks.json` saat aplikasi tidak sedang aktif menulis.

## Verifikasi setelah rollback

Lakukan checklist verifikasi berikut setelah rollback ke modul lama:

- [ ] Task Master membuka antarmuka modul lama (`HomeScreen` dengan CategoryGrid dan dialog kategori).
- [ ] Menambah atau mengedit kategori berhasil tersimpan ke disk.
- [ ] Melakukan increment tugas menaikkan hitungan dan tercatat di file.
- [ ] Jalur penulisan modul baru tidak lagi aktif.
- [ ] Bila enkripsi aktif, data tetap terbaca dan tersimpan dalam kondisi terenkripsi.
- [ ] Jurnal dan Checklist tetap sinkron membaca data yang sama.
- [ ] Data Center tetap dapat mengekspor dan mengimpor file `my_tasks.json`.

## Mengaktifkan kembali Task Master New

1. Buka Settings → **Fitur Eksperimental**.
2. Hidupkan switch **Task Master New**.
3. Konfirmasi dialog informasi fitur eksperimental.
4. Restart aplikasi. Modul baru kembali menjadi tampilan utama dan satu-satunya penulis aktif.
