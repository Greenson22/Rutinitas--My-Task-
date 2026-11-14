# SPEC — Task Master New

| Field | Value |
|---|---|
| Fitur | `task_master_new` |
| Sumber | `docs/taks_master/PRD.md` |
| Status | Ready for agent |
| Tanggal | 14 November 2026 |
| Platform utama | Android dan Linux desktop |
| Platform pendukung | Windows dan macOS (tetap harus kompilasi) |

---

## Problem Statement

Pengguna yang sudah memakai Task Master merasa fitur ini makin lambat dan berisiko saat data bertambah. Daftar tugas yang seharusnya cepat diakses malah terkunci di dalam dialog besar, setiap increment terasa berat karena aplikasi membaca ulang seluruh file, dan tidak ada cara membatalkan salah klik. Pengguna juga tidak bisa melihat riwayat atau konsistensi harian, padahal itu inti dari aplikasi pelacak kebiasaan.

Di sisi lain, pengguna lama takut kehilangan data. Kategori diidentifikasi hanya dari nama, sehingga rename berisiko; reset harian bergantung pada format string tanggal; dan belum ada test migrasi. Pengguna membutuhkan Task Master yang lebih cepat, lebih jelas, dan lebih aman, tanpa kehilangan data lama serta tanpa memutus integrasi Jurnal, Checklist, dan Data Center.

---

## Solution

Task Master New adalah penulisan ulang fitur Task Master dengan pengalaman yang lebih langsung:

- Dashboard “Hari Ini” yang menampilkan tugas penting, ringkasan, dan kategori tanpa harus membuka dialog.
- Halaman detail kategori yang nyaman di mobile dan layout dua panel di desktop.
- Increment satu klik dengan undo, bukan dialog konfirmasi berulang.
- Riwayat harian sparse dan streak yang dihitung dari data nyata.
- Identitas kategori yang stabil, sehingga rename tidak memutus tugas.
- Migrasi otomatis dari data lama dengan backup, atomic write, dan dukungan enkripsi.
- Integrasi Jurnal, Checklist, dan Data Center tetap berjalan dengan file data yang sama.

Versi lama tetap tersedia sebagai fallback sampai versi baru mencapai parity, lalu navigasi dialihkan ke Task Master New. Hanya satu versi yang boleh menjadi penulis aktif pada satu waktu.

---

## User Stories

### Migrasi dan keandalan data

1. Sebagai pengguna lama, saya ingin data Task Master lama dimigrasi otomatis saat pertama dibuka, agar saya tidak perlu membuat ulang kategori dan tugas.
2. Sebagai pengguna lama, saya ingin backup dibuat sebelum migrasi, agar saya bisa pulih jika terjadi masalah.
3. Sebagai pengguna, saya ingin migrasi berjalan idempoten, agar membuka aplikasi berulang kali tidak menggandakan data.
4. Sebagai pengguna lama, saya ingin `id` tugas dipertahankan, agar tautan ke Jurnal tidak putus.
5. Sebagai pengguna lama, saya ingin `countToday` historis dipindahkan ke riwayat harian, agar data kemarin tidak hilang.
6. Sebagai pengguna, saya ingin file asli tidak berubah jika migrasi gagal, agar data saya tetap aman.
7. Sebagai pengguna, saya ingin melihat pesan yang jelas saat migrasi gagal, agar saya tahu langkah pemulihan yang tersedia.
8. Sebagai pengguna, saya ingin bisa memulihkan backup, agar saya bisa kembali ke kondisi sebelum migrasi.
9. Sebagai pengguna, saya ingin file dengan versi skema yang tidak dikenal ditolak dengan aman, agar data tidak dirusak oleh pembacaan yang salah.
10. Sebagai pengguna, saya ingin field data yang tidak dikenal tidak langsung dihapus, agar integrasi lain tidak rusak.

### Dashboard dan ringkasan

11. Sebagai pengguna, saya ingin melihat dashboard “Hari Ini” saat membuka Task Master, agar saya langsung tahu apa yang perlu dikerjakan.
12. Sebagai pengguna, saya ingin melihat jumlah kategori aktif, agar saya tahu cakupan rutinitas saya.
13. Sebagai pengguna, saya ingin melihat jumlah tugas aktif, agar saya tahu beban yang sedang saya kelola.
14. Sebagai pengguna, saya ingin melihat berapa target yang sudah tercapai hari ini, agar saya bisa menilai progres harian.
15. Sebagai pengguna, saya ingin melihat durasi Jurnal hari ini, agar saya tahu waktu yang sudah saya catat.
16. Sebagai pengguna, saya ingin daftar tugas yang punya target atau aktivitas hari ini, agar saya tidak perlu mencari manual.
17. Sebagai pengguna, saya ingin menaikkan hitungan langsung dari dashboard, agar pencatatan cepat dilakukan.
18. Sebagai pengguna, saya ingin melihat kategori beserta ringkasan progresnya di dashboard, agar saya bisa memilih fokus berikutnya.
19. Sebagai pengguna baru, saya ingin empty state dengan ajakan membuat kategori pertama, agar saya tahu harus mulai dari mana.
20. Sebagai pengguna, saya ingin empty state ringan ketika belum ada tugas hari ini, agar dashboard tidak terasa rusak.
21. Sebagai pengguna, saya ingin kategori tersembunyi tidak muncul di dashboard, agar tampilan utama tetap fokus.
22. Sebagai pengguna, saya ingin bisa menampilkan kategori tersembunyi saat diperlukan, agar saya tetap bisa mengelola semuanya.

### Kategori

23. Sebagai pengguna, saya ingin menambah kategori, agar tugas bisa dikelompokkan.
24. Sebagai pengguna, saya ingin mengedit nama dan ikon kategori, agar tampilan tetap relevan.
25. Sebagai pengguna, saya ingin rename kategori tidak memutus tugas di dalamnya, agar data tetap utuh.
26. Sebagai pengguna, saya ingin setiap kategori memiliki identitas stabil, agar referensi tidak bergantung pada nama.
27. Sebagai pengguna, saya ingin validasi nama kategori duplikat, agar daftar tidak membingungkan.
28. Sebagai pengguna, saya ingin memilih ikon emoji untuk kategori, agar kategori mudah dikenali.
29. Sebagai pengguna, saya ingin menyembunyikan kategori, agar dashboard tidak penuh.
30. Sebagai pengguna, saya ingin mengubah urutan kategori, agar kategori penting berada di atas.
31. Sebagai pengguna, saya ingin menghapus kategori dengan konfirmasi, agar tidak menghapus data secara tidak sengaja.
32. Sebagai pengguna, saya ingin peringatan saat menghapus kategori yang masih memiliki tugas, agar saya sadar dampaknya.
33. Sebagai pengguna desktop, saya ingin memilih kategori dari panel kiri, agar detailnya tampil di panel kanan.
34. Sebagai pengguna mobile, saya ingin membuka halaman detail kategori, agar daftar tugas punya ruang yang cukup.
35. Sebagai pengguna, saya ingin melihat jumlah tugas dan progres hari ini di kartu kategori, agar saya bisa menilai kategori tanpa membukanya.

### Tugas

36. Sebagai pengguna, saya ingin menambah tugas ke kategori, agar aktivitas bisa dilacak.
37. Sebagai pengguna, saya ingin memilih jenis tugas `Habit`, `Counter`, atau `Progress`, agar aturan targetnya jelas.
38. Sebagai pengguna, saya ingin mengatur target harian, agar saya punya ukuran keberhasilan harian.
39. Sebagai pengguna, saya ingin mengatur target total untuk tugas `Progress`, agar progress bar punya tujuan.
40. Sebagai pengguna, saya ingin validasi target total wajib untuk `Progress`, agar data tidak setengah jadi.
41. Sebagai pengguna, saya ingin mengedit nama, jenis, target, dan status tugas, agar tugas bisa disesuaikan.
42. Sebagai pengguna, saya ingin menonaktifkan tugas, agar tidak lagi dihitung tanpa menghapus riwayatnya.
43. Sebagai pengguna, saya ingin mengaktifkan kembali tugas, agar bisa dipakai lagi kapan saja.
44. Sebagai pengguna, saya ingin menghapus tugas dengan konfirmasi, agar data tidak hilang karena salah tekan.
45. Sebagai pengguna, saya ingin mengubah urutan tugas, agar tugas penting mudah dijangkau.
46. Sebagai pengguna, saya ingin memindahkan tugas antar kategori, agar pengelompokan bisa berubah tanpa kehilangan `id`.
47. Sebagai pengguna, saya ingin memilih beberapa tugas lewat long press, agar bisa melakukan aksi massal.
48. Sebagai pengguna, saya ingin mengaktifkan, menonaktifkan, atau menghapus banyak tugas sekaligus, agar pengelolaan cepat.
49. Sebagai pengguna, saya ingin melihat badge jenis tugas, agar saya tahu apakah ini habit, counter, atau progress.
50. Sebagai pengguna, saya ingin melihat progress bar untuk tugas `Progress`, agar capaian terlihat jelas.
51. Sebagai pengguna, saya ingin melihat status aktif/nonaktif, agar saya tidak bingung why tugas tidak dihitung.
52. Sebagai pengguna, saya ingin melihat indikator tugas tertaut Jurnal, agar saya tahu dampak increment.
53. Sebagai pengguna, saya ingin melihat total dan hitungan hari ini pada setiap tugas, agar konteksnya lengkap.
54. Sebagai pengguna, saya ingin detail tugas terbaca tanpa membuka menu, agar saya tidak perlu klik berlapis.

### Increment dan undo

55. Sebagai pengguna, saya ingin menaikkan hitungan dengan satu klik, agar pencatatan tidak terasa lambat.
56. Sebagai pengguna, saya ingin UI berubah seketika setelah increment, agar aplikasi terasa responsif.
57. Sebagai pengguna, saya ingin increment tertaut menambah durasi Jurnal, agar pencatatan waktu tetap konsisten.
58. Sebagai pengguna, saya ingin melihat SnackBar setelah increment, agar saya tahu aksi berhasil.
59. Sebagai pengguna, saya ingin membatalkan increment lewat tombol Undo, agar salah klik bisa diperbaiki.
60. Sebagai pengguna, saya ingin undo mengembalikan hitungan dan riwayat hari ini, agar data kembali seperti semula.
61. Sebagai pengguna, saya ingin undo juga mengurangi durasi Jurnal, agar kedua data tetap sinkron.
62. Sebagai pengguna, saya ingin peringatan jika rollback Jurnal gagal, agar saya tahu perlu memeriksa manual.
63. Sebagai pengguna, saya ingin hanya aksi increment terakhir yang bisa di-undo, agar perilaku undo tidak membingungkan.
64. Sebagai pengguna, saya ingin tidak diminta konfirmasi setiap increment, agar alur cepat tidak terganggu.
65. Sebagai pengguna, saya ingin tombol increment tetap aman dari double tap, agar hitungan tidak dobel tanpa sengaja.

### Riwayat dan streak

66. Sebagai pengguna, saya ingin melihat riwayat harian tugas, agar saya tahu kapan saya aktif.
67. Sebagai pengguna, saya ingin melihat streak, agar saya termotivasi menjaga konsistensi.
68. Sebagai pengguna, saya ingin streak dihitung dari target harian jika target tersedia, agar maknanya sesuai tujuan.
69. Sebagai pengguna, saya ingin streak dihitung dari aktivitas jika tidak ada target harian, agar tugas tanpa target tetap punya ukuran.
70. Sebagai pengguna, saya ingin hari ini yang belum dikerjakan tidak langsung memutus streak, agar saya tidak kehilangan motivasi di pagi hari.
71. Sebagai pengguna, saya ingin riwayat disimpan maksimal 365 hari per tugas, agar file tidak tumbuh tanpa batas.
72. Sebagai pengguna, saya ingin definisi “selesai” konsisten untuk setiap jenis tugas, agar ringkasan tidak menyesatkan.
73. Sebagai pengguna, saya ingin riwayat tetap ada setelah aplikasi ditutup dan dibuka kembali, agar data tidak bersifat sementara.

### Pencarian dan filter

74. Sebagai pengguna, saya ingin mencari kategori dan tugas dari satu kolom, agar tidak perlu membuka satu per satu.
75. Sebagai pengguna, saya ingin hasil pencarian dikelompokkan per kategori, agar konteks tetap jelas.
76. Sebagai pengguna, saya ingin pencarian merespons dengan cepat, agar tidak mengganggu alur.
77. Sebagai pengguna, saya ingin memfilter tugas berdasarkan aktif, nonaktif, atau punya target hari ini, agar daftar lebih fokus.
78. Sebagai pengguna, saya ingin filter tetap menampilkan konteks kategori, agar saya tidak bingung.
79. Sebagai pengguna, saya ingin empty state saat pencarian tidak menemukan hasil, agar saya tahu untuk menghapus filter.
80. Sebagai pengguna desktop, saya ingin membuka pencarian dengan keyboard, agar navigasi lebih cepat.

### Integrasi Jurnal

81. Sebagai pengguna, saya ingin tugas yang tertaut Jurnal ditandai, agar saya tahu increment akan menambah waktu.
82. Sebagai pengguna, saya ingin durasi increment mengikuti pengaturan template Jurnal, agar tidak selalu 30 menit.
83. Sebagai pengguna, saya ingin fallback 30 menit jika pengaturan tidak tersedia, agar increment tetap berjalan.
84. Sebagai pengguna, saya ingin pesan jelas jika tugas tidak tertaut Jurnal, agar saya tidak mengira waktu tercatat.
85. Sebagai pengguna, saya ingin relasi Jurnal tidak diduplikasi di data Task Master, agar tidak ada dua sumber kebenaran.
86. Sebagai pengguna, saya ingin file Jurnal yang terenkripsi tetap bisa dibaca dan ditulis, agar keamanan tidak berkurang.

### Enkripsi dan recovery

87. Sebagai pengguna, saya ingin Task Master New membaca file terenkripsi, agar data lama tetap bisa dipakai.
88. Sebagai pengguna, saya ingin penulisan tetap terenkripsi saat enkripsi aktif, agar tidak ada kebocoran data.
89. Sebagai pengguna, saya ingin mendapat opsi memasukkan PIN saat file gagal didekripsi, agar saya bisa membuka data dengan sandi yang benar.
90. Sebagai pengguna, saya ingin mendapat opsi memulihkan backup, agar data bisa diselamatkan.
91. Sebagai pengguna, saya ingin mendapat opsi membuat file baru dengan konfirmasi, agar saya bisa mulai dari awal tanpa risiko tanpa sadar.
92. Sebagai pengguna, saya ingin semua penulisan memakai atomic write, agar file tidak korup saat aplikasi tertutup tiba-tiba.
93. Sebagai pengguna, saya ingin editor raw JSON hanya di area Advanced, agar pengguna biasa tidak mudah merusak data.
94. Sebagai pengguna, saya ingin validasi JSON sebelum menyimpan dari editor raw, agar kesalahan format terdeteksi lebih awal.

### Data Center

95. Sebagai pengguna, saya ingin mengekspor data Task Master New, agar saya punya backup manual.
96. Sebagai pengguna, saya ingin mengimpor file lama, agar data bisa dipindahkan ke perangkat lain.
97. Sebagai pengguna, saya ingin mengimpor file v2, agar backup baru bisa dipulihkan.
98. Sebagai pengguna, saya ingin hasil export/import tetap sama setelah round-trip, agar tidak ada data yang hilang.

### Responsif, aksesibilitas, dan kualitas

99. Sebagai pengguna mobile, saya ingin layout yang nyaman di layar sempit, agar tidak ada elemen terpotong.
100. Sebagai pengguna desktop, saya ingin layout dua panel, agar daftar dan detail terlihat bersamaan.
101. Sebagai pengguna tablet, saya ingin layout menyesuaikan lebar, agar tidak memaksa satu pola yang tidak cocok.
102. Sebagai pengguna, saya ingin target sentuh minimal 48 dp, agar tombol mudah ditekan.
103. Sebagai pengguna, saya ingin teks tetap terbaca saat ukuran font diperbesar, agar aksesibilitas tetap baik.
104. Sebagai pengguna pembaca layar, saya ingin ikon dan progress bar punya label, agar saya memahami konteks.
105. Sebagai pengguna desktop, saya ingin fokus keyboard terlihat dan `Esc` menutup dialog, agar navigasi tidak membingungkan.
106. Sebagai pengguna, saya ingin melihat loading state, agar tahu aplikasi sedang memuat.
107. Sebagai pengguna, saya ingin mendapat banner jika penyimpanan gagal, agar saya tahu perubahan belum tersimpan.
108. Sebagai pengguna dengan data besar, saya ingin Task Master tetap responsif, agar ribuan tugas tidak membuat aplikasi macet.
109. Sebagai pengguna, saya ingin pengaturan folder dan enkripsi tetap dapat diakses, agar perilaku lama tidak hilang.
110. Sebagai pengguna, saya ingin teks UI konsisten berbahasa Indonesia, agar aplikasi terasa menyatu.

---

## Implementation Decisions

### Cakupan dan rollout

1. Fitur baru dibangun sebagai modul fitur terpisah bernama `task_master_new`. Modul lama tidak dihapus pada fase awal.
2. Modul lama hanya menjadi fallback dan tidak boleh menulis file bersamaan dengan modul baru. Setelah switch, hanya modul baru yang menjadi penulis aktif.
3. Switch navigasi dilakukan setelah parity dan manual QA lulus. Rollback dilakukan dengan mengembalikan navigasi ke modul lama dan, jika perlu, memulihkan backup.
4. Penghapusan modul lama dilakukan sebagai pekerjaan terpisah setelah versi baru stabil.

### Arsitektur

5. Modul baru memakai pemisahan domain, data, dan presentasi.
6. Domain berisi entity, nilai `TaskKind`, aturan streak, kontrak repository, dan use case. Domain tidak mengenal Flutter, JSON, atau file system.
7. Data berisi DTO, mapper, local data source, implementasi repository, migrasi, enkripsi, dan adaptor Jurnal.
8. Presentasi berisi controller, state immutable, layar, dan widget. Presentasi tidak menulis file langsung.
9. `TaskMasterController` memakai `ChangeNotifier` bawaan Flutter. Tidak ada dependency state management baru.
10. State controller direpresentasikan oleh objek immutable dengan `copyWith`, mencakup status halaman, kategori, kategori terpilih, query pencarian, filter, mode edit, ringkasan hari ini, dan aksi terakhir untuk undo.
11. Controller bergantung pada kontrak repository, bukan implementasi file system.
12. Modul baru tidak menambah dependency pihak ketiga.

### Domain

13. `Category` memiliki `id` stabil, `name`, `icon`, `isHidden`, `sortOrder`, dan daftar tugas.
14. `Task` memiliki `id` stabil, `categoryId`, `name`, `kind`, `isActive`, `sortOrder`, `targetDaily`, `targetTotal`, `totalCount`, `createdAt`, `updatedAt`, dan riwayat harian.
15. `DailyProgress` memiliki tanggal lokal `YYYY-MM-DD`, jumlah increment, dan waktu pembaruan.
16. `TaskKind` terdiri dari `habit`, `counter`, dan `progress`.
17. `habit` adalah aktivitas berulang dengan target harian opsional. `counter` adalah akumulasi tanpa kewajiban harian. `progress` adalah pekerjaan menuju target total yang wajib lebih dari nol.
18. `countToday` adalah proyeksi dari riwayat hari ini, bukan sumber kebenaran. Sumber kebenaran harian adalah riwayat sparse.
19. Riwayat hanya menyimpan tanggal dengan hitungan lebih dari nol dan dipangkas maksimal 365 hari per tugas.
20. Streak dihitung dari hari kemarin ke belakang. Jika target harian lebih dari nol, hari berhasil bila hitungan mencapai target. Jika target nol, hari dianggap aktif bila ada hitungan. Hari ini yang belum dikerjakan tidak memutus streak.
21. Definisi selesai: `habit` selesai bila target harian tercapai; `counter` tidak punya status selesai; `progress` selesai bila total mencapai target total.

### Data dan kompatibilitas

22. File data Task Master yang ada tetap menjadi lokasi penyimpanan utama. Tidak ada file data baru yang terpisah untuk v1.
23. Skema v2 menambahkan `schemaVersion`, `id` kategori, `sortOrder`, `kind`, `createdAt`, `updatedAt`, dan `history`.
24. Field legacy `type`, `count`, `countToday`, `targetCountToday`, `targetCount`, `date`, `lastUpdated`, dan `checked` tetap ditulis untuk kompatibilitas selama transisi.
25. `type` adalah cermin legacy: `progress` menjadi `1`, `habit` dan `counter` menjadi `0`.
26. Mapper adalah satu-satunya jalur tulis dari domain ke JSON dan sebaliknya. Tidak ada penulisan field legacy secara ad hoc dari controller atau widget.
27. `id` kategori yang belum ada di-backfill secara deterministik dari nama, dengan penanganan kolisi agar unik dan stabil.
28. `id` tugas lama dipertahankan. Jika kosong, dibuat baru.
29. Pemetaan jenis tugas legacy: `type: 1` menjadi `progress`; `type: 0` dengan target harian lebih dari nol menjadi `habit`; `type: 0` tanpa target harian menjadi `counter`.
30. `countToday` legacy pada tanggal lampau dipindahkan ke riwayat agar tidak hilang saat migrasi.
31. Reset harian tidak memakai job terjadwal. Pergantian hari terjadi karena kunci tanggal riwayat berubah.
32. Migrasi dijalankan saat repository memuat file. Urutannya: baca, dekripsi bila perlu, deteksi versi, backup bila legacy, petakan, tulis dengan atomic write, enkripsi ulang bila perlu.
33. Migrasi harus idempoten dan tidak boleh mengubah file asli jika gagal.
34. Backup disimpan di area data Task Master dan memakai timestamp. Backup mengikuti status enkripsi file asli.
35. File dengan field tidak dikenal dipertahankan bila memungkinkan. Jika tidak, field tersebut dicatat di log tanpa data sensitif.
36. Semua baca/tulis memakai layanan penyimpanan dan helper kripto yang sudah ada. Penulisan wajib atomic.
37. Hanya satu versi Task Master yang boleh menulis. Ini adalah asumsi operasional selama masa transisi.

### Repository dan konkurensi

38. Kontrak repository mencakup pemuatan data, penyimpanan, CRUD kategori, CRUD tugas, increment, undo, pencarian/filter bila diperlukan, dan operasi migrasi.
39. Implementasi repository memakai local data source untuk file system dan mapper untuk konversi data.
40. Semua operasi tulis diserialisasi melalui antrean di local data source.
41. Increment memperbarui state di memori terlebih dahulu, lalu menjadwalkan penyimpanan dengan debounce 300 ms.
42. Penyimpanan berikutnya menunggu penyimpanan sebelumnya selesai. Tidak ada dua penulisan bersamaan.
43. Jika penyimpanan gagal, state tetap tampil, tetapi pengguna mendapat banner “Perubahan belum tersimpan” dengan opsi coba lagi.
44. Tidak ada operasi I/O di dalam `build`. Tidak ada penggunaan `BuildContext` setelah operasi async tanpa pengecekan `mounted`.
45. Waktu saat ini harus dapat diinjeksi untuk pengujian, bukan dibaca langsung dari `DateTime.now()` di logika domain.

### Integrasi Jurnal

46. Relasi tugas dengan Jurnal dimiliki oleh Jurnal melalui `linkedTaskIds`. Task Master New tidak menyimpan salinan relasi.
47. Integrasi Jurnal dibungkus dalam gateway tersendiri di data layer. Controller tidak membaca atau menulis file Jurnal secara langsung.
48. Increment tugas tertaut menambah durasi sesuai pengaturan template Jurnal, dengan fallback 30 menit.
49. Undo increment mengurangi durasi yang sama dari task Jurnal tertaut.
50. Rollback Jurnal bersifat best-effort. Jika gagal, data Task Master tetap dikembalikan dan pengguna mendapat peringatan eksplisit.
51. File Jurnal tetap mengikuti mekanisme enkripsi dan atomic write yang ada.

### Presentasi dan UX

52. Navigasi mobile memakai dashboard dan push ke halaman detail kategori. Dialog hanya untuk form pendek dan konfirmasi destruktif.
53. Navigasi desktop memakai dua panel: daftar kategori di kiri, detail atau dashboard di kanan.
54. Breakpoint: mobile di bawah 600 dp, tablet 600–1024 dp, desktop di atas 1024 dp.
55. Dashboard menampilkan empat kartu ringkasan, daftar “Hari Ini”, dan daftar/grid kategori.
56. Halaman detail kategori menampilkan header, toolbar pencarian/filter, daftar tugas, mode seleksi, dan aksi massal.
57. Increment tidak memakai dialog konfirmasi. Setelah increment, tampilkan SnackBar dengan Undo selama 5 detik.
58. Hanya increment terakhir yang dapat di-undo.
59. Reorder memakai drag handle. Tombol panah hanya menjadi fallback aksesibilitas.
60. Pencarian mencakup nama kategori dan tugas, dikelompokkan per kategori, dengan debounce 250 ms.
61. Filter minimal: semua, aktif, nonaktif, punya target hari ini.
62. Form kategori memvalidasi nama wajib, maksimal 60 karakter, dan duplikat case-insensitive.
63. Form tugas memvalidasi nama wajib, maksimal 120 karakter, target harian tidak negatif, dan target total wajib lebih dari nol untuk `Progress`.
64. Material 3 dipakai dengan identitas warna indigo/teal. Light mode menjadi target v1.
65. Target sentuh minimal 48 dp, kontras WCAG AA, dukungan text scale hingga 1.5, dan label aksesibilitas untuk ikon serta progress bar.
66. Keyboard shortcut desktop minimal: pencarian, tambah tugas, dan tutup dialog.
67. Raw JSON editor dipindahkan ke area Advanced, tetap memvalidasi JSON dan memakai atomic write.
68. Recovery file korup menyediakan buka kunci dengan PIN, pulihkan backup, dan buat baru dengan konfirmasi.

### Integrasi lintas fitur

69. Checklist tidak diubah pada v1 dan tetap membaca file data Task Master yang sama.
70. Data Center tidak diubah pada v1 dan tetap mengekspor/mengimpor file data Task Master yang sama. Import file lama akan dimigrasi saat dibuka.
71. Pengaturan folder dan enkripsi yang sudah dipakai lintas fitur dipindahkan ke area core pada fase awal agar modul baru tidak bergantung pada modul lama.
72. Password gate tingkat aplikasi tidak diubah.

### Performa

73. Target muat 1.000 tugas di bawah 500 ms pada Android kelas menengah.
74. Target perubahan UI setelah increment di bawah 100 ms.
75. Target pencarian 1.000 tugas di bawah 100 ms setelah input.
76. Riwayat sparse dipakai untuk membatasi ukuran file dan biaya parsing.

---

## Testing Decisions

### Prinsip pengujian

Test yang baik menguji perilaku eksternal melalui antarmuka publik, bukan detail implementasi. Test tidak boleh bergantung pada nama method privat, struktur widget internal, atau urutan pemanggilan yang tidak penting. Waktu harus deterministik melalui clock yang diinjeksi. File system harus memakai direktori sementara dan dibersihkan setelah test.

Prior art di repositori ini belum ada. Test Task Master New akan menjadi pola pertama, sehingga seam harus sederhana dan tidak memaksa perubahan besar pada fitur lain.

### Seam pengujian

Seam utama yang diusulkan:

1. **`TaskRepository`** — seam tertinggi untuk controller dan widget test. Controller menerima kontrak ini; test memakai fake in-memory untuk mengatur data, mensimulasikan error, dan memverifikasi perilaku pengguna tanpa menyentuh file.
2. **`TaskLocalDataSource`** — seam data untuk contract test implementasi repository. Implementasi nyata memakai layanan penyimpanan, enkripsi, dan atomic write; implementasi palsu dipakai untuk test yang tidak perlu file. Test contract memakai direktori sementara untuk memverifikasi baca/tulis, migrasi, backup, dan kegagalan.
3. **`JournalGateway`** — seam integrasi Jurnal. Test increment/undo memakai fake untuk memverifikasi penambahan dan pengurangan durasi, termasuk skenario rollback gagal.

`TaskLocalDataSource` dan `JournalGateway` adalah adapter di bawah seam utama. Keduanya hanya dipakai pada contract test, bukan untuk menguji ulang seluruh alur UI. Dengan begitu, sebagian besar test tetap berpusat pada satu seam: `TaskRepository`.

### Modul yang diuji

- **Mapper dan migrasi** — pemetaan legacy ke v2, backfill `id`, pemetaan `TaskKind`, pemindahan `countToday` historis, idempotensi, penanganan field hilang, dan field tidak dikenal.
- **Repository** — CRUD, increment, undo, pencarian, filter, reorder, pemindahan tugas, dan pemuatan data.
- **Local data source** — atomic write, enkripsi round-trip, file tidak ada, file korup, backup, dan serialisasi penulisan.
- **Streak calculator** — aturan target harian, tanpa target, hari ini belum dikerjakan, dan pemangkasan riwayat.
- **Controller** — loading, ready, empty, corrupted, search, filter, seleksi, increment, undo, dan error penyimpanan.
- **Widget** — dashboard, detail kategori, form, SnackBar undo, empty state, dan layout responsive.
- **Journal gateway** — penambahan durasi, pengurangan saat undo, fallback 30 menit, file terenkripsi, dan kegagalan rollback.

### Skenario test wajib

- Migrasi fixture legacy lengkap menghasilkan data v2 yang setara.
- Migrasi dua kali tidak menggandakan kategori, tugas, atau riwayat.
- Migrasi gagal tidak mengubah file asli dan tidak menghapus backup.
- Rename kategori mempertahankan `id` dan semua tugas.
- Increment menambah total, hitungan harian, dan riwayat hari ini.
- Undo mengembalikan ketiganya.
- Undo mengembalikan durasi Jurnal; jika gagal, data tugas tetap kembali dan ada peringatan.
- Pergantian hari membuat `countToday` menjadi nol tanpa job reset.
- Streak benar untuk target terpenuhi, target tidak terpenuhi, tanpa target, dan hari ini belum dikerjakan.
- Pencarian menemukan tugas lintas kategori dan mengembalikan konteks kategori.
- Filter aktif, nonaktif, dan target hari ini bekerja.
- Reorder dan pindah kategori bertahan setelah reload.
- Kategori tersembunyi dan tugas nonaktif tidak memengaruhi ringkasan.
- File terenkripsi dapat dimigrasi, dibaca, dan ditulis ulang.
- File korup menampilkan recovery dan tidak menimpa data.
- Export/import round-trip menghasilkan data yang sama.
- Layout mobile dan desktop tidak overflow pada text scale 1.5.

### Jenis test

- **Unit test** untuk mapper, streak, dan aturan domain.
- **Contract test** untuk repository dan local data source.
- **Widget test** untuk dashboard, detail kategori, form, increment/undo, search, dan empty state.
- **Manual QA** untuk Android dan Linux desktop, termasuk data 1.000 tugas, enkripsi, Jurnal, Checklist, dan Data Center.

---

## Out of Scope

- Notifikasi sistem atau local notification.
- Subtask dan checklist bertingkat di dalam tugas.
- Template tugas atau kategori.
- Statistik lanjutan, grafik jangka panjang, dan ekspor laporan.
- Sinkronisasi cloud, multi-perangkat, atau multi-user.
- Dark mode sebagai target rilis.
- Penggantian atau redesign fitur Jurnal dan Checklist.
- Perubahan skema enkripsi global.
- Penghapusan modul Task Master lama pada fase implementasi awal.
- Perubahan pada Data Center selain memastikan kompatibilitas file.
- Migrasi data fitur selain Task Master.
- Publikasi otomatis ke issue tracker (belum ada tracker yang dikonfigurasi di repositori ini).

---

## Further Notes

### Default untuk open questions

- Retensi riwayat: 365 hari per tugas.
- Dark mode: ditunda ke v2.
- Raw JSON editor: tersedia di area Advanced, bukan menu utama.
- Undo Jurnal: best-effort, dengan peringatan jika rollback gagal.
- Nama modul: `task_master_new`.

### Konfirmasi seam

Sebelum implementasi dimulai, konfirmasikan bahwa tiga seam di atas sesuai harapan:

1. `TaskRepository` sebagai seam utama controller dan widget.
2. `TaskLocalDataSource` untuk contract test penyimpanan dan migrasi.
3. `JournalGateway` untuk contract test integrasi Jurnal.

Jika ingin satu seam saja, alternatifnya adalah memasukkan seluruh operasi Jurnal ke dalam kontrak repository dan menguji integrasi Jurnal hanya melalui repository. Konsekuensinya, repository menjadi lebih besar dan tanggung jawabnya kurang fokus.

### Catatan rollout

- Fase 0: scaffold, entity, kontrak repository, mapper, dan test migrasi.
- Fase 1: data, migrasi, backup, enkripsi.
- Fase 2: parity CRUD, increment, Jurnal, recovery.
- Fase 3: dashboard, detail kategori, search, filter, undo, responsive.
- Fase 4: riwayat dan streak.
- Fase 5: QA dan switch navigasi.
- Fase 6: pembersihan modul lama.

### Catatan issue tracker

Repositori ini belum memiliki konfigurasi issue tracker atau vocabulary label triage. Spec ini disimpan sebagai dokumen lokal. Jika ingin spec dipublikasikan ke tracker dengan label `ready-for-agent`, jalankan `/setup-matt-pocock-skills` terlebih dahulu.
