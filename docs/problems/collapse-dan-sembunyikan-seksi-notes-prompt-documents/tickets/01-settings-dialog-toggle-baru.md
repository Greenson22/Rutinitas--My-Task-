# 01: Settings Dialog — dua toggle collapse global

**What to build:** Dua switch baru muncul di Settings Dialog di bawah bagian "Tampilan Checklist" yang sudah ada, dalam section baru bernama "Tampilan Sections (Notes, Prompt, Dokumen)". Switch pertama ("Tutup seksi secara default") menyimpan key `sections_default_collapsed`. Switch kedua ("Ingat status lipatan seksi") menyimpan key `sections_remember_collapse_state`. Kedua switch membaca nilai dari SharedPreferences saat dialog dibuka. Mengubah salah satu switch tidak mengubah key checklist yang sudah ada (`section_default_collapsed`, `section_remember_collapse_state`, `checklist_groups_default_collapsed`).

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] Section baru "Tampilan Sections (Notes, Prompt, Dokumen)" muncul di Settings Dialog di bawah section "Tampilan Checklist".
- [ ] Switch "Tutup seksi secara default" menampilkan nilai `sections_default_collapsed` dari SharedPreferences (default: `false`).
- [ ] Tap switch "Tutup seksi secara default" menyimpan nilai baru ke key `sections_default_collapsed`.
- [ ] Switch "Ingat status lipatan seksi" menampilkan nilai `sections_remember_collapse_state` dari SharedPreferences (default: `true`).
- [ ] Tap switch "Ingat status lipatan seksi" menyimpan nilai baru ke key `sections_remember_collapse_state`.
- [ ] Mengubah kedua switch baru tidak mengubah nilai `section_default_collapsed`, `section_remember_collapse_state`, atau `checklist_groups_default_collapsed`.
- [ ] Widget test: toggle "Tutup seksi secara default" → `sections_default_collapsed` berubah, key checklist lama tidak berubah.
- [ ] Widget test: toggle "Ingat status lipatan seksi" → `sections_remember_collapse_state` berubah, key checklist lama tidak berubah.
- [ ] `flutter analyze` tidak memunculkan issue baru dan seluruh test lulus.
