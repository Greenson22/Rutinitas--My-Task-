# 04: UI Card — Toggle Aktivasi & Badge DailyTracker

**What to build:** Pengguna dapat mengaktifkan atau menonaktifkan mode DailyTracker pada sebuah card `DailySubject` melalui popup menu card yang sudah ada di `ChecklistDetailScreen`. Ketika DailyTracker aktif, card menampilkan badge visual kecil (ikon kalender atau label "Daily") di area header card. Ketika nonaktif, card tampil identik dengan kondisi sebelum fitur ini ada — zero visual noise. Perubahan status disimpan langsung ke file JSON melalui `saveGroupData()`.

**Blocked by:** 01

**Status:** done

- [x] Popup menu card di `ChecklistDetailScreen` memiliki item baru: "Aktifkan DailyTracker" (jika `isDailyTrackerEnabled == false`) atau "Nonaktifkan DailyTracker" (jika `isDailyTrackerEnabled == true`).
- [x] Menekan item menu tersebut membalik nilai `isDailyTrackerEnabled` dan memanggil `saveGroupData()`.
- [x] Card dengan `isDailyTrackerEnabled == true` menampilkan badge penanda DailyTracker yang terlihat jelas di area header.
- [x] Card dengan `isDailyTrackerEnabled == false` tidak menampilkan badge atau elemen tambahan apapun.
- [x] Widget test: badge muncul di tree widget ketika `isDailyTrackerEnabled == true`.
- [x] Widget test: badge tidak ada di tree widget ketika `isDailyTrackerEnabled == false`.
- [x] Widget test: item menu "Aktifkan DailyTracker" muncul pada card yang nonaktif, dan sebaliknya.

---

## Catatan implementasi

**Tanggal & Waktu:** 23 November 2026, 23:40:00+08:00

### Ringkasan
Fitur UI Card untuk Toggle Aktivasi dan Badge DailyTracker telah diimplementasikan:
1. **Badge Visual di Header Card**:
   - Menambahkan badge penanda DailyTracker di sebelah nama subject (`subject.subjectName`) pada header card `InteractiveGridCard` di `ChecklistDetailScreen`.
   - Menggunakan ikon kalender kecil (`Icons.calendar_today_rounded`) dan label teks "Daily" dengan aksen tema `Colors.teal`.
   - Diberi key `Key('daily_tracker_badge')`.
   - Hanya muncul bila `subject.isDailyTrackerEnabled == true`. Ketika nonaktif, card bersih tanpa badge (zero visual noise).

2. **Toggle Aktivasi di Popup Menu Card**:
   - Menambahkan item menu baru di popup menu card (`InteractiveGridCard`):
     - Menampilkan "Aktifkan DailyTracker" dengan ikon `Icons.event_available_rounded` jika `isDailyTrackerEnabled == false`.
     - Menampilkan "Nonaktifkan DailyTracker" dengan ikon `Icons.event_busy_rounded` jika `isDailyTrackerEnabled == true`.
   - Menggunakan `Expanded` dan `TextOverflow.ellipsis` agar layout tidak overflow saat dirender dalam popup menu.
   - Saat diketuk (`TOGGLE_DAILY_TRACKER`), membalik nilai `subject.isDailyTrackerEnabled = !subject.isDailyTrackerEnabled` di dalam `setState` dan langsung memanggil `saveGroupData()`.

3. **Pengujian**:
   - Ditambahkan widget test di `test/features/checklist/presentation/checklist_card_ticket_04_test.dart`.
   - Memvalidasi kemunculan badge saat `isDailyTrackerEnabled == true`.
   - Memvalidasi ketiadaan badge saat `isDailyTrackerEnabled == false`.
   - Memvalidasi interaksi toggle dari popup menu card baik saat mengaktifkan maupun saat menonaktifkan status tracker.
   - Seluruh test (4/4 test tiket 04, 17/17 test modul checklist, dan 352/352 seluruh rangkaian test suite) lulus tanpa regresi.
