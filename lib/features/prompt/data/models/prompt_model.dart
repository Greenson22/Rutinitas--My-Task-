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
  final String content;
  String? description;
  final bool isFavorite;

  PromptItem({
    required this.id,
    required this.actAs,
    required this.content,
    this.description,
    required this.isFavorite,
  });

  factory PromptItem.fromJson(Map<String, dynamic> json) {
    return PromptItem(
      id: json['id'] ?? '',
      actAs: json['act_as'] ?? '',
      description: json['description'],
      content: json['content'] ?? '',
      isFavorite: json['is_favorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'act_as': actAs,
      'description': description,
      'content': content,
      'is_favorite': isFavorite,
    };
  }
}
