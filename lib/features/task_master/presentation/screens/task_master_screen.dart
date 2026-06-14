// lib/features/task_master/presentation/screens/task_master_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rutinitasku/core/presentation/widgets/base_detail_app_bar.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../../../../core/presentation/widgets/universal_empty_state.dart';
import '../../../../core/utils/crypto_helper.dart';
import '../../data/models/task_model.dart';
import '../controllers/task_master_controller.dart';
import '../widgets/add_category_dialog.dart';
import '../widgets/category_grid.dart';
import '../widgets/corrupted_empty_state.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/task_summary_header.dart';
import '../widgets/tasks_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TaskMasterController _controller;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Inisialisasi controller dengan callback setState lokal
    _controller = TaskMasterController(
      onUpdate: () {
        if (mounted) setState(() {});
      },
    );

    _controller.initStorageAndLoadData(
      onCorrupted: (jsonFile) => _showDecryptionErrorDialog(jsonFile),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDecryptionErrorDialog(File jsonFile) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Berkas Terkunci / Rusak'),
          ],
        ),
        content: const Text(
          'Aplikasi gagal membaca data Task Master. Berkas ini mungkin dienkripsi dengan PIN lain, atau format data rusak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
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
              final bool confirmNew = await _showConfirmResetDialog() ?? false;

              if (confirmNew) {
                _controller.forceResetNewFile(jsonFile);
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

  Future<bool?> _showConfirmResetDialog() {
    return showDialog<bool>(
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

                  final parsed = jsonDecode(decrypted); // Atau jsonDecode
                  if (parsed is Map && parsed.containsKey('categories')) {
                    Navigator.pop(ctx);
                    final List<dynamic> catList = parsed['categories'] ?? [];
                    List<TaskCategory> loaded = catList
                        .map((json) => TaskCategory.fromJson(json))
                        .toList();

                    _controller.handleManualUnlockSuccess(loaded);

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

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        currentBaseDir: _controller.selectedBaseDir,
        onSave: (newDir) => _controller.updateUbuntuStorage(newDir),
        onEncryptionToggled: () => _controller.initStorageAndLoadData(),
      ),
    );
  }

  void _showCategoryTasksDialog(TaskCategory category) {
    showDialog(
      context: context,
      builder: (context) => TasksDialog(
        category: category,
        allCategories: _controller.allCategoriesRaw,
        onIncrementTask: (task) =>
            _controller.incrementTaskCount(task, context),
        onUpdateTargetToday: (task, target) {},
        onEditTaskDetail: (task, name, c, ct, tc, tct, d, active, type) async {
          task.name = name;
          task.count = c;
          task.countToday = ct;
          task.targetCount = tc;
          task.targetCountToday = tct;
          task.date = d;
          task.isActive = active;
          task.type = type;
          await _controller.saveAllCategoriesToFile();
        },
        onDeleteTask: (task) async {
          final bool confirm =
              await _showConfirmDeleteTaskDialog(task) ?? false;
          if (confirm) {
            category.tasks.removeWhere((t) => t.id == task.id);
            await _controller.saveAllCategoriesToFile(shouldRefresh: false);
            return true;
          }
          return false;
        },
        onBulkAction: (tasksToUpdate, action) async {
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
          await _controller.saveAllCategoriesToFile();
        },
        onAddTask: () => _showAddTaskFormDialog(category),
        onMoveTaskCategory: (task, source, target) async {
          source.tasks.removeWhere((t) => t.id == task.id);
          target.tasks.add(task);
          // Ubah shouldRefresh menjadi false agar tidak memuat ulang file dari disk berturut-turut
          await _controller.saveAllCategoriesToFile(shouldRefresh: false);
        },
        onReorderTasks: () async {
          await _controller.saveAllCategoriesToFile(shouldRefresh: false);
        },
      ),
    );
  }

  Future<bool?> _showConfirmDeleteTaskDialog(TaskItem task) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddTaskFormDialog(TaskCategory category) {
    final taskNameController = TextEditingController();
    final targetTodayController = TextEditingController(text: '0');
    final targetTotalController = TextEditingController(text: '0');
    int selectedType = 0;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                    ),
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Tipe Tugas'),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Tugas Biasa')),
                      DropdownMenuItem(
                        value: 1,
                        child: Text('Tugas Progress (Bar)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: targetTodayController,
                    decoration: const InputDecoration(
                      labelText: 'Target Hari Ini',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  if (selectedType == 1) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: targetTotalController,
                      decoration: const InputDecoration(
                        labelText: 'Target Total',
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
                  final newTask = TaskItem(
                    id: TaskItem.generateRandomId(),
                    name: taskNameController.text.trim(),
                    count: 0,
                    checked: false,
                    countToday: 0,
                    lastUpdated: '',
                    targetCountToday:
                        int.tryParse(targetTodayController.text.trim()) ?? 0,
                    type: selectedType,
                    targetCount: selectedType == 1
                        ? (int.tryParse(targetTotalController.text.trim()) ?? 0)
                        : 0,
                    isActive: true,
                    date: _controller.getTodayDateString(),
                  );
                  category.tasks.add(newTask);
                  await _controller.saveAllCategoriesToFile();
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddCategoryDialog(onSave: _controller.addNewCategory),
    );
  }

  void _showEditCategoryDialog(TaskCategory category) {
    showDialog(
      context: context,
      builder: (ctx) => AddCategoryDialog(
        categoryToEdit: category,
        onSave: (newName, newIcon) =>
            _controller.updateCategory(category, newName, newIcon),
      ),
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
        selectedItemsCount: _controller.visibleCategories.length,
        isSearchMode: _controller.internalSearchMode,
        onClearSelection: () {
          _searchController.clear();
          _controller.clearSearch();
        },
        onToggleSearchMode: () {
          _controller.toggleInternalSearchMode();
          if (!_controller.internalSearchMode) {
            _searchController.clear();
          }
        },
        enableSearch: true,
        enableMultiSelect: false,
        onMoveMassive: () {},
        onDeleteMassive: () {},
        additionalAction: _controller.internalSearchMode
            ? IconButton(
                icon: Icon(
                  _controller.showHiddenSection
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.white,
                ),
                onPressed: _controller.toggleHiddenSection,
              )
            : null,
        searchBarContent: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onChanged: _controller.updateSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Cari kategori...',
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
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _controller.isFileCorrupted
          ? CorruptedEmptyState(
              onRecoveryPressed: () async {
                File jsonFile = await _controller.storageService
                    .getTargetJsonFile(_controller.selectedBaseDir);
                _showDecryptionErrorDialog(jsonFile);
              },
            )
          : _controller.allCategoriesRaw.isEmpty
          ? UniversalEmptyState(
              icon: Icons.assignment_turned_in_rounded,
              title: 'Mulai Langkah Produktif Anda!',
              description:
                  'Task Master membantu melacak repetisi aktivitas terintegrasi dengan Jurnal Waktu 30 menit.',
              buttonLabel: 'Buat Kategori Pertama',
              themeColor: Colors.indigo,
              onPressed: _showAddCategoryDialog,
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
                  children: [
                    TaskSummaryHeader(
                      allCategoriesRaw: _controller.allCategoriesRaw,
                      visibleCategories: _controller.visibleCategories,
                      totalJurnalDurationString:
                          _controller.totalJurnalDurationString,
                    ),
                    if (_controller.visibleCategories.isNotEmpty)
                      CategoryGrid(
                        categoriesList: _controller.visibleCategories,
                        isPageEditMode: _controller.isPageEditMode,
                        constraints: constraints,
                        onToggleEditMode: _controller.togglePageEditMode,
                        onTapCategory: _showCategoryTasksDialog,
                        onEditCategory: _showEditCategoryDialog,
                        onDeleteCategory: (cat) async {
                          _controller.deleteCategory(cat);
                        },
                        onToggleVisibility:
                            _controller.toggleCategoryVisibility,
                        onMoveCategoryOrder: (index, dir) =>
                            _controller.moveCategoryOrder(
                              _controller.visibleCategories,
                              index,
                              dir,
                            ),
                      ),
                    if (_controller.visibleCategories.isEmpty &&
                        _controller.hiddenCategories.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: Text('Tidak ada kategori.')),
                      ),
                    if (_controller.hiddenCategories.isNotEmpty &&
                        _controller.showHiddenSection) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Divider(thickness: 2, color: Colors.grey),
                      ),
                      CategoryGrid(
                        categoriesList: _controller.hiddenCategories,
                        isPageEditMode: _controller.isPageEditMode,
                        constraints: constraints,
                        onToggleEditMode: _controller.togglePageEditMode,
                        onTapCategory: _showCategoryTasksDialog,
                        onEditCategory: _showEditCategoryDialog,
                        onDeleteCategory: (cat) async {
                          _controller.deleteCategory(cat);
                        },
                        onToggleVisibility:
                            _controller.toggleCategoryVisibility,
                        onMoveCategoryOrder: (index, dir) =>
                            _controller.moveCategoryOrder(
                              _controller.hiddenCategories,
                              index,
                              dir,
                            ),
                      ),
                    ],
                  ],
                );
              },
            ),
    );
  }
}
