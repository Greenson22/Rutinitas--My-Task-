# 16: Hapus modul Task Master lama

**What to build:** Setelah Task Master New stabil dan menjadi navigasi utama, modul Task Master lama dihapus. Tidak ada referensi tersisa ke modul lama, dan seluruh fitur tetap berjalan melalui modul baru.

**Blocked by:** 15 — Parity QA dan switch navigasi

**Status:** deferred

> **Ditunda pada 18 November 2026.** Modul lama kembali menjadi fallback aktif karena Task Master New dipindah ke Fitur Eksperimental (default mati). Lihat `docs/tasks_master/today-visibility-experimental/PRD.md`. Tiket ini baru relevan setelah modul baru stabil dan dijadikan default kembali.

- [ ] Tidak ada import atau referensi ke modul Task Master lama.
- [ ] Semua navigasi Task Master memakai modul baru.
- [ ] Pengaturan bersama tidak lagi bergantung pada modul lama.
- [ ] `flutter analyze` dan seluruh test lulus setelah penghapusan.
- [ ] Dokumentasi internal diperbarui agar tidak merujuk modul lama.
