class AnnouncementModel {
  final int id;
  final String title;
  final String content;
  final String priority; // CRITICAL, IMPORTANT, NORMAL
  final String category; // SAFETY, TRAFFIC, EVENTS, EMERGENCY, GENERAL
  final String targetGroup;
  final String publishedAt;
  final String? expiresAt;
  final String sourceName;
  final int version;
  final bool isRead;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.priority,
    required this.category,
    required this.targetGroup,
    required this.publishedAt,
    this.expiresAt,
    required this.sourceName,
    required this.version,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'priority': priority,
      'category': category,
      'target_group': targetGroup,
      'published_at': publishedAt,
      'expires_at': expiresAt,
      'source_name': sourceName,
      'version': version,
      'is_read': isRead ? 1 : 0,
    };
  }

  factory AnnouncementModel.fromMap(Map<String, dynamic> map) {
    return AnnouncementModel(
      id: map['id'] as int? ?? 0,
      title: map['title'] as String? ?? 'Notice',
      content: map['content'] as String? ?? '',
      priority: map['priority'] as String? ?? 'NORMAL',
      category: map['category'] as String? ?? 'GENERAL',
      targetGroup: map['target_group'] as String? ?? 'ALL',
      publishedAt: map['published_at'] as String? ?? DateTime.now().toIso8601String(),
      expiresAt: map['expires_at'] as String?,
      sourceName: map['source_name'] as String? ?? 'Kumbh Disaster Control Command',
      version: map['version'] as int? ?? 1,
      isRead: (map['is_read'] as int? ?? 0) == 1,
    );
  }

  AnnouncementModel copyWith({bool? isRead}) {
    return AnnouncementModel(
      id: id,
      title: title,
      content: content,
      priority: priority,
      category: category,
      targetGroup: targetGroup,
      publishedAt: publishedAt,
      expiresAt: expiresAt,
      sourceName: sourceName,
      version: version,
      isRead: isRead ?? this.isRead,
    );
  }
}
