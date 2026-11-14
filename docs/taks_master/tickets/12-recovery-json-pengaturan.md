# 12: Recovery, editor JSON advanced, dan pengaturan di modul baru

**What to build:** Pengguna mendapat alur pemulihan saat file tidak dapat dibaca: memasukkan PIN, memulihkan backup, atau membuat file baru dengan konfirmasi. Pengguna juga dapat membuka pengaturan folder/enkripsi dari modul baru dan mengedit raw JSON melalui area Advanced dengan validasi serta atomic write.

**Blocked by:** 01 — Pindahkan pengaturan folder dan enkripsi ke core; 02 — Fondasi Task Master New dengan migrasi dan tampilan baca-saja; 04 — Kelola tugas, jenis tugas, dan target

**Status:** ready-for-agent

- [ ] File yang gagal didekripsi menampilkan opsi memasukkan PIN.
- [ ] PIN yang benar membuka data dan menampilkan hasilnya.
- [ ] Opsi memulihkan backup tersedia dan berfungsi.
- [ ] Opsi membuat file baru meminta konfirmasi destruktif.
- [ ] Pengaturan folder dan enkripsi dapat dibuka dari modul baru tanpa ketergantungan ke modul lama.
- [ ] Raw JSON editor tersedia di area Advanced, bukan menu utama.
- [ ] Editor memvalidasi JSON sebelum menyimpan.
- [ ] Penyimpanan dari editor memakai atomic write dan menghormati enkripsi.
- [ ] Widget test recovery dan validasi editor JSON lulus.
