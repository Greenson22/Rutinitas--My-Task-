// lib/features/task_master/presentation/screens/home_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/models/task_model.dart';
import '../widgets/category_card.dart';
import '../widgets/drawer_menu.dart';
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
  bool _isSortedAZ = false; // Status untuk melacak fitur urutan

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

  // Fungsi internal untuk memisahkan kategori aktif dan tersembunyi serta mengurutkannya
  void _processCategoriesDisplay() {
    List<TaskCategory> visible = _allCategoriesRaw
        .where((cat) => !cat.isHidden)
        .toList();
    List<TaskCategory> hidden = _allCategoriesRaw
        .where((cat) => cat.isHidden)
        .toList();

    // Jika fitur urutan aktif, urutkan masing-masing grup secara Alphabetical (A-Z)
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

  // Fungsi untuk mengaktifkan/menonaktifkan urutan
  void _toggleSortOrder() {
    setState(() {
      _isSortedAZ = !_isSortedAZ;
    });
    _processCategoriesDisplay();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSortedAZ
              ? 'Kategori diurutkan A-Z'
              : 'Urutan dikembalikan ke semula',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // Fungsi logika untuk sembunyikan/tampilkan kategori (Toggle Visibility)
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _allCategoriesRaw[index].isHidden
                ? 'Kategori "${category.name}" disembunyikan ke bawah.'
                : 'Kategori "${category.name}" kembali ditampilkan.',
          ),
        ),
      );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lokasi dipindahkan ke: $newDir/mytask/')),
          );
        },
      ),
    );
  }

  Future<bool> _incrementTaskCount(TaskItem task) async {
    bool? confirmIncrement = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Count'),
        content: Text(
          'Apakah Anda yakin ingin menambah hitungan untuk tugas "${task.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Tambah',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmIncrement == true) {
      setState(() {
        task.count += 1;
        task.countToday += 1;
        task.date = _getTodayDateString();
      });
      await _saveAllCategoriesToFile();
      return true;
    }
    return false;
  }

  Future<void> _updateTaskTargetToday(TaskItem task, int newTarget) async {
    setState(() {
      task.targetCountToday = newTarget;
    });
    await _saveAllCategoriesToFile();
  }

  void _showCategoryTasksDialog(TaskCategory category) {
    showDialog(
      context: context,
      builder: (context) => TasksDialog(
        category: category,
        onIncrementTask: (task) => _incrementTaskCount(task),
        onUpdateTargetToday: (task, newTarget) =>
            _updateTaskTargetToday(task, newTarget),
        onEditTaskDetail:
            (
              task,
              newName,
              newCount,
              newCountToday,
              newTargetCount,
              newTargetCountToday,
              newDate,
            ) {
              _editTaskDetail(
                category,
                task,
                newName,
                newCount,
                newCountToday,
                newTargetCount,
                newTargetCountToday,
                newDate,
              );
            },
        onDeleteTask: (task) => _deleteTask(category, task),
      ),
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCategoryDialog(
        onSave: (name, icon) => _addNewCategory(name, icon),
      ),
    );
  }

  void _showEditCategoryDialog(TaskCategory category) {
    showDialog(
      context: context,
      builder: (context) => AddCategoryDialog(
        categoryToEdit: category,
        onSave: (newName, newIcon) => _editCategory(category, newName, newIcon),
      ),
    );
  }

  // Widget generator untuk GridView Kategori agar kode di body lebih bersih
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
      physics:
          const NeverScrollableScrollPhysics(), // Supaya bisa digulung bareng di ListView utama
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
          onEdit: () => _showEditCategoryDialog(category),
          onDelete: () => _deleteCategory(category),
          onToggleVisibility: () => _toggleCategoryVisibility(
            category,
          ), // Pasang fungsi sembunyikan/tampilkan
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
          // === TOMBOL URUTKAN PADA APPBAR ===
          IconButton(
            icon: Icon(_isSortedAZ ? Icons.sort_by_alpha : Icons.sort),
            tooltip: 'Urutkan Kategori (A-Z)',
            onPressed: _toggleSortOrder,
          ),
        ],
      ),
      drawer: DrawerMenu(
        selectedBaseDir: _selectedBaseDir,
        fullJsonPath: _fullJsonPath,
        onOpenSettings: _showSettingsDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
                  children: [
                    // 1. Tampilkan Kategori Utama (Aktif)
                    if (_visibleCategories.isNotEmpty)
                      _buildCategoryGrid(_visibleCategories, constraints),

                    if (_visibleCategories.isEmpty && _hiddenCategories.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: Text('Tidak ada kategori.')),
                      ),

                    // 2. Tampilkan Area Kategori Tersembunyi di paling bawah (jika ada)
                    if (_hiddenCategories.isNotEmpty) ...[
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

  Future<void> _editCategory(
    TaskCategory oldCategory,
    String newName,
    String newIcon,
  ) async {
    int index = _allCategoriesRaw.indexWhere(
      (cat) => cat.name == oldCategory.name,
    );

    if (index != -1) {
      _allCategoriesRaw[index] = TaskCategory(
        name: newName,
        icon: newIcon,
        isHidden: oldCategory.isHidden,
        tasks: oldCategory.tasks,
      );
      await _saveAllCategoriesToFile();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kategori "$newName" berhasil diperbarui!')),
      );
    }
  }

  Future<void> _deleteCategory(TaskCategory category) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text(
          'Apakah Anda yakin ingin menghapus kategori "${category.name}" beserta semua tugas di dalamnya?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      _allCategoriesRaw.removeWhere((cat) => cat.name == category.name);
      await _saveAllCategoriesToFile();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kategori "${category.name}" berhasil dihapus.'),
        ),
      );
    }
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
      debugPrint("Error saving categories: $e");
    }
  }

  Future<void> _editTaskDetail(
    TaskCategory category,
    TaskItem oldTask,
    String newName,
    int newCount,
    int newCountToday,
    int newTargetCount,
    int newTargetCountToday,
    String? newDate,
  ) async {
    int catIndex = _allCategoriesRaw.indexWhere(
      (cat) => cat.name == category.name,
    );
    if (catIndex != -1) {
      int taskIndex = _allCategoriesRaw[catIndex].tasks.indexWhere(
        (t) => t.id == oldTask.id,
      );
      if (taskIndex != -1) {
        setState(() {
          var task = _allCategoriesRaw[catIndex].tasks[taskIndex];
          task.name = newName;
          task.count = newCount;
          task.countToday = newCountToday;
          task.targetCount = newTargetCount;
          task.targetCountToday = newTargetCountToday;
          task.date = newDate;
        });
        await _saveAllCategoriesToFile();
        _processCategoriesDisplay(); // Perbarui tampilan list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tugas "$newName" berhasil diperbarui!')),
        );
      }
    }
  }

  Future<bool> _deleteTask(TaskCategory category, TaskItem task) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tugas'),
        content: Text(
          'Apakah Anda yakin ingin menghapus tugas "${task.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      int catIndex = _allCategoriesRaw.indexWhere(
        (cat) => cat.name == category.name,
      );
      if (catIndex != -1) {
        setState(() {
          _allCategoriesRaw[catIndex].tasks.removeWhere((t) => t.id == task.id);
        });
        await _saveAllCategoriesToFile();
        _processCategoriesDisplay(); // Perbarui tampilan list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tugas "${task.name}" berhasil dihapus.')),
        );
        return true;
      }
    }
    return false;
  }
}
