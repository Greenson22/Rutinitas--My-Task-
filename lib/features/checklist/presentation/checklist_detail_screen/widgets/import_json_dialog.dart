import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ImportJsonDialog extends StatefulWidget {
  final Function(String rawInput) onImport;

  const ImportJsonDialog({super.key, required this.onImport});

  @override
  State<ImportJsonDialog> createState() => _ImportJsonDialogState();
}

class _ImportJsonDialogState extends State<ImportJsonDialog> {
  final TextEditingController _jsonFieldController = TextEditingController();

  static const String _completeJsonTemplate =
      '[\n'
      '  {\n'
      '    "nama_materi": "Contoh Normal Item",\n'
      '    "progress": "belum",\n'
      '    "finishedDate": null,\n'
      '    "itemType": "normal",\n'
      '    "currentValue": 0,\n'
      '    "targetValue": 0,\n'
      '    "isDisabled": false,\n'
      '    "linkedSubjectName": null,\n'
      '    "accumulatorItemName": null,\n'
      '    "linkedExternalCardName": null,\n'
      '    "linkedExternalItemName": null,\n'
      '    "sub_materi": []\n'
      '  }\n'
      ']';

  @override
  void dispose() {
    _jsonFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.code_rounded, color: Colors.indigo),
          SizedBox(width: 8),
          Text('Impor Data dari JSON'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Tempel data teks JSON sesuai format:',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      const ClipboardData(text: _completeJsonTemplate),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '📋 Template JSON disalin ke clipboard!',
                          ),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.copy_all,
                    size: 14,
                    color: Colors.indigo,
                  ),
                  label: const Text(
                    'Salin Template',
                    style: TextStyle(fontSize: 11, color: Colors.indigo),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _jsonFieldController,
              maxLines: 8,
              style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
              decoration: const InputDecoration(
                hintText:
                    '[\n  {\n    "nama_materi": "Nama Item Baru",\n    "itemType": "normal"\n  }\n]',
                border: OutlineInputBorder(),
                fillColor: Color(0xFFF8F9FA),
                filled: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            final String rawInput = _jsonFieldController.text;
            Navigator.pop(context);
            if (rawInput.trim().isNotEmpty) {
              widget.onImport(rawInput);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
          child: const Text(
            'Impor Teks',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
