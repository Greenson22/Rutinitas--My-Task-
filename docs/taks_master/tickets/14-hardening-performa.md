# 14: Hardening performa data besar dan kegagalan simpan

**What to build:** Task Master New tetap responsif saat pengguna memiliki sekitar 1.000 tugas. Pemuatan, pencarian, dan increment memenuhi target performa. Jika penyimpanan gagal, pengguna mendapat banner “Perubahan belum tersimpan” dengan opsi coba lagi, tanpa kehilangan state di layar.

**Blocked by:** 08 — Dashboard “Hari Ini” dan ringkasan; 09 — Pencarian dan filter

**Status:** ready-for-agent

- [ ] Data 1.000 tugas dimuat di bawah 500 ms pada perangkat Android kelas menengah.
- [ ] Pencarian 1.000 tugas selesai di bawah 100 ms setelah input.
- [ ] Perubahan UI setelah increment terjadi di bawah 100 ms.
- [ ] Penulisan file tidak memblokir frame render.
- [ ] Operasi tulis diserialisasi sehingga tidak ada dua penulisan bersamaan.
- [ ] Penyimpanan gagal menampilkan banner dengan opsi coba lagi.
- [ ] State di layar tetap tersedia saat penyimpanan gagal.
- [ ] Ada bukti pengukuran performa untuk data besar.
