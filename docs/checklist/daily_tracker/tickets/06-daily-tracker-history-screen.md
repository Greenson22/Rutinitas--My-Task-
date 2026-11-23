# 06: DailyTracker History Screen

**What to build:** Screen baru `DailyTrackerHistoryScreen` yang menampilkan riwayat harian dari `DailySubject.dailyLogs`. Screen ini dapat diakses dari tombol "Lihat History" di card (tiket 05). Daftar tanggal ditampilkan dari terbaru ke terlama; setiap entri menampilkan tanggal dan ringkasan (jumlah item selesai / total item). Mengetuk tanggal membuka detail snapshot secara read-only yang menampilkan item secara rekursif. History dapat dihapus seluruhnya atau per bulan — keduanya memerlukan dialog konfirmasi dan langsung memperbarui daftar setelah penghapusan. Jika `dailyLogs` kosong, tampil empty state yang informatif.

**Blocked by:** 03, 05

**Status:** ready-for-agent

- [ ] `DailyTrackerHistoryScreen` dapat diakses dan menampilkan AppBar dengan nama card sebagai judul.
- [ ] Daftar tanggal dari `dailyLogs.keys` ditampilkan diurutkan dari terbaru ke terlama.
- [ ] Setiap entri tanggal menampilkan: tanggal yang diformat dan ringkasan (jumlah item `selesai` / total item dari snapshot).
- [ ] Mengetuk tanggal menampilkan detail snapshot read-only yang merender `DailyLogEntry` secara rekursif.
- [ ] Di detail snapshot, item dengan `progress == 'selesai'` ditampilkan dengan ikon centang; item `belum` tampil dengan visual berbeda (misalnya abu-abu).
- [ ] Detail snapshot bersifat sepenuhnya read-only — tidak ada interaksi yang bisa mengubah data.
- [ ] Ketika `dailyLogs` kosong, tampil empty state dengan pesan informatif (misalnya: "Belum ada data tersimpan. Gunakan tombol 'Simpan Hari Ini' untuk mulai melacak.").
- [ ] Tersedia opsi "Hapus semua history card ini" dengan dialog konfirmasi; setelah dikonfirmasi, `deleteDailyLog()` dipanggil dan daftar langsung kosong / menampilkan empty state.
- [ ] Tersedia opsi "Hapus per bulan" yang menampilkan pilihan bulan dari key yang ada; setelah dipilih dan dikonfirmasi, `deleteDailyLogsByMonth()` dipanggil dan entri bulan tersebut hilang dari daftar.
- [ ] Widget test: daftar tanggal tampil sesuai data `dailyLogs` yang diberikan, diurutkan descending.
- [ ] Widget test: empty state tampil ketika `dailyLogs` kosong.
- [ ] Widget test: setelah aksi "Hapus semua history", daftar menjadi kosong dan empty state tampil.
- [ ] Widget test: setelah aksi "Hapus per bulan" untuk bulan tertentu, hanya entri bulan tersebut yang hilang; bulan lain tetap ada.
