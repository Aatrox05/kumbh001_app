import 'package:url_launcher/url_launcher.dart';

/// Marker Category for Kumbh Map Representation
enum MapMarkerCategory {
  ghat,
  temple,
  hospital,
  police,
  parking,
  emergencyCamp,
  userLocation
}

class MapMarkerData {
  final String id;
  final String title;
  final String categoryName;
  final MapMarkerCategory category;
  final double latitude;
  final double longitude;
  final String address;

  const MapMarkerData({
    required this.id,
    required this.title,
    required this.categoryName,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

abstract class MapServiceInterface {
  /// Open external Google Maps / native device navigation intent to destination coordinates
  Future<bool> launchDirectionsTo(double latitude, double longitude, {String? destinationName});
}

class MapService implements MapServiceInterface {
  @override
  Future<bool> launchDirectionsTo(double latitude, double longitude, {String? destinationName}) async {
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude');
    if (await canLaunchUrl(googleMapsUrl)) {
      return await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
