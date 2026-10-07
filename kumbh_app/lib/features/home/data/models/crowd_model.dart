class CrowdModel {
  final String locationId;
  final String level;
  final String? note;
  final DateTime updatedAt;

  const CrowdModel({
    required this.locationId,
    required this.level,
    this.note,
    required this.updatedAt,
  });

  factory CrowdModel.fromJson(Map<String, dynamic> json) {
    final updatedRaw = json['updatedAt'];
    DateTime updated;
    if (updatedRaw is String) {
      updated = DateTime.tryParse(updatedRaw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else if (updatedRaw is int) {
      updated = DateTime.fromMillisecondsSinceEpoch(updatedRaw);
    } else {
      updated = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return CrowdModel(
      locationId: json['locationId'] as String? ?? '',
      level: json['level'] as String? ?? 'LOW',
      note: json['note'] as String?,
      updatedAt: updated,
    );
  }

  factory CrowdModel.fromMap(Map<String, dynamic> m) => CrowdModel(
        locationId: m['location_id'] as String? ?? '',
        level: m['level'] as String? ?? 'LOW',
        note: m['note'] as String?,
        updatedAt: m['updated_at'] is String ? DateTime.tryParse(m['updated_at'] as String) ?? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.fromMillisecondsSinceEpoch(0),
      );

  Map<String, dynamic> toJson() => {
        'locationId': locationId,
        'level': level,
        'note': note,
        'updatedAt': updatedAt.toIso8601String(),
      };

  Map<String, dynamic> toMap() => {
        'location_id': locationId,
        'level': level,
        'note': note,
        'updated_at': updatedAt.toIso8601String(),
      };

  CrowdModel copyWith({
    String? locationId,
    String? level,
    String? note,
    DateTime? updatedAt,
  }) {
    return CrowdModel(
      locationId: locationId ?? this.locationId,
      level: level ?? this.level,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
