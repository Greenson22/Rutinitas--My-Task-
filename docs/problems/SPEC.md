# SPEC — Tiga Perbaikan UX: Aksi Seksi, Legenda Warna, Edit Hitungan Tugas

> **Versi:** 1.0  
> **Tanggal:** 2026-11-25  
> **Referensi PRD:** `docs/problems/PRD.md`

---

## Problem Statement

Pengguna menghadapi tiga masalah UX yang berbeda di aplikasi rutinitasku:

1. **Klutter tombol aksi seksi (Checklist):** Di layar detail checklist, setiap header seksi selalu menampilkan baris tombol aksi (Sembunyikan, Pindah Atas, Pindah Bawah, Ubah Nama, Hapus, Tambah Materi) di samping nama seksi. Ketika nama seksi panjang, layout rusak karena tombol-tombol ini bersaing memperebutkan ruang horizontal dengan teks. Selain itu, tombol yang selalu tampil membuat tampilan terasa penuh padahal aksi tersebut jarang dipakai.

2. **Legenda warna bar chart history (Checklist History):** Bar chart di layar riwayat harian menampilkan batang warna yang diwarnai secara stacked per item checklist yang selesai. Warna dihasilkan deterministik dari nama item. Namun tidak ada legenda — pengguna tidak dapat mengetahui warna mewakili item apa.

3. **Tidak bisa mengedit nilai hitungan tugas (Task Master New):** Di layar detail kategori, ketika pengguna membuka dialog "Ubah Tugas" (via menu ⋮ → Ubah), tidak ada field untuk mengoreksi nilai hitungan harian tugas yang sudah tercatat. Jika terjadi kesalahan input (misalnya tercatat 320, harusnya 20), pengguna tidak bisa memperbaikinya tanpa melakukan increment/decrement berkali-kali.

---

## Solution

1. **Tombol aksi seksi via long press + posisi di bawah nama:** Sembunyikan tombol aksi seksi by default. Ketika pengguna long press header seksi, tombol aksi muncul di bawah nama seksi (bukan di sampingnya) dalam layout `Wrap`. Long press lagi menyembunyikannya. State ini bersifat UI-only dan tidak mempengaruhi model data.

2. **Legenda warna di bawah bar chart:** Tambahkan widget legenda di bawah `HistoryBarChart` yang menampilkan daftar nama item beserta kotak warna yang sesuai. Legenda mengikuti filter tanggal yang aktif, hanya menampilkan item yang tercatat selesai pada rentang tersebut.

3. **Field edit hitungan harian di dialog ubah tugas:** Tambahkan field "Hitungan Hari Ini" ke `TaskFormDialog` saat mode edit. Field ini memungkinkan pengguna mengoreksi nilai `count` untuk hari ini secara langsung. Perubahan otomatis menyesuaikan `totalCount` via delta.

---

## User Stories

### Fitur 1 — Tombol Aksi Seksi via Long Press

1. Sebagai pengguna checklist, saya ingin header seksi tampil bersih tanpa tombol aksi by default, sehingga nama seksi yang panjang dapat terbaca penuh.
2. Sebagai pengguna checklist, saya ingin melakukan long press pada header seksi untuk memunculkan tombol aksi, sehingga saya bisa mengelola seksi tanpa header yang penuh tombol setiap saat.
3. Sebagai pengguna checklist, saya ingin tombol aksi muncul di bawah nama seksi (bukan di sampingnya), sehingga layout tidak rusak saat nama panjang.
4. Sebagai pengguna checklist, saya ingin melakukan long press lagi pada header yang sama untuk menyembunyikan tombol aksi, sehingga tampilan kembali bersih.
5. Sebagai pengguna checklist, saya ingin tombol Sembunyikan tersedia saat tombol aksi tampil, sehingga saya bisa mengarsip seksi yang tidak aktif.
6. Sebagai pengguna checklist, saya ingin tombol Pindah Atas dan Pindah Bawah tersedia saat tombol aksi tampil, sehingga saya bisa mengatur urutan seksi.
7. Sebagai pengguna checklist, saya ingin tombol Ubah Nama tersedia saat tombol aksi tampil, sehingga saya bisa mengganti nama seksi bila perlu.
8. Sebagai pengguna checklist, saya ingin tombol Hapus Seksi tersedia saat tombol aksi tampil, sehingga saya bisa menghapus seksi yang tidak diperlukan (dengan konfirmasi).
9. Sebagai pengguna checklist, saya ingin tombol Tambah Materi tersedia saat tombol aksi tampil, sehingga saya bisa menambah DailySubject baru ke seksi dari satu tempat.
10. Sebagai pengguna checklist, saya ingin transisi tombol aksi muncul/sembunyi menggunakan animasi halus, sehingga perubahan tidak terasa abrupt.
11. Sebagai pengguna checklist dengan banyak seksi, saya ingin hanya seksi yang di-long press yang menampilkan tombol aksi, sehingga seksi lain tetap bersih.
12. Sebagai pengguna checklist, saya ingin state "tombol aksi tampil" tidak tersimpan ke file JSON, sehingga saat saya buka kembali layar semua header tampil bersih.

### Fitur 2 — Legenda Warna History Bar Chart

13. Sebagai pengguna yang melihat riwayat harian checklist, saya ingin melihat legenda warna di bawah bar chart, sehingga saya tahu item mana yang diwakili warna tertentu.
14. Sebagai pengguna, saya ingin setiap baris legenda menampilkan kotak warna kecil dan nama item, sehingga asosiasi warna-nama mudah dipahami.
15. Sebagai pengguna, saya ingin warna di legenda konsisten dengan warna di bar chart (dari fungsi `colorFromItemName`), sehingga tidak ada ambiguitas.
16. Sebagai pengguna, saya ingin legenda berubah secara otomatis saat saya mengubah filter tanggal (7 Hari, Bulan Ini, Custom Range, dll.), sehingga hanya item relevan yang tampil.
17. Sebagai pengguna, saya ingin legenda hanya menampilkan item yang pernah selesai (`progress == 'selesai'`) pada rentang waktu yang difilter, sehingga legenda tetap singkat dan bermakna.
18. Sebagai pengguna dengan banyak item checklist, saya ingin legenda bisa di-scroll bila item terlalu banyak untuk ditampilkan sekaligus, sehingga ruang layar tidak habis.
19. Sebagai pengguna, saya ingin ada judul section "Keterangan Warna" di atas legenda, sehingga jelas fungsi area tersebut.
20. Sebagai pengguna pada filter tanpa data, saya ingin legenda tidak tampil (atau tampil pesan kosong), sehingga tidak ada area kosong yang membingungkan.

### Fitur 3 — Edit Hitungan Harian di Dialog Ubah Tugas

21. Sebagai pengguna Task Master New, saya ingin melihat field "Hitungan Hari Ini" ketika membuka dialog Ubah Tugas, sehingga saya tahu nilai yang saat ini tercatat.
22. Sebagai pengguna, saya ingin bisa mengubah hitungan hari ini dari 320 menjadi 20 melalui dialog Ubah Tugas, sehingga data saya akurat tanpa harus increment/decrement ratusan kali.
23. Sebagai pengguna, saya ingin bisa mengubah hitungan hari ini menjadi 0, sehingga saya bisa mereset pencatatan yang salah.
24. Sebagai pengguna, saya ingin perubahan hitungan harian otomatis menyesuaikan `totalCount` tugas, sehingga data keseluruhan tetap konsisten.
25. Sebagai pengguna, saya ingin field hitungan hanya muncul saat mode edit (bukan mode tambah baru), karena saat tambah baru belum ada hitungan untuk diubah.
26. Sebagai pengguna, saya ingin validasi mencegah saya memasukkan nilai negatif atau bukan angka di field hitungan, sehingga data tetap valid.
27. Sebagai pengguna, saya ingin jika hitungan hari ini tidak diubah (nilai sama), tidak ada operasi simpan tambahan yang dipicu, sehingga performa tetap optimal.
28. Sebagai pengguna, saya ingin field "Target Harian", "Target Total", dan semua field yang sudah ada tetap bisa diedit bersamaan dengan hitungan, sehingga saya bisa mengubah semuanya dalam satu dialog.

---

## Implementation Decisions

### Fitur 1 — Tombol Aksi Seksi

- **State UI-only:** State "seksi mana saja yang tombol aksinya sedang tampil" dikelola sebagai `Set<int>` indeks seksi di dalam `State` layar `ChecklistDetailScreen`. Tidak ada field baru di `ChecklistSection` atau `ChecklistGroup`.

- **Trigger long press:** Widget header seksi dibungkus dengan `GestureDetector` (atau `InkWell` yang sudah ada diperluas) dengan handler `onLongPress` yang melakukan toggle pada set indeks tersebut.

- **Layout tombol:** Tombol-tombol aksi diletakkan dalam `Wrap` dengan spacing kecil, dirender **di bawah** baris nama seksi. Urutan tombol: Tambah Materi · Ubah Nama · Pindah Atas · Pindah Bawah · Sembunyikan · Hapus.

- **Animasi:** Gunakan `AnimatedSize` atau `AnimatedCrossFade` untuk transisi muncul/sembunyi. Durasi ~200ms dengan curve `easeInOut`.

- **Tombol Pindah Atas/Bawah:** Dinonaktifkan (disabled) secara visual bila seksi sudah di posisi paling atas/paling bawah.

- **Tombol Hapus:** Memerlukan dialog konfirmasi sebelum eksekusi, mengikuti pola yang sudah ada di controller.

- **Tidak mengubah logika tombol aksi itu sendiri:** Fungsi-fungsi yang dipanggil oleh tombol (sembunyikan, pindah, ubah nama, hapus, tambah) tidak berubah — hanya cara memunculkan tombol yang berubah.

### Fitur 2 — Legenda Warna Bar Chart

- **Lokasi widget:** Widget legenda baru (`HistoryColorLegend`) dirender di dalam `DailyTrackerHistoryScreen`, setelah `HistoryBarChart` dan sebelum list riwayat tanggal.

- **Sumber data legenda:** Iterasi `filteredKeys` → ambil semua `DailyLogEntry` dengan `progress == 'selesai'` → kumpulkan `itemName` unik → urutkan alfabetis. Warna: `colorFromItemName(itemName)`.

- **Widget legenda:** `Wrap` dengan `spacing: 8` dan `runSpacing: 6`. Setiap item adalah `Row(kotak warna 12×12 + teks nama)`. Bila jumlah item banyak (lebih dari ambang batas, misalnya 12 item), bungkus dalam `ConstrainedBox` dengan `maxHeight: 120` agar bisa di-scroll via `SingleChildScrollView`.

- **Judul:** `Text('Keterangan Warna')` dengan `Icon(Icons.palette_outlined)`, dirender di atas area legenda.

- **Tidak ada perubahan ke `HistoryBarChart`:** Widget `HistoryBarChart` tidak diubah — legenda adalah widget terpisah yang dirender di luar chart.

- **Tidak ada perubahan ke `colorFromItemName`:** Fungsi yang ada sudah cukup dan bersifat deterministik.

### Fitur 3 — Edit Hitungan Harian di Dialog Ubah Tugas

- **Field baru di `TaskFormDialog`:** Tambahkan `TextEditingController` untuk hitungan hari ini. Field ini hanya dirender bila `_isEditing == true`. Nilai awal diambil dari `task.countOn(todayKey)`.

- **Parameter `todayKey` ke dialog:** `CategoryDetailScreen` meneruskan `todayKey` (hari ini dalam format `YYYY-MM-DD`) ke `TaskFormDialog` via konstruktor.

- **Perluasan callback `onSave`:** Tambahkan dua parameter opsional ke `onSave`: `int? countToday` dan `String? countDate`. Bila `countToday` tidak null dan berbeda dari nilai lama, controller menjalankan operasi update hitungan.

  ```dart
  // Skema perubahan parameter onSave (dari prototype):
  Future<bool> Function({
    required String name,
    required TaskKind kind,
    required int targetDaily,
    required int targetTotal,
    required bool isActive,
    required TodayVisibility todayVisibility,
    int? countToday,    // null = tidak ada perubahan hitungan
    String? countDate,  // todayKey; null jika countToday null
  })
  ```

- **Operasi update di repository/controller:** Bila `countToday != null && countToday != oldCount`, controller memanggil operasi untuk menyimpan `DailyProgress(date: countDate, count: countToday)` ke `task.history[countDate]` dan mengupdate `task.totalCount` dengan delta: `newTotal = task.totalCount - oldCount + countToday`. Operasi ini harus atomic dengan update metadata tugas lainnya.

- **Validasi field:** Integer ≥ 0. Field tidak boleh kosong. Error ditampilkan inline.

- **Tidak ada perubahan ke domain entity `Task` atau `DailyProgress`:** Struktur data sudah cukup untuk mendukung fitur ini.

- **`FakeTaskRepository` untuk test:** Perlu ditambahkan method `setTaskCount` atau memperluas `updateTask` untuk mendukung update hitungan harian, mengikuti pola `_mutateTasks` yang sudah ada.

---

## Testing Decisions

### Apa yang membuat test bagus

Test yang baik hanya menguji **perilaku yang terlihat dari luar** (output widget, perubahan state model, panggilan ke repository), bukan detail implementasi internal (nama variabel private, class helper internal, urutan pemanggilan method internal). Gunakan `WidgetTester` untuk flow UI end-to-end via widget test, bukan unit test pada widget private.

### Seams Pengujian

Semua fitur ini memiliki satu seam utama yang sudah ada di codebase:

- **Fitur 1:** Seam di `ChecklistDetailScreen` — widget test pump layar penuh dengan `ChecklistGroup` tiruan (pola yang sudah ada di `checklist_section_hide_ticket_03_test.dart`). Test memverifikasi visibilitas tombol sebelum dan sesudah `longPress`.
- **Fitur 2:** Seam di `DailyTrackerHistoryScreen` — widget test pump layar dengan `DailySubject` yang memiliki `dailyLogs` (pola yang ada di `daily_tracker_history_screen_test.dart`). Bisa juga test `HistoryColorLegend` sebagai widget terpisah.
- **Fitur 3:** Seam di `TaskMasterNewScreen` via `FakeTaskRepository` — widget test pump layar penuh (pola yang sudah ada di `task_management_test.dart`). Test membuka dialog ubah, mengubah field hitungan, dan memverifikasi perubahan di `repository.data`.

### Modul yang Diuji

**Fitur 1:**
- `ChecklistDetailScreen` (widget test) — verifikasi bahwa tombol aksi tidak tampil di awal, muncul setelah long press, tersembunyi setelah long press kedua.
- Verifikasi bahwa tombol aksi yang tampil bisa diinteraksi (tap Ubah Nama membuka dialog, tap Hapus membuka konfirmasi, dll.).

**Fitur 2:**
- `DailyTrackerHistoryScreen` (widget test) — verifikasi bahwa legenda muncul di bawah chart dengan item-item yang sesuai filter aktif.
- `HistoryColorLegend` (widget test terpisah, opsional) — verifikasi rendering kotak warna + nama item.
- Verifikasi legenda berubah saat filter diubah.

**Fitur 3:**
- `TaskMasterNewScreen` via `FakeTaskRepository` (widget test) — verifikasi field "Hitungan Hari Ini" muncul di mode edit, tidak muncul di mode tambah baru.
- Verifikasi pengguna dapat mengubah nilai hitungan dan perubahan tersimpan ke repository dengan delta `totalCount` yang benar.
- Verifikasi validasi menolak nilai negatif atau non-angka.

### Prior Art untuk Test

- **Widget test Checklist:** `test/features/checklist/presentation/checklist_section_hide_ticket_03_test.dart` — pola pump `ChecklistDetailScreen` dengan `ChecklistGroup` in-memory.
- **Widget test History Chart:** `test/features/checklist/presentation/widgets/history_filter_chips_and_bar_chart_test.dart` — pola pump `HistoryBarChart` standalone dan `DailyTrackerHistoryScreen`.
- **Widget test Task Master (via fake repo):** `test/features/task_master_new/presentation/task_management_test.dart` — pola `FakeTaskRepository`, pump `TaskMasterNewScreen`, dan navigasi ke `CategoryDetailScreen`.

---

## Out of Scope

- **Fitur 1:** Drag-to-reorder antar seksi menggunakan gesture drag (bukan tombol pindah atas/bawah). Tombol aksi pada baris item individual (`SubSubjectItem`) tidak berubah.
- **Fitur 2:** Kemampuan mengubah warna item secara manual. Perubahan pada tooltip bar chart (sudah menampilkan persentase).
- **Fitur 3:** Edit hitungan pada tanggal selain hari ini — ini fitur tersendiri. Edit hitungan via swipe gesture pada baris tugas. Layar `TaskHistoryScreen` yang sudah memiliki kemampuan edit tidak diubah.

---

## Further Notes

- Ketiga fitur ini bersifat **additive** — tidak ada perubahan breaking pada domain model atau kontrak repository yang sudah ada (kecuali penambahan parameter opsional di `onSave` Fitur 3, yang bersifat backward-compatible karena opsional).
- Fitur 1 dan 2 sepenuhnya UI-only — tidak ada perubahan ke lapisan data atau domain.
- Fitur 3 memerlukan perluasan `FakeTaskRepository` di test support untuk menangani update hitungan harian agar test dapat memverifikasi operasi end-to-end.
- Urutan implementasi yang disarankan: Fitur 2 (paling sederhana, isolated) → Fitur 1 → Fitur 3 (memerlukan perubahan interface).
- Gunakan glosarium domain di PRD untuk konsistensi penamaan di kode dan komentar.
