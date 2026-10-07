import '../../../home/data/models/place_model.dart';

abstract class PlaceRepository {
  Future<List<PlaceModel>> getPlaces({String? query, String? category});
}
