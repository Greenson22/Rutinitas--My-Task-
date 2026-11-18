# ADR-0001: Tri-state `TodayVisibility` untuk daftar Hari Ini

| Field | Value |
|---|---|
| Status | Accepted |
| Tanggal | 18 November 2026 |
| Konteks | `docs/tasks_master/today-visibility-experimental/PRD.md` |

## Konteks

Daftar “Hari Ini” di `task_master_new` saat ini menampilkan tugas aktif yang memenuhi salah satu dari:

- `targetDaily > 0`
- `kind == progress && targetTotal > 0`
- `countToday > 0`

Permintaan produk: setiap tugas dapat “diaktifkan atau dinonaktifkan untuk ditampilkan di daftar Hari Ini”, termasuk ketika tugas sedang aktif. Ini membutuhkan dua arah:

1. Menyembunyikan tugas yang seharusnya muncul menurut aturan lama.
2. Memunculkan tugas yang tidak muncul menurut aturan lama (mis. tugas tanpa target harian).

## Keputusan

Gunakan enum tiga nilai `TodayVisibility { auto, always, never }` dengan default `auto`, disimpan sebagai `todayVisibility` pada JSON v2.

## Alternatif yang Ditolak

### Boolean `showInToday` dengan default `true`

Default `true` berarti “tampil”, sehingga seluruh tugas aktif langsung masuk daftar Hari Ini dan perilaku lama berubah untuk semua pengguna. Default `false` berarti tugas bertarget hilang dari daftar sampai diaktifkan manual. Keduanya melanggar G-02 (default tidak berubah).

### Dua boolean: `showInToday` + `forceShowInToday`

Membuat dua field yang dapat bertentangan (`false` + `true`), menambah validasi tanpa manfaat, dan menyulitkan migrasi.

### Boolean sebagai filter saja (hanya menyembunyikan)

Memenuhi arah pertama tetapi tidak memenuhi permintaan “memunculkan tugas tanpa target”. Pengguna harus melakukan increment pertama sebelum tugas terlihat.

## Konsekuensi

- Tambah satu field dan satu enum; mapper harus menangani nilai tidak dikenal dan fallback ke `auto`.
- UI memakai tiga opsi, bukan switch on/off. Sedikit lebih berat di form, tetapi tidak ambigu.
- Cermin legacy `showInToday` hanya ditulis untuk `always` dan `never`, sehingga file tetap terbaca modul lama.
- `auto` identik dengan perilaku sebelum perubahan, jadi migrasi data lama tidak memerlukan langkah khusus dan `schemaVersion` tidak perlu dinaikkan.
- Jika kelak dibutuhkan nilai keempat (mis. “tampil hanya pada hari kerja”), enum dapat diperluas tanpa mengubah tipe field.
