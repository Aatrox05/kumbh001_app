class ContactModel {
  final int? id;
  final String name;
  final String phone;

  ContactModel({
    this.id,
    required this.name,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'phone': phone,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
    );
  }
}
