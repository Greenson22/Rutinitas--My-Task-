# 16: Hapus modul Task Master lama

**What to build:** Setelah Task Master New stabil dan menjadi navigasi utama, modul Task Master lama dihapus. Tidak ada referensi tersisa ke modul lama, dan seluruh fitur tetap berjalan melalui modul baru.

**Blocked by:** 15 — Parity QA dan switch navigasi

**Status:** ready-for-agent

- [ ] Tidak ada import atau referensi ke modul Task Master lama.
- [ ] Semua navigasi Task Master memakai modul baru.
- [ ] Pengaturan bersama tidak lagi bergantung pada modul lama.
- [ ] `flutter analyze` dan seluruh test lulus setelah penghapusan.
- [ ] Dokumentasi internal diperbarui agar tidak merujuk modul lama.
