# 19: Konsolidasi Pengaturan Task Master New ke sidebar

**What to build:** Entri “Pengaturan folder & enkripsi” dihapus dari sheet Advanced `task_master_new`. Settings hanya dibuka dari sidebar/drawer, sehingga tidak ada dua jalur pengaturan.

**Blocked by:** Tidak ada.

**Status:** ready-for-agent

- [ ] `TaskMasterAdvancedSheet` hanya berisi item “Editor JSON mentah”.
- [ ] Callback `onOpenSettings` dihapus dari sheet dan pemanggilnya.
- [ ] `_AdvancedAction.settings` dan `_openSettings()` dihapus bila tidak dipakai jalur lain.
- [ ] Dependensi `StorageService` pada `TaskMasterNewScreen` dihapus bila tidak lagi diperlukan.
- [ ] Settings tetap dapat dibuka dari `DrawerMenu` dan tetap menampilkan opsi folder serta enkripsi.
- [ ] Dialog Settings legacy tidak diubah dan tetap berfungsi saat modul lama aktif.
- [ ] Widget test: sheet Advanced hanya memiliki satu tile dan tidak ada tombol/jalur Settings di layar Task Master New.
- [ ] Tidak ada import `SettingsDialog` yang tersisa di `features/task_master_new` kecuali memang dibutuhkan.
- [ ] `flutter analyze` tidak memunculkan issue baru dan seluruh test lulus.

---

## Catatan implementasi

_(diisi setelah tiket dikerjakan)_
