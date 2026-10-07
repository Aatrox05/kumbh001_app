class EventModel {
  final String id;
  final String name;
  final String thumbnailUrl;
  final DateTime? startTime;
  final DateTime? endTime;
  final String location;
  final bool hasAudio;

  const EventModel({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    this.startTime,
    this.endTime,
    required this.location,
    required this.hasAudio,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseIso(String? s) => s == null ? null : DateTime.tryParse(s);

    return EventModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? json['thumbnail'] as String? ?? '',
      startTime: parseIso(json['startTime'] as String? ?? json['time'] as String?),
      endTime: parseIso(json['endTime'] as String?),
      location: json['location'] as String? ?? json['locationName'] as String? ?? '',
      hasAudio: (json['hasAudio'] is int) ? ((json['hasAudio'] as int) == 1) : (json['hasAudio'] as bool? ?? false),
    );
  }

  factory EventModel.fromMap(Map<String, dynamic> m) => EventModel(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? '',
        thumbnailUrl: m['thumbnailUrl'] as String? ?? '',
        startTime: m['startTime'] is String ? DateTime.tryParse(m['startTime'] as String) : null,
        endTime: m['endTime'] is String ? DateTime.tryParse(m['endTime'] as String) : null,
        location: m['location'] as String? ?? m['locationName'] as String? ?? '',
        hasAudio: (m['hasAudio'] is int) ? ((m['hasAudio'] as int) == 1) : (m['hasAudio'] as bool? ?? false),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'thumbnailUrl': thumbnailUrl,
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'location': location,
        'hasAudio': hasAudio,
      };

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'thumbnailUrl': thumbnailUrl,
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'location': location,
        'hasAudio': hasAudio ? 1 : 0,
      };

  EventModel copyWith({
    String? id,
    String? name,
    String? thumbnailUrl,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    bool? hasAudio,
  }) {
    return EventModel(
      id: id ?? this.id,
      name: name ?? this.name,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      hasAudio: hasAudio ?? this.hasAudio,
    );
  }
}
