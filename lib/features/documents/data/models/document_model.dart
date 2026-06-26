// lib/features/documents/data/models/document_model.dart

class DocumentGroup {
  String id;
  String groupName;
  String icon;
  String sectionCategory;
  bool isHidden;

  DocumentGroup({
    required this.id,
    required this.groupName,
    required this.icon,
    required this.sectionCategory,
    this.isHidden = false,
  });

  factory DocumentGroup.fromJson(Map<String, dynamic> json) {
    return DocumentGroup(
      id: json['id'] ?? '',
      groupName: json['groupName'] ?? 'Untitled Group',
      icon: json['icon'] ?? '📁',
      sectionCategory: json['sectionCategory'] ?? 'Lainnya',
      isHidden: json['isHidden'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupName': groupName,
      'icon': icon,
      'sectionCategory': sectionCategory,
      'isHidden': isHidden,
    };
  }
}
