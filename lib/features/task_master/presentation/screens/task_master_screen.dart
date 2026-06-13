import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rutinitasku/core/presentation/widgets/base_detail_app_bar.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/models/task_model.dart';
import '../../../jurnal_aktivitas/data/models/time_log_model.dart';
import '../widgets/category_card.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/tasks_dialog.dart';
import '../widgets/add_category_dialog.dart';
import '../../../../core/presentation/widgets/universal_empty_state.dart'; // <-- DIUBAH: Menggunakan Universal Widget dari Core
import 'package:intl/intl.dart';
// Perlu dipastikan CryptoHelper sudah di-import.
// Sesuaikan path import di bawah ini jika lokasi CryptoHelper Anda berbeda.
import '../../../../core/utils/crypto_helper.dart';

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
  bool _isPageEditMode = false;
  bool _showHiddenSection = false;

  // STATE: Manajemen Kontrol BaseDetailAppBar
  bool _internalSearchMode = false;
  late TextEditingController _searchController;
  String _searchQuery = '';

  // STATE BARU: Menyimpan total durasi riil dari jurnal aktivitas hari ini
  String _totalJurnalDurationString = "0j";

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initStorageAndLoadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // METHOD BARU: Membaca berkas jurnal dan menghitung total durasi hari ini
  Future<void> _kalkulasiTotalJurnalHariIni() async {
    try {
      File fileJurnal = await _storageService.getJurnalJsonFile(
        _selectedBaseDir,
      );

      if (await fileJurnal.exists()) {
        String jsonString = await fileJurnal.readAsString();

        // --- LOGIKA DEKRIPSI UNTUK KALKULASI JURNAL ---
        bool isEncrypted = await _storageService.isEncryptionEnabled();
        String? password = await _storageService.getEncryptionPassword();

        if (isEncrypted &&
            password != null &&
            !jsonString.trim().startsWith('[')) {
          jsonString = CryptoHelper.decrypt(jsonString, password);
        }
        // ----------------------------------------------

        if (jsonString.trim().isNotEmpty) {
          List<dynamic> decodedJson = jsonDecode(jsonString);
          List<TimeLogEntry> logs = decodedJson
              .map((e) => TimeLogEntry.fromJson(e))
              .toList();

          String todayStr = _getTodayDateString();
          final int todayLogIndex = logs.indexWhere(
            (entry) => entry.tanggal == todayStr,
          );

          if (todayLogIndex != -1) {
            final List<TimeLogTask> todayTasks = logs[todayLogIndex].tasks;

            // Agregasi seluruh properti durasiMenit pada hari ini
            int totalMenit = todayTasks.fold(
              0,
              (sum, task) => sum + task.durasiMenit,
            );

            int jam = totalMenit ~/ 60;
            int menit = totalMenit % 60;

            if (mounted) {
              setState(() {
                _totalJurnalDurationString = menit > 0
                    ? '${jam}j ${menit}m'
                    : '${jam}j';
              });
            }
            return;
          }
        }
      }
      if (mounted) {
        setState(() {
          _totalJurnalDurationString = "0j";
        });
      }
    } catch (e) {
      debugPrint("Gagal mengkalkulasi total jurnal hari ini: $e");
    }
  }

  Future<void> _initStorageAndLoadData() async {
    setState(() => _isLoading = true);
    try {
      _selectedBaseDir = await _storageService.getBaseDirSetting();
      File jsonFile = await _storageService.getTargetJsonFile(_selectedBaseDir);
      _fullJsonPath = jsonFile.path;
      String jsonString = await _storageService.loadOrInitializeJson(jsonFile);

      // --- LOGIKA DEKRIPSI UNTUK DATA TASK MASTER ---
      bool isEncrypted = await _storageService.isEncryptionEnabled();
      String? password = await _storageService.getEncryptionPassword();

      if (isEncrypted &&
          password != null &&
          !jsonString.trim().startsWith('{')) {
        jsonString = CryptoHelper.decrypt(jsonString, password);
      }
      // ----------------------------------------------

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

      // Ambil data dari jurnal aktivitas setelah struktur kategori siap
      await _kalkulasiTotalJurnalHariIni();
      _processCategoriesDisplay();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint("Error loading data: $e");
    }
  }

  void _processCategoriesDisplay() {
    final filteredCategories = _allCategoriesRaw.where((cat) {
      if (_searchQuery.isEmpty) return true;
      return cat.name.toLowerCase().contains(_searchQuery);
    }).toList();

    List<TaskCategory> visible = filteredCategories
        .where((cat) => !cat.isHidden)
        .toList();
    List<TaskCategory> hidden = filteredCategories
        .where((cat) => cat.isHidden)
        .toList();
    if (mounted) {
      setState(() {
        _visibleCategories = visible;
        _hiddenCategories = hidden;
        _isLoading = false;
      });
    }
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
    });
    _processCategoriesDisplay();
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
        onEncryptionToggled: () {
          _initStorageAndLoadData();
        },
      ),
    );
  }

  // PEMBARUAN: Modifikasi agar asinkron aman, status context divalidasi, dan memberi feedback jika tugas tidak terikat jurnal
  Future<bool> _incrementTaskCount(TaskItem task) async {
    setState(() {
      task.count += 1;
      task.countToday += 1;
      task.date = _getTodayDateString();
    });
    await _saveAllCategoriesToFile(shouldRefresh: false);

    // Simpan status keterhubungan jurnal
    bool isLinked = await _add30MinutesToJurnal(task.id);

    // Jika tidak ada task jurnal yang terikat, berikan umpan balik yang informatif
    if (!isLinked && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Progress bertambah! (Tugas tidak terhubung ke jurnal)',
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blueGrey,
        ),
      );
    }
    return true;
  }

  // PEMBARUAN: Mengubah return type menjadi Future<bool> dan membungkus jsonDecode dengan try-catch sekunder secara defensif
  Future<bool> _add30MinutesToJurnal(String myTaskId) async {
    try {
      final File jurnalFile = await _storageService.getJurnalJsonFile(
        _selectedBaseDir,
      );
      String jsonString = await _storageService.loadOrInitializeJurnalJson(
        jurnalFile,
      );

      // --- LOGIKA DEKRIPSI UNTUK PROSES UPDATE JURNAL (+30 MENIT) ---
      bool isEncrypted = await _storageService.isEncryptionEnabled();
      String? password = await _storageService.getEncryptionPassword();

      if (isEncrypted &&
          password != null &&
          !jsonString.trim().startsWith('[')) {
        jsonString = CryptoHelper.decrypt(jsonString, password);
      }
      // -------------------------------------------------------------

      // Mengantisipasi format data rusak/parsial pada file json eksternal agar tidak crash
      List<dynamic> decodedJson = [];
      if (jsonString.trim().isNotEmpty) {
        try {
          decodedJson = jsonDecode(jsonString);
        } catch (e) {
          debugPrint(
            "Format berkas JSON jurnal tidak valid, menggunakan array kosong: $e",
          );
        }
      }

      List<TimeLogEntry> loadedLogs = decodedJson
          .map((e) => TimeLogEntry.fromJson(e))
          .toList();
      final String todayStr = _getTodayDateString();
      bool hasTodayLog = loadedLogs.any((entry) => entry.tanggal == todayStr);

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

      int todayIndex = loadedLogs.indexWhere(
        (entry) => entry.tanggal == todayStr,
      );
      if (todayIndex != -1) {
        bool isUpdated = false;
        String updatedJurnalTaskName = "";
        for (var logTask in loadedLogs[todayIndex].tasks) {
          if (logTask.linkedTaskIds.contains(myTaskId)) {
            logTask.durasiMenit += 30;
            isUpdated = true;
            updatedJurnalTaskName = logTask.nama;
            break;
          }
        }
        if (isUpdated) {
          final String updatedJsonContent = jsonEncode(
            loadedLogs.map((e) => e.toJson()).toList(),
          );
          await _storageService.saveJsonData(jurnalFile, updatedJsonContent);

          // REFRESH DATA JAM DI HEADER SETELAH JURNAL UPDATE
          await _kalkulasiTotalJurnalHariIni();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '  Terhubung! "$updatedJurnalTaskName" di Jurnal +30 menit.',
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.teal[800],
              ),
            );
          }
          return true; // Berhasil mendeteksi relasi dan memperbarui jurnal
        }
      }
      return false; // Tidak ada logTask jurnal yang menyimpan ID Tugas Master ini
    } catch (e) {
      debugPrint("Error updating linked jurnal data: $e");
      return false;
    }
  }

  void _showCategoryTasksDialog(TaskCategory category) {
    showDialog(
      context: context,
      builder: (context) => TasksDialog(
        category: category,
        allCategories: _allCategoriesRaw,
        onIncrementTask: _incrementTaskCount,
        onUpdateTargetToday: (task, target) {},
        onEditTaskDetail:
            (
              TaskItem task,
              String name,
              int c,
              int ct,
              int tc,
              int tct,
              String? d,
              bool active,
              int type,
            ) async {
              setState(() {
                task.name = name;
                task.count = c;
                task.countToday = ct;
                task.targetCount = tc;
                task.targetCountToday = tct;
                task.date = d;
                task.isActive = active;
                task.type = type;
              });
              await _saveAllCategoriesToFile();
            },
        onDeleteTask: (task) async {
          final bool confirm =
              await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus Tugas?'),
                    ],
                  ),
                  content: Text(
                    'Apakah Anda yakin ingin menghapus tugas "${task.name}" secara permanen?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        'Hapus',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ) ??
              false;
          if (confirm) {
            setState(() {
              category.tasks.removeWhere((t) => t.id == task.id);
            });
            await _saveAllCategoriesToFile(shouldRefresh: false);
            return true;
          }
          return false;
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
          final TextEditingController taskNameController =
              TextEditingController();
          final TextEditingController targetTodayController =
              TextEditingController(text: '0');
          final TextEditingController targetTotalController =
              TextEditingController(text: '0');
          int selectedType = 0;
          final formKey = GlobalKey<FormState>();
          showDialog(
            context: context,
            builder: (ctx) => StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: Text('Tambah Tugas ke ${category.name}'),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: taskNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Tugas Baru',
                              hintText: 'Contoh: Belajar Flutter',
                            ),
                            validator: (v) => v!.trim().isEmpty
                                ? 'Nama tidak boleh kosong'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Tipe Tugas',
                              icon: Icon(Icons.stacked_line_chart),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 0,
                                child: Text('Tugas Biasa'),
                              ),
                              DropdownMenuItem(
                                value: 1,
                                child: Text(
                                  'Tugas Progress (Ada Progress Bar)',
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  selectedType = val;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: targetTodayController,
                            decoration: const InputDecoration(
                              labelText: 'Target Hitungan Hari Ini',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          if (selectedType == 1) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: targetTotalController,
                              decoration: const InputDecoration(
                                labelText: 'Target Total Keseluruhan Progress',
                                hintText: 'Contoh: 100',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final String newName = taskNameController.text.trim();
                          final int newTargetToday =
                              int.tryParse(targetTodayController.text.trim()) ??
                              0;
                          final int newTargetTotal =
                              int.tryParse(targetTotalController.text.trim()) ??
                              0;
                          final newTask = TaskItem(
                            id: TaskItem.generateRandomId(),
                            name: newName,
                            count: 0,
                            checked: false,
                            countToday: 0,
                            lastUpdated: '',
                            targetCountToday: newTargetToday,
                            type: selectedType,
                            targetCount: selectedType == 1 ? newTargetTotal : 0,
                            isActive: true,
                            date: _getTodayDateString(),
                          );
                          setState(() {
                            category.tasks.add(newTask);
                          });
                          await _saveAllCategoriesToFile();
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                      ),
                      child: const Text(
                        'Simpan Tugas',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
        onMoveTaskCategory: (task, source, target) async {
          setState(() {
            source.tasks.removeWhere((t) => t.id == task.id);
            target.tasks.add(task);
          });
          await _saveAllCategoriesToFile(shouldRefresh: true);
        },
        onReorderTasks: () async {
          await _saveAllCategoriesToFile(shouldRefresh: false);
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

  void _showEditCategoryDialog(TaskCategory category) {
    showDialog(
      context: context,
      builder: (ctx) => AddCategoryDialog(
        categoryToEdit: category,
        onSave: (newName, newIcon) async {
          setState(() {
            int idx = _allCategoriesRaw.indexWhere(
              (cat) => cat.name == category.name,
            );
            if (idx != -1) {
              _allCategoriesRaw[idx] = TaskCategory(
                name: newName,
                icon: newIcon,
                isHidden: category.isHidden,
                tasks: category.tasks,
              );
            }
          });
          await _saveAllCategoriesToFile();
        },
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

  Future<void> _deleteCategory(TaskCategory category) async {
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
    if (confirm) {
      setState(() {
        _allCategoriesRaw.removeWhere((cat) => cat.name == category.name);
      });
      await _saveAllCategoriesToFile();
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
        childAspectRatio: _isPageEditMode ? 1.3 : 1.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categoriesList.length,
      itemBuilder: (context, index) {
        final category = categoriesList[index];
        return CategoryCard(
          category: category,
          isEditMode: _isPageEditMode,
          onLongPress: () {
            setState(() {
              _isPageEditMode = !_isPageEditMode;
            });
          },
          onTap: _isPageEditMode
              ? () {}
              : () => _showCategoryTasksDialog(category),
          onEdit: () => _showEditCategoryDialog(category),
          onDelete: () => _deleteCategory(category),
          onToggleVisibility: () => _toggleCategoryVisibility(category),
          onMoveUp: index > 0
              ? () => _moveCategoryOrder(categoriesList, index, -1)
              : null,
          onMoveDown: index < categoriesList.length - 1
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
      appBar: BaseDetailAppBar(
        pageTitle: 'Task Master',
        forceShowMenu: true,
        isSelectMode: false,
        selectedItemsCount: _visibleCategories.length,
        isSearchMode: _internalSearchMode,
        onClearSelection: () {
          setState(() {
            _internalSearchMode = false;
            _isPageEditMode = false;
          });
          _searchController.clear();
          _updateSearchQuery('');
        },
        onToggleSearchMode: () {
          setState(() {
            _internalSearchMode = !_internalSearchMode;
          });
          if (!_internalSearchMode) {
            _searchController.clear();
            _updateSearchQuery('');
          }
        },
        enableSearch: true,
        enableMultiSelect: false,
        onMoveMassive: () {},
        onDeleteMassive: () {},
        additionalAction: _internalSearchMode
            ? IconButton(
                icon: Icon(
                  _showHiddenSection ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                ),
                tooltip: _showHiddenSection
                    ? 'Sembunyikan Kategori Nonaktif'
                    : 'Tampilkan Kategori Tersembunyi',
                onPressed: () {
                  setState(() {
                    _showHiddenSection = !_showHiddenSection;
                  });
                },
              )
            : null,
        searchBarContent: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onChanged: (val) => _updateSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'Cari kategori...',
                  hintStyle: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _showAddCategoryDialog,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
      ),
      drawer: const DrawerMenu(),
      // PEMBARUAN DI BODY: Menggunakan UniversalEmptyState terpusat dari folder core dengan penyesuaian parameter khusus Task Master
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allCategoriesRaw.isEmpty
          ? UniversalEmptyState(
              icon: Icons.assignment_turned_in_rounded,
              title: 'Mulai Langkah Produktif Anda!',
              description:
                  'Task Master membantu Anda melacak repetisi aktivitas, target progress bar, dan terhubung langsung dengan Jurnal Waktu 30 menit Anda.',
              buttonLabel: 'Buat Kategori Pertama',
              themeColor: Colors.indigo,
              onPressed: _showAddCategoryDialog,
            )
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
                      ),
                      Row(
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
                      _buildCategoryGrid(_hiddenCategories, constraints),
                    ],
                  ],
                );
              },
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
          LayoutBuilder(
            builder: (context, boxConstraints) {
              bool isMobile = boxConstraints.maxWidth < 600;
              Widget buildCard(
                String title,
                String mainText,
                String subText,
                Color bgColor,
                Color textColor,
                Color subTextColor,
              ) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mainText,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subText,
                        style: TextStyle(color: subTextColor, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }

              final cardKategori = buildCard(
                'Kategori',
                '$visibleCategoriesCount Active',
                'Total: $totalCategories',
                Colors.blue[50]!,
                Colors.blue[900]!,
                Colors.blue[700]!,
              );
              final cardTotalTugas = buildCard(
                'Total Tugas',
                '$totalTasks Unit',
                'Di semua kategori',
                Colors.amber[50]!,
                Colors.amber[900]!,
                Colors.amber[800]!,
              );
              final cardSelesai = buildCard(
                'Selesai Hari Ini',
                '$completedTasksToday / $tasksWithTargetToday',
                'Target tercapai',
                Colors.green[50]!,
                Colors.green[900]!,
                Colors.green[800]!,
              );

              final cardJam = buildCard(
                'Jam Hari Ini',
                _totalJurnalDurationString,
                'Durasi pengerjaan',
                Colors.teal[50]!,
                Colors.teal[900]!,
                Colors.teal[800]!,
              );

              if (isMobile) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: cardKategori),
                        const SizedBox(width: 8),
                        Expanded(child: cardTotalTugas),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: cardSelesai),
                        const SizedBox(width: 8),
                        Expanded(child: cardJam),
                      ],
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(child: cardKategori),
                    const SizedBox(width: 8),
                    Expanded(child: cardTotalTugas),
                    const SizedBox(width: 8),
                    Expanded(child: cardSelesai),
                    const SizedBox(width: 8),
                    Expanded(child: cardJam),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
