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
  String
  sectionCategory; // Ini yang bertindak sebagai nama Seksi (seperti sectionName di notes)
  bool isHidden;
  int orderIndex;
  List<DocumentSection> allList;

  DocumentGroup({
    required this.id,
    required this.groupName,
    required this.icon,
    this.sectionCategory =
        'Catatan Utama', // <--- DIUBAH: Berikan default 'Catatan Utama' jika baru dibuat
    this.isHidden = false,
    this.orderIndex = 0,
    required this.allList,
  });

  factory DocumentGroup.fromJson(Map<String, dynamic> json) {
    return DocumentGroup(
      id: json['id'] ?? '',
      groupName: json['groupName'] ?? 'Untitled Group',
      icon: json['icon'] ?? '📁',
      // <--- DIUBAH: Jika di JSON kosong atau bertuliskan "Lainnya", arahkan ke "Catatan Utama" agar seragam dengan Notes
      sectionCategory:
          (json['sectionCategory'] == null ||
              json['sectionCategory'] == 'Lainnya' ||
              json['sectionCategory'].toString().isEmpty)
          ? 'Catatan Utama'
          : json['sectionCategory'],
      isHidden: json['isHidden'] ?? false,
      orderIndex: json['order_index'] ?? 0,
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
      'sectionCategory': sectionCategory.isEmpty
          ? 'Catatan Utama'
          : sectionCategory, // <--- DIUBAH: Pastikan selalu tersimpan dengan benar
      'isHidden': isHidden,
      'order_index': orderIndex,
      'allList': allList.map((section) => section.toJson()).toList(),
    };
  }
}
