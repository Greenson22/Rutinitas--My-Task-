# 06: DailyTracker History Screen

**What to build:** Screen baru `DailyTrackerHistoryScreen` yang menampilkan riwayat harian dari `DailySubject.dailyLogs`. Screen ini dapat diakses dari tombol "Lihat History" di card (tiket 05). Daftar tanggal ditampilkan dari terbaru ke terlama; setiap entri menampilkan tanggal dan ringkasan (jumlah item selesai / total item). Mengetuk tanggal membuka detail snapshot secara read-only yang menampilkan item secara rekursif. History dapat dihapus seluruhnya atau per bulan — keduanya memerlukan dialog konfirmasi dan langsung memperbarui daftar setelah penghapusan. Jika `dailyLogs` kosong, tampil empty state yang informatif.

**Blocked by:** 03, 05

**Status:** done

- [x] `DailyTrackerHistoryScreen` dapat diakses dan menampilkan AppBar dengan nama card sebagai judul.
- [x] Daftar tanggal dari `dailyLogs.keys` ditampilkan diurutkan dari terbaru ke terlama.
- [x] Setiap entri tanggal menampilkan: tanggal yang diformat dan ringkasan (jumlah item `selesai` / total item dari snapshot).
- [x] Mengetuk tanggal menampilkan detail snapshot read-only yang merender `DailyLogEntry` secara rekursif.
- [x] Di detail snapshot, item dengan `progress == 'selesai'` ditampilkan dengan ikon centang; item `belum` tampil dengan visual berbeda (misalnya abu-abu).
- [x] Detail snapshot bersifat sepenuhnya read-only — tidak ada interaksi yang bisa mengubah data.
- [x] Ketika `dailyLogs` kosong, tampil empty state dengan pesan informatif (misalnya: "Belum ada data tersimpan. Gunakan tombol 'Simpan Hari Ini' untuk mulai melacak.").
- [x] Tersedia opsi "Hapus semua history card ini" dengan dialog konfirmasi; setelah dikonfirmasi, `deleteDailyLog()` dipanggil dan daftar langsung kosong / menampilkan empty state.
- [x] Tersedia opsi "Hapus per bulan" yang menampilkan pilihan bulan dari key yang ada; setelah dipilih dan dikonfirmasi, `deleteDailyLogsByMonth()` dipanggil dan entri bulan tersebut hilang dari daftar.
- [x] Widget test: daftar tanggal tampil sesuai data `dailyLogs` yang diberikan, diurutkan descending.
- [x] Widget test: empty state tampil ketika `dailyLogs` kosong.
- [x] Widget test: setelah aksi "Hapus semua history", daftar menjadi kosong dan empty state tampil.
- [x] Widget test: setelah aksi "Hapus per bulan" untuk bulan tertentu, hanya entri bulan tersebut yang hilang; bulan lain tetap ada.

---

## Catatan implementasi

**Tanggal & Waktu Selesai:** 24 November 2026, 08:33:00+08:00

### Ringkasan Pekerjaan
Fitur DailyTracker History Screen telah selesai diimplementasikan secara komprehensif:
1. **Screen `DailyTrackerHistoryScreen`**:
   - Dibuat di `lib/features/checklist/presentation/daily_tracker_history_screen/daily_tracker_history_screen.dart`.
   - **AppBar:** Menampilkan nama card (`widget.subject.subjectName`) sebagai judul dan popup menu pengelolaan riwayat jika riwayat tidak kosong.
   - **Empty State:** Menggunakan tampilan informatif ketika `dailyLogs` kosong dengan pesan petunjuk: *"Belum ada data tersimpan. Gunakan tombol 'Simpan Hari Ini' untuk mulai melacak."* (`Key('daily_tracker_history_empty')`).
   - **Daftar Tanggal:** Menampilkan `dailyLogs.keys` terurut descending (terbaru ke terlama) dengan format tanggal Indonesia (`d MMMM yyyy`) dan ringkasan selesai (`finished / total Selesai`).
   - **Detail Snapshot Rekursif:** Mengetuk tile tanggal membuka bottom sheet read-only yang merender struktur hierarki `DailyLogEntry` secara rekursif, menampilkan ikon centang untuk item selesai, ikon lingkaran untuk item belum, ikon jam pasir untuk status sementara, serta indikator nilai target `(currentValue/targetValue)` untuk item berjenis progress/countdown.
   - **Hapus Semua History:** Opsi pada popup menu dengan dialog konfirmasi ("Hapus Semua Riwayat?"), memanggil `deleteDailyLog(subject)` dan mengosongkan riwayat secara instan.
   - **Hapus per Bulan:** Opsi pada popup menu yang mengekstrak daftar bulan unik (format `yyyy-MM`), memformat label nama bulan Indonesia ramah pengguna, menyajikan dialog pilihan bulan, dan memanggil `deleteDailyLogsByMonth(subject, month)` setelah konfirmasi pengguna.

2. **Integrasi Screen di `ChecklistDetailScreen`**:
   - Menghubungkan navigasi tombol "Lihat History" pada card ke `DailyTrackerHistoryScreen` dengan menyuntikkan callback penghapusan (`onDeleteAll: () => deleteDailyLog(subject)` dan `onDeleteByMonth: (m) => deleteDailyLogsByMonth(subject, m)`) serta melakukan refresh UI saat kembali (`then`).

3. **Pengujian & Review**:
   - Widget test komprehensif ditambahkan di `test/features/checklist/presentation/daily_tracker_history_screen_test.dart` (6/6 test lulus).
   - Seluruh test modul checklist (29/29 test) dan seluruh test suite proyek (364/364 test) lulus 100% tanpa error maupun regresi.
   - Dilakukan evaluasi melalui sub-agent Standards & Spec review.
