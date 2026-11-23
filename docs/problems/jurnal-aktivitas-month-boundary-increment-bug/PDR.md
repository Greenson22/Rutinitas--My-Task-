# PDR — Jurnal Aktivitas: Increment Waktu Gagal Saat Berganti Bulan

| Field           | Value                                               |
|-----------------|-----------------------------------------------------|
| Fitur           | `jurnal_aktivitas`                                  |
| Kategori        | Bug — Data Corruption / Wrong File Target           |
| Status          | Identified — Ready for Spec                         |
| Tanggal         | 23 November 2026                                    |
| Platform        | Android, Linux Desktop                              |
| Ditemukan oleh  | Pengguna (manual edit JSON sebagai workaround)      |

---

## Deskripsi Masalah

Ketika tanggal berganti ke bulan baru, Jurnal Aktivitas mengalami dua gejala secara bersamaan:

1. **Data tampak error / rusak** — entri hari-hari terakhir menjadi tidak tampil atau berperilaku aneh.
2. **Tombol "+ Waktu" tidak bekerja** — menekan tombol increment 30 menit tidak menghasilkan perubahan yang tersimpan ke file yang benar.

Pengguna harus mengedit file JSON secara manual untuk memulihkan kondisi ini, setelah itu tombol kembali bekerja.

---

## Analisis Root Cause

### Arsitektur Partisi File Bulanan

Jurnal Aktivitas menyimpan log dalam file terpisah per bulan:
```
jurnal_aktivitas/
  jurnal_2026_10.json   ← file Oktober
  jurnal_2026_11.json   ← file November
  jurnal_template.json  ← kerangka tugas & pengaturan default
```

`JurnalAktivitasController` menyimpan referensi bulan aktif di field:

```dart
DateTime currentActiveMonth = DateTime.now(); // diinisialisasi sekali saat objek dibuat
```

### Alur Bug Saat Berganti Bulan

Ketika aplikasi dibuka di hari pertama bulan baru (misalnya 1 November setelah sebelumnya aktif di Oktober):

| Langkah | Perilaku Aktual (Buggy)                                     |
|---------|-------------------------------------------------------------|
| 1       | `currentActiveMonth` = tanggal inisialisasi (misalnya **1 Oktober** jika controller dibuat di Oktober) |
| 2       | `loadData()` dipanggil, `getJurnalFile()` membaca `jurnal_2026_10.json` (Oktober) |
| 3       | `getTodayDateString()` mengembalikan `"2026-11-01"` (hari ini = November) |
| 4       | Loop merge mencari `tanggal == "2026-11-01"` di `logs` → **tidak ditemukan** (`todayIdx == -1`) |
| 5       | Entri hari ini **tidak dibuat** dalam `logs` di memori (karena cek bulan di baris 148–149 gagal) |
| 6       | UI menampilkan tampilan yang tidak konsisten / "error" |
| 7       | Pengguna menekan tombol **+ Waktu** → `addActivityDuration` dipanggil |
| 8       | `todayIdx == -1` karena tidak ada entri November di `logs` |
| 9       | Fallback: loop `logs.reversed` menemukan task dengan ID yang sama di entri **bulan Oktober** |
| 10      | Durasi ditambahkan ke entri lama (Oktober) lalu disimpan ke `jurnal_2026_10.json` |
| 11      | Perubahan tidak terlihat di UI hari ini → **tombol seolah tidak bekerja** |

### Baris Kode Kritis

**`loadData()` — baris 147–149:** Cek yang harusnya membuat entri hari ini hanya berjalan jika bulan aktif sama dengan bulan sekarang. Karena `currentActiveMonth` tidak diperbarui, cek ini **selalu gagal** saat berganti bulan.

```dart
// jurnal_aktivitas_controller.dart
final DateTime now = DateTime.now();
if (currentActiveMonth.year == now.year &&
    currentActiveMonth.month == now.month) {
  // ← Blok ini tidak dieksekusi karena currentActiveMonth masih bulan lama
  // → Entri hari ini di bulan baru tidak pernah dibuat di memori
}
```

**`addActivityDuration()` — baris 545–561:** Fallback yang keliru.

```dart
void addActivityDuration(TimeLogTask task, int minutes) {
  final String todayStr = getTodayDateString();  // "2026-11-01"
  int todayIdx = logs.indexWhere((entry) => entry.tanggal == todayStr);
  if (todayIdx != -1) {
    // ← Tidak masuk ke sini karena tidak ada entri November di logs
    ...
    return;
  }
  // Fallback: tulis ke entri bulan lama yang tidak relevan!
  for (var logEntry in logs.reversed) {
    int idx = logEntry.tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      logEntry.tasks[idx].durasiMenit += minutes; // ← Oktober yang dimodifikasi
      break;
    }
  }
}
```

**`saveData()` — baris 219:** File tujuan penulisan adalah `getJurnalFile()` yang masih menunjuk file bulan lama.

```dart
final File jsonFile = await getJurnalFile(); // ← jurnal_2026_10.json, bukan _11!
```

---

## Dampak

| Aspek               | Dampak                                                            |
|---------------------|-------------------------------------------------------------------|
| Data integrity      | Durasi increment tersimpan di file bulan yang salah               |
| UX                  | Tombol "+ Waktu" tampak tidak berfungsi                           |
| Keterbacaan data    | Entri bulan lama dapat terkontaminasi data bulan baru             |
| Recovery            | Perlu edit JSON manual untuk memperbaiki kondisi                  |
| Frekuensi           | Terjadi setiap pergantian bulan (12× per tahun)                   |

---

## Workaround yang Sudah Dilakukan Pengguna

Pengguna mengedit file JSON secara manual untuk memastikan file bulan yang benar sudah ada dan strukturnya valid, setelah itu tombol kembali bekerja. Ini mengonfirmasi bahwa masalah bukan di data itu sendiri, melainkan pada penunjukan file dan entri target yang salah di dalam `JurnalAktivitasController`.

---

## Solusi yang Diusulkan

`currentActiveMonth` harus selalu mencerminkan bulan kalender saat ini (`DateTime.now()`) setiap kali `loadData` dipanggil — bukan nilai yang di-cache sejak inisialisasi controller. Selain itu, `addActivityDuration` harus memastikan entri hari ini selalu ada di `logs` sebelum mencoba menambahkan durasi, daripada jatuh ke fallback yang menulis ke entri lama.

Lihat [SPEC.md](./SPEC.md) untuk rincian implementasi.

---

## Referensi

- [`lib/features/jurnal_aktivitas/presentation/controllers/jurnal_aktivitas_controller.dart`](../../lib/features/jurnal_aktivitas/presentation/controllers/jurnal_aktivitas_controller.dart)
- [`lib/features/task_master_new/data/gateways/file_journal_gateway.dart`](../../lib/features/task_master_new/data/gateways/file_journal_gateway.dart)
- [`lib/features/jurnal_aktivitas/data/models/time_log_model.dart`](../../lib/features/jurnal_aktivitas/data/models/time_log_model.dart)
