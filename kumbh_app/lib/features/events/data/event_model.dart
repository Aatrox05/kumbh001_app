class EventModel {
  final int id;
  final String name;
  final String locationName;
  final String startTime;
  final String endTime;
  final String audioUrl;
  final String description;
  final String imageUrl;
  final String category;
  final double latitude;
  final double longitude;
  final String organizer;

  EventModel({
    required this.id,
    required this.name,
    required this.locationName,
    required this.startTime,
    required this.endTime,
    required this.audioUrl,
    required this.description,
    required this.imageUrl,
    this.category = 'GENERAL',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.organizer = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location_name': locationName,
      'start_time': startTime,
      'end_time': endTime,
      'audio_url': audioUrl,
      'description': description,
      'image_url': imageUrl,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'organizer': organizer,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] as int? ?? 0,
      name: (map['name'] ?? map['title']) as String? ?? 'Kumbh Event',
      locationName: map['location_name'] as String? ?? '',
      startTime: map['start_time'] as String? ?? '',
      endTime: map['end_time'] as String? ?? '',
      audioUrl: map['audio_url'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: (map['image_url'] as String?)?.isNotEmpty == true
          ? map['image_url'] as String
          : 'assets/images/event_sample.jpg',
      category: map['category'] as String? ?? 'GENERAL',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      organizer: map['organizer'] as String? ?? '',
    );
  }
}
