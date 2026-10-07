class Place {
  final int id;
  final String name;
  final String imageUrl;
  final double distanceKm;
  final String crowdLevel; // Low, Medium, High
  final String category; // Ghats, Temples, Parking, Hotels, Help Centers
  final String description;
  final double latitude;
  final double longitude;

  Place({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.distanceKm,
    required this.crowdLevel,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'distance_km': distanceKm,
      'crowd_level': crowdLevel,
      'category': category,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Place.fromMap(Map<String, dynamic> map) {
    return Place(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? 'Unknown Place',
      imageUrl: (map['image_url'] as String?)?.isNotEmpty == true
          ? map['image_url'] as String
          : 'assets/images/place_sample.jpg',
      distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 0.0,
      crowdLevel: map['crowd_level'] as String? ?? 'Low',
      category: map['category'] as String? ?? 'All',
      description: map['description'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
