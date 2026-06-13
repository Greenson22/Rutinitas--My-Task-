// lib/features/task_master/presentation/screens/task_master_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rutinitasku/core/presentation/widgets/base_detail_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/models/task_model.dart';
import '../../../jurnal_aktivitas/data/models/time_log_model.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/tasks_dialog.dart';
import '../widgets/add_category_dialog.dart';
import '../../../../core/presentation/widgets/universal_empty_state.dart';
import '../../../../core/utils/crypto_helper.dart';

// Import widget yang baru saja kita pisahkan
import '../widgets/task_summary_header.dart';
import '../widgets/corrupted_empty_state.dart';
import '../widgets/category_grid.dart';

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

  bool _isFileCorrupted = false;

  bool _internalSearchMode = false;
  late TextEditingController _searchController;
  String _searchQuery = '';

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

  Future<void> _kalkulasiTotalJurnalHariIni() async {
    try {
      File fileJurnal = await _storageService.getJurnalJsonFile(
        _selectedBaseDir,
      );

      if (await fileJurnal.exists()) {
        String jsonString = await fileJurnal.readAsString();

        bool isEncrypted = await _storageService.isEncryptionEnabled();
        String? password = await _storageService.getEncryptionPassword();
        if (isEncrypted &&
            password != null &&
            !jsonString.trim().startsWith('[')) {
          jsonString = CryptoHelper.decrypt(jsonString, password);
        }

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

  void _showDecryptionErrorDialog(File jsonFile) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.lock_outline, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Berkas Terkunci / Rusak'),
          ],
        ),
        content: const Text(
          'Aplikasi gagal membaca data Task Master. Berkas ini mungkin dienkripsi oleh sistem dengan kata sandi lain, atau format data di dalamnya rusak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _showManualUnlockDialog(jsonFile);
            },
            child: const Text(
              'Buka Kunci (Input PIN)',
              style: TextStyle(
                color: Colors.indigo,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final bool? confirmNew = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Buat Baru?'),
                  content: const Text(
                    'Semua data lama di dalam berkas Task Master ini akan dihapus total dan diganti dengan struktur baru yang kosong. Tindakan ini tidak bisa dibatalkan!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text(
                        'Ya, Hapus & Reset',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmNew == true) {
                setState(() {
                  _isLoading = true;
                  _isFileCorrupted = false;
                });

                await jsonFile.writeAsString(jsonEncode({'categories': []}));

                try {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('is_encrypted', false);
                  await prefs.remove('encryption_password');
                } catch (e) {
                  debugPrint("Gagal mereset preferensi enkripsi: $e");
                }

                _initStorageAndLoadData();
              } else {
                _showDecryptionErrorDialog(jsonFile);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text(
              'Buat Baru',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualUnlockDialog(File jsonFile) {
    final passController = TextEditingController();
    bool obscureText = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Masukkan Kata Sandi'),
          content: TextField(
            controller: passController,
            obscureText: obscureText,
            decoration: InputDecoration(
              labelText: 'Kata Sandi Dekripsi',
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                ),
                onPressed: () =>
                    setModalState(() => obscureText = !obscureText),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showDecryptionErrorDialog(jsonFile);
              },
              child: const Text(
                'Kembali',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final input = passController.text.trim();
                if (input.isEmpty) return;

                try {
                  String encryptedContent = await jsonFile.readAsString();
                  String decrypted = CryptoHelper.decrypt(
                    encryptedContent,
                    input,
                  );

                  final parsed = jsonDecode(decrypted);
                  if (parsed is Map && parsed.containsKey('categories')) {
                    Navigator.pop(ctx);
                    setState(() {
                      _isLoading = true;
                      _isFileCorrupted = false;
                    });

                    final List<dynamic> catList = parsed['categories'] ?? [];
                    _allCategoriesRaw = catList
                        .map((json) => TaskCategory.fromJson(json))
                        .toList();

                    await _kalkulasiTotalJurnalHariIni();
                    _processCategoriesDisplay();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Buka kunci data sukses!'),
                        backgroundColor: Colors.teal,
                      ),
                    );
                    return;
                  }
                  throw const FormatException();
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Kata sandi salah atau struktur data rusak!',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: const Text(
                'Buka Data',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initStorageAndLoadData() async {
    setState(() {
      _isLoading = true;
      _isFileCorrupted = false;
    });
    File? jsonFile;
    try {
      _selectedBaseDir = await _storageService.getBaseDirSetting();
      jsonFile = await _storageService.getTargetJsonFile(_selectedBaseDir);
      _fullJsonPath = jsonFile.path;
      String jsonString = await _storageService.loadOrInitializeJson(jsonFile);

      bool isEncrypted = await _storageService.isEncryptionEnabled();
      String? password = await _storageService.getEncryptionPassword();
      if (isEncrypted &&
          password != null &&
          !jsonString.trim().startsWith('{')) {
        jsonString = CryptoHelper.decrypt(jsonString, password);
      }

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

      await _kalkulasiTotalJurnalHariIni();
      _processCategoriesDisplay();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFileCorrupted = true;
        });
      }
      debugPrint("Error loading data: $e");

      if (jsonFile != null && mounted) {
        _showDecryptionErrorDialog(jsonFile);
      }
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

  Future<bool> _incrementTaskCount(TaskItem task) async {
    setState(() {
      task.count += 1;
      task.countToday += 1;
      task.date = _getTodayDateString();
    });
    await _saveAllCategoriesToFile(shouldRefresh: false);

    bool isLinked = await _add30MinutesToJurnal(task.id);

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

  Future<bool> _add30MinutesToJurnal(String myTaskId) async {
    try {
      final File jurnalFile = await _storageService.getJurnalJsonFile(
        _selectedBaseDir,
      );
      String jsonString = await _storageService.loadOrInitializeJurnalJson(
        jurnalFile,
      );

      bool isEncrypted = await _storageService.isEncryptionEnabled();
      String? password = await _storageService.getEncryptionPassword();
      if (isEncrypted &&
          password != null &&
          !jsonString.trim().startsWith('[')) {
        jsonString = CryptoHelper.decrypt(jsonString, password);
      }

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
          return true;
        }
      }
      return false;
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
        onEditTaskDetail: (task, name, c, ct, tc, tct, d, active, type) async {
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
                              if (val != null)
                                setDialogState(() => selectedType = val);
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
                onPressed: () =>
                    setState(() => _showHiddenSection = !_showHiddenSection),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isFileCorrupted
          ? CorruptedEmptyState(
              onRecoveryPressed: () async {
                File jsonFile = await _storageService.getTargetJsonFile(
                  _selectedBaseDir,
                );
                _showDecryptionErrorDialog(jsonFile);
              },
            )
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
                      TaskSummaryHeader(
                        allCategoriesRaw: _allCategoriesRaw,
                        visibleCategories: _visibleCategories,
                        totalJurnalDurationString: _totalJurnalDurationString,
                      ),
                    if (_visibleCategories.isNotEmpty)
                      CategoryGrid(
                        categoriesList: _visibleCategories,
                        isPageEditMode: _isPageEditMode,
                        constraints: constraints,
                        onToggleEditMode: () =>
                            setState(() => _isPageEditMode = !_isPageEditMode),
                        onTapCategory: _showCategoryTasksDialog,
                        onEditCategory: _showEditCategoryDialog,
                        onDeleteCategory: _deleteCategory,
                        onToggleVisibility: _toggleCategoryVisibility,
                        onMoveCategoryOrder: (index, dir) =>
                            _moveCategoryOrder(_visibleCategories, index, dir),
                      ),
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
                      CategoryGrid(
                        categoriesList: _hiddenCategories,
                        isPageEditMode: _isPageEditMode,
                        constraints: constraints,
                        onToggleEditMode: () =>
                            setState(() => _isPageEditMode = !_isPageEditMode),
                        onTapCategory: _showCategoryTasksDialog,
                        onEditCategory: _showEditCategoryDialog,
                        onDeleteCategory: _deleteCategory,
                        onToggleVisibility: _toggleCategoryVisibility,
                        onMoveCategoryOrder: (index, dir) =>
                            _moveCategoryOrder(_hiddenCategories, index, dir),
                      ),
                    ],
                  ],
                );
              },
            ),
    );
  }
}
