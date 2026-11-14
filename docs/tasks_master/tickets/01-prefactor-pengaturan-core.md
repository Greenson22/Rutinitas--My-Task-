# 01: Pindahkan pengaturan folder dan enkripsi ke core

**What to build:** Pengaturan folder dan enkripsi yang saat ini dipakai lintas fitur dipindahkan ke area core, sehingga Task Master New dapat membuka pengaturan tanpa bergantung pada modul Task Master lama. Perilaku pengaturan tidak berubah bagi pengguna.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Pengaturan folder, enkripsi, dan fitur eksperimental tetap dapat dibuka dari menu yang sudah ada.
- [x] Tidak ada lagi ketergantungan pengaturan dari fitur lain ke modul Task Master lama.
- [x] Perilaku enkripsi dan pemilihan folder tidak berubah.
- [x] `flutter analyze` bersih setelah pemindahan.

> Catatan: `flutter analyze` untuk seluruh proyek masih melaporkan issue lama di modul lain yang sudah ada sebelum pemindahan. Perubahan ini tidak menambah issue baru, dan file pengaturan yang dipindahkan bersih dari issue analyzer.
