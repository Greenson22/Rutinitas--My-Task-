# 01: Pindahkan pengaturan folder dan enkripsi ke core

**What to build:** Pengaturan folder dan enkripsi yang saat ini dipakai lintas fitur dipindahkan ke area core, sehingga Task Master New dapat membuka pengaturan tanpa bergantung pada modul Task Master lama. Perilaku pengaturan tidak berubah bagi pengguna.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Pengaturan folder, enkripsi, dan fitur eksperimental tetap dapat dibuka dari menu yang sudah ada.
- [ ] Tidak ada lagi ketergantungan pengaturan dari fitur lain ke modul Task Master lama.
- [ ] Perilaku enkripsi dan pemilihan folder tidak berubah.
- [ ] `flutter analyze` bersih setelah pemindahan.
