# 20: Tawaran sekali-jalan mengaktifkan Task Master New

**What to build:** Pengguna yang pernah memakai Task Master New dan kini memakai modul lama ditawari sekali untuk mengaktifkannya kembali saat membuka Task Master. Tawaran tidak mengganggu pengguna baru dan tidak muncul lagi setelah dijawab.

**Blocked by:** 19 — Saklar eksperimental Task Master New dan satu penulis.

**Status:** ready-for-agent

- [ ] Dialog tawaran muncul hanya bila ketiga syarat terpenuhi bersamaan: saklar `task_master_use_new_module` mati, file data sudah berformat v2, dan `seen_task_master_new_promo` belum `true`.
- [ ] Dialog muncul saat Task Master dibuka, bukan saat aplikasi pertama diluncurkan.
- [ ] Dialog berisi penjelasan singkat dan dua aksi: **Aktifkan Sekarang** dan **Nanti**.
- [ ] **Aktifkan Sekarang** menulis saklar `task_master_use_new_module = true` dan menampilkan instruksi restart.
- [ ] **Nanti** tidak mengubah saklar.
- [ ] Kedua aksi menulis `seen_task_master_new_promo = true`, sehingga dialog tidak muncul lagi.
- [ ] Dialog tidak muncul untuk pengguna baru yang belum punya file v2.
- [ ] Dialog tidak muncul saat saklar sudah hidup.
- [ ] Preferensi tawaran bertahan setelah restart.
- [ ] Widget test: dialog muncul pada kondisi yang tepat, tidak muncul pada tiga kondisi yang tidak tepat, dan tidak muncul lagi setelah salah satu aksi dipilih.
- [ ] `flutter analyze` tidak memunculkan issue baru dan seluruh test lulus.

---

## Catatan implementasi

_(diisi setelah tiket dikerjakan)_
