// lib/features/notes/presentation/screens/note_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:rutinitasku/core/presentation/widgets/base_popup_dialog.dart';
import 'package:rutinitasku/core/presentation/widgets/adaptive_banner_ad.dart'; // <--- IMPORT WIDGET ADMOB BARU DARI CORE
import '../../models/note_model.dart';
import '../controllers/note_detail_controller.dart';
import '../../../../core/presentation/widgets/base_detail_list_screen.dart';
import '../../../../core/presentation/widgets/universal_empty_state.dart';
import 'note_edit_dialog.dart';

class NoteDetailScreen extends StatefulWidget {
  final NoteGroup noteGroup;

  const NoteDetailScreen({super.key, required this.noteGroup});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late NoteDetailController _controller;
  // STATE BARU: Menyimpan jenis pengurutan aktif ('manual', 'az', 'za')
  String _currentSortType = 'manual';

  @override
  void initState() {
    super.initState();
    _controller = NoteDetailController(
      noteGroup: widget.noteGroup,
      context: context,
      onStateChanged: () => setState(() {}),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showNoteDialog({NoteModel? existingNote}) {
    showDialog(
      context: context,
      builder: (dialogContext) =>
          NoteEditDialog(controller: _controller, existingNote: existingNote),
    );
  }

  // =========================================================================
  // FITUR BARU: LOGIKA PROSES PENGURUTAN ITEM PROMPT
  // =========================================================================
  void _handleSort(String sortType) {
    setState(() {
      _currentSortType = sortType;
      if (sortType == 'az') {
        _controller.currentGroup.notes.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      } else if (sortType == 'za') {
        _controller.currentGroup.notes.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
      } else {
        // Mode Manual: Ditembalikan ke urutan default berdasarkan waktu pembuatan (createdAt)
        _controller.currentGroup.notes.sort(
          (a, b) => a.createdAt.compareTo(b.createdAt),
        );
      }
    });
    // Simpan susunan urutan baru ke penyimpanan lokal secara persisten
    _controller.saveCurrentGroup();
  }

  // =========================================================================
  // FITUR BARU: DIALOG PINDAH MASSAL MENGIKUTI STYLE PROMPT SCREEN
  // =========================================================================
  void _showMoveMassiveDialog(List<NoteModel> selectedItems) async {
    // 1. Tampilkan loading indicator selagi mengambil berkas dari storage
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.indigo)),
    );

    // 2. Ambil data semua grup notes via controller
    final allGroups = await _controller.getAllNoteGroups();

    if (!mounted) return;
    Navigator.pop(context); // Tutup loading indicator

    // 3. Saring grup tujuan agar tidak menyertakan grup asal saat ini
    final availableGroups = allGroups
        .where((g) => g.id != _controller.currentGroup.id)
        .toList();

    // 4. Jika tidak ada grup lain selain grup ini, tampilkan notifikasi
    if (availableGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada grup catatan lain yang tersedia.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 5. Tampilkan Dialog berbasis BasePopupDialog dengan spesifikasi UI modul Prompt
    showDialog(
      context: context,
      builder: (ctx) => BasePopupDialog(
        title: Text(
          'Pindahkan ${selectedItems.length} Catatan Terpilih',
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
                  itemCount: availableGroups.length,
                  itemBuilder: (c, idx) {
                    final targetG = availableGroups[idx];
                    return ListTile(
                      dense: true,
                      leading: Text(
                        targetG.icon.isEmpty ? '📁' : targetG.icon,
                        style: const TextStyle(fontSize: 18),
                      ),
                      title: Text(
                        targetG.groupName,
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
                          Navigator.pop(ctx); // Tutup Dialog utama

                          // Eksekusi pemindahan data massal di controller
                          await _controller.moveMassiveNotes(
                            selectedItems,
                            targetG,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Semua catatan terpilih berhasil dipindahkan ke "${targetG.groupName}"!',
                                ),
                                backgroundColor: Colors.indigo,
                              ),
                            );
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
    // ================= TANGANI KEADAAN AWAL KOSONG DI SINI =================
    if (_controller.currentGroup.notes.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(
          0xFFF5F6FA,
        ), // Menyelaraskan background BaseDetailListScreen
        appBar: AppBar(
          title: Text(
            _controller.currentGroup.groupName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: const Color(
            0xFF3F51B5,
          ), // Menyelaraskan warna AppBar utama (Indigo)
          elevation: 2,
        ),
        body: UniversalEmptyState(
          icon: Icons.note_add_rounded,
          title: 'Belum Ada Catatan',
          description:
              'Grup ini masih kosong dari lembar tulisan. Tekan tombol di bawah untuk membuat catatan teks atau lembar tabel data pertama Anda!',
          buttonLabel: 'Buat Catatan Baru',
          themeColor: const Color(0xFF3F51B5), // Warna tema Indigo
          onPressed: () => _showNoteDialog(),
        ),
        // IMPLEMENTASI LAYOUT FOOTER BANNER MENGGUNAKAN WIDGET ADAPTIVE PADA KONDISI DATA KOSONG
        bottomNavigationBar: const AdaptiveBannerAd(
          adKey: 'note_detail_banner',
        ),
      );
    }

    // ================= TAMPILKAN LIST UTAMA JIKA DATA TERSEDIA =================
    return Scaffold(
      body: BaseDetailListScreen<NoteModel>(
        pageTitle: _controller.currentGroup.groupName,
        items: _controller.currentGroup.notes,
        enableSearch: true,
        enableMultiSelect: true,
        enableAddButton: true,
        enableFavoriteSort: false,
        itemTitle: (note) => note.title,

        // =========================================================================
        // PERBAIKAN UTAMA: Menggunakan parameter 'additionalAction'
        // =========================================================================
        additionalAction: PopupMenuButton<String>(
          icon: const Icon(Icons.sort_rounded, color: Colors.white),
          tooltip: 'Urutkan Prompt',
          onSelected: _handleSort,
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'manual',
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: _currentSortType == 'manual'
                        ? Colors.indigo
                        : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Urutan Manual (Waktu)',
                    style: TextStyle(
                      fontWeight: _currentSortType == 'manual'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'az',
              child: Row(
                children: [
                  Icon(
                    Icons.sort_by_alpha_rounded,
                    color: _currentSortType == 'az'
                        ? Colors.indigo
                        : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Abjad: A ➔ Z',
                    style: TextStyle(
                      fontWeight: _currentSortType == 'az'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'za',
              child: Row(
                children: [
                  Icon(
                    Icons.sort_by_alpha_rounded,
                    color: _currentSortType == 'za'
                        ? Colors.indigo
                        : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Abjad: Z ➔ A',
                    style: TextStyle(
                      fontWeight: _currentSortType == 'za'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 1. Mengembalikan Layout Widget Custom dengan Warna Berbeda
        itemSubtitle: (note) {
          String created = _controller.formatDate(note.createdAt);
          String updated = _controller.formatDate(note.updatedAt);
          bool isTable = note.type == 'table';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Dibuat: $created',
                style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
              ),
              const SizedBox(height: 1),
              Text(
                'Diperbarui: $updated',
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
              if (isTable) ...[
                const SizedBox(height: 2),
                Text(
                  'Tipe: Tabel (${note.tableData.length} Baris)',
                  style: const TextStyle(
                    color: Colors.teal,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          );
        },

        // 2. Mengembalikan data String murni agar sistem search bawaan tetap berfungsi
        itemSearchString: (note) {
          String created = _controller.formatDate(note.createdAt);
          String updated = _controller.formatDate(note.updatedAt);
          String typeInfo = note.type == 'table' ? 'tabel table' : 'text teks';
          return '$created $updated $typeInfo';
        },
        itemIsFavorite: (note) => false,
        onAddPressed: () => _showNoteDialog(),
        onItemTap: (note) => _showNoteDialog(existingNote: note),
        itemMenuBuilder: (note) => const [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_note, size: 18, color: Colors.teal),
                SizedBox(width: 10),
                Text('Edit', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                SizedBox(width: 10),
                Text(
                  'Hapus',
                  style: TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
        onItemMenuSelected: (value, note) async {
          if (value == 'edit') {
            _showNoteDialog(existingNote: note);
          } else if (value == 'delete') {
            final bool confirm = await _controller.showConfirmDialog(
              title: 'Hapus Catatan',
              content:
                  'Apakah Anda yakin ingin menghapus catatan "${note.title}" secara permanen?',
            );

            if (confirm) {
              _controller.deleteNote(note);
            }
          }
        },
        onDeleteMassive: (selectedItems) async {
          await _controller.deleteMassiveNotes(selectedItems);
        },
        onMoveMassive: (selectedItems) {
          _showMoveMassiveDialog(selectedItems);
        },
      ),

      // IMPLEMENTASI LAYOUT FOOTER BANNER MENGGUNAKAN WIDGET ADAPTIVE YANG BARU & SEJAJAR DENGAN DATA UTAMA
      bottomNavigationBar: const AdaptiveBannerAd(adKey: 'note_detail_banner'),
    );
  }
}
