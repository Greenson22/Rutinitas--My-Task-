# PRD — Task Master New

| Field | Value |
|---|---|
| Produk | Rutinitasku — Task Master |
| Nama fitur | `task_master_new` |
| Versi dokumen | 1.0 |
| Tanggal | 14 November 2026 |
| Status | Draft untuk implementasi |
| Target rilis | v1 internal, menggantikan `features/task_master` setelah parity |
| Platform utama | Android dan Linux desktop |
| Platform pendukung | Windows dan macOS (tetap harus kompilasi) |

---

## 1. Ringkasan

`task_master_new` adalah penulisan ulang fitur Task Master dengan tiga tujuan yang tidak bisa dipisahkan:

1. **Keandalan data** — data lama tetap terbaca, tidak ada kehilangan riwayat, dan penulisan file aman.
2. **Arsitektur yang bisa dirawat** — domain, data, dan presentasi dipisahkan; controller tidak lagi menangani UI, I/O file, enkripsi, dan integrasi Jurnal sekaligus.
3. **Pengalaman pengguna yang lebih cepat** — dashboard “Hari Ini”, halaman detail kategori, pencarian, undo, dan layout adaptif desktop/mobile.

Versi lama tetap dipertahankan selama masa transisi. `task_master_new` menjadi satu-satunya penulis data Task Master setelah diaktifkan.

---

## 2. Latar Belakang

### 2.1 Kondisi saat ini

Berdasarkan kode yang ada:

- `TaskMasterController` berisi ±538 baris dan menangani pemuatan file, enkripsi, migrasi tanggal, pencarian, penyimpanan, serta penulisan Jurnal.
- `task_master_screen.dart` berisi ±842 baris dan menangani dialog, form, edit raw JSON, recovery, serta seluruh state halaman.
- `tasks_dialog.dart` berisi ±956 baris dan menangani daftar tugas, seleksi massal, reorder, progress bar, dan popup menu.
- `TaskItem` bersifat mutable dan mencampur status harian, total, target, tipe, dan tanggal dalam satu objek.
- `TaskCategory` belum memiliki `id`; kategori diidentifikasi dengan `name`, sehingga rename berpotensi memutus referensi.
- `countToday` direset dengan membandingkan string tanggal. Riwayat harian tidak disimpan, sehingga streak dan statistik tidak mungkin dihitung.
- Setiap penyimpanan sering memicu pembacaan ulang seluruh file (`initStorageAndLoadData`), yang membuat interaksi terasa berat dan rawan race condition.
- Integrasi Jurnal dan Checklist membaca `mytask/my_tasks.json` secara langsung. Perubahan skema harus tetap kompatibel.
- Belum ada test untuk migrasi, penyimpanan, atau perilaku harian.

### 2.2 Masalah yang harus diselesaikan

| Masalah | Dampak |
|---|---|
| Logic bercampur di controller dan widget | Sulit diuji, sulit diubah, mudah menimbulkan regresi |
| Tidak ada riwayat harian | Streak, konsistensi, dan laporan tidak bisa dibuat |
| Identitas kategori berbasis nama | Rename dan duplikasi nama berisiko |
| Reset harian berbasis string tanggal | Salah reset jika format tanggal berbeda atau aplikasi tidak dibuka |
| Simpan file memicu reload penuh | UI lambat dan boros I/O |
| Tidak ada undo | Salah klik increment langsung mengubah data dan Jurnal |
| Dialog besar untuk daftar tugas | Navigasi kurang nyaman, terutama di desktop |
| Tidak ada test migrasi | Risiko kehilangan data saat skema berubah |

---

## 3. Tujuan dan Non-Goals

### 3.1 Goals

| ID | Goal | Ukuran keberhasilan |
|---|---|---|
| G-01 | Data lama termigrasi tanpa kehilangan tugas, kategori, hitungan, atau target | 100% data legacy terpetakan; backup dibuat sebelum migrasi |
| G-02 | Arsitektur berlapis dengan domain yang stabil | Controller hanya mengatur state; I/O hanya di data layer |
| G-03 | Interaksi increment terasa instan | UI berubah < 100 ms; penulisan file dilakukan di luar jalur render |
| G-04 | Riwayat harian dan streak tersedia | Riwayat sparse per tugas; streak dihitung dari riwayat |
| G-05 | Navigasi lebih nyaman di mobile dan desktop | Master-detail desktop; push screen mobile |
| G-06 | Integrasi Jurnal, Checklist, dan Data Center tetap berjalan | Parity test lulus; file tetap kompatibel |
| G-07 | Tidak ada kehilangan data saat file korup atau enkripsi aktif | Recovery flow tersedia; atomic write dipakai |

### 3.2 Non-Goals v1

Fitur berikut **tidak** masuk v1:

- Notifikasi sistem atau local notification.
- Subtask dan checklist bertingkat di dalam tugas.
- Template tugas atau kategori.
- Statistik lanjutan, grafik jangka panjang, dan ekspor laporan.
- Sinkronisasi cloud atau multi-perangkat.
- Multi-user atau pembagian tugas.
- Penggantian total fitur Jurnal dan Checklist.
- Dark mode sebagai target rilis (boleh disiapkan di theme, tetapi bukan kriteria lulus).

### 3.3 Success metrics

- Migrasi data legacy: 100% kategori, tugas, `id`, `count`, `targetCount`, `targetCountToday`, dan `isActive` dipertahankan.
- Tidak ada kegagalan tulis file pada pengujian atomic write dan simulasi file korup.
- Waktu muat 1.000 tugas < 500 ms pada perangkat Android kelas menengah.
- Pencarian 1.000 tugas < 100 ms setelah input.
- Semua acceptance criteria di Bagian 12 lulus.
- Tidak ada regresi pada Jurnal, Checklist, dan Data Center berdasarkan manual QA.

---

## 4. Pengguna dan Skenario

### 4.1 Persona utama

**Pengguna produktivitas individu** yang melacak kebiasaan dan aktivitas harian, biasanya memakai Android atau Linux desktop. Pengguna sudah memiliki data Task Master lama dan mungkin mengaktifkan enkripsi.

### 4.2 Skenario utama

| ID | Skenario | Hasil yang diharapkan |
|---|---|---|
| S-01 | Membuka Task Master pertama kali setelah update | Data lama termigrasi, dashboard tampil, tidak ada data hilang |
| S-02 | Menambah kategori dan tugas | Kategori/tugas tersimpan, muncul di dashboard dan halaman kategori |
| S-03 | Menekan tombol increment | Hitungan naik seketika, Jurnal bertambah jika tertaut, undo tersedia |
| S-04 | Membatalkan increment | Hitungan dan Jurnal kembali ke kondisi sebelumnya |
| S-05 | Melihat riwayat dan streak | Riwayat harian dan streak tampil konsisten |
| S-06 | Mencari tugas lintas kategori | Hasil muncul dan bisa dibuka langsung |
| S-07 | Mengubah nama kategori | Identitas kategori tetap, semua tugas tetap terhubung |
| S-08 | Mengaktifkan enkripsi | File tetap terbaca, migrasi dan penyimpanan tetap berjalan |
| S-09 | File rusak atau PIN salah | Pengguna mendapat opsi buka kunci, buat baru, atau pulihkan backup |
| S-10 | Export/import dari Data Center | File v2 dapat diekspor, diimpor, dan dimigrasi ulang dengan aman |
| S-11 | Memakai desktop | Layout dua panel, pencarian dan aksi tetap mudah dijangkau |

---

## 5. Ruang Lingkup v1

### 5.1 Must have

- Migrasi otomatis dari `my_tasks.json` legacy ke skema v2.
- CRUD kategori dengan `id` stabil.
- CRUD tugas dengan `TaskKind` yang jelas.
- Increment tugas dengan undo.
- Dashboard “Hari Ini”.
- Halaman detail kategori.
- Riwayat harian sparse dan streak.
- Pencarian dan filter.
- Reorder kategori dan tugas.
- Sembunyikan kategori dan nonaktifkan tugas.
- Pindahkan tugas antar kategori.
- Aksi massal: aktifkan, nonaktifkan, hapus.
- Ringkasan kategori, tugas, target selesai hari ini, dan durasi Jurnal.
- Integrasi Jurnal yang setara dengan versi lama.
- Dukungan enkripsi global dan recovery file korup.
- Export/import Data Center tetap kompatibel.
- Layout responsif Android dan Linux desktop.

### 5.2 Should have

- Drag-and-drop reorder dengan handle yang jelas.
- Keyboard shortcut desktop: `Ctrl/Cmd + F`, `Ctrl/Cmd + N`, `Esc`.
- Filter cepat: semua, aktif, nonaktif, punya target hari ini.
- Indikator “tertaut ke Jurnal” pada tugas.
- Empty state yang menjelaskan cara mulai.
- Raw JSON editor dipindahkan ke area Advanced/Diagnostics.

### 5.3 Could have

- Dark mode.
- Grafik riwayat 7/30 hari.
- Quick add tugas dari dashboard.
- Duplikasi tugas/kategori.

### 5.4 Won’t have (v1)

- Notifikasi sistem.
- Subtask.
- Template.
- Statistik lanjutan.
- Cloud sync.

---

## 6. Pengalaman Pengguna

### 6.1 Prinsip UX

1. **Satu klik untuk aksi utama** — increment tidak lagi memakai dialog konfirmasi; kesalahan dicegah dengan undo.
2. **Daftar tugas bukan dialog** — dialog hanya untuk form pendek dan konfirmasi destruktif.
3. **Konteks selalu terlihat** — target hari ini, total, status aktif, dan keterkaitan Jurnal terlihat tanpa membuka menu.
4. **Desktop bukan mobile yang diperbesar** — desktop memakai dua panel dan keyboard shortcut.
5. **State kosong harus mengarahkan** — setiap empty state memberi aksi berikutnya.

### 6.2 Navigasi

**Mobile (< 600 dp):**

- Drawer lama tetap dipakai.
- Dashboard adalah halaman utama.
- Ketuk kategori → push `CategoryDetailScreen`.
- Kembali → dashboard.

**Tablet (600–1024 dp):**

- Dua panel opsional; jika sempit, perilaku sama dengan mobile.

**Desktop (> 1024 dp):**

- Panel kiri: daftar kategori, pencarian, dan tombol tambah.
- Panel kanan: detail kategori terpilih atau dashboard “Hari Ini” jika belum ada yang dipilih.
- Tidak ada push screen untuk kategori; seleksi mengubah panel kanan.

### 6.3 Dashboard

Komponen dari atas ke bawah:

1. **AppBar** — judul “Task Master”, tombol search, menu overflow.
2. **Ringkasan** — empat kartu: kategori aktif, total tugas aktif, target selesai hari ini, durasi Jurnal hari ini.
3. **Hari Ini** — daftar tugas yang memiliki target harian atau sudah memiliki aktivitas hari ini. Setiap baris menampilkan nama, kategori, progress harian, tombol increment, dan status target.
4. **Kategori** — grid/list kategori dengan ikon, nama, jumlah tugas aktif, dan ringkasan progress hari ini.
5. **Aksi** — FAB “Tambah” dengan pilihan “Tugas” dan “Kategori”.

Perilaku:

- Jika belum ada kategori, tampilkan empty state dengan CTA “Buat Kategori Pertama”.
- Jika belum ada tugas hari ini, tampilkan empty state ringan, bukan halaman kosong.
- Kategori tersembunyi tidak tampil di dashboard kecuali mode “Tampilkan tersembunyi” aktif.

### 6.4 Halaman detail kategori

Header:

- Ikon, nama, jumlah tugas, progress hari ini.
- Aksi: edit kategori, sembunyikan, hapus.

Toolbar:

- Search dalam kategori.
- Filter: semua, aktif, nonaktif, punya target hari ini.
- Tombol tambah tugas.
- Mode seleksi melalui long press.

Daftar tugas:

- Nama tugas dan badge jenis (`Habit`, `Counter`, `Progress`).
- `+countToday / targetHariIni` dan total.
- Progress bar untuk `TaskKind.progress`.
- Indikator aktif/nonaktif.
- Indikator tertaut Jurnal.
- Tombol increment besar dan mudah dijangkau.
- Menu: edit, pindahkan kategori, aktif/nonaktif, hapus.
- Reorder dengan drag handle; tombol panah hanya menjadi fallback aksesibilitas.
- Mode seleksi: aktifkan, nonaktifkan, hapus massal.

### 6.5 Form

**Form kategori:**

- Nama wajib, maksimal 60 karakter.
- Ikon emoji.
- Status tersembunyi.
- Validasi nama duplikat (case-insensitive) dengan opsi tetap lanjut atau ganti nama.

**Form tugas:**

- Nama wajib, maksimal 120 karakter.
- Kategori tujuan.
- Jenis tugas: `Habit`, `Counter`, `Progress`.
- Target harian (opsional, >= 0).
- Target total (hanya untuk `Progress`, >= 0).
- Status aktif.
- Untuk `Progress`, target total wajib > 0.

### 6.6 Pencarian dan filter

- Pencarian mencakup nama kategori dan nama tugas.
- Hasil dikelompokkan per kategori.
- Debounce 250 ms.
- Mencari tugas yang nonaktif tetap menampilkan badge nonaktif.
- Filter tidak menghilangkan konteks kategori.
- Tidak ada hasil → empty state dengan tombol hapus filter.

### 6.7 Undo

- Setelah increment, tampilkan SnackBar “+1 [nama tugas]” dengan aksi “Undo” selama 5 detik.
- Undo mengembalikan `count`, `countToday`, dan entri riwayat hari ini.
- Jika increment menambah durasi Jurnal, undo mengurangi durasi yang sama dari task Jurnal yang tertaut.
- Rollback Jurnal bersifat best-effort: jika gagal, data Task Master tetap dikembalikan dan pengguna melihat peringatan bahwa Jurnal perlu diperiksa manual.
- Hanya aksi increment terakhir yang bisa di-undo. Aksi lain memakai konfirmasi.

### 6.8 State halaman

| State | Tampilan |
|---|---|
| Loading | Skeleton atau progress indicator, bukan layar putih |
| Empty | Empty state dengan CTA |
| Error baca file | Pesan, tombol coba lagi, buka kunci, buat baru |
| File korup | Recovery dialog dengan opsi PIN, backup, reset |
| Search kosong | Empty state filter |
| Offline | Tidak ada perubahan; aplikasi memang lokal |

### 6.9 Responsif dan aksesibilitas

- Breakpoint: mobile `< 600`, tablet `600–1024`, desktop `> 1024`.
- Target sentuh minimal 48×48 dp.
- Kontras teks memenuhi WCAG AA.
- Mendukung text scale hingga 1.5 tanpa overflow.
- Semua ikon aksi memiliki tooltip/label.
- Progress bar memiliki semantic label.
- Navigasi keyboard desktop: fokus terlihat, `Esc` menutup dialog.

---

## 7. Model Domain

### 7.1 Entities

#### Category

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | String | Identitas stabil, tidak berubah saat rename |
| `name` | String | Nama tampilan |
| `icon` | String | Emoji |
| `isHidden` | bool | Disembunyikan dari tampilan utama |
| `sortOrder` | int | Urutan tampilan |
| `tasks` | List<Task> | Daftar tugas |

#### Task

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | String | Identitas stabil, dipakai Jurnal |
| `categoryId` | String | Relasi ke Category |
| `name` | String | Nama tugas |
| `kind` | TaskKind | `habit`, `counter`, `progress` |
| `isActive` | bool | Ikut dihitung atau tidak |
| `sortOrder` | int | Urutan dalam kategori |
| `targetDaily` | int | Target hari ini; 0 berarti tidak ada target |
| `targetTotal` | int | Target total; hanya untuk `progress` |
| `totalCount` | int | Akumulasi sepanjang waktu |
| `createdAt` | DateTime | Waktu dibuat |
| `updatedAt` | DateTime | Waktu terakhir diubah |
| `history` | Map<date, DailyProgress> | Riwayat sparse per tanggal |

#### DailyProgress

| Field | Tipe | Keterangan |
|---|---|---|
| `date` | String `YYYY-MM-DD` | Tanggal lokal |
| `count` | int | Jumlah increment pada tanggal tersebut |
| `updatedAt` | DateTime | Waktu terakhir diubah |

### 7.2 TaskKind

| Kind | Arti | Target harian | Target total | Contoh |
|---|---|---|---|---|
| `habit` | Aktivitas berulang yang diharapkan dilakukan setiap hari | Opsional, umumnya > 0 | Tidak dipakai | Push up 20×, baca 30 menit |
| `counter` | Akumulasi hitungan tanpa kewajiban harian | Opsional | Tidak dipakai | Minum kopi, jumlah panggilan |
| `progress` | Pekerjaan menuju target total | Opsional | Wajib > 0 | Menulis 10.000 kata |

Aturan tampilan:

- `habit` menonjolkan progress harian dan streak.
- `counter` menonjolkan total dan aktivitas hari ini.
- `progress` menampilkan progress bar terhadap `targetTotal`.

### 7.3 Riwayat dan streak

- `history` bersifat **sparse**: hanya tanggal dengan `count > 0` yang disimpan.
- `countToday` adalah proyeksi dari `history[today]?.count ?? 0`, bukan sumber kebenaran.
- `totalCount` tetap disimpan terpisah karena mencakup data sebelum riwayat tersedia.
- Streak didefinisikan sebagai jumlah hari berturut-turut yang memenuhi aturan:
  - Jika `targetDaily > 0`: hari dianggap berhasil jika `count >= targetDaily`.
  - Jika `targetDaily == 0`: hari dianggap aktif jika `count > 0`.
- Hari ini tidak memutus streak jika belum terpenuhi; streak dihitung dari hari kemarin ke belakang.
- Riwayat disimpan maksimal 365 hari per tugas. Entri lebih lama dipangkas saat penulisan.

### 7.4 JournalLink

- Relasi tugas dengan Jurnal **dimiliki oleh Jurnal**, bukan oleh Task Master.
- Task Master hanya membaca `linkedTaskIds` dari file Jurnal untuk mengetahui apakah sebuah tugas tertaut.
- Task Master tidak menyimpan salinan relasi di `my_tasks.json` agar tidak ada dua sumber kebenaran.
- Increment tugas yang tertaut menambah durasi pada task Jurnal yang sesuai.
- Durasi mengikuti `settings.default_increment_minutes` di `jurnal_template.json`; fallback 30 menit.

### 7.5 Glossary

| Istilah | Makna |
|---|---|
| **Task Master** | Fitur untuk mengelola kategori dan tugas yang dilacak |
| **Kategori** | Pengelompokan tugas; memiliki `id` stabil |
| **Tugas** | Satu item yang dilacak; memiliki `TaskKind` |
| **Target Hari Ini** | Jumlah minimal increment agar hari dianggap berhasil |
| **Target Total** | Target akumulasi untuk tugas `progress` |
| **Progress** | Angka capaian, bukan status selesai |
| **Riwayat** | Kumpulan `DailyProgress` sparse per tanggal |
| **Streak** | Jumlah hari berturut-turut yang memenuhi aturan harian |
| **Tertaut Jurnal** | Task Jurnal memiliki `linkedTaskIds` yang memuat `id` tugas ini |

---

## 8. Data dan Kompatibilitas

### 8.1 Lokasi file

| Data | Path |
|---|---|
| Task Master | `<baseDir>/mytask/my_tasks.json` |
| Jurnal bulanan | `<baseDir>/jurnal_aktivitas/jurnal_YYYY_MM.json` |
| Template Jurnal | `<baseDir>/jurnal_aktivitas/jurnal_template.json` |
| Backup Task Master | `<baseDir>/mytask/backup/my_tasks_YYYYMMDD_HHmmss.json` |

`baseDir` berasal dari `StorageService.getBaseDirSetting()`.

### 8.2 Skema v2

```json
{
  "schemaVersion": 2,
  "categories": [
    {
      "id": "cat_7f3a91",
      "name": "Olahraga",
      "icon": "🏃",
      "isHidden": false,
      "sortOrder": 0,
      "tasks": [
        {
          "id": "a1b2c3d4",
          "name": "Push up",
          "kind": "habit",
          "type": 0,
          "isActive": true,
          "sortOrder": 0,
          "count": 120,
          "countToday": 15,
          "targetCountToday": 20,
          "targetCount": 0,
          "date": "2026-11-14 08:30",
          "lastUpdated": "2026-11-14 08:30",
          "checked": false,
          "createdAt": "2026-01-01T08:00:00.000",
          "updatedAt": "2026-11-14T08:30:00.000",
          "history": {
            "2026-11-14": {
              "count": 15,
              "updatedAt": "2026-11-14T08:30:00.000"
            },
            "2026-11-13": {
              "count": 20,
              "updatedAt": "2026-11-13T19:10:00.000"
            }
          }
        }
      ]
    }
  ]
}
```

Catatan kompatibilitas:

- `type` tetap ditulis sebagai cermin legacy: `progress` → `1`, `habit`/`counter` → `0`.
- Nama field lama (`count`, `countToday`, `targetCountToday`, `targetCount`, `date`, `lastUpdated`, `checked`) dipertahankan agar fitur lama dapat membaca file selama transisi.
- `schemaVersion` tidak ada pada file lama; ketiadaannya berarti versi 1.
- Field baru diabaikan oleh model lama.

### 8.3 Pemetaan data legacy

| Legacy | v2 | Aturan |
|---|---|---|
| `category.name` | `category.name` | Dipertahankan |
| Tidak ada | `category.id` | Backfill deterministik dari nama, misalnya `cat_` + hash; kolisi diberi suffix |
| Tidak ada | `category.sortOrder` | Urutan array lama |
| `task.id` | `task.id` | Dipertahankan; jika kosong, generate baru |
| `task.type` | `task.kind` + `task.type` | `1` → `progress`; `0` + `targetCountToday > 0` → `habit`; `0` + target 0 → `counter` |
| `task.count` | `task.count` / `totalCount` | Dipertahankan |
| `task.countToday` | `task.countToday` + `history[today]` | Jika tanggal legacy adalah hari ini, pertahankan; jika bukan, pindahkan ke history tanggal legacy |
| `task.date` | `task.date` + `history` | Tanggal legacy dipakai untuk membuat entri riwayat jika ada `countToday > 0` |
| `task.targetCountToday` | `task.targetCountToday` | Dipertahankan |
| `task.targetCount` | `task.targetCount` | Dipertahankan |
| `task.isActive` | `task.isActive` | Default `true` jika tidak ada |

### 8.4 Reset harian

Versi lama mereset `countToday` dengan membandingkan string tanggal. Versi baru menggunakan riwayat:

1. Saat load, `countToday` dihitung dari `history[today]`.
2. Saat increment, `countToday` dan `history[today].count` diperbarui bersamaan.
3. Tidak ada job reset terjadwal. Pergantian hari terjadi secara alami karena kunci tanggal berubah.
4. Data legacy yang memiliki `countToday` pada tanggal lampau dipindahkan ke `history` agar tidak hilang.

### 8.5 Migrasi

Migrasi dijalankan saat `TaskMasterRepository` memuat file:

1. Baca file mentah.
2. Jika enkripsi aktif, dekripsi dengan `CryptoHelper`.
3. Deteksi `schemaVersion`.
4. Jika versi 2, validasi dan lanjut.
5. Jika versi 1 atau tidak ada versi:
   - Buat backup di `<baseDir>/mytask/backup/`.
   - Petakan kategori dan tugas ke v2.
   - Backfill `category.id` secara deterministik.
   - Pindahkan `countToday` historis ke `history`.
   - Tulis file v2 dengan `AtomicWriteHelper.writeSafe`.
6. Jika enkripsi aktif, enkripsi ulang konten sebelum ditulis.
7. Jika migrasi gagal, file asli tidak boleh berubah; tampilkan recovery.

Syarat:

- Migrasi **idempoten**: menjalankan ulang tidak menggandakan data atau mengubah `id`.
- Backup dibuat sebelum penulisan pertama.
- Tidak ada penulisan langsung ke file asli tanpa atomic write.
- File dengan field tidak dikenal tetap dipertahankan jika memungkinkan; jika tidak, field tersebut dicatat di log.

### 8.6 Matriks kompatibilitas

| Pembaca | File v1 | File v2 |
|---|---|---|
| Task Master lama | Ya | Ya, karena field legacy dipertahankan |
| `task_master_new` | Ya, via migrasi | Ya |
| Jurnal Aktivitas | Ya | Ya, field `id`, `name`, `tasks` tetap ada |
| Checklist | Ya | Ya, `TaskCategory.fromJson` tetap bekerja |
| Data Center export | Ya | Ya |
| Data Center import | Ya, lalu migrasi | Ya |

Catatan: hanya satu versi Task Master yang boleh menjadi penulis aktif pada satu waktu. Versi lama hanya berfungsi sebagai fallback, bukan untuk menulis bersamaan.

### 8.7 Enkripsi, file korup, dan recovery

- Semua baca/tulis memakai `StorageService` dan `CryptoHelper` yang sudah ada.
- Penulisan memakai `AtomicWriteHelper.writeSafe`.
- File yang gagal didekripsi menampilkan dialog:
  - “Buka Kunci” dengan input PIN.
  - “Pulihkan Backup” jika backup tersedia.
  - “Buat Baru” dengan konfirmasi destruktif.
- Backup migrasi tidak dienkripsi jika file asli tidak terenkripsi; jika asli terenkripsi, backup disimpan dalam bentuk terenkripsi.
- Raw JSON editor hanya untuk mode Advanced; validasi JSON sebelum menyimpan dan tetap memakai atomic write.

---

## 9. Arsitektur

### 9.1 Struktur folder

```text
lib/features/task_master_new/
├── task_master_new.dart
├── domain/
│   ├── entities/
│   │   ├── category.dart
│   │   ├── task.dart
│   │   ├── task_kind.dart
│   │   └── daily_progress.dart
│   ├── repositories/
│   │   └── task_repository.dart
│   └── usecases/
│       ├── load_task_master.dart
│       ├── increment_task.dart
│       ├── undo_increment.dart
│       ├── migrate_task_master.dart
│       └── calculate_streak.dart
├── data/
│   ├── models/
│   │   ├── category_dto.dart
│   │   ├── task_dto.dart
│   │   └── daily_progress_dto.dart
│   ├── datasources/
│   │   └── task_local_data_source.dart
│   ├── mappers/
│   │   └── task_mapper.dart
│   ├── repositories/
│   │   └── task_repository_impl.dart
│   └── services/
│       └── journal_link_service.dart
└── presentation/
    ├── controllers/
    │   ├── task_master_controller.dart
    │   └── task_master_state.dart
    ├── screens/
    │   ├── task_master_screen.dart
    │   └── category_detail_screen.dart
    └── widgets/
        ├── dashboard_summary.dart
        ├── today_task_list.dart
        ├── category_card.dart
        ├── category_grid.dart
        ├── task_tile.dart
        ├── task_form_dialog.dart
        ├── category_form_dialog.dart
        ├── search_field.dart
        ├── empty_states.dart
        ├── recovery_dialog.dart
        └── undo_snackbar.dart
```

### 9.2 Tanggung jawab layer

| Layer | Tanggung jawab | Tidak boleh |
|---|---|---|
| Domain | Entity, aturan bisnis, kontrak repository, use case | Tahu Flutter widget, file, atau JSON |
| Data | DTO, mapper, baca/tulis file, enkripsi, migrasi, integrasi Jurnal | Mengubah state UI |
| Presentation | State, widget, interaksi pengguna | Menulis file langsung atau memanggil `dart:io` |

### 9.3 State management

- `TaskMasterController extends ChangeNotifier`.
- State direpresentasikan oleh `TaskMasterState` immutable dengan `copyWith`.
- Field state minimal:
  - `status`: loading, ready, empty, corrupted, error.
  - `categories`: `List<Category>`.
  - `selectedCategoryId`: `String?`.
  - `searchQuery`: `String`.
  - `filter`: enum.
  - `isPageEditMode`, `showHiddenSection`.
  - `todaySummary`.
  - `lastAction`: untuk undo.
- Controller memanggil use case/repository, bukan `File` atau `CryptoHelper`.
- Widget mendengarkan controller melalui `AnimatedBuilder` atau `ListenableBuilder`.
- Tidak ada dependency state management baru.

### 9.4 Batas integrasi

| Integrasi | Mekanisme | Catatan |
|---|---|---|
| Jurnal | `JournalLinkService` di data layer | Membaca/menulis file Jurnal dengan enkripsi dan atomic write |
| Checklist | File `my_tasks.json` yang sama | Checklist hanya membaca; tidak diubah di v1 |
| Data Center | File `my_tasks.json` yang sama | Export/import tetap berjalan |
| Settings | `SettingsDialog` | Pindahkan ke `core/presentation/widgets` pada fase 1 karena sudah dipakai lintas fitur |
| PasswordGate | App-level | Tidak diubah |

### 9.5 Error handling dan konkurensi

- Semua operasi tulis diserialisasi melalui queue di `TaskLocalDataSource`.
- Increment memperbarui state di memori terlebih dahulu, lalu menjadwalkan save dengan debounce 300 ms.
- Save berikutnya menunggu save sebelumnya selesai.
- Jika save gagal, state tetap tampil, tetapi pengguna mendapat banner “Perubahan belum tersimpan” dan opsi coba lagi.
- Tidak ada `await` I/O di dalam `build`.
- `BuildContext` tidak dipakai setelah operasi async tanpa cek `mounted`.

---

## 10. Functional Requirements

| ID | Requirement | Prioritas | Acceptance |
|---|---|---|---|
| FR-01 | Memuat `my_tasks.json` dan mendeteksi versi skema | Must | File v1 dan v2 terbaca; versi tidak dikenal menampilkan error |
| FR-02 | Memigrasi v1 ke v2 dengan backup | Must | Data lengkap; file asli tidak berubah jika migrasi gagal |
| FR-03 | CRUD kategori dengan `id` stabil | Must | Rename tidak mengubah `id`; tugas tetap terhubung |
| FR-04 | CRUD tugas | Must | Semua field tersimpan dan tampil kembali setelah restart |
| FR-05 | Menambah hitungan tugas | Must | `count`, `countToday`, dan `history[today]` bertambah; UI instan |
| FR-06 | Undo increment | Must | Data tugas dan Jurnal kembali dalam 5 detik |
| FR-07 | Riwayat harian | Must | Riwayat muncul per tanggal; data lama tidak hilang |
| FR-08 | Streak | Must | Streak dihitung sesuai aturan `TaskKind` dan target |
| FR-09 | Dashboard Hari Ini | Must | Menampilkan tugas bertarget/beraktivitas hari ini |
| FR-10 | Pencarian lintas kategori | Must | Hasil muncul < 100 ms untuk 1.000 tugas |
| FR-11 | Filter kategori/tugas | Must | Filter aktif, nonaktif, target hari ini |
| FR-12 | Reorder kategori dan tugas | Must | Urutan tersimpan setelah restart |
| FR-13 | Sembunyikan kategori | Must | Kategori tersembunyi tidak tampil di dashboard |
| FR-14 | Aktif/nonaktif tugas | Must | Tugas nonaktif tidak dihitung di ringkasan |
| FR-15 | Pindahkan tugas antar kategori | Must | Tugas muncul di kategori tujuan; `id` tetap |
| FR-16 | Aksi massal | Must | Aktifkan, nonaktifkan, hapus massal dengan konfirmasi |
| FR-17 | Integrasi Jurnal | Must | Increment task tertaut menambah durasi sesuai setting |
| FR-18 | Ringkasan dashboard | Must | Empat kartu ringkasan akurat |
| FR-19 | Enkripsi dan recovery | Must | File terenkripsi terbaca; file korup menampilkan opsi recovery |
| FR-20 | Export/import Data Center | Must | File v2 dapat diekspor dan diimpor |
| FR-21 | Layout responsif | Must | Mobile, tablet, desktop tanpa overflow |
| FR-22 | Raw JSON editor | Should | Validasi JSON; simpan atomic; tersedia di Advanced |
| FR-23 | Keyboard shortcut desktop | Should | `Ctrl/Cmd + F`, `Ctrl/Cmd + N`, `Esc` berfungsi |
| FR-24 | Indikator tertaut Jurnal | Should | Badge tampil jika `linkedTaskIds` memuat `id` tugas |
| FR-25 | Dark mode | Could | Tema gelap konsisten; tidak memblokir rilis |

---

## 11. Non-Functional Requirements

| Aspek | Requirement |
|---|---|
| Performa muat | 1.000 tugas < 500 ms pada Android kelas menengah |
| Performa increment | UI berubah < 100 ms; I/O tidak memblokir frame |
| Performa pencarian | < 100 ms untuk 1.000 tugas |
| Penyimpanan | Atomic write; tidak ada partial write |
| Keandalan | Migrasi idempoten; backup sebelum perubahan skema |
| Memori | Tidak menyimpan duplikasi besar; history sparse |
| Keamanan | Mengikuti enkripsi global yang ada; tidak menyimpan password di source |
| Aksesibilitas | Target sentuh 48 dp; kontras AA; mendukung text scale 1.5 |
| Lokalisasi | Bahasa Indonesia untuk seluruh teks UI |
| Kompatibilitas | Android, Linux, Windows, macOS tetap kompilasi |
| Observability | `debugPrint` terstruktur untuk migrasi, save, dan error; tanpa data sensitif |

---

## 12. Acceptance Criteria

Rilis v1 dianggap selesai jika:

1. File `my_tasks.json` versi lama termigrasi tanpa kehilangan kategori, tugas, `id`, `count`, `targetCount`, `targetCountToday`, atau `isActive`.
2. Backup dibuat sebelum migrasi dan dapat dipulihkan.
3. Menjalankan migrasi dua kali tidak menggandakan data.
4. Rename kategori tidak memutus tugas di dalamnya.
5. Increment tugas memperbarui UI, menyimpan file, dan menambah durasi Jurnal jika tertaut.
6. Undo mengembalikan hitungan tugas dan durasi Jurnal.
7. Riwayat hari ini dan hari sebelumnya tampil benar setelah aplikasi ditutup dan dibuka kembali.
8. Pergantian hari tidak memerlukan job reset; `countToday` kembali 0 secara alami.
9. Streak sesuai aturan `TaskKind` dan target.
10. Pencarian menemukan tugas lintas kategori dan menampilkan konteks kategori.
11. Reorder kategori dan tugas bertahan setelah restart.
12. Kategori tersembunyi dan tugas nonaktif tidak memengaruhi ringkasan.
13. File terenkripsi dapat dibaca, dimigrasi, dan ditulis ulang.
14. File korup menampilkan opsi buka kunci, pulihkan backup, dan buat baru.
15. Export/import Data Center menghasilkan data yang sama setelah round-trip.
16. Layout mobile, tablet, dan desktop tidak overflow.
17. Semua unit test migrasi, mapper, repository, dan streak lulus.
18. Widget test dashboard, detail kategori, increment, undo, dan search lulus.
19. Manual QA di Android dan Linux desktop lulus tanpa crash.
20. `flutter analyze` bersih untuk kode baru.

---

## 13. Rencana Pengujian

### 13.1 Unit test

- `TaskMapper`:
  - legacy `type: 0` + target harian → `habit`
  - legacy `type: 0` tanpa target → `counter`
  - legacy `type: 1` → `progress`
  - field hilang memakai default yang benar.
- `CategoryMapper`:
  - backfill `id` deterministik.
  - kolisi nama menghasilkan `id` unik.
- Migrasi:
  - v1 → v2 lengkap.
  - idempoten.
  - file korup tidak menimpa asli.
  - backup dibuat.
- Riwayat:
  - `countToday` diturunkan dari history.
  - perpindahan hari.
  - pemangkasan 365 hari.
- Streak:
  - target harian terpenuhi.
  - target harian tidak terpenuhi.
  - tanpa target harian.
  - hari ini belum dikerjakan.
- Undo:
  - mengembalikan count, countToday, history.
  - rollback Jurnal berhasil dan gagal.

### 13.2 Repository dan data source

- Atomic write berhasil.
- Enkripsi round-trip.
- File tidak ada → dibuat default.
- Save gagal → state error, file lama tetap utuh.
- Queue serialisasi mencegah write bersamaan.
- Export/import round-trip.

### 13.3 Widget test

- Dashboard: loading, empty, ready, corrupted.
- Detail kategori: daftar tugas, filter, seleksi massal.
- Increment dan SnackBar undo.
- Search dan empty search state.
- Form validasi.
- Responsive: mobile dan desktop.

### 13.4 Manual QA

- Android: file lokal, enkripsi aktif/nonaktif, rotasi layar, text scale.
- Linux: window resize, keyboard shortcut, file picker.
- Data besar: 1.000 tugas.
- Jurnal: increment task tertaut dan tidak tertaut.
- Checklist: membaca kategori dan tugas setelah migrasi.
- Data Center: export lalu import.

---

## 14. Rollout Plan

| Fase | Fokus | Keluaran |
|---|---|---|
| 0 | Scaffold dan kontrak | Folder `task_master_new`, entity, repository interface, mapper, test migrasi |
| 1 | Data dan migrasi | Baca/tulis v2, backup, enkripsi, migrasi idempoten |
| 2 | Parity | CRUD, increment, Jurnal, kategori, tugas, enkripsi, recovery |
| 3 | UX baru | Dashboard, detail kategori, search, filter, undo, responsive |
| 4 | Riwayat dan streak | History sparse, streak, ringkasan |
| 5 | QA dan switch | Manual QA, perbaikan, arahkan `main.dart` dan `drawer_menu.dart` ke layar baru |
| 6 | Pembersihan | Hapus `features/task_master` setelah versi baru stabil |

Aturan switch:

- `task_master_new` belum menjadi default sampai Fase 5.
- Setelah switch, versi lama tidak boleh menulis file.
- Rollback dilakukan dengan mengembalikan import navigasi dan memulihkan backup jika diperlukan.
- `SettingsDialog` dipindahkan ke `core` pada Fase 1 agar tidak ada ketergantungan baru ke fitur lama.

---

## 15. Risiko dan Mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Migrasi merusak data | Kehilangan data pengguna | Backup wajib, migrasi idempoten, test dengan fixture legacy |
| Dua sumber kebenaran `kind` vs `type` | Data tidak konsisten | Mapper sebagai satu-satunya jalur tulis; test round-trip |
| Rollback Jurnal gagal | Durasi Jurnal tidak sinkron | Best-effort, peringatan eksplisit, test kegagalan |
| File tumbuh karena history | Performa dan ukuran file | History sparse, maksimal 365 hari per tugas |
| Scope creep | v1 tidak selesai | Non-goals dikunci; fitur baru masuk v2 |
| Race condition save | Data tertimpa | Queue serialisasi dan debounce |
| Perbedaan platform file system | Path/encoding error | Gunakan `StorageService`, test Linux dan Android |
| Fitur lama membaca file v2 | Regresi | Field legacy dipertahankan; test kompatibilitas |
| Enkripsi ganda | File tidak terbaca | Deteksi prefix JSON sebelum enkripsi; test round-trip |

---

## 16. Open Questions

Pertanyaan berikut belum memblokir implementasi karena ada default yang dipakai:

1. **Retensi riwayat** — default 365 hari per tugas. Apakah perlu selamanya?
2. **Dark mode** — default ditunda ke v2. Apakah perlu masuk v1?
3. **Raw JSON editor** — default dipindahkan ke Advanced. Apakah tetap di menu utama?
4. **Undo Jurnal** — default best-effort. Apakah perlu all-or-nothing dengan mekanisme transaksi?
5. **Nama folder** — dokumen ini mengikuti permintaan `task_master_new`. Jika ingin nama lain, ubah sebelum scaffold.

---

## 17. Lampiran

### 17.1 Contoh file legacy

```json
{
  "categories": [
    {
      "name": "Olahraga",
      "icon": "🏃",
      "isHidden": false,
      "tasks": [
        {
          "id": "a1b2c3d4",
          "name": "Push up",
          "count": 120,
          "date": "2026-11-14 08:30",
          "checked": false,
          "countToday": 15,
          "lastUpdated": "2026-11-14 08:30",
          "targetCountToday": 20,
          "type": 0,
          "targetCount": 0,
          "isActive": true
        }
      ]
    }
  ]
}
```

### 17.2 Checklist parity

Fitur lama yang wajib memiliki padanan di `task_master_new`:

- [ ] Tambah, edit, hapus kategori.
- [ ] Sembunyikan/tampilkan kategori.
- [ ] Reorder kategori.
- [ ] Tambah, edit, hapus tugas.
- [ ] Increment tugas.
- [ ] Edit detail tugas (nama, count, countToday, target, tanggal, aktif, tipe).
- [ ] Pindahkan tugas antar kategori.
- [ ] Reorder tugas.
- [ ] Aksi massal aktif/nonaktif/hapus.
- [ ] Pencarian kategori.
- [ ] Ringkasan kategori/tugas/selesai/durasi Jurnal.
- [ ] Integrasi Jurnal.
- [ ] Pengaturan folder dan enkripsi.
- [ ] Recovery file korup.
- [ ] Edit raw JSON.
- [ ] Export/import Data Center.

### 17.3 Definisi “selesai” untuk tugas

- `habit`: `countToday >= targetDaily` jika `targetDaily > 0`; jika target 0, “selesai” tidak didefinisikan dan hanya ditampilkan sebagai aktivitas.
- `counter`: tidak memiliki status selesai; hanya total dan aktivitas.
- `progress`: `count >= targetCount` untuk target total; progress harian tetap ditampilkan jika ada.
