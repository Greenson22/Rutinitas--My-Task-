// lib/features/documents/data/models/document_model.dart

class DocumentItem {
  String id;
  String title;
  String content;
  String lastModified;
  bool isHidden;

  DocumentItem({
    required this.id,
    required this.title,
    this.content = '',
    required this.lastModified,
    this.isHidden = false,
  });

  factory DocumentItem.fromJson(Map<String, dynamic> json) {
    return DocumentItem(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled Document',
      content: json['content'] ?? '',
      lastModified: json['lastModified'] ?? DateTime.now().toIso8601String(),
      isHidden: json['isHidden'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'lastModified': lastModified,
      'isHidden': isHidden,
    };
  }
}

class DocumentSection {
  String sectionName;
  List<DocumentItem> items;

  DocumentSection({required this.sectionName, required this.items});

  factory DocumentSection.fromJson(Map<String, dynamic> json) {
    return DocumentSection(
      sectionName: json['sectionName'] ?? 'General',
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => DocumentItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sectionName': sectionName,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class DocumentGroup {
  String id;
  String groupName;
  String icon;
  String sectionCategory;
  bool isHidden;
  int orderIndex; // <--- BARU: Menyimpan urutan posisi group
  List<DocumentSection> allList;

  DocumentGroup({
    required this.id,
    required this.groupName,
    required this.icon,
    required this.sectionCategory,
    this.isHidden = false,
    this.orderIndex = 0, // <--- BARU: Default value urutan
    required this.allList,
  });

  factory DocumentGroup.fromJson(Map<String, dynamic> json) {
    return DocumentGroup(
      id: json['id'] ?? '',
      groupName: json['groupName'] ?? 'Untitled Group',
      icon: json['icon'] ?? '📁',
      sectionCategory: json['sectionCategory'] ?? 'Lainnya',
      isHidden: json['isHidden'] ?? false,
      orderIndex: json['order_index'] ?? 0, // <--- BARU: Parsing dari JSON
      allList:
          (json['allList'] as List<dynamic>?)
              ?.map((section) => DocumentSection.fromJson(section))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupName': groupName,
      'icon': icon,
      'sectionCategory': sectionCategory,
      'isHidden': isHidden,
      'order_index': orderIndex, // <--- BARU: Menyimpan ke JSON
      'allList': allList.map((section) => section.toJson()).toList(),
    };
  }
}
