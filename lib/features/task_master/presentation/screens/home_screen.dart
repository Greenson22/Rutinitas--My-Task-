import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/models/task_model.dart';
import '../widgets/category_card.dart';
import '../widgets/drawer_menu.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/tasks_dialog.dart';
import '../widgets/add_category_dialog.dart'; // Import dialog baru
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  List<TaskCategory> _categories = [];
  List<TaskCategory> _allCategoriesRaw = [];
  String _selectedBaseDir = 'Documents';
  String _fullJsonPath = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initStorageAndLoadData();
  }

  // Mendapatkan string tanggal hari ini (Format: YYYY-MM-DD)
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

      // === LOGIKA RESET OTOMATIS JIKA BERGANTI HARI ===
      String todayStr = _getTodayDateString();
      bool isDataChanged = false;

      for (var category in loadedCategories) {
        for (var task in category.tasks) {
          // Jika field date berbeda dengan hari ini, reset countToday menjadi 0
          if (task.date != todayStr && task.countToday > 0) {
            task.countToday = 0;
            isDataChanged = true;
          }
        }
      }

      _allCategoriesRaw = loadedCategories;

      // Jika ada data ter-reset, langsung simpan perubahan kembali ke file
      if (isDataChanged) {
        await _saveAllCategoriesToFile(shouldRefresh: false);
      }

      setState(() {
        _categories = _allCategoriesRaw.where((cat) => !cat.isHidden).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error loading data: $e");
    }
  }

  // === FUNGSI BARU UNTUK MENYIMPAN KATEGORI BARU KE FILE ===
  Future<void> _addNewCategory(String name, String icon) async {
    final newCategory = TaskCategory(
      name: name,
      icon: icon,
      isHidden: false,
      tasks: [],
    );

    // Tambahkan ke penampung utama
    _allCategoriesRaw.add(newCategory);

    // Susun struktur JSON kembali
    final Map<String, dynamic> updatedMap = {
      'categories': _allCategoriesRaw.map((cat) => cat.toJson()).toList(),
    };

    // Encode kembali ke String JSON dengan format rapi (indent)
    final String updatedJsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(updatedMap);

    try {
      File jsonFile = await _storageService.getTargetJsonFile(_selectedBaseDir);
      await _storageService.saveJsonData(jsonFile, updatedJsonString);

      // Refresh UI dan memuat ulang data dari file lokal
      _initStorageAndLoadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kategori "$name" berhasil ditambahkan!')),
      );
    } catch (e) {
      debugPrint("Error saving new category: $e");
    }
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

  // === FUNGSI AKSI TOMBOL TAMBAH PADA TUGAS ===
  Future<void> _incrementTaskCount(TaskItem task) async {
    setState(() {
      task.count += 1;
      task.countToday += 1;
      task.date =
          _getTodayDateString(); // Mengubah tanggal otomatis ke hari ini
    });
    await _saveAllCategoriesToFile();
  }

  // === FUNGSI AKSI UPDATE TARGET HARIAN TUGAS ===
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
        onIncrementTask: (task) {
          _incrementTaskCount(task);
        },
        onUpdateTargetToday: (task, newTarget) {
          _updateTaskTargetToday(task, newTarget);
        },
      ),
    );
  }

  // Fungsi untuk memicu dialog tambah kategori
  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCategoryDialog(
        onSave: (name, icon) {
          _addNewCategory(name, icon);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Task Master'),
        backgroundColor: Colors.indigo[700],
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
                int crossAxisCount = 2;
                if (constraints.maxWidth >= 1200) {
                  crossAxisCount = 5;
                } else if (constraints.maxWidth >= 900) {
                  crossAxisCount = 4;
                } else if (constraints.maxWidth >= 600) {
                  crossAxisCount = 3;
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return CategoryCard(
                      category: category,
                      onTap: () => _showCategoryTasksDialog(category),
                      onEdit: () => _showEditCategoryDialog(
                        category,
                      ), // Pasang callback edit
                      onDelete: () =>
                          _deleteCategory(category), // Pasang callback hapus
                    );
                  },
                );
              },
            ),
      // === HUBUNGKAN FLOATING ACTION BUTTON DI SINI ===
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  // === FUNGSI LOGIKA UNTUK MENYIMPAN HASIL EDIT ===
  Future<void> _editCategory(
    TaskCategory oldCategory,
    String newName,
    String newIcon,
  ) async {
    // Cari index kategori lama di dalam list utama
    int index = _allCategoriesRaw.indexWhere(
      (cat) => cat.name == oldCategory.name,
    );

    if (index != -1) {
      // Buat objek kategori baru dengan data terupdate tetapi mempertahankan task yang ada
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

  // === FUNGSI LOGIKA UNTUK MENGHAPUS KATEGORI ===
  Future<void> _deleteCategory(TaskCategory category) async {
    // Tampilkan dialog konfirmasi sebelum menghapus
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

  // Fungsi memicu dialog edit
  void _showEditCategoryDialog(TaskCategory category) {
    showDialog(
      context: context,
      builder: (context) => AddCategoryDialog(
        categoryToEdit: category,
        onSave: (newName, newIcon) {
          _editCategory(category, newName, newIcon);
        },
      ),
    );
  }
}
