import '../../../home/data/models/event_model.dart';

abstract class EventRepository {
  Future<List<EventModel>> getEvents();
}
