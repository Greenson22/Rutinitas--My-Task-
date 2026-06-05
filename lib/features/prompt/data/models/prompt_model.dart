class PromptGroup {
  final String id;
  final String title;
  final String sectionName;
  final String icon;
  final String lastUpdated;
  final List<PromptItem> prompts;

  PromptGroup({
    required this.id,
    required this.title,
    required this.sectionName,
    required this.icon,
    required this.lastUpdated,
    required this.prompts,
  });

  factory PromptGroup.fromJson(Map<String, dynamic> json) {
    var list = json['prompts'] as List? ?? [];
    List<PromptItem> promptList = list
        .map((i) => PromptItem.fromJson(i))
        .toList();

    return PromptGroup(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      sectionName: json['section_name'] ?? '',
      icon: json['icon'] ?? '📝',
      lastUpdated: json['last_updated'] ?? '',
      prompts: promptList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'section_name': sectionName,
      'icon': icon,
      'last_updated': lastUpdated,
      'prompts': prompts.map((e) => e.toJson()).toList(),
    };
  }
}

class PromptItem {
  final String id;
  final String actAs;
  String? description;
  final bool isFavorite;

  // Fitur Baru: Versioning
  String activeVersionId;
  final List<PromptVersion> versions;

  PromptItem({
    required this.id,
    required this.actAs,
    this.description,
    required this.isFavorite,
    required this.activeVersionId,
    required this.versions,
  });

  // Helper untuk mengambil objek versi yang sedang aktif saat ini
  PromptVersion get activeVersion {
    return versions.firstWhere(
      (v) => v.id == activeVersionId,
      orElse: () => versions.isNotEmpty
          ? versions.first
          : PromptVersion(id: 'v1', versionName: 'v1.0', content: ''),
    );
  }

  factory PromptItem.fromJson(Map<String, dynamic> json) {
    var versionList = json['versions'] as List? ?? [];
    List<PromptVersion> parsedVersions = versionList
        .map((v) => PromptVersion.fromJson(v))
        .toList();

    // Migrasi data lama: jika data lama tidak punya 'versions' tapi punya 'content'
    if (parsedVersions.isEmpty && json['content'] != null) {
      parsedVersions.add(
        PromptVersion(
          id: 'v1',
          versionName: 'v1.0 (Migrasi)',
          content: json['content'] ?? '',
        ),
      );
    }

    return PromptItem(
      id: json['id'] ?? '',
      actAs: json['act_as'] ?? '',
      description: json['description'],
      isFavorite: json['is_favorite'] ?? false,
      activeVersionId:
          json['active_version_id'] ??
          (parsedVersions.isNotEmpty ? parsedVersions.first.id : 'v1'),
      versions: parsedVersions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'act_as': actAs,
      'description': description,
      'is_favorite': isFavorite,
      'active_version_id': activeVersionId,
      'versions': versions.map((v) => v.toJson()).toList(),
    };
  }

  // Metode pembantu untuk manipulasi state di UI/Controller
  PromptItem copyWith({
    String? activeVersionId,
    List<PromptVersion>? versions,
  }) {
    return PromptItem(
      id: id,
      actAs: actAs,
      description: description,
      isFavorite: isFavorite,
      activeVersionId: activeVersionId ?? this.activeVersionId,
      versions: versions ?? this.versions,
    );
  }
}

// Model Baru: Menyimpan data setiap versi prompt
class PromptVersion {
  final String id;
  final String versionName; // Misal: "v1.0", "v2.0 (Optimized)"
  final String content;

  PromptVersion({
    required this.id,
    required this.versionName,
    required this.content,
  });

  factory PromptVersion.fromJson(Map<String, dynamic> json) {
    return PromptVersion(
      id: json['id'] ?? '',
      versionName: json['version_name'] ?? '',
      content: json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'version_name': versionName, 'content': content};
  }
}
