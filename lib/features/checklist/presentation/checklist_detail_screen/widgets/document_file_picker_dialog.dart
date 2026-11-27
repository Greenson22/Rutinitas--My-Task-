import 'dart:io';

import 'package:flutter/material.dart';

import 'package:rutinitasku/core/services/storage_service.dart';
import 'package:rutinitasku/features/documents/data/models/document_model.dart';
import 'package:rutinitasku/features/documents/data/services/document_file_service.dart';
import 'package:rutinitasku/features/documents/presentation/controllers/documents_controller.dart';

typedef DocumentFileSelection = ({
  String groupId,
  String relativePath,
  String fileName,
});

/// Dialog penjelajah hierarkis Group -> Folder -> Berkas untuk memilih satu berkas.
class DocumentFilePickerDialog extends StatefulWidget {
  final String? baseDirOverride;

  const DocumentFilePickerDialog({super.key, this.baseDirOverride});

  @override
  State<DocumentFilePickerDialog> createState() =>
      _DocumentFilePickerDialogState();
}

class _DocumentFilePickerDialogState extends State<DocumentFilePickerDialog> {
  final DocumentsController _documentsController = DocumentsController();
  late DocumentFileService _fileService;

  bool _isLoading = true;
  DocumentGroup? _selectedGroup;
  String? _currentFolderId;
  List<DocumentFolder> _childFolders = [];
  List<File> _files = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final baseDir =
        widget.baseDirOverride ?? await StorageService().getBaseDirSetting();
    _fileService = DocumentFileService(baseDir: baseDir);
    await _documentsController.loadGroupsData();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openGroup(DocumentGroup group) async {
    setState(() {
      _selectedGroup = group;
      _currentFolderId = null;
      _isLoading = true;
    });
    await _loadCurrentDirectory();
  }

  Future<void> _openFolder(String? folderId) async {
    setState(() {
      _currentFolderId = folderId;
      _isLoading = true;
    });
    await _loadCurrentDirectory();
  }

  Future<void> _loadCurrentDirectory() async {
    final group = _selectedGroup;
    if (group == null) return;
    final relPath = _documentsController.folderRelativePath(
      group,
      _currentFolderId,
    );
    final listing = await _fileService.listDirectory(
      group.id,
      relativePath: relPath,
    );
    final folders = _documentsController.getChildFolders(
      group,
      _currentFolderId,
    );
    if (mounted) {
      setState(() {
        _childFolders = folders;
        _files = listing.files;
        _isLoading = false;
      });
    }
  }

  List<DocumentFolder> _breadcrumbChain() {
    final group = _selectedGroup;
    if (group == null || _currentFolderId == null) return const [];
    final byId = {for (final f in group.folders) f.id: f};
    final chain = <DocumentFolder>[];
    String? current = _currentFolderId;
    final visited = <String>{};
    while (current != null && current.isNotEmpty) {
      if (!visited.add(current)) break;
      final folder = byId[current];
      if (folder == null) break;
      chain.add(folder);
      current = folder.parentId;
    }
    return chain.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();

    return AlertDialog(
      title: const Text('Pilih Berkas My Documents'),
      content: SizedBox(
        width: 420,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari nama berkas...',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 8),
            if (_selectedGroup != null) _buildBreadcrumb(),
            const SizedBox(height: 4),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedGroup == null
                  ? _buildGroupList(query)
                  : _buildDirectoryList(query),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ],
    );
  }

  Widget _buildBreadcrumb() {
    final chain = _breadcrumbChain();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          InkWell(
            onTap: () => setState(() {
              _selectedGroup = null;
              _currentFolderId = null;
            }),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text('Groups', style: TextStyle(color: Colors.blueGrey)),
            ),
          ),
          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          InkWell(
            onTap: () => _openFolder(null),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                _selectedGroup!.groupName,
                style: TextStyle(
                  fontWeight: _currentFolderId == null
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _currentFolderId == null
                      ? Colors.indigo
                      : Colors.blueGrey,
                ),
              ),
            ),
          ),
          for (int i = 0; i < chain.length; i++) ...[
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            InkWell(
              onTap: i == chain.length - 1
                  ? null
                  : () => _openFolder(chain[i].id),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  chain[i].name,
                  style: TextStyle(
                    fontWeight: i == chain.length - 1
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: i == chain.length - 1
                        ? Colors.indigo
                        : Colors.blueGrey,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupList(String query) {
    final groups = _documentsController.allGroupRaw
        .where(
          (g) => query.isEmpty || g.groupName.toLowerCase().contains(query),
        )
        .toList();
    if (groups.isEmpty) {
      return const Center(child: Text('Tidak ada group dokumen.'));
    }
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (ctx, i) {
        final g = groups[i];
        return ListTile(
          leading: Text(g.icon, style: const TextStyle(fontSize: 22)),
          title: Text(g.groupName),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openGroup(g),
        );
      },
    );
  }

  Widget _buildDirectoryList(String query) {
    final folders = _childFolders
        .where((f) => query.isEmpty || f.name.toLowerCase().contains(query))
        .toList();
    final files = _files
        .where(
          (f) =>
              query.isEmpty ||
              _fileService.fileName(f).toLowerCase().contains(query),
        )
        .toList();

    if (folders.isEmpty && files.isEmpty) {
      return const Center(child: Text('Folder kosong.'));
    }

    return ListView(
      children: [
        for (final folder in folders)
          ListTile(
            leading: Text(folder.icon, style: const TextStyle(fontSize: 22)),
            title: Text(folder.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openFolder(folder.id),
          ),
        for (final file in files)
          ListTile(
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(_fileService.fileName(file)),
            onTap: () {
              final group = _selectedGroup!;
              final relPath = _fileService.relativePath(group.id, file);
              Navigator.pop<DocumentFileSelection>(context, (
                groupId: group.id,
                relativePath: relPath,
                fileName: _fileService.fileName(file),
              ));
            },
          ),
      ],
    );
  }
}
