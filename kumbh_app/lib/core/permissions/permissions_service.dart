import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class PermissionsService {
  /// Check and request location permission for SOS and map services.
  static Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[PermissionsService] Location services are disabled.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('[PermissionsService] Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('[PermissionsService] Location permissions are permanently denied.');
      return false;
    }

    return true;
  }
}
