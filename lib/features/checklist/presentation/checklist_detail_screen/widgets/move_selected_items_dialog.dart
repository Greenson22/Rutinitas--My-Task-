import 'package:flutter/material.dart';
import '../../../data/models/daily_model.dart';

class MoveSelectedItemsDialog extends StatefulWidget {
  final List<SubSubjectItem> allFlattened;
  final List<SubSubjectItem> selectedItems;
  final DailySubject currentSubject;
  final List<DailySubject> allAvailableSubjects;
  final Function({SubSubjectItem? targetParent}) onMoveToTarget;
  final Function(DailySubject targetSubject) onMoveToOtherSubject;

  const MoveSelectedItemsDialog({
    super.key,
    required this.allFlattened,
    required this.selectedItems,
    required this.currentSubject,
    required this.allAvailableSubjects,
    required this.onMoveToTarget,
    required this.onMoveToOtherSubject,
  });

  @override
  State<MoveSelectedItemsDialog> createState() =>
      _MoveSelectedItemsDialogState();
}

class _MoveSelectedItemsDialogState extends State<MoveSelectedItemsDialog> {
  bool _isInternalMenuExpanded = false;

  @override
  Widget build(BuildContext context) {
    List<SubSubjectItem> validTargets = widget.allFlattened.where((item) {
      if (widget.selectedItems.contains(item)) return false;
      return !widget.selectedItems.any((selected) {
        bool isDescendant(SubSubjectItem parent, SubSubjectItem target) {
          if (parent.subMateri.contains(target)) return true;
          for (var child in parent.subMateri) {
            if (isDescendant(child, target)) return true;
          }
          return false;
        }

        return isDescendant(selected, item);
      });
    }).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Pindahkan Item Terpilih ke...'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _isInternalMenuExpanded = !_isInternalMenuExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 4.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pindah Posisi (Internal List Saat Ini)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                          fontSize: 13,
                        ),
                      ),
                      Icon(
                        _isInternalMenuExpanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_right_rounded,
                        color: Colors.indigo,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _isInternalMenuExpanded
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.label_important,
                              color: Colors.indigo,
                            ),
                            title: const Text(
                              'Daftar Utama (Root List)',
                              style: TextStyle(fontSize: 14),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onMoveToTarget(targetParent: null);
                            },
                          ),
                          ...validTargets.map(
                            (target) => ListTile(
                              leading: const Icon(
                                Icons.subdirectory_arrow_right,
                                color: Colors.teal,
                                size: 20,
                              ),
                              title: Text(
                                target.subjectName,
                                style: const TextStyle(fontSize: 14),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                widget.onMoveToTarget(targetParent: target);
                              },
                            ),
                          ),
                        ],
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ),
              const Divider(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Pindahkan ke Kotak List Lain:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                    fontSize: 13,
                  ),
                ),
              ),
              ...widget.allAvailableSubjects
                  .where((sub) => sub != widget.currentSubject)
                  .map(
                    (targetSubject) => ListTile(
                      leading: Text(
                        targetSubject.icon,
                        style: const TextStyle(fontSize: 18),
                      ),
                      title: Text(
                        targetSubject.subjectName,
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onMoveToOtherSubject(targetSubject);
                      },
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
