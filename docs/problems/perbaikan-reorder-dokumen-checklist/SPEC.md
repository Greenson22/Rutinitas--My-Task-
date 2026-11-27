# SPEC — Perbaikan Reorder Hari Ini, Folder Bertingkat My Documents, Tautan Berkas Checklist & Pembaruan Tentang

| Field | Value |
|---|---|
| Fitur | `perbaikan_reorder_dokumen_checklist` |
| Sumber | `docs/problems/perbaikan-reorder-dokumen-checklist/PRD.md` |
| Status | Ready for agent |
| Tanggal | 2026-11-27 |
| Platform utama | Android dan Linux desktop |

---

## Problem Statement

Pengguna menghadapi lima masalah dalam satu siklus pemakaian aplikasi:

**Urutan Hari Ini hilang.** Di dashboard Task Master, pengguna bisa menggeser tugas pada seksi "Hari Ini", tetapi urutan itu hanya bertahan selama layar belum dibangun ulang. Begitu keluar-masuk layar atau menutup aplikasi, urutan kembali ke default. Mode pengurutan yang dipilih juga tidak diingat.

**My Documents terlalu datar.** Pengguna hanya bisa mengelompokkan berkas ke dalam kartu Group; di dalam group tidak ada folder. Akibatnya berkas bercampur dalam satu daftar panjang, dan tidak ada cara membedakan dua berkas bernama sama untuk konteks berbeda. Aksi Ekspor masih ada dan memakai nama berkas saja, sehingga berpotensi saling menimpa saat diekspor ke direktori yang sama. Ikon group masih diketik bebas sebagai emoji, rawan tidak konsisten.

**Item checklist tidak bisa terhubung ke berkas.** Pengguna menyimpan materi di My Documents dan daftar tugas di My Checklist, tetapi keduanya terpisah. Tidak ada cara menautkan satu item checklist ke satu berkas, membukanya langsung, atau melepas kaitannya.

**Card DailyTracker terlalu ramai.** Tombol "Reset Hari Baru" di card menduplikasi fungsi reset yang sudah ada di dalam dialog checklist, dan tombol "Lihat History" terpisah jauh di bawah sehingga tidak praktis dijangkau.

**Halaman Tentang usang.** Email kontak masih alamat lama, dan daftar Fitur Aplikasi tidak menyebut fitur-fitur yang sudah ada (folder bertingkat, tautan berkas, lipat/sembunyikan seksi, color wheel, stacked history, visibilitas Hari Ini).

---

## Solution

Lima workstream yang independen secara teknis namun dirilis bersama:

**WS1 — Urutan Hari Ini yang permanen.** Urutan manual dan mode pengurutan terakhir disimpan ke data tugas (schema baru), bukan ke state layar. Urutan ini terpisah dari urutan tugas di dalam kategori. Tugas baru otomatis di akhir, ID tugas yang sudah tidak ada dibersihkan, dan tugas yang sedang tidak tampil hari ini tetap mempertahankan posisinya.

**WS2 — Folder bertingkat di My Documents.** Group tetap menjadi akar, tetapi di dalamnya pengguna bisa membuat folder, folder di dalam folder, tanpa batas kedalaman. Setiap folder adalah direktori fisik, sehingga nama sama di folder berbeda aman. Navigasi memakai drill-down dengan breadcrumb, folder selalu tampil di atas berkas, berkas bentrok mendapat akhiran otomatis, ikon dipilih lewat picker emoji, aksi Ekspor dihapus, dan folder bisa dibagikan sebagai ZIP utuh.

**WS3 — Tautan berkas pada item checklist.** Satu item checklist bisa menunjuk ke satu berkas My Documents. Penautan dan pelepasan dilakukan di dialog "Ubah Item & Hubungan Lintas Data". Item tertaut menampilkan indikator 📎 dan menyediakan entri "Buka Berkas" di titik tiga. Rename/pindah/hapus dari dalam aplikasi menjaga tautan tetap benar; berkas yang hilang dari luar aplikasi ditandai dan bisa dilepas.

**WS4 — Card DailyTracker yang ringkas.** Tombol Reset Hari Baru dihapus dari card (reset tetap tersedia di dialog checklist), dan Lihat History diletakkan tepat di bawah Simpan Hari Ini dengan jarak rapat, keduanya selebar card.

**WS5 — Halaman Tentang yang akurat.** Email kontak diganti, dan daftar Fitur Aplikasi ditulis ulang agar mencerminkan kemampuan aplikasi saat ini, hanya fitur final yang terlihat pengguna.

---

## User Stories

### Urutan Hari Ini

1. Sebagai pengguna Task Master, saya ingin urutan manual di Hari Ini tetap sama setelah saya keluar-masuk layar, agar saya tidak perlu mengurutkan ulang setiap kali.
2. Sebagai pengguna Task Master, saya ingin urutan manual tetap sama setelah aplikasi ditutup dan dibuka kembali, agar pengaturan saya terasa permanen.
3. Sebagai pengguna Task Master, saya ingin mode pengurutan terakhir yang saya pilih tetap aktif saat aplikasi dibuka kembali, agar tampilan konsisten dengan kebiasaan saya.
4. Sebagai pengguna Task Master, saya ingin menggeser tugas dengan drag maupun tombol naik/turun, agar bisa memilih cara yang nyaman.
5. Sebagai pengguna Task Master, saya ingin tugas baru muncul di akhir urutan manual saya, agar urutan yang sudah saya susun tidak berantakan.
6. Sebagai pengguna Task Master, saya ingin tugas yang dihapus tidak meninggalkan jejak di urutan, agar data tetap bersih.
7. Sebagai pengguna Task Master, saya ingin tugas yang sedang tidak tampil hari ini tetap mengingat posisinya, agar saat muncul lagi ia kembali ke tempat yang saya tentukan.
8. Sebagai pengguna Task Master, saya ingin menggeser tugas di Hari Ini tidak mengubah urutan tugas di dalam kategori, agar kedua tampilan bisa saya atur secara independen.
9. Sebagai pengguna Task Master, saya ingin data tugas lama tetap terbaca setelah pembaruan, agar tidak kehilangan kategori, tugas, atau riwayat.
10. Sebagai pengguna Task Master, saya ingin urutan custom yang kosong tidak menampilkan hasil acak, agar tampilan tetap dapat diprediksi.

### Folder My Documents

11. Sebagai pengguna My Documents, saya ingin membuat folder di dalam group, agar berkas bisa saya kelompokkan lebih rinci.
12. Sebagai pengguna My Documents, saya ingin membuat folder di dalam folder tanpa batas kedalaman, agar struktur arsip saya mengikuti kebutuhan nyata.
13. Sebagai pengguna My Documents, saya ingin melihat breadcrumb Group / Folder / Subfolder, agar saya selalu tahu posisi saya.
14. Sebagai pengguna My Documents, saya ingin kembali ke folder induk lewat tombol back atau breadcrumb, agar navigasi cepat.
15. Sebagai pengguna My Documents, saya ingin folder selalu tampil di atas berkas, agar struktur mudah dibaca.
16. Sebagai pengguna My Documents, saya ingin mengurutkan berkas dengan mode yang sudah ada, agar daftar sesuai preferensi saya.
17. Sebagai pengguna My Documents, saya ingin menyimpan dua berkas bernama sama di folder berbeda tanpa saling menimpa, agar konteks masing-masing tetap utuh.
18. Sebagai pengguna My Documents, saya ingin berkas bentrok di folder yang sama otomatis diberi akhiran (1), (2), dan seterusnya, agar impor tidak terhenti oleh dialog berulang.
19. Sebagai pengguna My Documents, saya ingin nama folder yang bentrok ditolak dengan pesan jelas, agar tidak terjadi tabrakan direktori.
20. Sebagai pengguna My Documents, saya ingin mengganti nama folder beserta isinya, agar struktur bisa dirapikan kapan saja.
21. Sebagai pengguna My Documents, saya ingin memindahkan folder ke folder induk lain di group yang sama, agar hierarki bisa disusun ulang.
22. Sebagai pengguna My Documents, saya ingin aplikasi menolak pemindahan folder ke dalam dirinya sendiri atau turunannya, agar struktur tidak rusak.
23. Sebagai pengguna My Documents, saya ingin menghapus folder beserta seluruh isinya dengan konfirmasi, agar tidak ada penghapusan tidak sengaja.
24. Sebagai pengguna My Documents, saya ingin memindahkan berkas ke folder lain atau ke group lain, agar berkas berada di tempat yang tepat.
25. Sebagai pengguna My Documents, saya ingin mengganti ikon group dan folder lewat picker emoji, agar tampilan konsisten dan tidak salah ketik.
26. Sebagai pengguna My Documents, saya ingin ikon lama tetap tampil walau tidak ada di daftar picker, agar data lama tidak rusak.
27. Sebagai pengguna My Documents, saya ingin mengimpor berkas langsung ke folder yang sedang saya buka, agar tidak perlu memindahkannya setelahnya.
28. Sebagai pengguna My Documents, saya ingin tidak melihat lagi menu Ekspor, agar pilihan yang tersedia tidak membingungkan.
29. Sebagai pengguna My Documents, saya ingin membagikan berkas lewat menu Bagikan, agar berkas bisa dikirim ke aplikasi lain.
30. Sebagai pengguna My Documents, saya ingin membagikan beberapa berkas sekaligus, agar tidak perlu mengirim satu per satu.
31. Sebagai pengguna My Documents, saya ingin membagikan satu folder sebagai ZIP berisi seluruh subfolder dan isinya, agar struktur tetap utuh saat diterima.
32. Sebagai pengguna My Documents, saya ingin folder kosong tetap valid saat dibagikan, agar tidak terjadi kesalahan.
33. Sebagai pengguna My Documents, saya ingin berkas lama tetap tampil di layar group tanpa migrasi paksa, agar pembaruan tidak mengubah kebiasaan saya.

### Tautan berkas checklist

34. Sebagai pengguna My Checklist, saya ingin menautkan satu berkas My Documents ke satu item lewat dialog Ubah Item & Hubungan Lintas Data, agar materi dan tugas saling terhubung.
35. Sebagai pengguna My Checklist, saya ingin memilih berkas lewat penjelajah Group → Folder → Berkas dengan pencarian, agar berkas yang dalam tetap mudah ditemukan.
36. Sebagai pengguna My Checklist, saya ingin melihat nama dan path berkas yang tertaut di dialog, agar saya yakin berkas yang dipilih benar.
37. Sebagai pengguna My Checklist, saya ingin mengganti berkas tertaut tanpa melepasnya lebih dulu, agar koreksi cepat.
38. Sebagai pengguna My Checklist, saya ingin melepas kaitan berkas lewat dialog dengan konfirmasi, agar tidak terlepas karena salah tekan.
39. Sebagai pengguna My Checklist, saya ingin item yang punya tautan menampilkan indikator 📎, agar mudah dikenali sekilas.
40. Sebagai pengguna My Checklist, saya ingin entri Buka Berkas muncul di titik tiga hanya untuk item yang tertaut, agar menu tidak dipenuhi opsi yang tidak relevan.
41. Sebagai pengguna My Checklist, saya ingin berkas tertaut terbuka di aplikasi yang sesuai, agar bisa langsung dibaca atau diedit.
42. Sebagai pengguna My Checklist, saya ingin tautan tetap benar saat berkas di-rename dari dalam aplikasi, agar tidak putus.
43. Sebagai pengguna My Checklist, saya ingin tautan tetap benar saat berkas dipindah ke folder atau group lain dari dalam aplikasi, agar tidak putus.
44. Sebagai pengguna My Checklist, saya ingin tautan otomatis dilepas saat berkas dihapus dari dalam aplikasi, agar tidak menyimpan kaitan mati.
45. Sebagai pengguna My Checklist, saya ingin diberi tahu bila berkas tertaut hilang karena perubahan di luar aplikasi, agar saya bisa memutuskan melepasnya.
46. Sebagai pengguna My Checklist, saya ingin tautan ke dua berkas bernama sama di folder berbeda tetap menunjuk berkas yang benar, agar tidak tertukar.
47. Sebagai pengguna My Checklist, saya ingin membatalkan dialog penautan tanpa mengubah apa pun, agar eksperimen aman.
48. Sebagai pengguna My Checklist, saya ingin relasi checklist lama (akumulasi, prasyarat, lintas card) tetap berfungsi, agar fitur baru tidak merusak yang lama.

### Card DailyTracker

49. Sebagai pengguna card DailyTracker, saya ingin tombol Reset Hari Baru tidak lagi memenuhi card, agar tampilan lebih ringkas.
50. Sebagai pengguna card DailyTracker, saya ingin tetap bisa mereset progres lewat dialog checklist, agar fungsi reset tidak hilang.
51. Sebagai pengguna card DailyTracker, saya ingin tombol Lihat History tepat di bawah Simpan Hari Ini, agar mudah dijangkau dengan satu tangan.
52. Sebagai pengguna card DailyTracker, saya ingin kedua tombol selebar card dan berjarak rapat, agar tidak ada ruang terbuang.
53. Sebagai pengguna card biasa atau card catatan, saya ingin tombol DailyTracker tetap tidak muncul, agar tampilan tidak berubah tanpa alasan.

### Halaman Tentang

54. Sebagai pengguna, saya ingin halaman Tentang menampilkan email kontak yang benar, agar saya bisa menghubungi pengembang.
55. Sebagai pengguna, saya ingin daftar Fitur Aplikasi mencerminkan fitur yang benar-benar ada, agar saya memahami kemampuan aplikasi.
56. Sebagai pengguna, saya ingin daftar fitur tidak memuat fitur eksperimental atau internal, agar tidak bingung dengan hal yang belum stabil.
57. Sebagai pengguna, saya ingin deskripsi fitur tetap terbaca pada layar kecil, agar halaman Tentang nyaman dibuka di perangkat apa pun.

---

## Implementation Decisions

### WS1 — Urutan Hari Ini

1. Sumber kebenaran urutan Hari Ini dipindahkan dari state widget ke agregat data Task Master. Agregat mendapat dua field baru: `todaySortMode` (nama mode pengurutan) dan `todayOrder` (daftar ID tugas terurut). Versi schema dinaikkan menjadi 3.
2. Bentuk data yang disepakati:

   ```json
   {
     "schemaVersion": 3,
     "categories": ["..."],
     "todaySortMode": "custom",
     "todayOrder": ["task_a", "task_b", "task_c"]
   }
   ```

3. Nilai `todaySortMode` yang tidak dikenal atau kosong diperlakukan sebagai mode default. `todayOrder` yang tidak ada diperlakukan sebagai daftar kosong. Migrasi dari schema 1/2 hanya menambahkan dua field tersebut; kategori, tugas, dan riwayat tidak diubah.
4. Urutan Hari Ini independen dari `sortOrder` tugas di dalam kategori. Menggeser di dashboard tidak menulis `sortOrder`, dan sebaliknya.
5. Menyimpan urutan dan mode dilakukan melalui repository yang sudah menangani penulisan atomik dan serialisasi. Layar tidak lagi menyimpan urutan sebagai state lokal yang menjadi sumber kebenaran; state layar hanya cermin dari state controller.
6. ID tugas yang sudah tidak ada di seluruh kategori dibuang saat data dimuat dan saat disimpan. ID tugas yang sedang tidak lolos aturan visibilitas Hari Ini tetap dipertahankan. Tugas baru yang belum ada di daftar urutan dianggap berada di akhir.
7. Mode custom dengan daftar urutan kosong berperilaku seperti mode default.
8. Menggeser tugas saat mode bukan custom otomatis berpindah ke mode custom dan menyimpan perubahan.
9. Serialisasi nama mode pengurutan dipusatkan di satu helper agar penulisan dan pembacaan tidak menyimpang.

### WS2 — Folder My Documents

10. Metadata folder adalah entitas baru di dalam data group: `id`, `name`, `icon`, `parentId` (null berarti root), dan `orderIndex`. Daftar folder disimpan di dalam JSON group, bukan file terpisah, sehingga backup dan sinkronisasi yang sudah ada otomatis membawanya.
11. Setiap folder dipetakan ke satu direktori fisik di dalam direktori group. Identitas sebuah berkas adalah path relatif terhadap direktori group, memakai pemisah `/`. Tidak ada ID berkas baru.
12. Nama folder wajib unik tanpa membedakan huruf besar/kecil di antara saudara dalam parent yang sama. Bentrok ditolak dengan pesan validasi. Nama folder disanitasi dari karakter yang tidak valid untuk path.
13. Layar detail group menjadi sadar-folder dan menerima path relatif awal. Isi layar mengikuti path tersebut, dengan breadcrumb yang setiap segmennya bisa ditekan untuk naik. Tap folder membuka layar yang sama pada path folder itu (drill-down), sehingga tombol back berfungsi alami.
14. Pemuatan isi direktori bersifat non-rekursif: pisahkan direktori dan berkas, sembunyikan berkas JSON metadata di level root. Folder ditampilkan lebih dulu dan diurutkan A-Z; berkas mengikuti mode pengurutan yang sudah ada. Ringkasan isi folder menampilkan jumlah berkas dan subfolder langsung.
15. Aksi folder: buat, ubah nama, ganti ikon, pindahkan, bagikan ZIP, hapus. Ubah nama folder ikut mengganti nama direktori fisik dan memperbarui tautan checklist di bawahnya. Pemindahan folder hanya diizinkan di dalam group yang sama dan ditolak bila tujuan adalah dirinya sendiri atau turunannya. Hapus folder bersifat rekursif dengan konfirmasi destruktif.
16. Aksi berkas: impor, ubah nama, pindahkan, bagikan, hapus. Impor dan ubah nama memakai direktori aktif. Pemindahan memakai pemilih tujuan hierarkis Group → Folder dan boleh lintas group. Semua bentrok nama berkas di folder yang sama diselesaikan dengan akhiran `nama (1).ext`, `nama (2).ext`, dan seterusnya, tanpa dialog.
17. Aksi Ekspor dihapus dari My Documents, termasuk ekspor massal dan seluruh pemanggilan terkait. Data Center tidak disentuh dan tetap memiliki backup/restore. Bagikan per berkas dan bagikan massal berkas dipertahankan.
18. Folder dapat dibagikan sebagai ZIP berisi seluruh subtree dengan struktur relatif terjaga. Folder kosong tetap menghasilkan ZIP yang valid. Berkas ZIP sementara dibersihkan setelah proses bagikan selesai.
19. Multi-select tetap khusus berkas pada folder aktif; folder tidak ikut multi-select dan dikelola lewat menunya sendiri.
20. Ikon group dan folder dipilih lewat satu widget picker emoji terkurasi yang dipakai bersama. Nilai emoji lama yang tidak ada di daftar tetap ditampilkan dan dianggap valid.
21. Berkas lama tetap berada di root group dan tampil di layar group tanpa migrasi. Data lama tanpa daftar folder dibaca sebagai daftar kosong.

### WS3 — Tautan Berkas Checklist

22. Item checklist mendapat tiga field opsional: ID group dokumen, path relatif berkas, dan nama tampilan berkas. Field dibaca dengan default null untuk data lama dan ditulis dengan aman.
23. Penautan dan pelepasan hanya dilakukan di dialog "Ubah Item & Hubungan Lintas Data". Dialog mendapat bagian baru berisi berkas tertaut, tombol pilih/ganti berkas, dan tombol hapus kaitan dengan konfirmasi destruktif.
24. Pemilih berkas berupa penjelajah hierarkis Group → Folder → Berkas dengan breadcrumb dan pencarian nama berkas. Hanya berkas yang bisa dipilih, bukan folder.
25. Item yang punya tautan menampilkan indikator 📎 di barisnya. Entri "Buka Berkas" hanya muncul di titik tiga saat item punya tautan, dan membuka berkas dengan aplikasi eksternal. Pelepasan tautan tidak ditambahkan ke titik tiga.
26. Layanan propagasi tautan bertanggung jawab menyelaraskan tautan ketika berkas berubah. Kontrak yang disepakati:
    - `updateLinkPath(groupId, oldRelativePath, newRelativePath, newName)`
    - `clearLinksFor(groupId, relativePathPrefix)`
    - `clearLinkForItem(groupId, relativePath)`
27. Propagasi dijalankan untuk rename berkas, pindah berkas, rename folder, pindah folder, hapus berkas, hapus folder, dan hapus group. Pencocokan memakai pasangan ID group + path relatif, sehingga nama sama di folder berbeda tidak tertukar.
28. Penghapusan dari dalam aplikasi melepas tautan otomatis dan menampilkan notifikasi informasi. Berkas yang hilang karena perubahan di luar aplikasi tidak mengubah data; item menampilkan status "Berkas tidak ditemukan" dan menawarkan opsi lepas.
29. Propagasi memakai jalur baca/tulis checklist yang sama dengan penyimpanan biasa, termasuk menghormati konfigurasi enkripsi, dan menulis secara atomik.
30. Item yang baru saja ditautkan tetapi berkasnya sudah tidak ada saat dialog disimpan ditolak dengan pesan yang jelas.

### WS4 — Card DailyTracker

31. Tombol "Reset Hari Baru" dan method reset harian di controller dihapus, termasuk key widget terkait. Tidak boleh ada pemanggil yang tersisa.
32. Di card, "Simpan Hari Ini" menjadi selebar card, diikuti jarak 6 piksel, lalu "Lihat History" selebar card. Keduanya tetap hanya muncul saat DailyTracker aktif dan card bukan bertipe catatan.
33. Reset tetap dapat dilakukan dari dialog checklist melalui "Reset Progress" dan "Reset Total Checklist"; perilaku reset yang ada tidak diubah.

### WS5 — Halaman Tentang

34. Email kontak pada tab Pengembang diganti menjadi `frendyrikalgerung@gmail.com`.
35. Daftar Fitur Aplikasi ditulis ulang memakai struktur item yang sudah ada (ikon, judul, deskripsi). Cakupan minimal: Task Master & target harian, tipe tugas fleksibel, My Checklist Hubs, kontrol tampilan checklist, tautan berkas checklist, My Documents dengan folder bertingkat dan bagikan, My Notes, Manajemen Prompt, Jurnal Aktivitas, Statistik & Analitik, DailyTracker & riwayat, Data Center, serta penyimpanan offline & direktori kustom.
36. Daftar fitur hanya memuat fitur final yang terlihat pengguna; fitur eksperimental, iklan, dan detail protokol internal tidak dicantumkan. Ikon memakai ikon Material, bukan emoji. Deskripsi dibuat cukup ringkas agar tidak overflow pada layar kecil.

---

## Testing Decisions

### Prinsip

Test yang baik menguji perilaku eksternal yang bisa diamati pengguna atau kontrak data yang stabil: urutan yang bertahan setelah reload, direktori yang benar-benar terbentuk, isi ZIP, nilai field yang tersimpan, dan elemen UI yang tampil atau hilang. Test tidak boleh bergantung pada nama method privat, struktur widget internal, atau detail implementasi yang mudah berubah.

Test tidak boleh memakai filesystem produksi. Gunakan direktori sementara yang di-inject sebagai base directory, dan `SharedPreferences.setMockInitialValues` bila state UI terlibat.

### Seam Pengujian

Seam yang diusulkan, dari yang tertinggi:

1. **Seam layar (utama).** Widget test pada layar Task Master, layar detail group dokumen, dialog checklist, dan halaman Tentang, dipump dengan fixture minimal dan base directory sementara. Ini menguji perilaku yang dilihat pengguna: urutan setelah reopen, breadcrumb, menu yang muncul, tombol yang hilang/berpindah, email dan daftar fitur.
2. **Seam repository/service (pendukung).** Test langsung pada repository Task Master dan layanan folder/tautan dengan base directory sementara. Dipakai untuk kontrak yang sulit diamati lewat UI: migrasi schema, prune/append urutan, auto-rename, isi ZIP, dan propagasi tautan.
3. **Seam model (paling rendah).** Round-trip JSON untuk data tugas, metadata folder, dan field tautan item. Hanya dipakai untuk menjaga kompatibilitas data lama.

Tidak ada seam baru berupa abstraksi database atau mock framework; kedua seam di atas memakai pola yang sudah ada di repositori.

### Modul yang Diuji

**WS1**
- Mapper/repository Task Master: migrasi v1/v2 → v3, default field, round-trip, prune ID, append tugas baru, mode tak dikenal jatuh ke default.
- Layar Task Master: geser tugas, reopen layar, urutan dan mode tetap; menggeser tidak mengubah urutan kategori.
- Helper pengurutan: mode custom dengan daftar kosong berperilaku default.

**WS2**
- Model: group lama tanpa daftar folder; round-trip metadata folder.
- Layanan folder: pembuatan bersarang, validasi nama unik, sanitasi, rename direktori, pindah folder, tolak pindah ke descendant, hapus rekursif.
- Layanan berkas: auto-rename saat impor dan rename, pindah lintas group + folder, nama sama di folder berbeda.
- Layar detail group: breadcrumb, drill-down, back, folder di atas berkas, menu folder, menu Ekspor hilang, Bagikan tetap ada.
- ZIP folder: entri memuat subtree dengan struktur benar; folder kosong valid.
- Picker emoji: nilai tersimpan dan emoji lama tetap valid.

**WS3**
- Model item: round-trip tiga field tautan; JSON lama menghasilkan null.
- Dialog relasi: pilih berkas lalu simpan; hapus kaitan dengan konfirmasi; batal tidak mengubah apa pun.
- Titik tiga dan indikator: entri Buka Berkas hanya untuk item tertaut; 📎 muncul/hilang.
- Layanan propagasi: rename/pindah/hapus berkas, rename/pindah/hapus folder, hapus group; nama sama di folder berbeda tidak tertukar.
- Dangling: berkas dihapus dari luar aplikasi menghasilkan status tidak ditemukan dan opsi lepas.

**WS4**
- Layar detail checklist: tombol Save dan History ada, tombol Reset tidak ada, posisi History di bawah Save, keduanya selebar card.
- Regresi: card catatan dan card tanpa DailyTracker tetap tidak menampilkan tombol.

**WS5**
- Halaman Tentang: email baru tampil, email lama tidak; entri fitur kunci tampil; tidak ada overflow pada ukuran layar kecil.

### Prior Art

- Persistensi dan reopen: `reorder_bulk_actions_test.dart`, `task_repository_reorder_contract_test.dart`.
- Pengurutan Hari Ini: `today_task_sorting_test.dart` (perlu diperluas dengan skenario reopen).
- Data sementara dan base directory: pola widget test Documents yang sudah ada.
- Konfirmasi dialog dan state checklist: test checklist section collapse.
- Catatan: dua test Documents yang ada memakai path sementara yang tidak sama dengan path produksi; perbaiki dulu agar tidak stale sebelum menambah test baru.

---

## Out of Scope

- Urutan Hari Ini per tanggal atau per hari.
- Sinkronisasi cloud; hanya local sharing dan backup yang sudah ada.
- Pemindahan folder lintas group (folder hanya dipindah di dalam group yang sama).
- Menggabungkan bagikan folder dengan multi-select berkas dalam satu aksi.
- Mengubah format backup/Data Center di luar konsekuensi otomatis dari struktur folder.
- File versioning atau riwayat perubahan dokumen.
- Lebih dari satu berkas tertaut per item checklist.
- Menampilkan fitur eksperimental atau iklan di halaman Tentang.
- Redesign visual menyeluruh di luar tombol DailyTracker.
- Migrasi paksa berkas lama ke dalam folder baru.

---

## Further Notes

- **ADR yang disarankan:** keputusan menyimpan urutan Hari Ini di data tugas (bukan preferensi lokal) dan keputusan folder fisik dengan path relatif sebagai identitas berkas layak dicatat sebagai ADR karena sulit dibalik dan memengaruhi backup/sinkronisasi.
- **Risiko propagasi tautan:** aksi My Documents kini menulis ke data checklist. Pastikan penulisan atomik dan tidak berjalan bersamaan dengan penyimpanan checklist dari layar lain; gunakan pola serialisasi yang sudah dipakai repository Task Master bila diperlukan.
- **Risiko Data Center:** sinkronisasi dokumen sudah berbasis daftar rekursif dan path relatif, sehingga folder ikut otomatis. Verifikasi khusus diperlukan untuk operasi hapus/rename folder agar manifest tidak menyisakan entri yatim.
- **Urutan implementasi:** WS1 → WS2 → WS3 → WS4 → WS5. WS3 bergantung pada identitas berkas (path relatif) yang diperkenalkan WS2.
- **Definition of done:** seluruh acceptance criteria di PRD terpenuhi, test baru hijau, test lama yang menyebut tombol Reset Hari Baru diperbarui, dan `flutter analyze` bersih.
