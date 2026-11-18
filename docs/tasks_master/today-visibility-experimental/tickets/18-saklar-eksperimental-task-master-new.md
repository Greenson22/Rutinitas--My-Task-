# 18: Saklar eksperimental Task Master New

**What to build:** `task_master_new` diaktifkan lewat saklar runtime di Settings → Fitur Eksperimental, dengan default mati sehingga modul legacy dipakai. Pergantian modul tidak boleh menghilangkan riwayat, dan hanya satu modul yang menulis `my_tasks.json`.

**Blocked by:** 17 — Visibilitas Hari Ini per tugas (field baru harus sudah tersimpan sebelum penulis berganti); 15 — Parity QA dan switch navigasi.

**Status:** ready-for-agent

- [ ] `taskMasterUseNewModule` tidak lagi konstanta compile-time; nilainya dibaca dari SharedPreferences `task_master_use_new_module` (default `false`).
- [ ] `legacyWritesEnabled` diturunkan dari saklar runtime, bukan dari konstanta.
- [ ] `TaskMasterEntry` memilih layar berdasarkan saklar runtime dan menangani pembacaan preferensi yang asinkron tanpa kedipan berlebihan.
- [ ] Guard tulis modul legacy memakai nilai runtime; modul baru tidak menulis saat saklar mati, legacy tidak menulis saat saklar hidup.
- [ ] Settings → Fitur Eksperimental memiliki item **Task Master New** dengan badge/deskripsi eksperimental.
- [ ] Mengaktifkan saklar memunculkan dialog konfirmasi, menyimpan preferensi, dan memberi tahu bahwa restart diperlukan.
- [ ] Mematikan saklar memunculkan dialog peringatan tentang riwayat v2 dan keterbatasan modul lama.
- [ ] `TaskCategory` dan `TaskItem` legacy menyimpan serta menulis kembali field JSON tak dikenal (passthrough), termasuk `history`, `kind`, `sortOrder`, `todayVisibility`, dan `showInToday`.
- [ ] Dialog promo sekali-jalan tampil hanya bila saklar mati, file sudah `schemaVersion: 2`, dan `seen_task_master_new_promo` belum `true`.
- [ ] `docs/tasks_master/ROLLBACK.md` diperbarui: rollback lewat Settings, bukan build ulang.
- [ ] `docs/tasks_master/PARITY_QA.md` mencatat skenario ganti modul.
- [ ] Unit test passthrough legacy dan pembacaan preferensi.
- [ ] Widget test saklar Settings, dialog konfirmasi, dan dialog promo.
- [ ] Test regresi “satu penulis”: tidak ada dua modul menulis file pada satu waktu.
- [ ] `flutter analyze` tidak memunculkan issue baru dan seluruh test lulus.

---

## Catatan implementasi

_(diisi setelah tiket dikerjakan)_
