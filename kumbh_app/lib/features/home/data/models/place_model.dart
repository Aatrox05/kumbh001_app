class PlaceModel {
  final String id;
  final String name;
  final String imageUrl;
  final double distanceKm;
  final String crowdLevel;
  final String category;

  const PlaceModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.distanceKm,
    required this.crowdLevel,
    this.category = '',
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    final distanceValue = json['distanceKm'];
    double distanceKm;
    if (distanceValue is num) {
      distanceKm = distanceValue.toDouble();
    } else {
      distanceKm = double.tryParse(distanceValue?.toString() ?? '') ?? 0.0;
    }

    return PlaceModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      distanceKm: distanceKm,
      crowdLevel: json['crowdLevel'] as String? ?? 'LOW',
      category: json['category'] as String? ?? '',
    );
  }

  factory PlaceModel.fromMap(Map<String, dynamic> m) => PlaceModel(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? '',
        // DB column is image_url, fallback to imageUrl for JSON compat
        imageUrl: m['image_url'] as String? ?? m['imageUrl'] as String? ?? '',
        distanceKm: (m['distance_km'] is num)
            ? (m['distance_km'] as num).toDouble()
            : double.tryParse('${m['distance_km']}') ?? 0.0,
        crowdLevel: m['crowd_level'] as String? ?? 'LOW',
        category: m['category'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'distanceKm': distanceKm,
        'crowdLevel': crowdLevel,
        'category': category,
      };

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'image_url': imageUrl,
        'distance_km': distanceKm,
        'crowd_level': crowdLevel,
        'category': category,
      };

  PlaceModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    double? distanceKm,
    String? crowdLevel,
    String? category,
  }) {
    return PlaceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      distanceKm: distanceKm ?? this.distanceKm,
      crowdLevel: crowdLevel ?? this.crowdLevel,
      category: category ?? this.category,
    );
  }
}
