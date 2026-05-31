// lib/features/prompt/presentation/screens/prompt_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../../../daily/data/models/daily_model.dart';

// =========================================================================
// 1. WIDGET HALAMAN UTAMA PROMPT
// =========================================================================
class PromptScreen extends StatefulWidget {
  const PromptScreen({super.key});

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  final List<ChecklistGroup> _promptGroups = [
    ChecklistGroup(id: '1', groupName: 'Daily Prompt', icon: '📆', allList: []),
    ChecklistGroup(id: '2', groupName: 'Bible Study', icon: '✝', allList: []),
    ChecklistGroup(
      id: '3',
      groupName: 'SoftSkill & MetaSkill',
      icon: '🧠',
      allList: [],
    ),
    ChecklistGroup(
      id: '4',
      groupName: 'Coding Assistant',
      icon: '👨‍💻',
      allList: [],
    ),
  ];

  bool _isPageEditMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('My Prompts'),
        backgroundColor: Colors.indigo,
      ),
      drawer: const DrawerMenu(isPromptActive: true),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'PROMPT LIST',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[900],
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 8, thickness: 1),
              ),
              _buildPromptGrid(_promptGroups, constraints),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.indigo,
        tooltip: 'Tambah Prompt Baru',
        child: const Icon(
          Icons.create_new_folder_outlined,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPromptGrid(
    List<ChecklistGroup> promptList,
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
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.15,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: promptList.length,
      itemBuilder: (context, index) {
        final prompt = promptList[index];

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.indigo, width: 3.5),
          ),
          color: Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            // === FUNGSI DIUBAH: Navigasi mengarah ke detail saat di-tap ===
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PromptDetailScreen(
                    title: prompt.groupName,
                    icon: prompt.icon,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(prompt.icon, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text(
                    prompt.groupName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Lihat Prompt',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// =========================================================================
// 2. WIDGET HALAMAN DETAIL DAFTAR BANYAK PROMPT (BARU)
// =========================================================================
class PromptDetailScreen extends StatelessWidget {
  final String title;
  final String icon;

  const PromptDetailScreen({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Data Dummy Daftar Prompt Panjang untuk Simulasi
    final List<Map<String, String>> dummyPrompts = [
      {
        'act': 'Sebagai Ahli Konten',
        'desc':
            'Buatkan struktur kerangka tulisan blog yang SEO-friendly mengenai topik produktivitas kerja...',
      },
      {
        'act': 'Sebagai Senior Flutter Dev',
        'desc':
            'Refactor kode arsitektur BLoC berikut agar lebih efisien dan clean code sesuai standar kode global...',
      },
      {
        'act': 'Sebagai Penerjemah Profesional',
        'desc':
            'Terjemahkan teks akademis bahasa Inggris ini ke bahasa Indonesia dengan gaya bahasa formal literatur...',
      },
      {
        'act': 'Sebagai Coach Karier',
        'desc':
            'Berikan poin-poin evaluasi pertanyaan wawancara untuk posisi system analyst berikut beserta tips menjawabnya...',
      },
      {
        'act': 'Sebagai Ringkasan Buku AI',
        'desc':
            'Ekstrak 5 pemikiran utama (key takeaways) dari ringkasan bab konsep teknik deep work ini...',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [Text(icon), const SizedBox(width: 8), Text(title)],
        ),
        backgroundColor: Colors.indigo,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dummyPrompts.length,
        itemBuilder: (context, index) {
          final item = dummyPrompts[index];
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
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                item['act']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.indigo,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  item['desc']!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy, color: Colors.grey, size: 20),
                tooltip: 'Salin Prompt',
                onPressed: () {
                  // Tambahkan visual snackbar pemicu tiruan saat tombol copy ditekan
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Menyalin: ${item['act']}')),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
