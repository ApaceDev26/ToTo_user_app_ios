import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class DirectionsHelper {
  static const String _baseUrl = 'https://router.project-osrm.org';

  /// Get road directions between two points using OSRM.
  static Future<List<LatLng>?> getDirections({
    required LatLng origin,
    required LatLng destination,
    LatLng? waypoint,
  }) async {
    try {
      final coordinates = waypoint == null
          ? '${origin.longitude},${origin.latitude};'
              '${destination.longitude},${destination.latitude}'
          : '${origin.longitude},${origin.latitude};'
              '${waypoint.longitude},${waypoint.latitude};'
              '${destination.longitude},${destination.latitude}';

      final uri = Uri.parse(
        '$_baseUrl/route/v1/driving/$coordinates'
        '?overview=full&geometries=geojson&steps=false',
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        print('OSRM HTTP ERROR: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);

      if (data['code'] != 'Ok' ||
          data['routes'] == null ||
          (data['routes'] as List).isEmpty) {
        print('OSRM ROUTE ERROR: ${data['code']}');
        return null;
      }

      final routeCoordinates =
          data['routes'][0]['geometry']['coordinates'] as List;

      final points = routeCoordinates.map<LatLng>((point) {
        return LatLng(
          (point[1] as num).toDouble(),
          (point[0] as num).toDouble(),
        );
      }).toList();

      print('OSRM DIRECTIONS SUCCESS: ${points.length} points');
      return points;
    } catch (e, stackTrace) {
      print('OSRM DIRECTIONS EXCEPTION: $e');
      print('STACK TRACE: $stackTrace');
      return null;
    }
  }

  static Future<List<LatLng>?> getRestaurantToCustomerRoute({
    required LatLng restaurant,
    required LatLng customer,
  }) async {
    return getDirections(
      origin: restaurant,
      destination: customer,
    );
  }

  static Future<List<LatLng>?> getDeliveryRoute({
    required LatLng restaurant,
    required LatLng deliveryMan,
    required LatLng customer,
  }) async {
    return getDirections(
      origin: restaurant,
      waypoint: deliveryMan,
      destination: customer,
    );
  }

  /// Compatibility method for existing code.
  static Future<bool> testApiKey() async {
    try {
      final result = await getDirections(
        origin: LatLng(23.8486, 90.9803),
        destination: LatLng(23.8500, 90.9900),
      );
      return result != null && result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Fallback path only if road routing is unavailable.
  static List<LatLng> createCurvedPath(
    LatLng start,
    LatLng end, {
    int segments = 20,
  }) {
    final points = <LatLng>[];

    final midLat = (start.latitude + end.latitude) / 2;
    final midLng = (start.longitude + end.longitude) / 2;

    final latDiff = end.latitude - start.latitude;
    final lngDiff = end.longitude - start.longitude;

    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final t2 = t * t;
      final mt = 1 - t;
      final mt2 = mt * mt;
      final curveOffset = 4 * t * mt * 0.1;

      final lat = mt2 * start.latitude +
          2 * mt * t * (midLat + lngDiff * curveOffset) +
          t2 * end.latitude;

      final lng = mt2 * start.longitude +
          2 * mt * t * (midLng - latDiff * curveOffset) +
          t2 * end.longitude;

      points.add(LatLng(lat, lng));
    }

    return points;
  }
}

