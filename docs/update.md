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

---

## 🔧 Perbaikan Bug

- **Persistensi Mode Markdown Catatan Card**: Mode Markdown kini langsung tersimpan permanen ke model dan disk saat di-toggle, sehingga pratinjau Markdown tetap aktif saat dialog dibuka kembali.
- **Akurasi Perhitungan Persentase**: Sinkronisasi kalkulasi persentase antara bar chart History dan Card Checklist via `ChecklistCalculationHelper` (item dinonaktifkan dikecualikan dari perhitungan).
- **Backward Compatibility**: Skema JSON lama tetap terbaca aman tanpa error (`isHidden`, `isCollapsed`, `id`, `isDisabled` memiliki fallback default otomatis).
