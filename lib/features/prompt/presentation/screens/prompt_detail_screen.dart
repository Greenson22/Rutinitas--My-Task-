// lib/features/prompt/presentation/screens/prompt_detail_screen.dart
import 'dart:io'; // Ditambahkan untuk mengecek platform
import 'package:flutter/foundation.dart'; // Ditambahkan untuk mendeteksi kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Ditambahkan untuk SDK AdMob
import 'package:rutinitasku/core/presentation/widgets/base_popup_dialog.dart';
import '../../../../core/presentation/widgets/base_detail_list_screen.dart';
import '../../../../core/presentation/widgets/universal_empty_state.dart'; // IMPORT BARU
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

  // Variabel kontrol untuk Banner AdMob
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // Getter adaptif untuk menentukan Ad Unit ID Iklan Banner
  String get adUnitId {
    if (Platform.isAndroid) {
      if (kDebugMode) {
        // ID Test Resmi dari Google untuk pengujian iklan Banner Android
        return 'ca-app-pub-3940256099942544/6300978111';
      } else {
        // GANTI dengan Ad Unit ID asli Anda dari dasbor AdMob saat rilis nanti
        return 'ca-app-pub-5320800343545863/1957989622';
      }
    }
    return ''; // Kosongkan jika berjalan di Desktop (Windows/Linux/macOS) agar tidak crash
  }

  @override
  void initState() {
    super.initState();
    // Langsung gunakan data group yang dioper dari halaman utama
    _currentGroup = widget.promptGroup;

    // Pastikan controller memuat data seluruh group di background
    // karena fungsi riwayat versi di PromptController mengandalkan list internal '_promptGroups'.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.loadAllPrompts(context);
      }
    });

    // Panggil fungsi pemuatan iklan banner
    _loadBannerAd();
  }

  // Fungsi untuk mengunduh iklan banner AdMob
  void _loadBannerAd() {
    if (adUnitId.isEmpty) return; // Batalkan jika bukan platform Android

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Iklan Banner Prompt Detail gagal dimuat: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _controller.clearSelectedPrompts();
    _bannerAd
        ?.dispose(); // Hancurkan objek iklan dari memori saat halaman ditutup untuk mencegah kebocoran memori
    super.dispose();
  }

  void _openAddPromptDialog() {
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

  void _openEditPromptDialog(PromptItem item) {
    final titleController = TextEditingController(text: item.actAs);
    final descController = TextEditingController(text: item.description ?? '');
    final contentController = TextEditingController(
      text: item.activeVersion.content,
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => BasePopupDialog(
        themeColor: Colors.indigo,
        titleColor: Colors.white,
        title: Row(
          children: const [
            Icon(Icons.edit_note, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text('Edit Data Prompt', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Bertindak Sebagai (Act As)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Judul act as wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Singkat',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Isi Perintah Konten Utama Prompt',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Isi prompt wajib diisi'
                      : null,
                ),
              ],
            ),
          ),
        ),
        footer: Padding(
          padding: const EdgeInsets.all(12.0),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final res = await _controller.editPromptItem(
                      group: _currentGroup,
                      itemId: item.id,
                      newActAs: titleController.text,
                      newDescription: descController.text,
                      newContent: contentController.text,
                      context: context,
                    );
                    if (res != null && mounted) {
                      setState(() {
                        _currentGroup = res;
                      });
                    }
                    if (context.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text(
                  'Simpan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteSingleDialog(PromptItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Prompt'),
        content: Text(
          'Apakah Anda yakin ingin menghapus prompt "${item.actAs}" secara permanen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final res = await _controller.deletePromptItem(
                group: _currentGroup,
                itemId: item.id,
                context: context,
              );
              if (res != null && mounted) {
                setState(() {
                  _currentGroup = res;
                });
              }
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMoveOrCopyDialog(PromptItem item) {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<List<PromptGroup>>(
        future: _controller.promptGroups.isEmpty
            ? (() async {
                await _controller.loadAllPrompts(context);
                return _controller.promptGroups;
              })()
            : Future.value(_controller.promptGroups),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups = snapshot.data!;
          return BasePopupDialog(
            title: Text('Salin / Pindahkan "${item.actAs}"'),
            themeColor: Colors.indigo,
            titleColor: Colors.white,
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: groups.length,
                itemBuilder: (context, idx) {
                  final targetG = groups[idx];
                  if (targetG.id.startsWith("CORRUPTED_")) {
                    return const SizedBox.shrink();
                  }
                  return ListTile(
                    dense: true,
                    leading: Text(
                      targetG.icon,
                      style: const TextStyle(fontSize: 16),
                    ),
                    title: Text(
                      targetG.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
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
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final res = await _controller.moveOrCopyPromptItem(
                              sourceGroup: _currentGroup,
                              targetGroup: targetG,
                              item: item,
                              isCopy: true,
                              context: context,
                            );
                            if (res != null && mounted) {
                              setState(() {
                                _currentGroup = res;
                              });
                            }
                          },
                          child: const Text(
                            'Salin',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final res = await _controller.moveOrCopyPromptItem(
                              sourceGroup: _currentGroup,
                              targetGroup: targetG,
                              item: item,
                              isCopy: false,
                              context: context,
                            );
                            if (res != null && mounted) {
                              setState(() {
                                _currentGroup = res;
                              });
                            }
                          },
                          child: const Text(
                            'Pindah',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showMassMoveDialog(List<PromptItem> selectedItems) {
    showDialog(
      context: context,
      builder: (ctx) => BasePopupDialog(
        title: Text('Pindahkan ${selectedItems.length} Prompt'),
        themeColor: Colors.indigo,
        titleColor: Colors.white,
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _controller.promptGroups.length,
            itemBuilder: (context, idx) {
              final targetG = _controller.promptGroups[idx];
              if (targetG.id == _currentGroup.id ||
                  targetG.id.startsWith("CORRUPTED_")) {
                return const SizedBox.shrink();
              }
              return ListTile(
                dense: true,
                leading: Text(
                  targetG.icon,
                  style: const TextStyle(fontSize: 16),
                ),
                title: Text(
                  targetG.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  targetG.sectionName,
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.indigo),
                onTap: () async {
                  Navigator.pop(ctx);
                  _controller.clearSelectedPrompts();
                  for (var item in selectedItems) {
                    _controller.toggleSelectPromptItem(item.id);
                  }
                  final res = await _controller.moveSelectedPromptItems(
                    sourceGroup: _currentGroup,
                    targetGroup: targetG,
                    context: context,
                  );
                  if (res != null && mounted) {
                    setState(() {
                      _currentGroup = res;
                    });
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _openVersionSelectorDialog(PromptItem item) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return BasePopupDialog(
              themeColor: Colors.indigo,
              titleColor: Colors.white,
              title: Row(
                children: [
                  const Icon(
                    Icons.history_toggle_off_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Versi: ${item.actAs}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              content: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: item.versions.length,
                        itemBuilder: (c, idx) {
                          final version = item.versions[idx];
                          final bool isActive =
                              item.activeVersionId == version.id;
                          return Card(
                            elevation: 0,
                            color: isActive
                                ? Colors.indigo.withOpacity(0.06)
                                : Colors.grey.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isActive
                                    ? Colors.indigo.withOpacity(0.3)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              title: Text(
                                version.versionName,
                                style: TextStyle(
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isActive
                                      ? Colors.indigo
                                      : Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                version.content,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                      color: Colors.indigo,
                                    ),
                                    onPressed: () {
                                      _openEditVersionNameDialog(
                                        item,
                                        version,
                                        () {
                                          setModalState(() {});
                                          setState(() {});
                                        },
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: item.versions.length <= 1
                                        ? null
                                        : () async {
                                            // PENGAMANAN: Pastikan list memori controller sudah terisi
                                            if (_controller
                                                .promptGroups
                                                .isEmpty) {
                                              await _controller.loadAllPrompts(
                                                context,
                                              );
                                            }
                                            await _controller
                                                .deletePromptVersion(
                                                  group: _currentGroup,
                                                  itemId: item.id,
                                                  versionId: version.id,
                                                  context: context,
                                                );
                                            // Ambil group terbaru pasca penghapusan
                                            final updatedGroup = _controller
                                                .promptGroups
                                                .firstWhere(
                                                  (g) =>
                                                      g.id == _currentGroup.id,
                                                  orElse: () => _currentGroup,
                                                );
                                            setModalState(() {
                                              item = updatedGroup.prompts
                                                  .firstWhere(
                                                    (p) => p.id == item.id,
                                                  );
                                            });
                                            setState(() {
                                              _currentGroup = updatedGroup;
                                            });
                                          },
                                  ),
                                  if (!isActive)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: () async {
                                        // PENGAMANAN: Pastikan list memori controller sudah terisi
                                        if (_controller.promptGroups.isEmpty) {
                                          await _controller.loadAllPrompts(
                                            context,
                                          );
                                        }
                                        await _controller.switchPromptVersion(
                                          group: _currentGroup,
                                          itemId: item.id,
                                          versionId: version.id,
                                          context: context,
                                        );
                                        final updatedGroup = _controller
                                            .promptGroups
                                            .firstWhere(
                                              (g) => g.id == _currentGroup.id,
                                              orElse: () => _currentGroup,
                                            );
                                        setModalState(() {
                                          item = updatedGroup.prompts
                                              .firstWhere(
                                                (p) => p.id == item.id,
                                              );
                                        });
                                        setState(() {
                                          _currentGroup = updatedGroup;
                                        });
                                      },
                                      child: const Text(
                                        'Gunakan',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.teal,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                        ),
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                        label: const Text(
                          'Buat Duplikat Versi Baru',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: () {
                          _openCreateNewVersionDialog(item, () {
                            // SINKRONISASI DATA: Cari group dan item yang diperbarui dari controller
                            final updatedGroup = _controller.promptGroups
                                .firstWhere(
                                  (g) => g.id == _currentGroup.id,
                                  orElse: () => _currentGroup,
                                );

                            setModalState(() {
                              // Memperbarui objek item lokal dialog agar ListView me-render daftar versi yang baru
                              item = updatedGroup.prompts.firstWhere(
                                (p) => p.id == item.id,
                              );
                            });

                            setState(() {
                              _currentGroup = updatedGroup;
                            });
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openEditVersionNameDialog(
    PromptItem item,
    PromptVersion version,
    VoidCallback onUpdated,
  ) {
    final nameController = TextEditingController(text: version.versionName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Nama Versi'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tag Penanda Versi'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                // PENGAMANAN: Pastikan list memori controller sudah terisi
                if (_controller.promptGroups.isEmpty) {
                  await _controller.loadAllPrompts(context);
                }
                await _controller.editPromptVersionName(
                  group: _currentGroup,
                  itemId: item.id,
                  versionId: version.id,
                  newVersionName: nameController.text,
                  context: context,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                onUpdated();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _openCreateNewVersionDialog(PromptItem item, VoidCallback onUpdated) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Versi Baru'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nama Versi Baru',
            hintText: 'Misal: v${item.versions.length + 1}.0 (Optimasi)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              // PENGAMANAN: Memastikan data controller list telah termuat
              if (_controller.promptGroups.isEmpty) {
                await _controller.loadAllPrompts(context);
              }

              // Menunggu proses asinkronus penulisan ke storage selesai
              await _controller.createNewPromptVersion(
                group: _currentGroup,
                itemId: item.id,
                versionName: nameController.text,
                context: context,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              // Memicu callback sinkronisasi data ke dialog riwayat versi induk
              onUpdated();
            },
            child: const Text('Duplikat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ================= TANGANI KEADAAN AWAL KOSONG DI SINI =================
    if (_currentGroup.prompts.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: Text(
            _currentGroup.title,
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
          backgroundColor: const Color(0xFF3F51B5),
          elevation: 2,
        ),
        body: UniversalEmptyState(
          icon: Icons.playlist_add_rounded,
          title: 'Grup Prompt Kosong',
          description:
              'Grup ini belum memiliki item perintah kecerdasan buatan AI.\nSilakan ketuk tombol di bawah untuk menyusun instruksi pertamamu!',
          buttonLabel: 'Tambah Item Prompt Baru',
          themeColor: const Color(0xFF3F51B5),
          onPressed: _openAddPromptDialog,
        ),
        // IMPLEMENTASI FOOTER AD BANNER PADA KONDISI DATA KOSONG
        bottomNavigationBar:
            _isAdLoaded && _bannerAd != null && Platform.isAndroid
            ? SafeArea(
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              )
            : const SizedBox.shrink(),
      );
    }

    return Scaffold(
      body: ListBehaviorBuilder(
        controller: _controller,
        builder: (context) {
          // ================= TAMPILKAN LIST UTAMA JIKA DATA TERSEDIA =================
          return BaseDetailListScreen<PromptItem>(
            pageTitle: _currentGroup.title,
            items: _currentGroup.prompts,
            enableSearch: true,
            enableMultiSelect: true,
            enableAddButton: true,
            enableFavoriteSort: true,
            itemTitle: (item) => item.actAs,

            // =========================================================================
            // FITUR BARU: UTILITY SORT DROPDOWN PADA KANAN APPBAR
            // =========================================================================
            additionalAction: PopupMenuButton<String>(
              icon: const Icon(Icons.sort_rounded, color: Colors.white),
              tooltip: 'Urutkan Prompt',
              onSelected: (String sortType) {
                _controller.sortPromptItems(
                  group: _currentGroup,
                  sortType: sortType,
                  context: context,
                );
                setState(() {});
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'manual',
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        color: _controller.currentSortType == 'manual'
                            ? Colors.indigo
                            : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Urutan Manual',
                        style: TextStyle(
                          fontWeight: _controller.currentSortType == 'manual'
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
                        color: _controller.currentSortType == 'az'
                            ? Colors.indigo
                            : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Abjad: A ➔ Z',
                        style: TextStyle(
                          fontWeight: _controller.currentSortType == 'az'
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
                        color: _controller.currentSortType == 'za'
                            ? Colors.indigo
                            : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Abjad: Z ➔ A',
                        style: TextStyle(
                          fontWeight: _controller.currentSortType == 'za'
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

            itemSubtitle: (item) {
              final hasDesc =
                  item.description != null &&
                  item.description!.trim().isNotEmpty;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasDesc ? item.description! : 'Tidak ada deskripsi',
                    style: TextStyle(
                      color: hasDesc ? Colors.blueGrey[700] : Colors.grey[400],
                      fontSize: 13,
                      fontStyle: hasDesc ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Versi Aktif: ${item.activeVersion.versionName}',
                          style: const TextStyle(
                            color: Colors.indigo,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Total: ${item.versions.length} Versi',
                          style: const TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },

            // Penyatuan String untuk Pencarian Komponen Bawaan
            itemSearchString: (item) =>
                '${item.actAs} ${item.description ?? ''} ${item.activeVersion.content}',
            itemIsFavorite: (item) => item.isFavorite,
            onAddPressed: _openAddPromptDialog,

            // Aksi Klik Menyalin Konten Prompt Utama Langsung ke Clipboard OS
            onItemTap: (item) async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(
                ClipboardData(text: item.activeVersion.content),
              );
              scaffoldMessenger.clearSnackBars();
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Berhasil menyalin instruksi "${item.actAs}" ke papan klip!',
                  ),
                  backgroundColor: Colors.teal,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                ),
              );
            },

            itemMenuBuilder: (item) => [
              const PopupMenuItem(
                value: 'manage_versions',
                child: Row(
                  children: [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 18,
                      color: Colors.indigo,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Kelola Riwayat Versi',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.mode_edit_outline_outlined,
                      size: 18,
                      color: Colors.teal,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Ubah Detail Informasi',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_favorite',
                child: Row(
                  children: [
                    Icon(
                      item.isFavorite ? Icons.star_border_rounded : Icons.star,
                      size: 18,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item.isFavorite
                          ? 'Hilangkan dari Favorit'
                          : 'Jadikan Prompt Favorit',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'move_or_copy',
                child: Row(
                  children: [
                    Icon(
                      Icons.drive_file_move_outlined,
                      size: 18,
                      color: Colors.blueGrey,
                    ),
                    SizedBox(width: 10),
                    Text('Salin / Pindah Box', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Colors.redAccent,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Hapus Prompt',
                      style: TextStyle(fontSize: 13, color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],

            onItemMenuSelected: (value, item) async {
              if (value == 'manage_versions') {
                _openVersionSelectorDialog(item);
              } else if (value == 'edit') {
                _openEditPromptDialog(item);
              } else if (value == 'toggle_favorite') {
                final res = await _controller.toggleFavoritePromptItem(
                  group: _currentGroup,
                  itemId: item.id,
                  context: context,
                );
                if (res != null) {
                  setState(() {
                    _currentGroup = res;
                  });
                }
              } else if (value == 'move_or_copy') {
                _showMoveOrCopyDialog(item);
              } else if (value == 'delete') {
                _showDeleteSingleDialog(item);
              }
            },

            onDeleteMassive: (selectedItems) async {
              // Pasang list terpilih ke controller untuk bulk actions
              _controller.clearSelectedPrompts();
              for (var item in selectedItems) {
                _controller.toggleSelectPromptItem(item.id);
              }
              final res = await _controller.deleteSelectedPromptItems(
                group: _currentGroup,
                context: context,
              );
              if (res != null && mounted) {
                setState(() {
                  _currentGroup = res;
                });
              }
            },
            onMoveMassive: (selectedItems) async {
              // PENGAMANAN: Pastikan list memori controller sudah terisi
              if (_controller.promptGroups.isEmpty) {
                await _controller.loadAllPrompts(context);
              }
              _showMassMoveDialog(selectedItems);
            },
          );
        },
      ),

      // IMPLEMENTASI LAYOUT FOOTER BANNER ADMOB KHUSUS ANDROID
      bottomNavigationBar:
          _isAdLoaded && _bannerAd != null && Platform.isAndroid
          ? SafeArea(
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class ListBehaviorBuilder extends StatelessWidget {
  final PromptController controller;
  final WidgetBuilder builder;

  const ListBehaviorBuilder({
    super.key,
    required this.controller,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) => builder(context),
    );
  }
}
