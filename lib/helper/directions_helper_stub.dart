import 'package:latlong2/latlong.dart';

/// Stub implementation for non-web platforms
/// This file is used by conditional imports when not on web
class DirectionsHelperWeb {
  static Future<List<LatLng>?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    // This should never be called on non-web platforms
    throw UnsupportedError(
        'Web DirectionsService is only available on web platform');
  }
}

