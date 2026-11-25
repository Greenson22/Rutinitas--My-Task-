# Update 2.4.0

## ✅ Fitur Baru

### Checklist — Kontrol Visibilitas & Lipatan Seksi (Section Features)
- **Sembunyikan Seksi**: Sembunyikan seksi beserta seluruh isinya langsung dari ikon mata di header seksi tanpa menghapus data.
- **Tampilkan Kembali Seksi**: Toggle global di AppBar untuk menampilkan seksi tersembunyi (dilengkapi badge "Tersembunyi") dan melakukan unhide.
- **Lipat Seksi (Collapse)**: Ketuk header seksi atau ikon chevron untuk melipat/membuka isi seksi dengan transisi halus (`AnimatedCrossFade`).
- **Pengaturan Global Lipatan**: Opsi baru di Pengaturan Aplikasi ("Tampilan Checklist"):
  - *Tutup seksi secara default* (`section_default_collapsed`).
  - *Ingat status lipatan seksi* (`section_remember_collapse_state`).
- **Guard Konfirmasi Hapus Seksi**: Peringatan konfirmasi saat menghapus seksi berisi item (termasuk item tersembunyi). Seksi kosong terhapus langsung tanpa konfirmasi.

### Checklist — Kaitan Akumulasi & ID Unik
- Setiap item checklist memiliki ID unik untuk kaitan akumulasi lintas card yang presisi tanpa tabrakan nama.
- Tampilan progres akumulasi langsung pada Tree View: `⚡ (nilaiSekarang/nilaiTarget)`.

### Checklist — Peningkatan UX (Color Wheel, Stacked History, & Edit History)
- **Color Wheel Interaktif**: Pemilihan warna pada Card Checklist kini dilengkapi color wheel yang sinkron dua arah dengan input kode HEX serta palet kuratif. Warna teks (hitam/putih) otomatis disesuaikan berdasarkan kecerahan latar belakang agar selalu terbaca jelas.
- **Bar History Multi-Warna (Stacked)**: Grafik batang riwayat DailyTracker kini tersusun dari segmen-segmen berwarna yang mewakili setiap item yang diselesaikan, dengan warna konsisten yang dihasilkan otomatis dari kombinasi huruf nama item.
- **Edit History Sadar Tipe Item**: Sheet edit riwayat kini menampilkan badge tipe item (`Progress` atau `Hitung Mundur`) beserta label input nilai yang lebih jelas (*"Nilai saat ini:"* / *"Sisa:"*) secara rekursif hingga ke sub-item.
- **Legenda Warna History Bar Chart**: Menambahkan legenda warna di bawah grafik batang riwayat harian yang mengikuti filter tanggal aktif dan hanya menampilkan item yang selesai.
- **Tombol Aksi Seksi via Long Press**: Tombol aksi pada header seksi checklist kini disembunyikan secara default agar judul panjang tidak terpotong, dan dapat dimunculkan/disembunyikan di bawah nama seksi melalui long press.

### Task Master New
- **Edit Hitungan Hari Ini**: Dialog *Ubah Tugas* kini menyediakan field *Hitungan Hari Ini* untuk mengoreksi hitungan harian secara langsung (termasuk ke `0`) dengan penyesuaian `totalCount` otomatis via delta.

---

## 🔧 Perbaikan Bug

- **Persistensi Mode Markdown Catatan Card**: Mode Markdown kini langsung tersimpan permanen ke model dan disk saat di-toggle, sehingga pratinjau Markdown tetap aktif saat dialog dibuka kembali.
- **Akurasi Perhitungan Persentase**: Sinkronisasi kalkulasi persentase antara bar chart History dan Card Checklist via `ChecklistCalculationHelper` (item dinonaktifkan dikecualikan dari perhitungan).
- **Backward Compatibility**: Skema JSON lama tetap terbaca aman tanpa error (`isHidden`, `isCollapsed`, `id`, `isDisabled` memiliki fallback default otomatis).
