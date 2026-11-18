# 21: Satu pintu pengaturan di Advanced Task Master New

**What to build:** Entri “Pengaturan folder & enkripsi” dihapus dari sheet Advanced `task_master_new`. Settings hanya dibuka dari sidebar/drawer, sehingga tidak ada dua jalur pengaturan.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] `TaskMasterAdvancedSheet` hanya berisi item “Editor JSON mentah”.
- [ ] Callback `onOpenSettings` dihapus dari sheet dan pemanggilnya.
- [ ] Aksi `settings` pada alur Advanced dan fungsi pembuka Settings di layar baru dihapus.
- [ ] Dependensi layanan penyimpanan pada layar Task Master New dihapus bila tidak lagi dipakai jalur lain.
- [ ] Settings tetap dapat dibuka dari `DrawerMenu` dan tetap menampilkan opsi folder serta enkripsi.
- [ ] Dialog Settings modul lama tidak diubah dan tetap berfungsi saat modul lama aktif.
- [ ] Tidak ada jalur Settings kedua di layar Task Master New, baik di mobile maupun desktop.
- [ ] Widget test: sheet Advanced hanya memiliki satu tile, dan tidak ada aksi yang membuka Settings dari layar Task Master New.
- [ ] Tidak ada import dialog Settings yang tersisa di modul baru bila tidak lagi dibutuhkan.
- [ ] `flutter analyze` tidak memunculkan issue baru dan seluruh test lulus.

---

## Catatan implementasi

_(diisi setelah tiket dikerjakan)_
