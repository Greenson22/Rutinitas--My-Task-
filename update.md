# Update Pembaruan UI/UX (2026-11-25)

- **Checklist Groups (`DailyController` & `DailyScreen`)**:
  - Menambahkan fitur collapse per-seksi (ketuk header untuk melipat/membuka card dengan ikon chevron).
  - Menambahkan tombol sembunyi seksi di edit mode header (ikon mata + badge *Tersembunyi*), bersifat ephemeral per sesi.
  - Menambahkan pengaturan *Checklist Groups: Tutup seksi secara default* di `SettingsDialog`.
- **Checklist Detail (`ChecklistControlPanel`)**:
  - Mengubah opsi *Pindah Seksi* menjadi lazy-expand dengan animasi `AnimatedSize` (200 ms), memfilter seksi aktif saat ini, dan menutup picker setelah pemilihan.
- **Task Master New**:
  - Memberi latar belakang hijau muda (`#E8F5E9`) pada `TodayTaskTile` yang target hariannya sudah tercapai.
  - Mengubah kartu dashboard *Target tercapai* menjadi format `X / Y` dengan warna dinamis (hijau jika semua selesai, oranye jika belum/kosong).
