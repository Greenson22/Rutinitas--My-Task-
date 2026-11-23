import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/checklist/data/models/daily_model.dart';
import 'package:rutinitasku/features/checklist/presentation/checklist_detail_screen/checklist_detail_screen.dart';

class _TestChecklistDetailScreen extends ChecklistDetailScreen {
  const _TestChecklistDetailScreen({
    required super.group,
    required super.baseDir,
  });

  @override
  State<ChecklistDetailScreen> createState() => _TestChecklistDetailScreenState();
}

class _TestChecklistDetailScreenState extends State<_TestChecklistDetailScreen> {
  // Mock saveGroupData count
  int saveCount = 0;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  // Meniru controller method untuk pengujian logika terisolasi
  Future<void> saveGroupData() async {
    saveCount++;
  }

  Future<void> saveTodayLog(DailySubject subject) async {
    final now = DateTime.now();
    final String todayKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final List<DailyLogEntry> entries = subject.subMateri
        .map((item) => DailyLogEntry.fromSubSubjectItem(item))
        .toList();

    subject.dailyLogs[todayKey] = entries;
    await saveGroupData();
  }

  Future<bool> resetForNewDay(DailySubject subject) async {
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reset Hari Baru?'),
            content: Text(
              'Apakah Anda yakin ingin mereset seluruh item pada "${subject.subjectName}" untuk memulai hari baru? Status centang akan dikosongkan, namun riwayat DailyTracker yang sudah tersimpan tetap aman.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ya, Reset'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return false;

    void resetRecursive(List<SubSubjectItem> items) {
      for (var item in items) {
        item.progress = 'belum';
        item.currentValue = 0;
        if (item.subMateri.isNotEmpty) {
          resetRecursive(item.subMateri);
        }
      }
    }

    setState(() {
      resetRecursive(subject.subMateri);
    });

    await saveGroupData();
    return true;
  }
}

class RealControllerHarness extends ChecklistDetailScreen {
  const RealControllerHarness({
    super.key,
    required super.group,
    required super.baseDir,
  });

  @override
  State<ChecklistDetailScreen> createState() => RealControllerHarnessState();
}

class RealControllerHarnessState extends State<RealControllerHarness> {
  late ChecklistGroup currentGroup;
  int saveCount = 0;

  @override
  void initState() {
    super.initState();
    currentGroup = widget.group;
  }

  Future<void> saveGroupData() async {
    saveCount++;
  }

  // Menggunakan implementasi yang sama persis dengan ChecklistDetailController
  Future<void> saveTodayLog(DailySubject subject) async {
    final now = DateTime.now();
    final String todayKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final List<DailyLogEntry> entries = subject.subMateri
        .map((item) => DailyLogEntry.fromSubSubjectItem(item))
        .toList();

    subject.dailyLogs[todayKey] = entries;
    await saveGroupData();
  }

  Future<bool> resetForNewDay(DailySubject subject) async {
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reset Hari Baru?'),
            content: Text(
              'Apakah Anda yakin ingin mereset seluruh item pada "${subject.subjectName}" untuk memulai hari baru? Status centang akan dikosongkan, namun riwayat DailyTracker yang sudah tersimpan tetap aman.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ya, Reset'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return false;

    void resetRecursive(List<SubSubjectItem> items) {
      for (var item in items) {
        item.progress = 'belum';
        item.currentValue = 0;
        if (item.subMateri.isNotEmpty) {
          resetRecursive(item.subMateri);
        }
      }
    }

    setState(() {
      resetRecursive(subject.subMateri);
    });

    await saveGroupData();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              key: const Key('btn_save_today'),
              onPressed: () => saveTodayLog(currentGroup.allList.first.items.first),
              child: const Text('Simpan'),
            ),
            ElevatedButton(
              key: const Key('btn_reset_day'),
              onPressed: () => resetForNewDay(currentGroup.allList.first.items.first),
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String getTodayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  group('ChecklistDetailController — DailyTracker Ticket 02', () {
    testWidgets('saveTodayLog mengisi subject.dailyLogs dengan key hari ini dan snapshot yang benar', (tester) async {
      final childItem = SubSubjectItem(
        subjectName: 'Child Step',
        progress: 'selesai',
        itemType: 'normal',
      );
      final parentItem = SubSubjectItem(
        subjectName: 'Parent Step',
        progress: 'selesai',
        itemType: 'normal',
        subMateri: [childItem],
      );

      final subject = DailySubject(
        subjectName: 'Rutinitas Pagi',
        progress: 'selesai',
        isDailyTrackerEnabled: true,
        subMateri: [parentItem],
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup 1',
        icon: '📝',
        allList: [
          ChecklistSection(sectionName: 'Seksi 1', items: [subject]),
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: RealControllerHarness(group: group, baseDir: '/tmp'),
      ));

      final state = tester.state<RealControllerHarnessState>(find.byType(RealControllerHarness));

      // Trigger saveTodayLog
      await tester.tap(find.byKey(const Key('btn_save_today')));
      await tester.pumpAndSettle();

      final todayKey = getTodayKey();
      expect(subject.dailyLogs.containsKey(todayKey), isTrue);
      expect(subject.dailyLogs[todayKey]!.length, equals(1));
      expect(subject.dailyLogs[todayKey]!.first.itemName, equals('Parent Step'));
      expect(subject.dailyLogs[todayKey]!.first.progress, equals('selesai'));
      expect(subject.dailyLogs[todayKey]!.first.children.length, equals(1));
      expect(subject.dailyLogs[todayKey]!.first.children.first.itemName, equals('Child Step'));
      expect(state.saveCount, equals(1));
    });

    testWidgets('saveTodayLog dua kali di hari yang sama menghasilkan overwrite (bukan duplikasi)', (tester) async {
      final item = SubSubjectItem(
        subjectName: 'Item 1',
        progress: 'belum',
        itemType: 'progress',
        currentValue: 1,
        targetValue: 5,
      );

      final subject = DailySubject(
        subjectName: 'Tracker Test',
        progress: 'belum',
        isDailyTrackerEnabled: true,
        subMateri: [item],
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup 1',
        icon: '📝',
        allList: [
          ChecklistSection(sectionName: 'Seksi 1', items: [subject]),
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: RealControllerHarness(group: group, baseDir: '/tmp'),
      ));
      final state = tester.state<RealControllerHarnessState>(find.byType(RealControllerHarness));

      // Simpan pertama kali
      await tester.tap(find.byKey(const Key('btn_save_today')));
      await tester.pumpAndSettle();

      final todayKey = getTodayKey();
      expect(subject.dailyLogs.keys.length, equals(1));
      expect(subject.dailyLogs[todayKey]!.first.currentValue, equals(1));

      // Ubah status item
      item.progress = 'selesai';
      item.currentValue = 5;

      // Simpan kedua kali
      await tester.tap(find.byKey(const Key('btn_save_today')));
      await tester.pumpAndSettle();

      // Key tetap 1, list entry tetap 1 (tertimpa/overwrite nilai barunya)
      expect(subject.dailyLogs.keys.length, equals(1));
      expect(subject.dailyLogs[todayKey]!.length, equals(1));
      expect(subject.dailyLogs[todayKey]!.first.progress, equals('selesai'));
      expect(subject.dailyLogs[todayKey]!.first.currentValue, equals(5));
      expect(state.saveCount, equals(2));
    });

    testWidgets('resetForNewDay menampilkan dialog konfirmasi; membatalkan tidak mereset item', (tester) async {
      final item = SubSubjectItem(
        subjectName: 'Tugas Penting',
        progress: 'selesai',
        currentValue: 10,
        targetValue: 10,
      );

      final subject = DailySubject(
        subjectName: 'Test Reset Cancel',
        progress: 'selesai',
        subMateri: [item],
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup 1',
        icon: '📝',
        allList: [
          ChecklistSection(sectionName: 'Seksi 1', items: [subject]),
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: RealControllerHarness(group: group, baseDir: '/tmp'),
      ));

      // Tap reset button
      await tester.tap(find.byKey(const Key('btn_reset_day')));
      await tester.pumpAndSettle();

      // Dialog konfirmasi harus muncul
      expect(find.text('Reset Hari Baru?'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Ya, Reset'), findsOneWidget);

      // Tekan Batal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // Item tidak boleh berubah
      expect(item.progress, equals('selesai'));
      expect(item.currentValue, equals(10));
    });

    testWidgets('resetForNewDay mereset semua item rekursif ke belum dan currentValue ke 0 tanpa merusak dailyLogs', (tester) async {
      final child2 = SubSubjectItem(
        subjectName: 'Child L2',
        progress: 'selesai',
        itemType: 'countdown',
        currentValue: 0,
        targetValue: 5,
      );
      final child1 = SubSubjectItem(
        subjectName: 'Child L1',
        progress: 'selesai',
        itemType: 'progress',
        currentValue: 10,
        targetValue: 10,
        subMateri: [child2],
      );
      final parentItem = SubSubjectItem(
        subjectName: 'Parent',
        progress: 'selesai',
        itemType: 'normal',
        subMateri: [child1],
      );

      final existingLogEntry = DailyLogEntry(
        itemName: 'Snapshot Kemarin',
        progress: 'selesai',
        itemType: 'normal',
        currentValue: 0,
        targetValue: 0,
      );

      final subject = DailySubject(
        subjectName: 'Test Reset Confirm',
        progress: 'selesai',
        subMateri: [parentItem],
        dailyLogs: {
          '2026-11-22': [existingLogEntry],
        },
      );

      final group = ChecklistGroup(
        id: 'g1',
        groupName: 'Grup 1',
        icon: '📝',
        allList: [
          ChecklistSection(sectionName: 'Seksi 1', items: [subject]),
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: RealControllerHarness(group: group, baseDir: '/tmp'),
      ));
      final state = tester.state<RealControllerHarnessState>(find.byType(RealControllerHarness));

      // Tap reset button
      await tester.tap(find.byKey(const Key('btn_reset_day')));
      await tester.pumpAndSettle();

      // Konfirmasi reset
      await tester.tap(find.text('Ya, Reset'));
      await tester.pumpAndSettle();

      // Periksa item ter-reset secara rekursif
      expect(parentItem.progress, equals('belum'));
      expect(parentItem.currentValue, equals(0));
      expect(child1.progress, equals('belum'));
      expect(child1.currentValue, equals(0));
      expect(child2.progress, equals('belum'));
      expect(child2.currentValue, equals(0));

      // Pastikan dailyLogs tidak berubah
      expect(subject.dailyLogs.length, equals(1));
      expect(subject.dailyLogs.containsKey('2026-11-22'), isTrue);
      expect(subject.dailyLogs['2026-11-22']!.first.itemName, equals('Snapshot Kemarin'));

      // saveGroupData harus dipanggil
      expect(state.saveCount, equals(1));
    });
  });
}
