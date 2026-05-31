// lib/features/prompt/presentation/screens/prompt_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../../data/models/prompt_model.dart';
import '../controllers/prompt_controller.dart';

// =========================================================================
// 1. WIDGET HALAMAN UTAMA PROMPT (UI ONLY)
// =========================================================================
class PromptScreen extends StatefulWidget {
  const PromptScreen({super.key});

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  late final PromptController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PromptController();
    _controller.loadAllPrompts(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // === DIALOG DI LEVEL UI ===
  void _showAddSectionDialog() {
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
              if (sectionController.text.trim().isNotEmpty) {
                _controller.addSection(sectionController.text, context);
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditSectionNameDialog(String oldName) {
    final textController = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () {
              _controller.editSectionName(
                oldName,
                textController.text,
                context,
              );
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSectionDialog(String sectionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () {
              _controller.deleteSection(sectionName, context);
              Navigator.pop(context);
            },
            child: const Text(
              'Hapus All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGroupDialog({String? defaultSection}) {
    final titleController = TextEditingController();
    final iconController = TextEditingController(text: '📝');
    final sectionController = TextEditingController(text: defaultSection ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              _controller.addPromptGroup(
                title: titleController.text,
                icon: iconController.text,
                section: sectionController.text,
                context: context,
              );
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
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
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              _controller.editGroup(
                group,
                titleController.text,
                iconController.text,
                context,
              );
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showMoveSectionDialog(PromptGroup group) {
    final Map<String, List<PromptGroup>> sectionsMap = {};
    for (var g in _controller.promptGroups) {
      final name = g.sectionName.isEmpty
          ? 'GENERAL'
          : g.sectionName.toUpperCase();
      sectionsMap.putIfAbsent(name, () => []);
    }
    for (var sec in _controller.localEmptySections) {
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
                onTap: () {
                  _controller.moveGroupToSection(group, secName, context);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDeleteGroupItemDialog(PromptGroup group) {
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
            onPressed: () {
              _controller.deleteGroupItem(group, context);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // === FUNGSI BARU: DIALOG UNTUK INPUT TAMBAH ITEM PROMPT ===
  void _showAddPromptItemDialog(PromptGroup group) {
    final titleController = TextEditingController();
    final descController =
        TextEditingController(); // Deskripsi tambahan pendukung
    final contentController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.playlist_add, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Tambah Item Prompt Baru'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                // Input Title (Bertindak Sebagai / Act As)
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul / Peran (Title)',
                    hintText: 'Contoh: Ahli Copywriting, Senior Flutter',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Title tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),

                // Input Deskripsi (Catatan/Keterangan singkat)
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Pendek (Opsional)',
                    hintText: 'Contoh: Untuk caption instagram promosi produk',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Input Isi Prompt (Content utama)
                TextFormField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Isi Perintah Prompt (Content)',
                    hintText:
                        'Tulis template instruksi AI Anda secara lengkap di sini...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => v!.trim().isEmpty
                      ? 'Isi prompt tidak boleh kosong'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _controller.addPromptItemToGroup(
                  group: group,
                  title: titleController.text,
                  description: descController.text,
                  content: contentController.text,
                  context: context,
                );
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Simpan Prompt',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final Map<String, List<PromptGroup>> sectionsMap = {};

        for (var group in _controller.promptGroups) {
          final secName = group.sectionName.isEmpty
              ? 'GENERAL'
              : group.sectionName.toUpperCase();
          if (!sectionsMap.containsKey(secName)) {
            sectionsMap[secName] = [];
          }
          sectionsMap[secName]!.add(group);
        }

        for (var sec in _controller.localEmptySections) {
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
                onPressed: () => _controller.loadAllPrompts(context),
              ),
            ],
          ),
          drawer: const DrawerMenu(isPromptActive: true),
          body: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _controller.promptGroups.isEmpty &&
                    _controller.localEmptySections.isEmpty
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
                              () => _showAddGroupDialog(
                                defaultSection: sectionName,
                              ),
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
                                : _buildPromptGrid(
                                    groupsInSection,
                                    constraints,
                                  ),
                            const SizedBox(height: 10),
                          ],
                        );
                      },
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddSectionDialog,
            backgroundColor: Colors.indigo,
            tooltip: 'Tambah Seksi Baru',
            child: const Icon(
              Icons.create_new_folder_outlined,
              size: 28,
              color: Colors.white,
            ),
          ),
        );
      },
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
          if (_controller.isCardEditMode) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Matikan Mode Edit Kotak/Card terlebih dahulu!'),
                duration: Duration(seconds: 1),
              ),
            );
            return;
          }
          _controller.toggleSectionEditMode();
        },
        onTap: () {},
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: _controller.isSectionEditMode
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
                  if (_controller.isSectionEditMode) ...[
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_upward,
                            size: 18,
                            color: Colors.blueGrey,
                          ),
                          onPressed: index > 0
                              ? () => _controller.moveSectionOrder(
                                  index,
                                  -1,
                                  context,
                                )
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_downward,
                            size: 18,
                            color: Colors.blueGrey,
                          ),
                          onPressed: index < totalSections - 1
                              ? () => _controller.moveSectionOrder(
                                  index,
                                  1,
                                  context,
                                )
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.indigo,
                          ),
                          onPressed: () =>
                              _showEditSectionNameDialog(sectionName),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          onPressed: () =>
                              _showDeleteSectionDialog(sectionName),
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
        childAspectRatio: _controller.isCardEditMode ? 0.85 : 1.15,
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
                    bottomLeft: Radius.circular(
                      _controller.isCardEditMode ? 0 : 16,
                    ),
                    bottomRight: Radius.circular(
                      _controller.isCardEditMode ? 0 : 16,
                    ),
                  ),
                  onLongPress: () {
                    if (_controller.isSectionEditMode) {
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
                    _controller.toggleCardEditMode();
                  },
                  onTap: _controller.isCardEditMode
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PromptDetailScreen(promptGroup: promptGroup),
                            ),
                          ).then((_) => _controller.loadAllPrompts(context));
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
              if (_controller.isCardEditMode) ...[
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
                            ? () => _controller.moveGroupOrderHorizontal(
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
                            _showDeleteGroupItemDialog(promptGroup);
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
                            ? () => _controller.moveGroupOrderHorizontal(
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
// 2. WIDGET HALAMAN DETAIL DAFTAR BANYAK PROMPT
// =========================================================================
// =========================================================================
// 2. WIDGET HALAMAN DETAIL DAFTAR BANYAK PROMPT
// =========================================================================
class PromptDetailScreen extends StatelessWidget {
  final PromptGroup promptGroup;

  const PromptDetailScreen({super.key, required this.promptGroup});

  // Fungsi internal untuk memunculkan dialog tambah item prompt langsung di halaman detail
  void _showAddPromptItemDialog(BuildContext context, PromptGroup group) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final contentController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final PromptController controller = PromptController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.playlist_add, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Tambah Item Prompt'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul / Peran (Title)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Title tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Pendek (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Isi Perintah Prompt (Content)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => v!.trim().isEmpty
                      ? 'Isi prompt tidak boleh kosong'
                      : null,
                ),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                controller.addPromptItemToGroup(
                  group: group,
                  title: titleController.text,
                  description: descController.text,
                  content: contentController.text,
                  context: context,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text(
              'Simpan Prompt',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // PERBAIKAN: Langsung panggil 'promptGroup' tanpa kata kunci 'widget.'
    final currentGroup = promptGroup;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            Text(currentGroup.icon),
            const SizedBox(width: 8),
            Text(
              currentGroup.title,
            ), // PERBAIKAN: Menggunakan .title sesuai model data
          ],
        ),
        backgroundColor: Colors.indigo,
      ),
      body: currentGroup.prompts.isEmpty
          ? const Center(
              child: Text(
                'Tidak ada item prompt di dalam grup ini.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: currentGroup.prompts.length,
              itemBuilder: (context, index) {
                final item = currentGroup.prompts[index];
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
      // MENAMBAHKAN FLOATING ACTION BUTTON DI LEVEL DETAIL SCREEN
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPromptItemDialog(context, currentGroup),
        backgroundColor: Colors.indigo,
        tooltip: 'Tambah Item Prompt Baru',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
