# 03: Kelola kategori dengan identitas stabil

**What to build:** Pengguna dapat menambah, mengedit, menyembunyikan, dan menghapus kategori. Rename kategori tidak memutus tugas di dalamnya karena kategori memakai `id` stabil. Daftar kategori dan tampilan dashboard langsung mencerminkan perubahan.

**Blocked by:** 02 — Fondasi Task Master New dengan migrasi dan tampilan baca-saja

**Status:** ready-for-agent

- [ ] Pengguna dapat menambah kategori dengan nama dan ikon emoji.
- [ ] Pengguna dapat mengedit nama dan ikon tanpa mengubah `id` kategori.
- [ ] Rename kategori tidak memutus atau menghilangkan tugas di dalamnya.
- [ ] Nama kategori duplikat ditolak atau meminta konfirmasi yang jelas.
- [ ] Pengguna dapat menyembunyikan dan menampilkan kembali kategori.
- [ ] Penghapusan kategori meminta konfirmasi dan memberi peringatan jika masih memiliki tugas.
- [ ] Semua perubahan bertahan setelah aplikasi ditutup dan dibuka kembali.
- [ ] Widget test untuk tambah, edit, rename, sembunyikan, dan hapus kategori lulus.
