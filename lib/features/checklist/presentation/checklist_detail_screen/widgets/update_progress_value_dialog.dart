import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rutinitasku/core/utils/string_helper.dart';
import '../../../data/models/daily_model.dart';

class UpdateProgressValueDialog extends StatefulWidget {
  final SubSubjectItem item;
  final Function(SubSubjectItem item, int value, bool isCountdown) onConfirm;

  const UpdateProgressValueDialog({
    super.key,
    required this.item,
    required this.onConfirm,
  });

  @override
  State<UpdateProgressValueDialog> createState() =>
      _UpdateProgressValueDialogState();
}

class _UpdateProgressValueDialogState extends State<UpdateProgressValueDialog> {
  final _valueController = TextEditingController();
  late final bool _isCountdown;

  @override
  void initState() {
    super.initState();
    _isCountdown = widget.item.itemType == 'countdown';
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        _isCountdown
            ? 'Input Angka Pengurang untuk "${widget.item.subjectName}"'
            : 'Input Angka Tambahan untuk "${widget.item.subjectName}"',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isCountdown
                ? 'Sisa saat ini: ${StringHelper.formatRibuan(widget.item.currentValue)}'
                : 'Progres saat ini: ${StringHelper.formatRibuan(widget.item.currentValue)} / ${StringHelper.formatRibuan(widget.item.targetValue)}',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: _isCountdown
                  ? 'Jumlah Angka Pengurang (Misal: 5)'
                  : 'Jumlah Angka Tambahan (Misal: 1.000)',
              border: const OutlineInputBorder(),
            ),
            onChanged: (val) {
              if (val.isEmpty) return;
              String cleanText = val.replaceAll('.', '');

              String formattedText = StringHelper.formatRibuan(
                int.tryParse(cleanText) ?? 0,
              );

              _valueController.value = TextEditingValue(
                text: formattedText,
                selection: TextSelection.collapsed(
                  offset: formattedText.length,
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            final String rawText = _valueController.text
                .replaceAll('.', '')
                .trim();
            final int? addValue = int.tryParse(rawText);
            if (addValue != null && addValue > 0) {
              Navigator.pop(context);
              widget.onConfirm(widget.item, addValue, _isCountdown);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          child: Text(
            _isCountdown ? 'Kurangi' : 'Tambah',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
