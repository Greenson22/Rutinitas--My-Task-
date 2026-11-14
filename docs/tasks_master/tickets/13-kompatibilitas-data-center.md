# 13: Kompatibilitas Data Center dan migrasi saat import

**What to build:** Data Task Master New dapat diekspor dan diimpor melalui Data Center. Import file legacy tetap masuk dan dimigrasi saat dibuka, import file v2 memulihkan data dengan benar, dan hasil export/import round-trip tidak kehilangan data.

**Blocked by:** 02 — Fondasi Task Master New dengan migrasi dan tampilan baca-saja

**Status:** ready-for-agent

- [ ] Export Task Master New menghasilkan file yang dapat dibaca kembali.
- [ ] Import file legacy berhasil dan data dimigrasi saat dibuka.
- [ ] Import file v2 memulihkan kategori, tugas, target, status aktif, dan riwayat.
- [ ] Round-trip export lalu import menghasilkan data yang setara.
- [ ] Import tidak merusak data lama jika file yang diimpor tidak valid.
- [ ] Tidak ada perubahan perilaku Data Center di luar kompatibilitas file Task Master.
- [ ] Contract test round-trip dan migrasi hasil import lulus.
