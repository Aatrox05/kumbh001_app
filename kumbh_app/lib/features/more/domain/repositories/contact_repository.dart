import '../../data/models/contact_model.dart';

abstract class ContactRepository {
  Future<List<ContactModel>> getContacts();
  Future<int> insertContact(ContactModel contact);
  Future<int> deleteContact(int id);
}
