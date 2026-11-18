# SPEC — Visibilitas Hari Ini & Rollout Eksperimental Task Master New

| Field | Value |
|---|---|
| Fitur | `today-visibility-experimental` |
| Sumber | `docs/tasks_master/today-visibility-experimental/PRD.md` v1.0 |
| Status | ready-for-agent |
| Tanggal | 18 November 2026 |
| Platform utama | Android dan Linux desktop |
| Platform pendukung | Windows dan macOS (tetap harus kompilasi) |
| ADR terkait | `ADR-0001-tri-state-today-visibility.md` |

---

## Problem Statement

Pengguna yang merawat kebiasaan punya dua keluhan yang saling berseberangan tentang daftar **Hari Ini**.

Pertama, daftar itu terlalu ramai. Tugas yang punya target harian selalu muncul, padahal tidak semua tugas relevan setiap hari. Tidak ada cara menyembunyikan tugas yang sedang **aktif** dari daftar Hari Ini tanpa menonaktifkannya — dan menonaktifkan tugas ikut mengubah ringkasan, sehingga pengguna kehilangan angka yang sebenarnya masih ingin ia lacak.

Kedua, daftar itu terlalu sempit. Tugas tanpa target harian baru muncul setelah pengguna menekan increment pertama. Akibatnya tugas yang ingin dikerjakan hari itu justru tidak terlihat saat pengguna membuka aplikasi di pagi hari.

Di sisi lain, pengguna dan pengembang terjebak pada keputusan rilis yang tidak bisa diuji: modul Task Master baru dipilih lewat konstanta saat build, sehingga pengguna tidak bisa mencobanya sendiri dan rollback memerlukan build ulang. Bila modul baru dimatikan, pengguna berisiko kehilangan riwayat karena model lama membuang field yang tidak dikenalnya saat menyimpan. Terakhir, pengaturan folder dan enkripsi bisa dibuka dari dua tempat berbeda, sehingga pengguna melihat dua jalur untuk hal yang sama dan tidak jelas mana yang menjadi sumber kebenaran.

---

## Solution

Tiga perubahan yang dikerjakan bersama:

1. **Tampil di Hari Ini** — setiap Tugas mendapat pengaturan tri-state: **Otomatis** (perilaku sekarang), **Selalu** (tampil walau tanpa target dan tanpa aktivitas), dan **Sembunyikan** (tidak tampil walau punya target atau aktivitas). Pengaturan ini terpisah dari status aktif dan dapat diubah dari form tugas, menu baris, serta aksi massal.

2. **Saklar Eksperimental** — Task Master New dipindah ke section Fitur Eksperimental di Settings dengan default mati. Saat mati, modul lama menjadi penulis aktif dan tetap menjadi tampilan utama. Saat hidup, modul baru menjadi satu-satunya penulis. Perubahan berlaku setelah aplikasi dimulai ulang, dan pengguna yang pernah memakai modul baru mendapat tawaran sekali-jalan untuk mengaktifkannya kembali.

3. **Satu pintu pengaturan** — entri pengaturan folder dan enkripsi dihapus dari sheet Advanced modul baru. Settings hanya dibuka dari sidebar.

Perilaku default tidak berubah: pengguna yang tidak pernah menyentuh pengaturan baru melihat daftar Hari Ini yang sama seperti sebelumnya, dan tetap memakai modul yang sama sampai ia mengaktifkan saklar.

---

## User Stories

### Tampil di Hari Ini

1. Sebagai pengguna dengan banyak tugas bertarget, saya ingin menyembunyikan tugas tertentu dari daftar Hari Ini, sehingga daftar hanya berisi hal yang benar-benar saya kerjakan hari itu.
2. Sebagai pengguna yang menyembunyikan tugas, saya ingin tugas itu tetap aktif dan tetap dihitung di ringkasan, sehingga angka konsistensi saya tidak berubah hanya karena tampilan.
3. Sebagai pengguna dengan tugas tanpa target harian, saya ingin memunculkannya di daftar Hari Ini, sehingga saya tidak perlu menekan increment hanya agar tugas itu terlihat.
4. Sebagai pengguna baru, saya ingin tugas baru memakai pengaturan Otomatis, sehingga saya tidak perlu memahami tiga opsi sebelum mulai.
5. Sebagai pengguna lama, saya ingin tugas lama berperilaku persis seperti sebelum pembaruan, sehingga tidak ada kejutan setelah update.
6. Sebagai pengguna, saya ingin melihat tiga pilihan dengan penjelasan singkat (Otomatis, Selalu, Sembunyikan), sehingga saya tahu konsekuensi tiap pilihan.
7. Sebagai pengguna, saya ingin mengubah pengaturan ini dari form edit tugas, sehingga saya bisa mengaturnya saat membuat atau memperbaiki tugas.
8. Sebagai pengguna, saya ingin mengubahnya langsung dari baris tugas di daftar Hari Ini, sehingga saya tidak perlu membuka form.
9. Sebagai pengguna, saya ingin mengubahnya dari daftar tugas di halaman detail kategori, sehingga saya bisa mengatur banyak tugas dari satu tempat.
10. Sebagai pengguna, saya ingin mengubahnya sekaligus untuk beberapa tugas terpilih, sehingga merapikan daftar tidak berarti mengedit satu per satu.
11. Sebagai pengguna, saya ingin perubahan langsung terlihat tanpa memuat ulang file, sehingga aplikasi terasa responsif.
12. Sebagai pengguna, saya ingin pengaturan ini bertahan setelah aplikasi ditutup dan dibuka, sehingga saya tidak perlu mengulanginya.
13. Sebagai pengguna, saya ingin pengaturan ini ikut pada export dan import Data Center, sehingga perpindahan perangkat tidak kehilangan preferensi.
14. Sebagai pengguna yang menonaktifkan tugas, saya ingin tugas nonaktif tetap tidak muncul di daftar Hari Ini, apa pun pengaturan tampilnya, sehingga aturan aktif tetap jelas.
15. Sebagai pengguna yang menyembunyikan kategori, saya ingin kategori tersembunyi tetap tidak muncul di daftar Hari Ini, sehingga visibilitas tugas tidak membocorkan kategori tersembunyi.
16. Sebagai pengguna, saya ingin jumlah tugas di header Hari Ini ikut berubah saat visibilitas diubah, sehingga angka di layar selalu benar.
17. Sebagai pengguna yang mengosongkan daftar Hari Ini, saya ingin empty state menjelaskan cara memunculkan tugas, sehingga saya tidak bingung mengira data hilang.
18. Sebagai pengguna, saya ingin tugas yang dipaksa tampil tetap menampilkan status “Tanpa target” bila memang tanpa target, sehingga saya tahu tugas itu bukan tugas bertarget.
19. Sebagai pengguna, saya ingin tombol increment tetap tersedia pada tugas yang dipaksa tampil, sehingga tugas tanpa target tetap bisa dicatat.
20. Sebagai pengguna yang memberi target total pada tugas progress, saya ingin tugas itu tetap mengikuti aturan Otomatis, sehingga progress total tidak terpengaruh fitur ini.
21. Sebagai pengguna, saya ingin melihat tanda centang pada pilihan visibilitas yang sedang aktif di menu baris, sehingga saya tahu keadaan saat ini sebelum mengubahnya.
22. Sebagai pengguna dengan data lama, saya ingin file lama tanpa field visibilitas terbaca sebagai Otomatis, sehingga migrasi tidak meminta tindakan tambahan.
23. Sebagai pengguna, saya ingin nilai visibilitas yang rusak atau tidak dikenal diperlakukan sebagai Otomatis, sehingga aplikasi tidak gagal membuka data.
24. Sebagai pengguna modul lama, saya ingin field visibilitas tidak merusak file, sehingga saya tetap bisa membuka data yang sama.

### Saklar Eksperimental

25. Sebagai pengguna, saya ingin menemukan Task Master New di section Fitur Eksperimental, sehingga saya tahu fitur ini belum stabil.
26. Sebagai pengguna baru, saya ingin Task Master New mati secara default, sehingga saya memakai modul yang sudah stabil.
27. Sebagai pengguna, saya ingin membaca deskripsi singkat sebelum mengaktifkan, sehingga saya tahu apa yang berubah dan bahwa restart diperlukan.
28. Sebagai pengguna, saya ingin mendapat dialog konfirmasi saat mengaktifkan, sehingga saya tidak mengaktifkannya karena salah tekan.
29. Sebagai pengguna, saya ingin melihat pemberitahuan bahwa perubahan berlaku setelah restart, sehingga saya tidak mengira saklar tidak berfungsi.
30. Sebagai pengguna, saya ingin mendapat peringatan berbeda saat mematikan, yang menjelaskan dampaknya pada riwayat, sehingga saya bisa memutuskan dengan sadar.
31. Sebagai pengguna, saya ingin saklar tersimpan permanen, sehingga pilihan saya tidak berubah setelah restart.
32. Sebagai pengguna, saya ingin modul baru dan lama tidak menulis file bersamaan, sehingga data saya tidak tertimpa.
33. Sebagai pengguna yang memakai modul baru, saya ingin modul lama tidak bisa menulis file, sehingga riwayat v2 tetap utuh.
34. Sebagai pengguna yang kembali ke modul lama, saya ingin modul baru tidak bisa menulis file, sehingga modul lama menjadi sumber kebenaran tunggal.
35. Sebagai pengguna yang memakai modul lama, saya ingin field baru tetap tersimpan saat saya mengedit tugas, sehingga riwayat dan pengaturan tampil tidak hilang.
36. Sebagai pengguna yang pernah memakai modul baru, saya ingin ditawari mengaktifkannya kembali ketika membuka Task Master, sehingga saya tidak bingung kehilangan tampilan yang saya kenal.
37. Sebagai pengguna yang menolak tawaran itu, saya ingin tawaran tidak muncul lagi, sehingga tidak mengganggu.
38. Sebagai pengguna yang menerima tawaran itu, saya ingin saklar langsung aktif dan instruksi restart muncul, sehingga langkahnya jelas.
39. Sebagai pengguna yang belum pernah memakai modul baru, saya ingin tawaran itu tidak muncul sama sekali, sehingga tidak ada kebingungan yang tidak perlu.
40. Sebagai pengguna, saya ingin modul lama tetap bisa membaca file v2, sehingga fallback darurat tetap berguna.
41. Sebagai pengguna enkripsi, saya ingin pergantian modul tidak mematahkan dekripsi, sehingga file terenkripsi tetap terbuka di kedua modul.
42. Sebagai pengguna, saya ingin keadaan “satu penulis” berlaku juga saat file gagal dibaca, sehingga tidak ada modul yang menulis setengah jalan.
43. Sebagai pengguna, saya ingin pengaturan ini bertahan di perangkat yang sama setelah pembaruan aplikasi, sehingga tidak kembali ke default tanpa alasan.

### Satu Pintu Pengaturan

44. Sebagai pengguna, saya ingin hanya menemukan pengaturan folder dan enkripsi di sidebar Settings, sehingga tidak ada dua jalur yang membingungkan.
45. Sebagai pengguna modul baru, saya ingin sheet Advanced hanya berisi editor JSON mentah, sehingga Advanced tetap berguna untuk diagnostik tanpa menduplikasi pengaturan.
46. Sebagai pengguna, saya ingin Settings tetap dapat dibuka dari sidebar saat modul baru aktif, sehingga menghilangkan entri duplikat tidak menghilangkan akses.
47. Sebagai pengguna modul lama, saya ingin pengaturan lama tetap berfungsi, sehingga fallback tidak kehilangan kemampuan.
48. Sebagai pengguna, saya ingin tidak ada tombol atau menu tersisa yang membuka Settings dari layar Task Master New, sehingga perilakunya konsisten di mobile dan desktop.
49. Sebagai pengguna desktop, saya ingin shortcut dan navigasi sidebar tetap membuka Settings yang sama, sehingga alur desktop tidak berubah.
50. Sebagai pengguna, saya ingin editor JSON mentah tetap ada di Advanced, sehingga perbaikan data darurat masih mungkin dilakukan.

### Kualitas dan keandalan

51. Sebagai pengguna, saya ingin daftar Hari Ini memuat cepat setelah visibilitas diubah, sehingga tidak ada jeda saat merapikan daftar.
52. Sebagai pengguna dengan data besar, saya ingin fitur ini tidak memperlambat dashboard, sehingga 1.000 tugas tetap responsif.
53. Sebagai pengguna, saya ingin aplikasi tidak crash bila file menyimpan nilai visibilitas yang tidak dikenal, sehingga data rusak tidak memblokir akses.
54. Sebagai pengguna, saya ingin ringkasan dashboard tetap akurat setelah perubahan visibilitas, sehingga angka yang saya lihat dapat dipercaya.
55. Sebagai pengguna, saya ingin aplikasi menjelaskan keterbatasan modul lama saat saya mematikannya, sehingga saya tidak kaget bila riwayat hari ini terlihat berbeda.
56. Sebagai pengguna yang memakai modul lama sementara, saya ingin modul baru menghitung ulang hitungan hari ini dari data yang tersimpan saat dibuka kembali, sehingga ketidakcocokan sementara bisa pulih.

---

## Implementation Decisions

### Domain

- Tambah tipe nilai `TodayVisibility` dengan tiga nilai: `auto`, `always`, `never`. `auto` adalah default. Parser harus mengembalikan `auto` untuk nilai tidak dikenal dan mencatat peringatan debug, bukan melempar error.
- `Task` mendapat field `todayVisibility`. `copyWith` dan kesetaraan entity wajib memperhitungkan field ini; dua tugas yang hanya berbeda visibilitas dianggap berbeda.
- Aturan tampil di daftar Hari Ini menjadi satu fungsi domain murni: tugas nonaktif selalu dikecualikan; kategori tersembunyi tetap difilter terpisah; `never` dikecualikan; `always` disertakan; `auto` memakai aturan lama (target harian, target total untuk progress, atau ada hitungan hari ini).
- Ringkasan dashboard tidak boleh berubah karena visibilitas tugas. Perhitungan ringkasan tetap memakai himpunan tugas Hari Ini, dan tugas `always` tanpa target menyumbang nol pada hitungan target tercapai.
- Tidak ada perubahan pada perhitungan streak.

### Data dan kompatibilitas

- Sumber kebenaran persistensi adalah `todayVisibility` (string) pada skema v2. Field cermin lama `showInToday` ditulis hanya untuk `always` dan `never`; `auto` tidak menulis field itu.
- Saat membaca, urutan prioritas: `todayVisibility` valid, lalu `showInToday` (`true` menjadi `always`, `false` menjadi `never`), lalu `auto`.
- Tidak ada kenaikan `schemaVersion`. Field bersifat aditif dan opsional.
- Mapper adalah satu-satunya jalur tulis. Field tak dikenal yang sudah ada pada file harus dipertahankan seperti perilaku sekarang.
- Model lama (legacy) wajib menyimpan seluruh key JSON yang tidak dikenalnya per kategori dan per tugas, lalu menuliskannya kembali saat menyimpan. Ini melindungi `history`, `kind`, `sortOrder`, `todayVisibility`, dan `showInToday`. Passthrough hanya untuk key; nilai tidak boleh diubah.
- Model lama tidak perlu memahami arti `todayVisibility`; ia hanya membawanya.

### Rollout dan preferensi

- Konstanta compile-time untuk memilih modul diganti preferensi runtime `task_master_use_new_module` dengan default `false`.
- Status “modul lama boleh menulis” diturunkan dari preferensi yang sama, bukan dari konstanta. Tidak boleh ada dua sumber kebenaran untuk status penulis.
- Titik masuk Task Master membaca preferensi saat dibangun dan memilih layar. Karena pembacaan preferensi asinkron, titik masuk menampilkan indikator loading ringan, dan hasilnya di-cache selama proses aplikasi berjalan agar navigasi berulang tidak berkedip.
- Preferensi kedua `seen_task_master_new_promo` menyimpan status tawaran sekali-jalan.
- Tawaran sekali-jalan hanya muncul bila ketiga syarat berikut terpenuhi bersamaan: saklar mati, file data sudah berformat v2, dan tawaran belum pernah ditampilkan. Baik memilih “Aktifkan Sekarang” maupun “Nanti” menandai tawaran sudah dilihat. “Aktifkan Sekarang” menulis saklar dan meminta restart.
- Perubahan saklar tidak melakukan restart otomatis. Aplikasi memberi instruksi restart yang jelas; mekanisme restart proses, bila ada, bersifat opsional dan tidak boleh menjadi syarat lulus.

### Satu penulis

- Saat saklar mati: modul lama adalah penulis; modul baru hanya membaca (bila dipakai untuk diagnostik) dan tidak boleh menulis.
- Saat saklar hidup: modul baru adalah penulis; seluruh jalur tulis modul lama ditolak, termasuk reset file, penyimpanan kategori, increment, penulisan Jurnal, dan editor JSON mentah.
- Guard harus berada di lapisan logika, bukan hanya menyembunyikan tombol, sehingga jalur program tetap aman.
- Status penulis dibaca pada saat operasi, bukan disimpan sebagai salinan statis, agar perubahan preferensi tidak meninggalkan guard yang basi.

### Presentasi modul baru

- Form tugas menampilkan kontrol tiga opsi berlabel **Tampil di Hari Ini** dengan teks bantuan per opsi. Default untuk tugas baru adalah `Otomatis`.
- Menu baris pada daftar Hari Ini dan pada daftar tugas kategori menampilkan submenu tiga opsi dengan tanda centang pada nilai aktif.
- Aksi massal menyediakan satu entri **Visibilitas Hari Ini** dengan submenu tiga opsi. Aksi ini hanya mengubah field visibilitas, tidak menyentuh status aktif.
- Perubahan visibilitas memperbarui state controller di memori dan menjadwalkan penyimpanan yang sudah ada. Tidak memicu pembacaan ulang file.
- Empty state daftar Hari Ini mendapat kalimat bantuan tentang pengaturan Tampil di Hari Ini.
- Header daftar Hari Ini dihitung dari hasil filter terkini, bukan angka yang di-cache terpisah.

### Settings

- Section Fitur Eksperimental yang sudah ada mendapat item baru **Task Master New**, memakai ikon dan warna section yang sama.
- Mengaktifkan memunculkan dialog konfirmasi berisi ringkasan fitur dan catatan eksperimental; menonaktifkan memunculkan dialog berbeda yang menyebut: riwayat baru ada di file v2, modul lama dapat membaca tetapi tidak menampilkan, dan detail tertentu bisa tidak sinkron bila diubah dari modul lama.
- Setelah salah satu alur selesai, muncul pemberitahuan bahwa restart diperlukan. Dialog Settings tetap dapat ditutup seperti biasa.
- Preferensi ditulis segera saat switch diubah, bukan saat tombol Simpan ditekan, mengikuti pola preferensi eksperimental yang sudah ada.

### Advanced

- Sheet Advanced modul baru hanya memuat **Editor JSON mentah**.
- Aksi dan callback pengaturan dihapus dari sheet, alur Advanced, dan layar. Dependensi layanan penyimpanan pada layar dihapus bila tidak lagi dipakai jalur lain.
- Pengaturan tetap diakses lewat sidebar. Tidak ada tombol pengaturan baru yang ditambahkan sebagai pengganti.
- Dialog Settings modul lama tidak diubah.

### Dokumentasi

- `docs/tasks_master/ROLLBACK.md` diperbarui: rollback kini lewat saklar, bukan build ulang, dan wajib menyebut status penulis serta langkah verifikasi.
- `docs/tasks_master/PARITY_QA.md` mendapat skenario ganti modul dan visibilitas Hari Ini.
- Tiket 17 (passthrough), 18 (visibilitas), 19 (saklar), 20 (tawaran), dan 21 (Advanced) menjadi acuan kerja; tiket 16 tetap ditunda. Urutan dependensi: 17 → 18 → 19 → 20; tiket 21 independen.

### Bentuk tipe (dari PRD, dipertahankan sebagai kontrak)

```text
TodayVisibility = auto | always | never      (default: auto)

aturan tampil:
  !isActive                  -> tidak tampil
  category.isHidden          -> tidak tampil
  todayVisibility == never   -> tidak tampil
  todayVisibility == always  -> tampil
  todayVisibility == auto    -> tampil bila targetDaily > 0
                                        atau (kind == progress && targetTotal > 0)
                                        atau countToday > 0

JSON v2:
  todayVisibility: "auto" | "always" | "never"
  showInToday: true    (hanya bila always)
  showInToday: false   (hanya bila never)
```

---

## Testing Decisions

### Prinsip

Test hanya memverifikasi perilaku yang terlihat dari luar: JSON yang dihasilkan, entity yang dibaca, hasil fungsi domain, dan apa yang tampil atau bisa dilakukan pengguna di layar. Test tidak boleh mengunci nama field internal, urutan pemanggilan, atau widget privat. Setiap perilaku baru harus punya satu test yang gagal bila perilaku itu dihapus.

### Seam 1 — JSON round-trip

- Modul: mapper skema v2 dan model lama.
- Yang diuji: membaca `todayVisibility` valid, tidak dikenal, dan hilang; migrasi dari `showInToday` saja; penulisan cermin `showInToday`; round-trip penuh mempertahankan field tak dikenal pada tugas dan kategori; model lama menulis kembali `history`, `kind`, `sortOrder`, `todayVisibility`, dan key acak.
- Prior art: `task_master_mapper_test.dart` dan test kontrak repository.

### Seam 2 — Fungsi domain

- Modul: operasi dashboard Hari Ini.
- Yang diuji: matriks lengkap tiga visibilitas × (punya target harian, tanpa target, ada aktivitas hari ini, progress dengan target total) × tugas aktif/nonaktif × kategori terlihat/tersembunyi; ringkasan tidak berubah saat visibilitas diubah; urutan hasil tetap berdasarkan `sortOrder`.
- Prior art: `task_operations_test.dart`, `streak_calculator_test.dart`, `dashboard_test.dart` untuk gaya matriks tabel.

### Seam 3 — Layar Task Master New

- Modul: layar modul baru dengan repository, journal gateway, dan clock palsu yang sudah tersedia.
- Yang diuji: form menyimpan tiga opsi; menu baris mengubah visibilitas dan daftar langsung berubah; aksi massal menerapkan ke semua tugas terpilih; ringkasan tidak berubah; empty state menampilkan bantuan; sheet Advanced hanya memiliki satu tile dan tidak ada jalur Settings di layar.
- Prior art: `task_management_test.dart`, `reorder_bulk_actions_test.dart`, `dashboard_test.dart`, `adaptive_layout_test.dart` untuk desktop dan mobile.

### Seam 4 — Entry dan Settings

- Modul: titik masuk Task Master dan dialog Settings, dengan preferensi palsu.
- Yang diuji: fresh install memakai modul lama; saklar hidup memakai modul baru; guard tulis modul lama mengikuti preferensi; dialog konfirmasi muncul untuk aktif dan nonaktif; preferensi tersimpan; pemberitahuan restart tampil; tawaran sekali-jalan muncul hanya pada kondisi yang ditentukan dan tidak muncul lagi setelah dipilih.
- Prior art: `navigation_switch_test.dart` yang sudah menguji titik masuk dan guard baca-saja modul lama.

### Cakupan manual

- Android dan Linux: ganti modul, restart, buka Hari Ini, ubah visibilitas, edit dari modul lama, kembali ke modul baru.
- Enkripsi aktif saat berganti modul.
- Export, aktifkan modul lama, import, kembali ke modul baru.
- Desktop: Settings tetap dapat dibuka dari sidebar saat modul baru aktif.

### Gate

- `flutter analyze` tidak memunculkan issue baru pada file yang diubah.
- Seluruh test lama dan baru lulus.
- Test performa data besar yang sudah ada tidak boleh melampaui ambang 500 ms.

---

## Out of Scope

- Menambah daftar Hari Ini ke modul lama.
- Menghapus modul lama.
- Menyeragamkan dialog Settings modul lama.
- Menambah nilai visibilitas keempat seperti “hanya hari kerja”.
- Sinkronisasi cloud, notifikasi, subtask, template, dan statistik lanjutan.
- Mengubah `schemaVersion` atau melakukan migrasi file baru.
- Mekanisme restart proses otomatis; instruksi manual sudah memenuhi syarat.
- Menulis `showInToday` untuk nilai `auto` demi pembaca pihak ketiga.
- Perubahan pada perhitungan streak, Jurnal, Checklist, atau Data Center selain yang disebut di atas.

---

## Further Notes

- Spec ini melengkapi, bukan menggantikan, `PRD.md` di folder yang sama. Bila ada pertentangan, PRD menang untuk keputusan produk dan spec ini menang untuk keputusan implementasi dan pengujian.
- `ADR-0001-tri-state-today-visibility.md` menjelaskan mengapa tri-state dipilih dan mengapa boolean ditolak. Perubahan desain yang menghapus tri-state harus disertai ADR baru.
- Urutan kerja yang disarankan mengikuti tiket: 17 (visibilitas) → 18 (saklar dan passthrough) → 19 (Advanced). Tiket 18 bergantung pada 17 karena field baru harus sudah tersimpan sebelum penulis berganti.
- Dua detail dibiarkan untuk implementasi dan tidak menghalangi: mekanisme restart proses, dan apakah editor JSON mentah perlu menampilkan field visibilitas secara khusus (default: tidak, karena JSON mentah apa adanya).
- Istilah **Tampil di Hari Ini**, **Saklar Eksperimental**, **Passthrough**, dan **Satu penulis** dipakai konsisten di seluruh dokumen dan sebaiknya masuk glosarium proyek.
