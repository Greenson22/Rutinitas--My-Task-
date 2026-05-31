// lib/features/prompt/presentation/screens/prompt_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../../data/models/prompt_model.dart';
import 'package:flutter/services.dart';

// =========================================================================
// 1. WIDGET HALAMAN UTAMA PROMPT
// =========================================================================
class PromptScreen extends StatefulWidget {
  const PromptScreen({super.key});

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  final StorageService _storageService = StorageService();
  List<PromptGroup> _promptGroups = [];
  bool _isLoading = true;

  // Memisahkan state edit mode agar tidak bentrok satu sama lain
  bool isSectionEditMode = false;
  bool isCardEditMode = false;

  // Menampung nama seksi kosong baru yang belum memiliki group di dalamnya
  final List<String> _localEmptySections = [];

  @override
  void initState() {
    super.initState();
    _loadAllPrompts();
  }

  Future<void> _loadAllPrompts() async {
    setState(() => _isLoading = true);
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final files = await _storageService.getAllPromptGroups(baseDir);
      List<PromptGroup> loadedGroups = [];
      for (var file in files) {
        final content = await file.readAsString();
        final jsonMap = jsonDecode(content);
        loadedGroups.add(PromptGroup.fromJson(jsonMap));
      }
      setState(() {
        _promptGroups = loadedGroups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat data prompt: $e')));
    }
  }

  // === FITUR UTAMA BARU: TAMBAH SEKSI UTAMA BARU KOSONG ===
  void showAddSectionDialog() {
    final sectionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Seksi Kategori Baru'),
        content: TextField(
          controller: sectionController,
          decoration: const InputDecoration(
            hintText: 'Nama Seksi Utama (Misal: CODING, COPYWRITING)...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final String namaSeksiBaru = sectionController.text
                  .trim()
                  .toUpperCase();
              if (namaSeksiBaru.isNotEmpty) {
                setState(() {
                  if (!_localEmptySections.contains(namaSeksiBaru)) {
                    _localEmptySections.add(namaSeksiBaru);
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Seksi "$namaSeksiBaru" berhasil dibuat! Tekan tahan judul seksi lalu tekan tombol + untuk menambah group.',
                    ),
                    backgroundColor: Colors.indigo,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void moveSectionOrder(int index, int direction) async {
    final Map<String, List<PromptGroup>> sectionsMap = {};
    for (var group in _promptGroups) {
      final secName = group.sectionName.isEmpty
          ? 'GENERAL'
          : group.sectionName.toUpperCase();
      if (!sectionsMap.containsKey(secName)) {
        sectionsMap[secName] = [];
      }
      sectionsMap[secName]!.add(group);
    }

    for (var sec in _localEmptySections) {
      sectionsMap.putIfAbsent(sec, () => []);
    }

    final sectionKeys = sectionsMap.keys.toList();
    if (sectionKeys.contains('GENERAL')) {
      sectionKeys.remove('GENERAL');
      sectionKeys.insert(0, 'GENERAL');
    }

    int targetIndex = index + direction;
    if (targetIndex < 0 || targetIndex >= sectionKeys.length) return;

    final currentSectionName = sectionKeys[index];
    final targetSectionName = sectionKeys[targetIndex];

    setState(() {
      if (_localEmptySections.contains(currentSectionName) ||
          _localEmptySections.contains(targetSectionName)) {
        final int idxA = _localEmptySections.indexOf(currentSectionName);
        final int idxB = _localEmptySections.indexOf(targetSectionName);
        if (idxA != -1 && idxB != -1) {
          final temp = _localEmptySections[idxA];
          _localEmptySections[idxA] = _localEmptySections[idxB];
          _localEmptySections[idxB] = temp;
        }
      }

      final List<PromptGroup> reorderedGroups = [];
      final tempKey = sectionKeys[index];
      sectionKeys[index] = sectionKeys[targetIndex];
      sectionKeys[targetIndex] = tempKey;

      for (var key in sectionKeys) {
        if (sectionsMap.containsKey(key)) {
          reorderedGroups.addAll(sectionsMap[key]!);
        }
      }
      _promptGroups = reorderedGroups;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Seksi beserta seluruh isinya berhasil dipindahkan!'),
        duration: Duration(milliseconds: 700),
      ),
    );

    try {
      final baseDir = await _storageService.getBaseDirSetting();
      for (var group in _promptGroups) {
        await _storageService.savePromptGroup(
          baseDir,
          group.id,
          jsonEncode(group.toJson()),
        );
      }
    } catch (e) {
      debugPrint(
        "Gagal mengamankan urutan seksi beserta isinya di storage: $e",
      );
      _loadAllPrompts();
    }
  }

  void editSectionName(String oldName) async {
    final textController = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ubah Nama Seksi "$oldName"'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(labelText: 'Nama Seksi Baru'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = textController.text.trim();
                if (newName.isEmpty ||
                    newName.toUpperCase() == oldName.toUpperCase()) {
                  Navigator.pop(context);
                  return;
                }
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  final String cleanOldName = oldName.trim().toUpperCase();
                  final String cleanNewName = newName.trim().toUpperCase();

                  if (_localEmptySections.contains(cleanOldName)) {
                    final int indexSeksi = _localEmptySections.indexOf(
                      cleanOldName,
                    );
                    if (indexSeksi != -1) {
                      _localEmptySections[indexSeksi] = cleanNewName;
                    }
                  }

                  final baseDir = await _storageService.getBaseDirSetting();
                  List<PromptGroup> groupsToUpdate = [];
                  for (var group in _promptGroups) {
                    final currentSecName = group.sectionName.isEmpty
                        ? 'GENERAL'
                        : group.sectionName.toUpperCase();
                    if (currentSecName == cleanOldName) {
                      groupsToUpdate.add(group);
                    }
                  }

                  for (var group in groupsToUpdate) {
                    final updatedGroup = PromptGroup(
                      id: group.id,
                      title: group.title,
                      sectionName: cleanNewName,
                      icon: group.icon,
                      lastUpdated: DateTime.now().toIso8601String(),
                      prompts: group.prompts,
                    );
                    await _storageService.savePromptGroup(
                      baseDir,
                      group.id,
                      jsonEncode(updatedGroup.toJson()),
                    );
                  }

                  if (mounted) {
                    setState(() {
                      for (var group in _promptGroups) {
                        final currentSecName = group.sectionName.isEmpty
                            ? 'GENERAL'
                            : group.sectionName.toUpperCase();
                        if (currentSecName == cleanOldName) {
                          int idx = _promptGroups.indexOf(group);
                          if (idx != -1) {
                            _promptGroups[idx] = PromptGroup(
                              id: group.id,
                              title: group.title,
                              sectionName: cleanNewName,
                              icon: group.icon,
                              lastUpdated: DateTime.now().toIso8601String(),
                              prompts: group.prompts,
                            );
                          }
                        }
                      }
                      isSectionEditMode = true;
                    });
                    await _loadAllPrompts();
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal mengubah nama seksi: $e')),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void deleteSection(String sectionName) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Hapus Seksi "$sectionName"?'),
          content: Text(
            'Tindakan ini akan menghapus seluruh grup prompt yang ada di dalam seksi "$sectionName". Perubahan ini permanen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  if (_localEmptySections.contains(sectionName.toUpperCase())) {
                    _localEmptySections.remove(sectionName.toUpperCase());
                  }

                  final baseDir = await _storageService.getBaseDirSetting();
                  for (var group in _promptGroups) {
                    final currentSecName = group.sectionName.isEmpty
                        ? 'GENERAL'
                        : group.sectionName.toUpperCase();
                    if (currentSecName == sectionName.toUpperCase()) {
                      await _storageService.deletePromptGroup(
                        baseDir,
                        group.id,
                      );
                    }
                  }
                  if (mounted) {
                    setState(() {
                      isSectionEditMode = true;
                    });
                    _loadAllPrompts();
                  }
                } catch (e) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus seksi: $e')),
                  );
                }
              },
              child: const Text(
                'Hapus All',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddGroupDialog({String? defaultSection}) async {
    final titleController = TextEditingController();
    final iconController = TextEditingController(text: '📝');
    final sectionController = TextEditingController(text: defaultSection ?? '');
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Group Prompt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Group (e.g. Copywriting, Coding)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: iconController,
                  decoration: const InputDecoration(labelText: 'Icon Emoji'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: sectionController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Seksi / Kategori',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                try {
                  final baseDir = await _storageService.getBaseDirSetting();
                  final id = DateTime.now().millisecondsSinceEpoch.toString();
                  final targetSection = sectionController.text.trim().isEmpty
                      ? 'General'
                      : sectionController.text.trim();

                  final newGroup = PromptGroup(
                    id: id,
                    title: titleController.text.trim(),
                    sectionName: targetSection,
                    icon: iconController.text.trim().isEmpty
                        ? '📝'
                        : iconController.text.trim(),
                    lastUpdated: DateTime.now().toIso8601String(),
                    prompts: [],
                  );

                  final jsonContent = jsonEncode(newGroup.toJson());
                  await _storageService.savePromptGroup(
                    baseDir,
                    id,
                    jsonContent,
                  );

                  _localEmptySections.remove(targetSection.toUpperCase());

                  if (mounted) {
                    Navigator.pop(context);
                    setState(() {
                      isSectionEditMode = isSectionEditMode;
                    });
                    _loadAllPrompts();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menyimpan group: $e')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _moveGroupOrderHorizontal(
    List<PromptGroup> currentList,
    int index,
    int direction,
  ) async {
    int targetIndex = index + direction;
    if (targetIndex < 0 || targetIndex >= currentList.length) return;

    setState(() {
      final item = currentList.removeAt(index);
      currentList.insert(targetIndex, item);

      final List<PromptGroup> updatedGlobal = [];
      final Set<String> processedSections = {};
      for (var g in _promptGroups) {
        final sec = g.sectionName.toUpperCase();
        if (!processedSections.contains(sec)) {
          processedSections.add(sec);
          if (sec == item.sectionName.toUpperCase()) {
            updatedGlobal.addAll(currentList);
          } else {
            updatedGlobal.addAll(
              _promptGroups.where((x) => x.sectionName.toUpperCase() == sec),
            );
          }
        }
      }
      _promptGroups = updatedGlobal;
    });

    try {
      final baseDir = await _storageService.getBaseDirSetting();
      for (var group in _promptGroups) {
        await _storageService.savePromptGroup(
          baseDir,
          group.id,
          jsonEncode(group.toJson()),
        );
      }
    } catch (e) {
      debugPrint("Gagal mengamankan urutan group: $e");
    }
  }

  void _showEditGroupDialog(PromptGroup group) {
    final titleController = TextEditingController(text: group.title);
    final iconController = TextEditingController(text: group.icon);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama & Ikon Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Judul Group'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(labelText: 'Ikon Emoji'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                final baseDir = await _storageService.getBaseDirSetting();
                final updatedGroup = PromptGroup(
                  id: group.id,
                  title: titleController.text.trim(),
                  sectionName: group.sectionName,
                  icon: iconController.text.trim().isEmpty
                      ? '📝'
                      : iconController.text.trim(),
                  lastUpdated: DateTime.now().toIso8601String(),
                  prompts: group.prompts,
                );

                await _storageService.savePromptGroup(
                  baseDir,
                  group.id,
                  jsonEncode(updatedGroup.toJson()),
                );
                _loadAllPrompts();
              } catch (e) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal mengubah group: $e')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showMoveSectionDialog(PromptGroup group) async {
    final Map<String, List<PromptGroup>> sectionsMap = {};
    for (var g in _promptGroups) {
      final name = g.sectionName.isEmpty
          ? 'GENERAL'
          : g.sectionName.toUpperCase();
      sectionsMap.putIfAbsent(name, () => []);
    }
    for (var sec in _localEmptySections) {
      sectionsMap.putIfAbsent(sec, () => []);
    }
    final List<String> availableSections = sectionsMap.keys.toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pindahkan Group ke Seksi Lain'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableSections.length,
            itemBuilder: (context, index) {
              final secName = availableSections[index];
              return ListTile(
                title: Text(secName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  try {
                    final baseDir = await _storageService.getBaseDirSetting();
                    final updatedGroup = PromptGroup(
                      id: group.id,
                      title: group.title,
                      sectionName: secName,
                      icon: group.icon,
                      lastUpdated: DateTime.now().toIso8601String(),
                      prompts: group.prompts,
                    );

                    await _storageService.savePromptGroup(
                      baseDir,
                      group.id,
                      jsonEncode(updatedGroup.toJson()),
                    );
                    _localEmptySections.remove(secName.toUpperCase());
                    _loadAllPrompts();
                  } catch (e) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal memindahkan seksi group: $e'),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _deleteGroupItem(PromptGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Group "${group.title}"?'),
        content: const Text(
          'Tindakan ini akan menghapus group ini secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                final baseDir = await _storageService.getBaseDirSetting();
                await _storageService.deletePromptGroup(baseDir, group.id);
                _loadAllPrompts();
              } catch (e) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal menghapus group: $e')),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    int index,
    String sectionName,
    Color color,
    bool hideTitle,
    VoidCallback onAddPressed,
    int totalSections,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: Colors.indigo.withOpacity(0.1),
        highlightColor: Colors.indigo.withOpacity(0.05),
        onLongPress: () {
          // GUARD PENYALANGAN: Jika mode edit card sedang aktif, jangan ijinkan edit seksi terbuka
          if (isCardEditMode) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Matikan Mode Edit Kotak/Card terlebih dahulu!'),
                duration: Duration(seconds: 1),
              ),
            );
            return;
          }
          setState(() {
            isSectionEditMode = !isSectionEditMode;
          });
        },
        onTap: () {},
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: isSectionEditMode
              ? const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)
              : const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  hideTitle
                      ? const SizedBox.shrink()
                      : Text(
                          sectionName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                  if (isSectionEditMode) ...[
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_upward,
                            size: 18,
                            color: Colors.blueGrey,
                          ),
                          onPressed: index > 0
                              ? () => moveSectionOrder(index, -1)
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_downward,
                            size: 18,
                            color: Colors.blueGrey,
                          ),
                          onPressed: index < totalSections - 1
                              ? () => moveSectionOrder(index, 1)
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.indigo,
                          ),
                          onPressed: () => editSectionName(sectionName),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => deleteSection(sectionName),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.indigo,
                            size: 18,
                          ),
                          tooltip: 'Tambah Group ke Seksi Ini',
                          onPressed: onAddPressed,
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox.shrink(),
                  ],
                ],
              ),
              if (!hideTitle) const Divider(height: 2, thickness: 1),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<PromptGroup>> sectionsMap = {};

    for (var group in _promptGroups) {
      final secName = group.sectionName.isEmpty
          ? 'GENERAL'
          : group.sectionName.toUpperCase();
      if (!sectionsMap.containsKey(secName)) {
        sectionsMap[secName] = [];
      }
      sectionsMap[secName]!.add(group);
    }

    for (var sec in _localEmptySections) {
      sectionsMap.putIfAbsent(sec, () => []);
    }

    final sectionKeys = sectionsMap.keys.toList();
    if (sectionKeys.contains('GENERAL')) {
      sectionKeys.remove('GENERAL');
      sectionKeys.insert(0, 'GENERAL');
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('My Prompts'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllPrompts,
          ),
        ],
      ),
      drawer: const DrawerMenu(isPromptActive: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _promptGroups.isEmpty && _localEmptySections.isEmpty
          ? const Center(
              child: Text('Belum ada data seksi / prompt di penyimpanan.'),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: sectionKeys.length,
                  itemBuilder: (context, sIndex) {
                    final sectionName = sectionKeys[sIndex];
                    final groupsInSection = sectionsMap[sectionName]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          sIndex,
                          sectionName,
                          Colors.indigo[900]!,
                          false,
                          () =>
                              _showAddGroupDialog(defaultSection: sectionName),
                          sectionKeys.length,
                        ),
                        groupsInSection.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.only(
                                  left: 24,
                                  top: 12,
                                  bottom: 12,
                                ),
                                child: Text(
                                  'Belum ada group di seksi ini.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : _buildPromptGrid(groupsInSection, constraints),
                        const SizedBox(height: 10),
                      ],
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddSectionDialog,
        backgroundColor: Colors.indigo,
        tooltip: 'Tambah Seksi Baru',
        child: const Icon(
          Icons.create_new_folder_outlined,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPromptGrid(
    List<PromptGroup> promptList,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isCardEditMode ? 0.85 : 1.15,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: promptList.length,
      itemBuilder: (context, index) {
        final promptGroup = promptList[index];
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.indigo, width: 3.5),
          ),
          color: Colors.white,
          child: Column(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isCardEditMode ? 0 : 16),
                    bottomRight: Radius.circular(isCardEditMode ? 0 : 16),
                  ),
                  onLongPress: () {
                    // GUARD PENYALANGAN: Jika mode edit seksi sedang aktif, jangan ijinkan edit card terbuka
                    if (isSectionEditMode) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Matikan Mode Edit Kategori/Seksi terlebih dahulu!',
                          ),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      isCardEditMode = !isCardEditMode;
                    });
                  },
                  onTap: isCardEditMode
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PromptDetailScreen(promptGroup: promptGroup),
                            ),
                          ).then((_) => _loadAllPrompts());
                        },
                  child: SizedBox.expand(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            promptGroup.icon,
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            promptGroup.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${promptGroup.prompts.length} Item',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (isCardEditMode) ...[
                Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 18),
                        color: index > 0 ? Colors.indigo : Colors.grey[300],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: index > 0
                            ? () => _moveGroupOrderHorizontal(
                                promptList,
                                index,
                                -1,
                              )
                            : null,
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _showEditGroupDialog(promptGroup);
                          } else if (value == 'move_section') {
                            _showMoveSectionDialog(promptGroup);
                          } else if (value == 'delete') {
                            _deleteGroupItem(promptGroup);
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18, color: Colors.teal),
                                SizedBox(width: 10),
                                Text(
                                  'Ubah Nama & Ikon',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'move_section',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.drive_file_move_outlined,
                                  size: 18,
                                  color: Colors.indigo,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Pindahkan Seksi',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Hapus Group',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        color: index < promptList.length - 1
                            ? Colors.indigo
                            : Colors.grey[300],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: index < promptList.length - 1
                            ? () => _moveGroupOrderHorizontal(
                                promptList,
                                index,
                                1,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// =========================================================================
// 2. WIDGET HALAMAN DETAIL DAFTAR BANYAK PROMPT (Tetap sama)
// =========================================================================
class PromptDetailScreen extends StatelessWidget {
  final PromptGroup promptGroup;
  const PromptDetailScreen({super.key, required this.promptGroup});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            Text(promptGroup.icon),
            const SizedBox(width: 8),
            Text(promptGroup.title),
          ],
        ),
        backgroundColor: Colors.indigo,
      ),
      body: promptGroup.prompts.isEmpty
          ? const Center(
              child: Text(
                'Tidak ada item prompt di dalam grup ini.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: promptGroup.prompts.length,
              itemBuilder: (context, index) {
                final item = promptGroup.prompts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo[50],
                      child: Icon(
                        item.isFavorite ? Icons.star : Icons.description,
                        color: item.isFavorite ? Colors.orange : Colors.indigo,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.actAs,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.indigo,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        item.content,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.copy,
                        color: Colors.grey,
                        size: 20,
                      ),
                      tooltip: 'Salin Prompt',
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: item.content),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Berhasil menyalin: ${item.actAs}'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
