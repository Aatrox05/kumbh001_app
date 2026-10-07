class ContactModel {
  final int? id;
  final String name;
  final String phone;

  const ContactModel({
    this.id,
    required this.name,
    required this.phone,
  });

  factory ContactModel.fromMap(Map<String, dynamic> m) => ContactModel(
        id: m['id'] as int?,
        name: m['name'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
      };
}
