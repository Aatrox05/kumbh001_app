import '../../../core/storage/app_database.dart';
import 'contact_model.dart';

abstract class ContactRepository {
  Future<List<ContactModel>> getContacts();
  Future<int> insertContact(ContactModel contact);
  Future<int> deleteContact(int id);
}

class SqliteContactRepository implements ContactRepository {
  final AppDatabase _dbHelper;

  SqliteContactRepository(this._dbHelper);

  @override
  Future<List<ContactModel>> getContacts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('contacts');
    return List.generate(maps.length, (i) => ContactModel.fromMap(maps[i]));
  }

  @override
  Future<int> insertContact(ContactModel contact) async {
    final db = await _dbHelper.database;
    return await db.insert('contacts', contact.toMap());
  }

  @override
  Future<int> deleteContact(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }
}
