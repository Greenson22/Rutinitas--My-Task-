// lib/features/prompt/presentation/screens/prompt_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rutinitasku/core/presentation/widgets/base_popup_dialog.dart';
import '../../data/models/prompt_model.dart';
import '../controllers/prompt_controller.dart';
import '../widgets/prompt_detail_screen/add_prompt_item_dialog.dart';

class PromptDetailScreen extends StatefulWidget {
  final PromptGroup promptGroup;

  const PromptDetailScreen({super.key, required this.promptGroup});

  @override
  State<PromptDetailScreen> createState() => _PromptDetailScreenState();
}

class _PromptDetailScreenState extends State<PromptDetailScreen> {
  late PromptGroup _currentGroup;
  final PromptController _controller = PromptController();

  // State untuk Fitur Search via Long Press AppBar
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentGroup = widget.promptGroup; //[cite: 1]
    // Muat semua grup ke controller agar fitur pindah/salin bisa mengambil daftar grup lain
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadAllPrompts(context); //[cite: 1]
    });

    // Listener untuk mendeteksi perubahan input pencarian
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    // Pastikan state multi-select dibersihkan saat keluar dari screen ini
    _controller.clearSelectedPrompts(); //[cite: 1]
    _searchController.dispose();
    super.dispose();
  }

  void _openAddPromptDialog() {
    //[cite: 1]
    showDialog(
      context: context,
      builder: (ctx) => AddPromptItemDialog(
        currentGroup: _currentGroup,
        controller: _controller,
        onPromptAdded: (updatedGroup) {
          setState(() {
            _currentGroup = updatedGroup;
          });
        },
      ),
    );
  }

  // ========= FITUR EDIT, HAPUS, MOVE/COPY DIALOG =========
  void _openEditPromptDialog(PromptItem item) {
    //[cite: 1]
    final actAsController = TextEditingController(text: item.actAs);
    final descController = TextEditingController(text: item.description ?? '');
    final contentController = TextEditingController(text: item.content);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => BasePopupDialog(
        themeColor: Colors.indigo,
        titleColor: Colors.white,
        title: Row(
          children: const [
            Icon(Icons.edit_note_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Edit Item Prompt',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: actAsController,
                  decoration: const InputDecoration(
                    labelText: 'Act As / Judul',
                    hintText: 'Misal: Ahli SEO, Kode Reviewer',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Judul tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Singkat (Opsional)',
                    hintText: 'Keterangan singkat guna/fungsi prompt',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contentController,
                  maxLines: 5,
                  minLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Isi Prompt template',
                    hintText: 'Masukkan instruksi detail AI...',
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
        footer: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(ctx);
                    final res = await _controller.editPromptItem(
                      group: _currentGroup,
                      itemId: item.id,
                      newActAs: actAsController.text,
                      newDescription: descController.text,
                      newContent: contentController.text,
                      context: context,
                    );
                    if (res != null) {
                      setState(() {
                        _currentGroup = res;
                      });
                    }
                  }
                },
                child: const Text(
                  'Simpan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteSingleDialog(PromptItem item) {
    //[cite: 1]
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Prompt "${item.actAs}"?'),
        content: const Text('Tindakan ini permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await _controller.deletePromptItem(
                group: _currentGroup,
                itemId: item.id,
                context: context,
              );
              if (res != null) {
                setState(() {
                  _currentGroup = res;
                });
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteMassiveDialog(int totalSelected) {
    //[cite: 1]
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Item Terpilih?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus $totalSelected prompt ini secara permanen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await _controller.deleteSelectedPromptItems(
                group: _currentGroup,
                context: context,
              );
              if (res != null) {
                setState(() {
                  _currentGroup = res;
                });
              }
            },
            child: const Text(
              'Hapus Semua',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoveOrCopyDialog(PromptItem item) {
    //[cite: 1]
    final otherGroups = _controller.promptGroups
        .where((g) => g.id != _currentGroup.id)
        .toList();
    if (otherGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada grup prompt lain yang tersedia.'),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => BasePopupDialog(
        title: const Text(
          'Pindahkan / Salin Prompt',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        themeColor: Colors.indigo,
        titleColor: Colors.white,
        content: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Grup Target:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: otherGroups.length,
                  itemBuilder: (c, idx) {
                    final targetG = otherGroups[idx];
                    return ListTile(
                      dense: true,
                      leading: Text(
                        targetG.icon,
                        style: const TextStyle(fontSize: 18),
                      ),
                      title: Text(
                        targetG.title,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        targetG.sectionName,
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final res = await _controller
                                  .moveOrCopyPromptItem(
                                    sourceGroup: _currentGroup,
                                    targetGroup: targetG,
                                    item: item,
                                    isCopy: true,
                                    context: context,
                                  );
                              if (res != null) {
                                setState(() {
                                  _currentGroup = res;
                                });
                              }
                            },
                            child: const Text(
                              'Salin',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final res = await _controller
                                  .moveOrCopyPromptItem(
                                    sourceGroup: _currentGroup,
                                    targetGroup: targetG,
                                    item: item,
                                    isCopy: false,
                                    context: context,
                                  );
                              if (res != null) {
                                setState(() {
                                  _currentGroup = res;
                                });
                              }
                            },
                            child: const Text(
                              'Pindah',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    //[cite: 1]
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Isi prompt berhasil disalin ke clipboard!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showMoveMassiveDialog(int totalSelected) {
    //[cite: 1]
    final otherGroups = _controller.promptGroups
        .where((g) => g.id != _currentGroup.id)
        .toList();
    if (otherGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada grup prompt lain yang tersedia.'),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => BasePopupDialog(
        title: Text(
          'Pindahkan $totalSelected Prompt Terpilih',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        themeColor: Colors.indigo,
        titleColor: Colors.white,
        content: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Grup Target Pemindahan:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: otherGroups.length,
                  itemBuilder: (c, idx) {
                    final targetG = otherGroups[idx];
                    return ListTile(
                      dense: true,
                      leading: Text(
                        targetG.icon,
                        style: const TextStyle(fontSize: 18),
                      ),
                      title: Text(
                        targetG.title,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        targetG.sectionName,
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final res = await _controller.moveSelectedPromptItems(
                            sourceGroup: _currentGroup,
                            targetGroup: targetG,
                            context: context,
                          );
                          if (res != null) {
                            setState(() {
                              _currentGroup = res;
                            });
                          }
                        },
                        child: const Text(
                          'Pindah Ke Sini',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final PromptGroup updatedGroup = _controller.promptGroups.firstWhere(
          (g) => g.id == _currentGroup.id,
          orElse: () => _currentGroup,
        );
        _currentGroup = updatedGroup; //[cite: 1]

        final bool isSelectMode = _controller.isMultiSelectMode; //[cite: 1]
        final int totalSelected =
            _controller.selectedPromptIds.length; //[cite: 1]

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA), //[cite: 1]
          // 1. Bungkus AppBar dengan PreferredSize + GestureDetector agar bisa mendeteksi Long Press
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: GestureDetector(
              onLongPress: () {
                if (!isSelectMode) {
                  setState(() {
                    _isSearchMode = !_isSearchMode; // Toggle mode search on/off
                    if (!_isSearchMode) _searchController.clear();
                  });
                }
              },
              child: AppBar(
                title: Text(
                  isSelectMode
                      ? '$totalSelected Terpilih'
                      : _currentGroup.title, //[cite: 1]
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: isSelectMode
                    ? Colors.red[900]
                    : const Color(0xFF3F51B5), //[cite: 1]
                elevation: 0, //[cite: 1]
                leading: isSelectMode
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () =>
                            _controller.clearSelectedPrompts(), //[cite: 1]
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context), //[cite: 1]
                      ),
                actions: [
                  if (isSelectMode) ...[
                    //[cite: 1]
                    IconButton(
                      icon: const Icon(
                        Icons.drive_file_move,
                        color: Colors.white,
                      ), //[cite: 1]
                      tooltip: 'Pindahkan Semua Terpilih',
                      onPressed: () =>
                          _showMoveMassiveDialog(totalSelected), //[cite: 1]
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ), //[cite: 1]
                      tooltip: 'Hapus Semua Terpilih',
                      onPressed: () =>
                          _showDeleteMassiveDialog(totalSelected), //[cite: 1]
                    ),
                  ] else if (_isSearchMode) ...[
                    // Berikan tombol close search di AppBar jika search aktif
                    IconButton(
                      icon: const Icon(
                        Icons.search_off_rounded,
                        color: Colors.white,
                      ),
                      tooltip: 'Tutup Pencarian',
                      onPressed: () {
                        setState(() {
                          _isSearchMode = false;
                          _searchController.clear();
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              // 2. WIDGET SEARCH DENGAN ANIMASI MEMBUKA (Slide/Expand down)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                height: _isSearchMode ? 70.0 : 0.0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                color: const Color(
                  0xFF3F51B5,
                ), // Warna latar belakang area search disamakan AppBar
                clipBehavior: Clip
                    .antiAlias, // Mencegah teks meluber saat animasi mengecil
                child: _isSearchMode
                    ? TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari judul atau deskripsi prompt...',
                          hintStyle: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white70,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.15),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // 3. DAFTAR ITEM PROMPT
              Expanded(
                child:
                    _currentGroup
                        .prompts
                        .isEmpty //[cite: 1]
                    ? const Center(
                        child: Text(
                          'Grup ini belum memiliki item prompt.\nSilakan tambah menggunakan tombol di bawah.', //[cite: 1]
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : () {
                        // LOGIKA FILTERING
                        final filteredPrompts = _currentGroup.prompts.where((
                          item,
                        ) {
                          if (_searchQuery.isEmpty) return true;
                          final titleMatch = item.actAs.toLowerCase().contains(
                            _searchQuery,
                          );
                          final descMatch =
                              item.description?.toLowerCase().contains(
                                _searchQuery,
                              ) ??
                              false;
                          return titleMatch || descMatch;
                        }).toList();

                        if (filteredPrompts.isEmpty) {
                          return const Center(
                            child: Text(
                              'Tidak ada item prompt yang cocok.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        // LOGIKA SORTING FAVORITE
                        filteredPrompts.sort((a, b) {
                          if (a.isFavorite && !b.isFavorite)
                            return -1; //[cite: 1]
                          if (!a.isFavorite && b.isFavorite)
                            return 1; //[cite: 1]
                          return 0; //[cite: 1]
                        });

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          itemCount: filteredPrompts.length,
                          itemBuilder: (context, index) {
                            final item = filteredPrompts[index];
                            final bool isSelected = _controller
                                .selectedPromptIds
                                .contains(item.id); //[cite: 1]
                            final bool hasDescription =
                                item.description != null &&
                                item.description!.trim().isNotEmpty; //[cite: 1]

                            return Card(
                              elevation: isSelected ? 4 : 0, //[cite: 1]
                              color: isSelected
                                  ? Colors.red.withOpacity(0.08)
                                  : Colors.white, //[cite: 1]
                              margin: const EdgeInsets.only(
                                bottom: 12,
                              ), //[cite: 1]
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  16,
                                ), //[cite: 1]
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.red[700]!
                                      : Colors.grey.shade100, //[cite: 1]
                                  width: isSelected ? 1.5 : 1, //[cite: 1]
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  16,
                                ), //[cite: 1]
                                onTap: () {
                                  if (isSelectMode) {
                                    //[cite: 1]
                                    _controller.toggleSelectPromptItem(
                                      item.id,
                                    ); //[cite: 1]
                                  } else {
                                    _copyToClipboard(item.content); //[cite: 1]
                                  }
                                },
                                onLongPress: () {
                                  _controller.toggleSelectPromptItem(
                                    item.id,
                                  ); //[cite: 1]
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16), //[cite: 1]
                                  child: Row(
                                    children: [
                                      if (isSelectMode) ...[
                                        //[cite: 1]
                                        Checkbox(
                                          activeColor:
                                              Colors.red[700], //[cite: 1]
                                          value: isSelected, //[cite: 1]
                                          onChanged: (_) => _controller
                                              .toggleSelectPromptItem(
                                                item.id,
                                              ), //[cite: 1]
                                        ),
                                        const SizedBox(width: 12), //[cite: 1]
                                      ] else ...[
                                        Container(
                                          width: 44, //[cite: 1]
                                          height: 44, //[cite: 1]
                                          decoration: const BoxDecoration(
                                            color: Color(
                                              0xFFE8EAF6,
                                            ), //[cite: 1]
                                            shape: BoxShape.circle, //[cite: 1]
                                          ),
                                          child: const Icon(
                                            Icons
                                                .description_rounded, //[cite: 1]
                                            color: Color(
                                              0xFF3F51B5,
                                            ), //[cite: 1]
                                            size: 20, //[cite: 1]
                                          ),
                                        ),
                                        const SizedBox(width: 16), //[cite: 1]
                                      ],
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.actAs, //[cite: 1]
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                      color: Color(0xFF2E3A59),
                                                    ),
                                                    overflow: TextOverflow
                                                        .ellipsis, //[cite: 1]
                                                  ),
                                                ),
                                                if (item.isFavorite) ...[
                                                  //[cite: 1]
                                                  const SizedBox(
                                                    width: 6,
                                                  ), //[cite: 1]
                                                  const Icon(
                                                    Icons
                                                        .star_rounded, //[cite: 1]
                                                    color: Colors
                                                        .amber, //[cite: 1]
                                                    size: 20, //[cite: 1]
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 4,
                                            ), //[cite: 1]
                                            Text(
                                              hasDescription
                                                  ? item.description! //[cite: 1]
                                                  : 'Tidak ada deskripsi', //[cite: 1]
                                              style: TextStyle(
                                                fontSize: 13, //[cite: 1]
                                                color: hasDescription
                                                    ? Colors
                                                          .grey[600] //[cite: 1]
                                                    : Colors
                                                          .grey[400], //[cite: 1]
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // ================= ACTION BUTTONS =================
                                      if (isSelectMode &&
                                          totalSelected <= 1) ...[
                                        //[cite: 1]
                                        const SizedBox(width: 8), //[cite: 1]
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(
                                              width: 12,
                                            ), //[cite: 1]
                                            PopupMenuButton<String>(
                                              icon: const Icon(
                                                Icons
                                                    .more_vert_rounded, //[cite: 1]
                                                color:
                                                    Colors.black38, //[cite: 1]
                                                size: 20, //[cite: 1]
                                              ),
                                              padding:
                                                  EdgeInsets.zero, //[cite: 1]
                                              constraints:
                                                  const BoxConstraints(), //[cite: 1]
                                              onSelected: (value) async {
                                                if (value == 'edit') {
                                                  //[cite: 1]
                                                  _openEditPromptDialog(
                                                    item,
                                                  ); //[cite: 1]
                                                } else if (value ==
                                                    'toggle_favorite') {
                                                  //[cite: 1]
                                                  final res = await _controller
                                                      .toggleFavoritePromptItem(
                                                        //[cite: 1]
                                                        group:
                                                            _currentGroup, //[cite: 1]
                                                        itemId:
                                                            item.id, //[cite: 1]
                                                        context:
                                                            context, //[cite: 1]
                                                      );
                                                  if (res != null) {
                                                    //[cite: 1]
                                                    setState(() {
                                                      _currentGroup = res;
                                                    });
                                                  }
                                                } else if (value ==
                                                    'move_or_copy') {
                                                  //[cite: 1]
                                                  _showMoveOrCopyDialog(
                                                    item,
                                                  ); //[cite: 1]
                                                } else if (value == 'delete') {
                                                  //[cite: 1]
                                                  _showDeleteSingleDialog(
                                                    item,
                                                  ); //[cite: 1]
                                                }
                                              },
                                              itemBuilder: (ctx) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .edit_note_rounded, //[cite: 1]
                                                        size: 20, //[cite: 1]
                                                        color: Colors
                                                            .teal, //[cite: 1]
                                                      ),
                                                      SizedBox(
                                                        width: 10,
                                                      ), //[cite: 1]
                                                      Text(
                                                        'Edit Prompt', //[cite: 1]
                                                        style: TextStyle(
                                                          fontSize:
                                                              13, //[cite: 1]
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value:
                                                      'toggle_favorite', //[cite: 1]
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        item
                                                                .isFavorite //[cite: 1]
                                                            ? Icons
                                                                  .star_rounded //[cite: 1]
                                                            : Icons
                                                                  .star_border_rounded, //[cite: 1]
                                                        size: 20, //[cite: 1]
                                                        color: Colors
                                                            .amber, //[cite: 1]
                                                      ),
                                                      const SizedBox(
                                                        width: 10,
                                                      ), //[cite: 1]
                                                      Text(
                                                        item
                                                                .isFavorite //[cite: 1]
                                                            ? 'Hapus Favorit' //[cite: 1]
                                                            : 'Jadikan Favorit', //[cite: 1]
                                                        style: const TextStyle(
                                                          fontSize:
                                                              13, //[cite: 1]
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value:
                                                      'move_or_copy', //[cite: 1]
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .drive_file_move_outlined, //[cite: 1]
                                                        size: 20, //[cite: 1]
                                                        color: Colors
                                                            .indigo, //[cite: 1]
                                                      ),
                                                      SizedBox(
                                                        width: 10,
                                                      ), //[cite: 1]
                                                      Text(
                                                        'Pindah / Salin', //[cite: 1]
                                                        style: TextStyle(
                                                          fontSize:
                                                              13, //[cite: 1]
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuDivider(), //[cite: 1]
                                                const PopupMenuItem(
                                                  value: 'delete', //[cite: 1]
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .delete_outline_rounded, //[cite: 1]
                                                        size: 20, //[cite: 1]
                                                        color: Colors
                                                            .redAccent, //[cite: 1]
                                                      ),
                                                      SizedBox(
                                                        width: 10,
                                                      ), //[cite: 1]
                                                      Text(
                                                        'Hapus Prompt', //[cite: 1]
                                                        style: TextStyle(
                                                          fontSize:
                                                              13, //[cite: 1]
                                                          color: Colors
                                                              .redAccent, //[cite: 1]
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }(),
              ),
            ],
          ),
          floatingActionButton:
              isSelectMode //[cite: 1]
              ? null //[cite: 1]
              : FloatingActionButton(
                  //[cite: 1]
                  onPressed: _openAddPromptDialog, //[cite: 1]
                  backgroundColor: const Color(0xFF3F51B5), //[cite: 1]
                  tooltip: 'Tambah Item Prompt Baru', //[cite: 1]
                  child: const Icon(Icons.add, color: Colors.white), //[cite: 1]
                ),
        );
      },
    );
  }
}
