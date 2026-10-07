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

  const LostFoundReport({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.location,
    required this.contact,
    required this.description,
    required this.isLost,
    this.synced = false,
  });

  factory LostFoundReport.fromMap(Map<String, dynamic> m) => LostFoundReport(
        id: m['id'] as int?,
        name: m['name'] as String? ?? '',
        age: m['age'] as int? ?? 0,
        gender: m['gender'] as String? ?? '',
        location: m['location'] as String? ?? '',
        contact: m['contact'] as String? ?? '',
        description: m['description'] as String? ?? '',
        isLost: (m['is_lost'] as int? ?? 0) == 1,
        synced: (m['synced'] as int? ?? 0) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'age': age,
        'gender': gender,
        'location': location,
        'contact': contact,
        'description': description,
        'is_lost': isLost ? 1 : 0,
        'synced': synced ? 1 : 0,
      };
}
