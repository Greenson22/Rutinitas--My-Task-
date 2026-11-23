# SPEC — Perbaikan Bug Increment Jurnal Aktivitas Saat Berganti Bulan

| Field           | Value                                                     |
|-----------------|-----------------------------------------------------------|
| Fitur           | `jurnal_aktivitas`                                        |
| Sumber          | `docs/problems/jurnal-aktivitas-month-boundary-increment-bug/PDR.md` |
| Status          | Ready for agent                                           |
| Tanggal         | 23 November 2026                                          |
| Platform utama  | Android dan Linux desktop                                 |

---

## Problem Statement

Ketika tanggal berganti ke bulan baru, pengguna Jurnal Aktivitas mengalami dua gejala: tampilan data tampak error/tidak konsisten, dan tombol "+ Waktu" (increment 30 menit) tidak berfungsi. Penyebabnya adalah `currentActiveMonth` di dalam `JurnalAktivitasController` tidak diperbarui saat `loadData` dipanggil di bulan baru — sehingga controller masih membaca dan menulis ke file jurnal bulan lama. Akibatnya, entri hari ini di bulan baru tidak pernah terbentuk di memori, dan increment ditulis ke entri bulan yang salah.

---

## Solution

Pastikan `currentActiveMonth` selalu disegarkan ke waktu saat ini sebelum `loadData` membaca atau membuat file. Selain itu, perkuat `addActivityDuration` agar selalu menjamin entri hari ini ada di `logs` sebelum menambahkan durasi — menghilangkan fallback yang keliru menulis ke entri bulan lama.

---

## User Stories

1. Sebagai pengguna, saya ingin Jurnal Aktivitas membaca file bulan yang benar saat hari pertama bulan baru, agar data tidak tercampur antar bulan.
2. Sebagai pengguna, saya ingin entri hari ini otomatis dibuat di bulan baru ketika belum ada riwayat, agar saya langsung bisa mencatat aktivitas tanpa error.
3. Sebagai pengguna, saya ingin tombol "+ Waktu" tetap berfungsi di hari pertama bulan baru, agar saya tidak perlu mengedit JSON secara manual.
4. Sebagai pengguna, saya ingin durasi yang saya tambahkan tersimpan di file bulan yang tepat, agar riwayat bulanan tidak terkontaminasi data bulan lain.
5. Sebagai pengguna, saya ingin durasi yang saya tambahkan di hari pertama bulan baru tercermin segera di UI, agar saya mendapat umpan balik yang benar setelah menekan tombol.
6. Sebagai pengguna, saya ingin riwayat bulan sebelumnya tidak diubah saat saya menambah waktu di bulan baru, agar integritas data historis terjaga.
7. Sebagai pengguna, saya ingin Jurnal tetap berfungsi normal di hari-hari pertengahan bulan, agar perbaikan ini tidak memperkenalkan regresi.
8. Sebagai pengguna, saya ingin `jurnal_template.json` tetap bisa dibaca di bulan baru, agar daftar tugas default tidak hilang saat berganti bulan.
9. Sebagai pengguna, saya ingin Jurnal tetap bisa menampilkan statistik lintas bulan dengan benar, agar analitik tidak terpengaruh oleh perbaikan ini.
10. Sebagai pengguna, saya ingin file bulan baru dibuat secara otomatis jika belum ada, agar tidak perlu intervensi manual.
11. Sebagai pengguna, saya ingin rollback Jurnal (undo increment) tetap menunjuk file bulan yang benar, agar undo tidak memengaruhi data bulan lain.
12. Sebagai pengguna dengan enkripsi aktif, saya ingin file bulan baru dibuat dan ditulis dengan enkripsi yang sama, agar keamanan data tidak berkurang.

---

## Implementation Decisions

### 1. Penyegaran `currentActiveMonth` di `loadData`

`currentActiveMonth` wajib diperbarui ke `DateTime.now()` sebagai langkah pertama dalam `loadData`, sebelum `getJurnalFile()` dipanggil. Ini memastikan controller selalu menarget file bulan yang benar, terlepas dari kapan controller diinisialisasi atau kapan terakhir kali `loadData` dipanggil.

```dart
// Keputusan dari PDR — bukan implementasi lengkap
Future<void> loadData({required VoidCallback onNotify}) async {
  currentActiveMonth = DateTime.now(); // ← tambahkan sebelum getJurnalFile()
  ...
}
```

### 2. Penjaminan Entri Hari Ini di `addActivityDuration`

Blok fallback yang menulis ke entri bulan lama harus dihilangkan. Sebagai gantinya, jika `todayIdx == -1`, entri baru untuk hari ini dibuat langsung dengan task yang diminta, menggunakan template yang sudah dimuat. Ini konsisten dengan logika yang sudah ada di `loadData` ketika hari belum punya riwayat.

Prioritas pencarian entri hari ini:
1. Cari di `logs` berdasarkan `tanggal == getTodayDateString()`.
2. Jika tidak ditemukan, buat entri baru dengan task template (durasi 0) lalu tambahkan durasi ke task yang diminta.
3. Jangan pernah menulis ke entri dengan tanggal selain hari ini.

### 3. Tidak Ada Perubahan pada Skema File atau Format JSON

Perbaikan ini murni di layer controller (logika runtime). Skema file `jurnal_YYYY_MM.json` dan `jurnal_template.json` tidak berubah.

### 4. `saveData` Tidak Berubah Secara Struktural

`saveData` sudah memanggil `getJurnalFile()` yang bergantung pada `currentActiveMonth`. Setelah keputusan nomor 1 diterapkan, `saveData` otomatis menulis ke file bulan yang benar tanpa perubahan tambahan.

### 5. `FileJournalGateway` (Task Master New) — Tidak Terpengaruh

`FileJournalGateway` sudah menggunakan `_clock()` yang diinjeksi dan memanggil `_monthFile(at)` per operasi — tidak menyimpan cache bulan aktif. Bug ini tidak ada di gateway tersebut; gateway hanya perlu diuji terhadap skenario lintas bulan untuk konfirmasi.

### 6. Cakupan Perbaikan

Hanya `JurnalAktivitasController` yang dimodifikasi. Tidak ada perubahan pada:
- `StorageService`
- `TimeLogEntry` / `TimeLogTask`
- `FileJournalGateway`
- Widget dan layar Jurnal
- Format atau path file JSON

---

## Testing Decisions

### Prinsip Pengujian

Test yang baik menguji perilaku eksternal melalui antarmuka publik controller, bukan detail implementasi internal. Waktu harus dapat diinjeksi atau di-mock agar skenario berganti bulan dapat direproduksi secara deterministik.

### Seam Pengujian

Seam yang digunakan adalah **`JurnalAktivitasController`** itu sendiri — khususnya metode `loadData` dan `addActivityDuration`. Karena controller bergantung pada `StorageService` dan file system, test perlu menggunakan direktori sementara atau mock `StorageService`.

Prior art: `TaskRepository` di `task_master_new` sudah menetapkan pola injeksi clock dan penggunaan direktori sementara yang dapat dijadikan referensi.

### Skenario Test Wajib

| # | Skenario | Ekspektasi |
|---|----------|------------|
| 1 | `loadData` dipanggil di hari pertama bulan baru (file bulan baru belum ada) | `currentActiveMonth` diperbarui; file bulan baru dibuat; entri hari ini terbentuk di `logs` |
| 2 | `addActivityDuration` dipanggil di hari pertama bulan baru (tanpa entri today di `logs`) | Durasi bertambah di entri hari ini yang baru dibuat; tidak ada entri bulan lama yang dimodifikasi |
| 3 | `saveData` dipanggil setelah skenario 2 | Data tersimpan di file bulan baru; file bulan lama tidak berubah |
| 4 | `loadData` dipanggil di pertengahan bulan (skenario normal) | Tidak ada regresi; perilaku sama seperti sebelum perbaikan |
| 5 | `addActivityDuration` dipanggil di pertengahan bulan dengan entri today sudah ada | Durasi bertambah di entri yang ada; fallback tidak diperlukan |
| 6 | `loadData` dipanggil dua kali berturut-turut di bulan yang sama | `currentActiveMonth` konsisten; tidak ada duplikasi entri |
| 7 | Enkripsi aktif; `loadData` dipanggil di bulan baru | File baru dibuat dan terenkripsi dengan benar |

### Jenis Test

- **Unit test** untuk `JurnalAktivitasController.loadData` dan `addActivityDuration` dengan mock `StorageService` dan direktori sementara.
- **Manual QA** di perangkat Android: tunggu atau simulasikan pergantian bulan, verifikasi tombol "+ Waktu" bekerja dan data tersimpan di file bulan yang benar.

---

## Out of Scope

- Perubahan pada format skema file jurnal (JSON).
- Perbaikan pada `FileJournalGateway` (tidak ada bug di sana).
- Navigasi atau UI untuk berpindah antar bulan di tampilan jurnal.
- Migrasi atau penggabungan data yang sudah terlanjur tersimpan di file bulan yang salah (data historis yang terkontaminasi dibiarkan sebagai tanggung jawab pengguna atau fitur recovery terpisah).
- Perubahan pada `StorageService`, `TimeLogEntry`, atau `TimeLogTask`.
- Dark mode atau perubahan visual.

---

## Further Notes

### Konfirmasi Seam

Sebelum implementasi, konfirmasikan bahwa satu seam `JurnalAktivitasController` sudah cukup — tidak perlu abstraksi tambahan untuk perbaikan ini.

### Risiko Regresi

Perbaikan `currentActiveMonth = DateTime.now()` di awal `loadData` berdampak pada semua pemanggilan `getJurnalFile()` setelahnya. Pastikan tidak ada tempat lain di controller atau screen yang mengandalkan nilai `currentActiveMonth` yang di-cache dari bulan sebelumnya untuk tujuan navigasi atau filter historis.

### Catatan Rollout

Perbaikan ini bersifat minimal dan terisolasi — tidak memerlukan migrasi data atau flag feature. Dapat di-deploy langsung tanpa rollout bertahap.
