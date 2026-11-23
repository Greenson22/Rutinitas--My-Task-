# SPEC — DailyTracker

| Field | Value |
|---|---|
| Fitur | `daily_tracker` |
| Sumber | `docs/checklist/daily_tracker/PRD.md` |
| Status | Ready for Agent |
| Tanggal | 23 November 2026 |
| Platform Utama | Android |
| Platform Pendukung | Linux desktop |

---

## Problem Statement

Pengguna yang memiliki checklist rutinitas harian (seperti "Rutinitas Pagi" atau "Ibadah Harian") tidak bisa melacak konsistensi pengerjaan dari hari ke hari. Setiap kali membuka checklist, status centang dari hari sebelumnya tidak terdokumentasi — tidak ada cara untuk menjawab pertanyaan "kemarin saya selesaikan apa?". Selain itu, tidak ada mekanisme eksplisit untuk memulai hari baru: pengguna harus menghapus centang satu per satu secara manual.

Akibatnya, checklist yang ada hanya berguna sebagai daftar tugas statis, bukan sebagai alat pelacak kebiasaan harian yang bermakna.

---

## Solution

Tambahkan mode **DailyTracker** yang bisa diaktifkan per card `DailySubject` di dalam `ChecklistDetailScreen`. Ketika diaktifkan:

- Pengguna mencentang item seperti biasa, lalu menekan **"Simpan Hari Ini"** untuk menyimpan snapshot status seluruh item dengan key tanggal.
- Data hari ini tetap tampil setelah disimpan; pengguna menekan **"Reset Hari Baru"** secara eksplisit untuk mengosongkan status.
- Riwayat setiap tanggal dapat dibuka melalui **DailyTracker History Screen** (screen baru, mirip Jurnal Aktivitas) yang dapat diakses langsung dari card.
- History bisa dibersihkan per card atau per bulan.

Fitur ini sepenuhnya opt-in per card — card yang tidak mengaktifkan DailyTracker tidak terpengaruh sama sekali.

---

## User Stories

### Aktivasi & Konfigurasi

1. Sebagai pengguna, saya ingin mengaktifkan mode DailyTracker pada card checklist tertentu, agar hanya card yang saya pilih yang ikut ditracking harian.
2. Sebagai pengguna, saya ingin menonaktifkan DailyTracker pada card tertentu, agar card tersebut kembali berfungsi seperti checklist biasa.
3. Sebagai pengguna, saya ingin status aktif/nonaktif DailyTracker tersimpan secara persisten di file JSON, agar pengaturan tidak hilang setelah aplikasi ditutup.
4. Sebagai pengguna, saya ingin card yang sudah mengaktifkan DailyTracker memiliki penanda visual (badge) yang jelas, agar saya bisa membedakannya dari card biasa sekilas pandang.
5. Sebagai pengguna, saya ingin menonaktifkan DailyTracker tidak menghapus history yang sudah tersimpan, agar riwayat saya tetap aman.
6. Sebagai pengguna, saya ingin file JSON yang belum memiliki field DailyTracker tetap terbaca tanpa error, agar data lama tidak rusak setelah pembaruan.

### Menyimpan Data Harian

7. Sebagai pengguna, saya ingin menekan tombol "Simpan Hari Ini" untuk menyimpan status semua item checklist ke riwayat hari ini, agar pengerjaan hari ini terdokumentasi.
8. Sebagai pengguna, saya ingin snapshot mencakup seluruh item secara rekursif (termasuk child item bertingkat), agar riwayat benar-benar lengkap.
9. Sebagai pengguna, saya ingin snapshot menyimpan nama item, status progress, tipe item, serta nilai current dan target (untuk item tipe progress/countdown), agar history bermakna.
10. Sebagai pengguna, saya ingin mendapat konfirmasi (SnackBar) setelah berhasil menyimpan, agar saya tahu aksi berhasil.
11. Sebagai pengguna, saya ingin tampilan checklist tidak berubah setelah menyimpan, agar saya bisa melanjutkan bekerja tanpa gangguan.
12. Sebagai pengguna, saya ingin menekan "Simpan Hari Ini" dua kali di hari yang sama menghasilkan overwrite (snapshot terbaru menang), agar tidak ada duplikasi data.
13. Sebagai pengguna, saya ingin data tersimpan di file JSON yang sama dengan checklist saya (dalam `ChecklistGroup`), agar tidak perlu mengelola file baru.
14. Sebagai pengguna, saya ingin data DailyTracker ikut terenkripsi jika `ChecklistGroup` sudah menggunakan enkripsi, agar keamanan data terjaga konsisten.

### Reset Hari Baru

15. Sebagai pengguna, saya ingin menekan tombol "Reset Hari Baru" untuk mengosongkan status semua item (kembali ke `belum` / `currentValue: 0`), agar saya bisa memulai hari baru dengan slate bersih.
16. Sebagai pengguna, saya ingin ada dialog konfirmasi sebelum reset dilakukan, agar saya tidak kehilangan data karena salah tekan.
17. Sebagai pengguna, saya ingin reset tidak menghapus history — `dailyLogs` yang sudah tersimpan tetap utuh, agar riwayat lama tidak hilang karena reset.

### DailyTracker History Screen

18. Sebagai pengguna, saya ingin membuka DailyTracker History Screen dari tombol di card, agar saya bisa melihat riwayat pengerjaan dari waktu ke waktu.
19. Sebagai pengguna, saya ingin melihat daftar tanggal yang pernah disimpan, diurutkan dari yang terbaru ke yang terlama, agar tanggal terakhir mudah ditemukan.
20. Sebagai pengguna, saya ingin setiap entri tanggal menampilkan ringkasan (jumlah item selesai / total item), agar saya bisa menilai hari itu tanpa harus membukanya.
21. Sebagai pengguna, saya ingin mengetuk tanggal untuk melihat detail snapshot item pada hari itu secara read-only, agar saya bisa mereview apa yang dikerjakan.
22. Sebagai pengguna, saya ingin snapshot di History Screen ditampilkan secara rekursif (mirip tampilan checklist), agar struktur item bertingkat tetap terlihat.
23. Sebagai pengguna, saya ingin item `selesai` tampil dengan centang dan item `belum` tampil dengan visual berbeda (misalnya abu-abu), agar status mudah dibaca.
24. Sebagai pengguna, saya ingin History Screen menampilkan nama card sebagai judul, agar saya tahu sedang melihat history card mana.
25. Sebagai pengguna, saya ingin History Screen memiliki tombol back yang konsisten, agar navigasi terasa natural.
26. Sebagai pengguna, saya ingin History Screen menampilkan empty state yang informatif jika belum ada history, agar saya tidak bingung menghadapi layar kosong.

### Menghapus History

27. Sebagai pengguna, saya ingin menghapus semua history dari satu card sekaligus, agar saya bisa membersihkan riwayat yang sudah tidak relevan.
28. Sebagai pengguna, saya ingin menghapus history per bulan tertentu, agar saya bisa membersihkan riwayat lama secara selektif.
29. Sebagai pengguna, saya ingin ada dialog konfirmasi sebelum penghapusan dilakukan, agar tidak ada penghapusan yang tidak disengaja.
30. Sebagai pengguna, saya ingin setelah penghapusan, daftar tanggal di History Screen langsung diperbarui, agar feedback-nya instan dan akurat.

---

## Implementation Decisions

### ID.1 — Lingkup Perubahan Model (`DailySubject`)

`DailySubject` diperluas dengan dua field baru:
- `isDailyTrackerEnabled: bool` — flag aktif/nonaktif mode DailyTracker. Default `false` agar backward compatible.
- `dailyLogs: Map<String, List<DailyLogEntry>>` — riwayat harian. Key berformat `yyyy-MM-dd` (ISO 8601). Value adalah list snapshot item rekursif. Default map kosong `{}`.

Kedua field ini diparse di `fromJson` dengan fallback ke default, sehingga file JSON lama yang tidak punya field ini tetap terbaca tanpa error.

### ID.2 — Model Baru: `DailyLogEntry`

`DailyLogEntry` adalah model snapshot satu item checklist untuk satu hari. Propertinya (dari prototipe domain model):

```
DailyLogEntry {
  itemName: String
  progress: String          // 'belum' | 'sementara' | 'selesai'
  itemType: String          // 'normal' | 'progress' | 'countdown'
  currentValue: int
  targetValue: int
  children: List<DailyLogEntry>   // Rekursif untuk item bertingkat
}
```

Factory constructor `DailyLogEntry.fromSubSubjectItem(SubSubjectItem)` melakukan deep-clone snapshot secara rekursif. `DailyLogEntry` bersifat immutable (selalu dibuat ulang saat snapshot, tidak diubah setelah tersimpan).

### ID.3 — Strategi Penyimpanan

History disimpan di dalam `DailySubject.dailyLogs` yang merupakan bagian dari file JSON `ChecklistGroup` yang sudah ada. Tidak ada file baru yang dibuat. Penyimpanan dilakukan lewat `saveGroupData()` yang sudah ada di `ChecklistDetailController`, termasuk dukungan enkripsi jika `ChecklistGroup.isEncrypted = true`.

### ID.4 — Perilaku Konflik (Simpan Dua Kali Sehari)

Jika `saveTodayLog()` dipanggil lebih dari sekali di hari yang sama, log di-**overwrite** — `dailyLogs[tanggalHariIni]` diganti dengan snapshot terbaru. Tidak ada penggabungan (merge) atau duplikasi.

### ID.5 — Perilaku Setelah Simpan & Reset

Setelah `saveTodayLog()`: UI **tidak berubah** — item tetap menampilkan status saat ini.
Setelah `resetForNewDay()`: seluruh `SubSubjectItem` di-reset ke `progress = 'belum'` dan `currentValue = 0` secara rekursif, lalu `saveGroupData()` dipanggil. `dailyLogs` tidak disentuh.

### ID.6 — Penambahan ke Controller (`ChecklistDetailController`)

Empat method baru ditambahkan ke controller yang ada:
- `saveTodayLog(DailySubject subject)` — membuat snapshot dan menyimpan ke `dailyLogs[today]`.
- `resetForNewDay(DailySubject subject)` — mereset semua item rekursif, dengan dialog konfirmasi.
- `deleteDailyLog(DailySubject subject)` — menghapus seluruh `dailyLogs`.
- `deleteDailyLogsByMonth(DailySubject subject, String yearMonth)` — menghapus semua key yang diawali `yearMonth` (format `yyyy-MM`).

### ID.7 — Penambahan ke UI Card (checklist_dialog.dart)

Ketika `DailySubject.isDailyTrackerEnabled == true`, card menampilkan:
- **Badge DailyTracker** di area header card (ikon kalender kecil atau label teks ringkas).
- **Tombol "Simpan Hari Ini"** — memanggil `saveTodayLog()`.
- **Tombol "Reset Hari Baru"** — memanggil `resetForNewDay()` (dengan konfirmasi dialog).
- **Tombol "Lihat History"** — navigasi ke `DailyTrackerHistoryScreen`.

Jika `isDailyTrackerEnabled == false`, tidak ada elemen tambahan apapun yang tampil (zero visual noise).

### ID.8 — Toggle Aktivasi via Popup Menu

Item menu baru ditambahkan di popup menu card `ChecklistDetailScreen`:
- Jika nonaktif: tampilkan "Aktifkan DailyTracker".
- Jika aktif: tampilkan "Nonaktifkan DailyTracker".

Toggle ini memanggil `setState` untuk membalik `isDailyTrackerEnabled` lalu `saveGroupData()`.

### ID.9 — DailyTracker History Screen (Modul Baru)

Screen baru `DailyTrackerHistoryScreen` dibuat di dalam feature `checklist`, mengikuti pola yang sudah ada. Screen ini menerima `DailySubject` sebagai parameter. Screen bersifat stateful karena daftarnya bisa berubah setelah penghapusan history.

Layout: AppBar dengan nama card sebagai judul + `ListView` tanggal tersimpan (diurutkan descending) + empty state jika `dailyLogs` kosong.

### ID.10 — Format Tanggal

Key `dailyLogs` menggunakan format `yyyy-MM-dd` (ISO 8601). Tanggal diambil dari `DateTime.now()` di sisi client saat `saveTodayLog()` dipanggil. Tidak ada normalisasi timezone — diasumsikan waktu lokal device.

---

## Testing Decisions

### Apa yang Membuat Test Baik

Test yang baik menguji **perilaku yang dapat diobservasi dari luar**, bukan detail implementasi internal. Untuk fitur ini, perilaku yang dapat diobservasi adalah:
- Apakah `dailyLogs` di `DailySubject` terisi dengan benar setelah `saveTodayLog()`?
- Apakah item direset dengan benar setelah `resetForNewDay()`?
- Apakah `fromJson` / `toJson` pada `DailySubject` dan `DailyLogEntry` round-trip dengan benar?
- Apakah `fromJson` pada file JSON lama (tanpa field baru) tidak throw error?
- Apakah `deleteDailyLogsByMonth()` hanya menghapus key bulan yang tepat?

Test **tidak** boleh menguji: nama variabel internal, urutan method call, atau detail implementasi `saveTodayLog()`.

### Modul yang Diuji

| Modul | Jenis Test | Prioritas |
|---|---|---|
| `DailySubject.fromJson` / `toJson` | Unit test — round-trip serialisasi | Tinggi |
| `DailySubject.fromJson` pada JSON lama (tanpa field baru) | Unit test — backward compatibility | Tinggi |
| `DailyLogEntry.fromSubSubjectItem` | Unit test — snapshot rekursif | Tinggi |
| `DailyLogEntry.fromJson` / `toJson` | Unit test — round-trip | Tinggi |
| `saveTodayLog()` — overwrite jika hari sama | Unit/integration test via controller | Tinggi |
| `resetForNewDay()` — semua item kembali ke `belum` | Unit test via controller | Tinggi |
| `deleteDailyLogsByMonth()` — hanya hapus key bulan yang sesuai | Unit test | Sedang |
| `DailyTrackerHistoryScreen` — daftar tanggal tampil dengan benar | Widget test | Sedang |
| `DailyTrackerHistoryScreen` — empty state jika `dailyLogs` kosong | Widget test | Sedang |

### Prior Art

- **Unit test model**: lihat `test/features/task_master/data/task_model_test.dart` dan `test/features/task_master_new/data/task_master_mapper_test.dart` untuk pola pengujian serialisasi model.
- **Unit test controller**: lihat `test/features/jurnal_aktivitas/presentation/controllers/` untuk pola pengujian perilaku controller.
- **Widget test**: lihat `test/features/ad_banner_showcase/presentation/screens/ad_banner_showcase_screen_test.dart` untuk pola pengujian widget screen dengan mock data.

---

## Out of Scope

- **Notifikasi / reminder** untuk mengisi checklist harian — fitur ini murni opt-in manual.
- **Statistik agregat** lintas card (misalnya: "minggu ini berapa card yang 100% selesai").
- **Otomatisasi reset** — reset hanya dilakukan atas permintaan eksplisit pengguna.
- **Visualisasi kalender** (heatmap) untuk history — ditampilkan sebagai daftar list saja.
- **Sinkronisasi cloud atau multi-device** — data tetap lokal.
- **Batas maksimum history** secara teknis — pengguna mengelola ukuran sendiri via fitur hapus.
- **Perubahan pada card yang tidak mengaktifkan DailyTracker** — zero side effect.
- **Modifikasi data history** — History Screen bersifat read-only sepenuhnya.

---

## Further Notes

- **Naming convention:** Ikuti pola yang ada di proyek — `daily_tracker_history_screen.dart`, `daily_tracker_history_controller.dart`. Semua di dalam `lib/features/checklist/`.
- **Urutan tombol di card:** Badge DailyTracker → Tombol "Simpan Hari Ini" → Tombol "Reset Hari Baru" → Tombol "Lihat History". Tombol "Reset" sebaiknya secara visual lebih subtle (secondary style) agar tidak mudah ditekan tidak sengaja.
- **Enkripsi:** Karena `dailyLogs` tersimpan di dalam `DailySubject.toJson()` yang merupakan bagian dari `ChecklistGroup.toJson()`, dan mekanisme enkripsi sudah dihandle di level `saveGroupData()`, tidak ada perubahan khusus pada layer enkripsi.
- **Ukuran file JSON:** Setiap entri harian menyimpan seluruh tree item. Untuk checklist dengan 50 item dan 365 hari history, estimasi kasar ~1–2 MB per card. Fitur hapus per bulan adalah mitigasi utamanya.
- **Tidak ada issue tracker eksternal:** Proyek menggunakan dokumentasi lokal di `docs/`. SPEC ini sendiri adalah artefak tracking-nya.
