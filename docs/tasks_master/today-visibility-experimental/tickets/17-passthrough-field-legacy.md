# 17: Passthrough field tak dikenal di model legacy

**What to build:** Modul Task Master lama tidak lagi menghapus data yang tidak dikenalnya saat menyimpan. Semua key JSON yang tidak dipahami model kategori dan tugas disimpan lalu ditulis kembali apa adanya, sehingga riwayat harian, jenis tugas, urutan, dan pengaturan tampil tetap utuh ketika pengguna memakai modul lama.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] Kategori lama menyimpan seluruh key JSON yang tidak dikenalnya dan menuliskannya kembali saat menyimpan.
- [ ] Tugas lama menyimpan seluruh key JSON yang tidak dikenalnya dan menuliskannya kembali saat menyimpan.
- [ ] Passthrough hanya menyalin key; nilai tidak diubah, dikonversi, atau diurutkan ulang.
- [ ] Key yang dikenali model lama tetap ditulis dari field model, bukan dari salinan mentah, sehingga perubahan yang dilakukan pengguna tidak tertimpa.
- [ ] Field `history`, `kind`, `sortOrder`, `todayVisibility`, dan `showInToday` bertahan setelah simpan-muat-simpan berulang.
- [ ] Field tak dikenal pada kategori dan tugas tidak saling bercampur.
- [ ] File lama tanpa field tambahan tetap menghasilkan JSON yang setara saat disimpan.
- [ ] Unit test round-trip: JSON dengan key tak dikenal → model lama → JSON, isinya sama.
- [ ] Unit test regresi: mengubah field yang dikenali (mis. nama atau hitungan) tidak menghapus key tak dikenal.
- [ ] `flutter analyze` tidak memunculkan issue baru dan seluruh test lulus.

---

## Catatan implementasi

_(diisi setelah tiket dikerjakan)_
