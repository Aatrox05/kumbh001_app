import 'package:kumbh_app/core/storage/app_database.dart';
import '../models/contact_model.dart';
import '../../domain/repositories/contact_repository.dart';

class SqliteContactRepository implements ContactRepository {
  final AppDatabase _db = AppDatabase();

  @override
  Future<List<ContactModel>> getContacts() async {
    final db = await _db.database;
    final maps = await db.query('contacts');
    return maps.map((m) => ContactModel.fromMap(m)).toList();
  }

  @override
  Future<int> insertContact(ContactModel contact) async {
    final db = await _db.database;
    return db.insert('contacts', contact.toMap());
  }

  @override
  Future<int> deleteContact(int id) async {
    final db = await _db.database;
    return db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }
}
