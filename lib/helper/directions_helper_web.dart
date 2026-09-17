import 'dart:async';
import 'dart:js' as js;
import 'package:latlong2/latlong.dart';

/// Web-specific implementation using Google Maps JavaScript API
/// This avoids CORS issues by using the DirectionsService from the loaded JS API
class DirectionsHelperWeb {
  /// Get directions using Google Maps JavaScript API DirectionsService
  static Future<List<LatLng>?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      print('🌐 WEB: Using Google Maps JavaScript API DirectionsService');
      print('🗺️ Origin: (${origin.latitude}, ${origin.longitude})');
      print(
          '🗺️ Destination: (${destination.latitude}, ${destination.longitude})');

      // Use JavaScript evaluation to call DirectionsService
      final completer = Completer<List<LatLng>?>();

      // Create a unique callback name
      final callbackName =
          'directionsCallback_${DateTime.now().millisecondsSinceEpoch}';

      // Register callback in Dart that JavaScript can call
      js.context[callbackName] = (result, status) {
        try {
          final statusStr = status.toString();
          print('🗺️ WEB: DirectionsService callback - Status: $statusStr');

          if (statusStr == 'OK' && result != null) {
            final points = _extractPointsFromResult(result);
            completer.complete(points);
          } else {
            print('❌ WEB: DirectionsService failed with status: $statusStr');
            completer.complete(null);
          }
        } catch (e) {
          print('❌ WEB: Error in callback: $e');
          completer.complete(null);
        } finally {
          // Cleanup callback
          js.context.deleteProperty(callbackName);
        }
      };

      // Execute JavaScript to call DirectionsService
      final script = '''
        (function() {
          try {
            if (typeof google === 'undefined' || !google.maps) {
              console.error('❌ Google Maps not loaded');
              window.$callbackName(null, 'ERROR');
              return;
            }
            
            console.log('🌐 Creating DirectionsService...');
            var directionsService = new google.maps.DirectionsService();
            var request = {
              origin: {lat: ${origin.latitude}, lng: ${origin.longitude}},
              destination: {lat: ${destination.latitude}, lng: ${destination.longitude}},
              travelMode: 'DRIVING'
            };
            
            console.log('🗺️ Calling DirectionsService.route()...');
            directionsService.route(request, function(result, status) {
              console.log('📍 DirectionsService response:', status);
              window.$callbackName(result, status);
            });
          } catch (e) {
            console.error('❌ DirectionsService error:', e);
            window.$callbackName(null, 'ERROR');
          }
        })();
      ''';

      js.context.callMethod('eval', [script]);

      // Wait for callback with timeout
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ WEB: DirectionsService timeout');
          js.context.deleteProperty(callbackName);
          return null;
        },
      );
    } catch (e, stackTrace) {
      print('❌ WEB DirectionsService ERROR: $e');
      print('❌ STACK TRACE: $stackTrace');
      return null;
    }
  }

  /// Extract LatLng points from DirectionsResult
  static List<LatLng>? _extractPointsFromResult(dynamic result) {
    try {
      // Use JavaScript to extract and serialize the polyline points
      final extractScript = '''
        (function(result) {
          if (!result || !result.routes || result.routes.length === 0) {
            return JSON.stringify([]);
          }
          
          var points = [];
          var route = result.routes[0];
          
          for (var i = 0; i < route.legs.length; i++) {
            var leg = route.legs[i];
            for (var j = 0; j < leg.steps.length; j++) {
              var step = leg.steps[j];
              var path = step.path;
              for (var k = 0; k < path.length; k++) {
                points.push({
                  lat: path[k].lat(),
                  lng: path[k].lng()
                });
              }
            }
          }
          
          return JSON.stringify(points);
        })
      ''';

      final pointsJson = js.context
          .callMethod('eval', [extractScript]).callMethod(
              'call', [js.context, result]).toString();

      // Parse JSON string to extract points
      final pointsList = <LatLng>[];
      final regex = RegExp(r'"lat":([-\d.]+),"lng":([-\d.]+)');
      final matches = regex.allMatches(pointsJson);

      for (final match in matches) {
        final lat = double.parse(match.group(1)!);
        final lng = double.parse(match.group(2)!);
        pointsList.add(LatLng(lat, lng));
      }

      if (pointsList.isNotEmpty) {
        print(
            '✅ WEB: Successfully extracted ${pointsList.length} route points');
        return pointsList;
      } else {
        print('⚠️ WEB: No points extracted from result');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ WEB: Error extracting points: $e');
      print('❌ STACK TRACE: $stackTrace');
      return null;
    }
  }
}

