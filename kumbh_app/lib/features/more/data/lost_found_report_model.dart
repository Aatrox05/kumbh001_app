class LostFoundReport {
  final int? id;
  final String name;
  final int age;
  final String gender;
  final String location;
  final String contact;
  final String description;
  final bool isLost;
  final bool synced;
  final String? imageBase64;

  LostFoundReport({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.location,
    required this.contact,
    required this.description,
    required this.isLost,
    this.synced = false,
    this.imageBase64,
  });

  LostFoundReport copyWith({
    int? id,
    String? name,
    int? age,
    String? gender,
    String? location,
    String? contact,
    String? description,
    bool? isLost,
    bool? synced,
    String? imageBase64,
  }) {
    return LostFoundReport(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      contact: contact ?? this.contact,
      description: description ?? this.description,
      isLost: isLost ?? this.isLost,
      synced: synced ?? this.synced,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'age': age,
      'gender': gender,
      'location': location,
      'contact': contact,
      'description': description,
      'is_lost': isLost ? 1 : 0,
      'synced': synced ? 1 : 0,
      'image_base64': imageBase64,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory LostFoundReport.fromMap(Map<String, dynamic> map) {
    return LostFoundReport(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      age: (map['age'] as num?)?.toInt() ?? 0,
      gender: map['gender'] as String? ?? '',
      location: map['location'] as String? ?? '',
      contact: map['contact'] as String? ?? '',
      description: map['description'] as String? ?? '',
      isLost: (map['is_lost'] as int? ?? 0) == 1,
      synced: (map['synced'] as int? ?? 0) == 1,
      imageBase64: map['image_base64'] as String?,
    );
  }
}
