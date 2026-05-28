// lib/features/task_master/presentation/screens/home_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/models/task_model.dart';
import '../../../jurnal_aktivitas/data/models/time_log_model.dart'; // <--- IMPORT BARU MODEL JURNAL
import '../widgets/category_card.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/tasks_dialog.dart';
import '../widgets/add_category_dialog.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  List<TaskCategory> _visibleCategories = [];
  List<TaskCategory> _hiddenCategories = [];
  List<TaskCategory> _allCategoriesRaw = [];
  String _selectedBaseDir = 'Documents';
  String _fullJsonPath = '';
  bool _isLoading = true;

  bool _isSortedAZ = false;
  bool _showHiddenSection = false;

  @override
  void initState() {
    super.initState();
    _initStorageAndLoadData();
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> _initStorageAndLoadData() async {
    setState(() => _isLoading = true);
    try {
      _selectedBaseDir = await _storageService.getBaseDirSetting();
      File jsonFile = await _storageService.getTargetJsonFile(_selectedBaseDir);
      _fullJsonPath = jsonFile.path;

      String jsonString = await _storageService.loadOrInitializeJson(jsonFile);
      final Map<String, dynamic> parsedMap = jsonDecode(jsonString);
      final List<dynamic> catList = parsedMap['categories'] ?? [];

      List<TaskCategory> loadedCategories = catList
          .map((json) => TaskCategory.fromJson(json))
          .toList();

      String todayStr = _getTodayDateString();
      bool isDataChanged = false;

      for (var category in loadedCategories) {
        for (var task in category.tasks) {
          if (task.date != todayStr && task.countToday > 0) {
            task.countToday = 0;
            isDataChanged = true;
          }
        }
      }

      _allCategoriesRaw = loadedCategories;

      if (isDataChanged) {
        await _saveAllCategoriesToFile(shouldRefresh: false);
      }

      _processCategoriesDisplay();
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error loading data: $e");
    }
  }

  void _processCategoriesDisplay() {
    List<TaskCategory> visible = _allCategoriesRaw
        .where((cat) => !cat.isHidden)
        .toList();
    List<TaskCategory> hidden = _allCategoriesRaw
        .where((cat) => cat.isHidden)
        .toList();

    if (_isSortedAZ) {
      visible.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      hidden.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    }

    setState(() {
      _visibleCategories = visible;
      _hiddenCategories = hidden;
      _isLoading = false;
    });
  }

  void _moveCategoryOrder(
    List<TaskCategory> targetSubList,
    int currentIndex,
    int direction,
  ) async {
    int newIndex = currentIndex + direction;
    if (newIndex < 0 || newIndex >= targetSubList.length) return;

    final itemA = targetSubList[currentIndex];
    final itemB = targetSubList[newIndex];

    int rawIdxA = _allCategoriesRaw.indexWhere((cat) => cat.name == itemA.name);
    int rawIdxB = _allCategoriesRaw.indexWhere((cat) => cat.name == itemB.name);

    if (rawIdxA != -1 && rawIdxB != -1) {
      setState(() {
        final temp = _allCategoriesRaw[rawIdxA];
        _allCategoriesRaw[rawIdxA] = _allCategoriesRaw[rawIdxB];
        _allCategoriesRaw[rawIdxB] = temp;
      });

      await _saveAllCategoriesToFile(shouldRefresh: false);
      _processCategoriesDisplay();
    }
  }

  void _toggleSortOrder() {
    setState(() {
      _isSortedAZ = !_isSortedAZ;
    });
    _processCategoriesDisplay();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSortedAZ
              ? 'Kategori diurutkan A-Z (Urutan manual dinonaktifkan)'
              : 'Kembali ke Urutan Manual',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _toggleCategoryVisibility(TaskCategory category) async {
    int index = _allCategoriesRaw.indexWhere(
      (cat) => cat.name == category.name,
    );
    if (index != -1) {
      setState(() {
        _allCategoriesRaw[index].isHidden = !_allCategoriesRaw[index].isHidden;
      });
      await _saveAllCategoriesToFile(shouldRefresh: false);
      _processCategoriesDisplay();
    }
  }

  Future<void> _addNewCategory(String name, String icon) async {
    final newCategory = TaskCategory(
      name: name,
      icon: icon,
      isHidden: false,
      tasks: [],
    );
    _allCategoriesRaw.add(newCategory);
    await _saveAllCategoriesToFile();
  }

  Future<void> _updateUbuntuStorage(String newDir) async {
    await _storageService.saveBaseDirSetting(newDir);
    _initStorageAndLoadData();
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        currentBaseDir: _selectedBaseDir,
        onSave: (newDir) {
          _updateUbuntuStorage(newDir);
        },
      ),
    );
  }

  // === MODIFIKASI: FUNGSI INCREMENT TASK MENJALANKAN FUNGSI PENAMBAH JURNAL ===
  Future<bool> _incrementTaskCount(TaskItem task) async {
    setState(() {
      task.count += 1;
      task.countToday += 1;
      task.date = _getTodayDateString();
    });
    await _saveAllCategoriesToFile(shouldRefresh: false);

    // Panggil fungsi penambahan waktu 30 menit ke Jurnal Aktivitas
    await _add30MinutesToJurnal(task.id);

    return true;
  }

  // === FITUR BARU: MENGHUBUNGKAN DAN MENAMBAH 30 MENIT KE JURNAL ===
  Future<void> _add30MinutesToJurnal(String myTaskId) async {
    try {
      final File jurnalFile = await _storageService.getJurnalJsonFile(
        _selectedBaseDir,
      );
      String jsonString = await _storageService.loadOrInitializeJurnalJson(
        jurnalFile,
      );
      List<dynamic> decodedJson = jsonDecode(jsonString);

      List<TimeLogEntry> loadedLogs = decodedJson
          .map((e) => TimeLogEntry.fromJson(e))
          .toList();

      final String todayStr = _getTodayDateString();
      bool hasTodayLog = loadedLogs.any((entry) => entry.tanggal == todayStr);

      // 1. Jika belum ada log hari ini, otomatis salin dari hari terakhir seperti di jurnal_aktivitas_screen
      if (!hasTodayLog && loadedLogs.isNotEmpty) {
        final lastLog = loadedLogs.last;
        List<TimeLogTask> copiedTasks = lastLog.tasks.map((task) {
          return TimeLogTask(
            id: task.id,
            nama: task.nama,
            durasiMenit: 0,
            kategori: task.kategori,
            linkedTaskIds: task.linkedTaskIds,
          );
        }).toList();
        loadedLogs.add(TimeLogEntry(tanggal: todayStr, tasks: copiedTasks));
      } else if (loadedLogs.isEmpty) {
        loadedLogs.add(TimeLogEntry(tanggal: todayStr, tasks: []));
      }

      // 2. Cari entry hari ini
      int todayIndex = loadedLogs.indexWhere(
        (entry) => entry.tanggal == todayStr,
      );
      if (todayIndex != -1) {
        bool isUpdated = false;
        String updatedJurnalTaskName = "";

        for (var logTask in loadedLogs[todayIndex].tasks) {
          // Jika array linkedTaskIds memiliki id tugas dari my_tasks
          if (logTask.linkedTaskIds.contains(myTaskId)) {
            logTask.durasiMenit += 30;
            isUpdated = true;
            updatedJurnalTaskName = logTask.nama;
            break; // Jika sudah ketemu, langsung break asumsikan 1 ID hanya nempel ke 1 logTask.
          }
        }

        // 3. Jika ada kecocokan, simpan ulang jurnalnya
        if (isUpdated) {
          final String updatedJsonContent = jsonEncode(
            loadedLogs.map((e) => e.toJson()).toList(),
          );
          await _storageService.saveJsonData(jurnalFile, updatedJsonContent);

          // Tampilkan notifikasi keberhasilan di layar My Tasks
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '⏱ Terhubung! "$updatedJurnalTaskName" di Jurnal +30 menit.',
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.teal[800],
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error updating linked jurnal data: $e");
    }
  }

  void _showCategoryTasksDialog(TaskCategory category) {
    showDialog(
      context: context,
      builder: (context) => TasksDialog(
        category: category,
        onIncrementTask: (task) => _incrementTaskCount(task),
        onUpdateTargetToday: (task, target) {},
        onEditTaskDetail: (task, name, c, ct, tc, tct, d, active) async {
          setState(() {
            task.name = name;
            task.count = c;
            task.countToday = ct;
            task.targetCount = tc;
            task.targetCountToday = tct;
            task.date = d;
            task.isActive = active;
          });
          await _saveAllCategoriesToFile();
        },
        onDeleteTask: (task) async {
          setState(() {
            category.tasks.removeWhere((t) => t.id == task.id);
          });
          // TAMBAHKAN baris auto-save ini agar perubahan tersimpan ke file JSON lokal:
          await _saveAllCategoriesToFile(shouldRefresh: false);
          return true;
        },
        onBulkAction: (tasksToUpdate, action) async {
          setState(() {
            if (action == 'delete') {
              category.tasks.removeWhere((t) => tasksToUpdate.contains(t.id));
            } else if (action == 'activate') {
              for (var t in category.tasks) {
                if (tasksToUpdate.contains(t.id)) t.isActive = true;
              }
            } else if (action == 'deactivate') {
              for (var t in category.tasks) {
                if (tasksToUpdate.contains(t.id)) t.isActive = false;
              }
            }
          });
          await _saveAllCategoriesToFile();
        },
        onAddTask: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Membuka menu tambah tugas untuk Kategori ${category.name}',
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddCategoryDialog(onSave: _addNewCategory),
    );
  }

  // lib/features/task_master/presentation/screens/home_screen.dart

  Future<void> _deleteCategory(TaskCategory category) async {
    // 1. Tampilkan dialog konfirmasi terlebih dahulu
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus Kategori?'),
            content: Text(
              'Apakah Anda yakin ingin menghapus kategori "${category.name}" beserta seluruh tugas di dalamnya secara permanen?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;

    // 2. Jika pengguna memilih Ya/Konfirmasi, hapus dari list utama dan simpan ke file
    if (confirm) {
      setState(() {
        _allCategoriesRaw.removeWhere((cat) => cat.name == category.name);
      });
      await _saveAllCategoriesToFile(); // Otomatis menyimpan perubahan ke JSON lokal
    }
  }

  Widget _buildCategoryGrid(
    List<TaskCategory> categoriesList,
    BoxConstraints constraints,
  ) {
    int crossAxisCount = 2;
    if (constraints.maxWidth >= 1200) {
      crossAxisCount = 5;
    } else if (constraints.maxWidth >= 900) {
      crossAxisCount = 4;
    } else if (constraints.maxWidth >= 600) {
      crossAxisCount = 3;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categoriesList.length,
      itemBuilder: (context, index) {
        final category = categoriesList[index];
        return CategoryCard(
          category: category,
          onTap: () => _showCategoryTasksDialog(category),
          onEdit: () {},
          onDelete: () => _deleteCategory(category),
          onToggleVisibility: () => _toggleCategoryVisibility(category),
          onMoveUp: !_isSortedAZ && index > 0
              ? () => _moveCategoryOrder(categoriesList, index, -1)
              : null,
          onMoveDown: !_isSortedAZ && index < categoriesList.length - 1
              ? () => _moveCategoryOrder(categoriesList, index, 1)
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Task Master'),
        backgroundColor: Colors.indigo[700],
        actions: [
          IconButton(
            icon: Icon(
              _showHiddenSection ? Icons.visibility : Icons.visibility_off,
            ),
            tooltip: _showHiddenSection
                ? 'Sembunyikan Sesi Tersembunyi'
                : 'Tampilkan Sesi Tersembunyi',
            onPressed: () {
              setState(() {
                _showHiddenSection = !_showHiddenSection;
              });
            },
          ),
          IconButton(
            icon: Icon(_isSortedAZ ? Icons.sort_by_alpha : Icons.unfold_more),
            tooltip: 'Ganti Mode Urutan (Manual / A-Z)',
            onPressed: _toggleSortOrder,
          ),
        ],
      ),
      drawer: const DrawerMenu(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
                  children: [
                    if (!_isLoading && _allCategoriesRaw.isNotEmpty)
                      _buildSummaryHeader(),

                    if (_visibleCategories.isNotEmpty)
                      _buildCategoryGrid(_visibleCategories, constraints),

                    if (_visibleCategories.isEmpty && _hiddenCategories.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: Text('Tidak ada kategori.')),
                      ),

                    if (_hiddenCategories.isNotEmpty && _showHiddenSection) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Divider(thickness: 2, color: Colors.grey),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.visibility_off_outlined,
                              color: Colors.blueGrey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Kategori yang disembunyikan (${_hiddenCategories.length})',
                              style: const TextStyle(
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildCategoryGrid(_hiddenCategories, constraints),
                    ],
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    int totalCategories = _allCategoriesRaw.length;
    int visibleCategoriesCount = _visibleCategories.length;

    int totalTasks = 0;
    int completedTasksToday = 0;
    int tasksWithTargetToday = 0;

    for (var category in _allCategoriesRaw) {
      for (var task in category.tasks) {
        if (task.isActive) {
          totalTasks++;
          if (task.targetCountToday > 0) {
            tasksWithTargetToday++;
            if (task.countToday >= task.targetCountToday) {
              completedTasksToday++;
            }
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 16, 12, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard_customize,
                color: Colors.indigo[700],
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Ringkasan Tugas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[900],
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kategori',
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$visibleCategoriesCount Active',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total: $totalCategories',
                        style: TextStyle(color: Colors.blue[700], fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Tugas',
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalTasks Unit',
                        style: TextStyle(
                          color: Colors.amber[900],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Di semua kategori',
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selesai Hari Ini',
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedTasksToday / $tasksWithTargetToday',
                        style: TextStyle(
                          color: Colors.green[900],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Target harian tercapai',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveAllCategoriesToFile({bool shouldRefresh = true}) async {
    final Map<String, dynamic> updatedMap = {
      'categories': _allCategoriesRaw.map((cat) => cat.toJson()).toList(),
    };
    final String updatedJsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(updatedMap);

    try {
      File jsonFile = await _storageService.getTargetJsonFile(_selectedBaseDir);
      await _storageService.saveJsonData(jsonFile, updatedJsonString);
      if (shouldRefresh) {
        _initStorageAndLoadData();
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }
}
