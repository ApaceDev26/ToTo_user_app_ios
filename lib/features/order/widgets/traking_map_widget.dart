import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre/maplibre.dart';

import 'package:toto_user/common/models/restaurant_model.dart';
import 'package:toto_user/features/address/domain/models/address_model.dart';
import 'package:toto_user/features/location/controllers/location_controller.dart';
import 'package:toto_user/features/order/domain/models/order_model.dart';
import 'package:toto_user/helper/directions_helper.dart';
import 'package:toto_user/helper/responsive_helper.dart';
import 'package:toto_user/util/dimensions.dart';

class TrackingMapWidget extends StatefulWidget {
  final OrderModel? track;

  const TrackingMapWidget({
    super.key,
    required this.track,
  });

  @override
  State<TrackingMapWidget> createState() => _TrackingMapWidgetState();
}

class _TrackingMapWidgetState extends State<TrackingMapWidget> {
  static const String _openFreeMapStyle =
      'https://tiles.openfreemap.org/styles/liberty';

  MapController? _controller;

  bool _isLoading = true;
  bool _hasAnimated = false;

  List<ll.LatLng> _routePoints = [];
  Color _routeColor = Colors.blue;

  DateTime? _lastRouteApiCallAt;
  ll.LatLng? _lastRouteApiDeliveryLocation;

  static const Duration _routeApiCooldown = Duration(seconds: 60);
  static const double _routeApiMinMovementMeters = 100.0;

  bool _restaurantCustomerRouteLoaded = false;
  bool _routeRequestInProgress = false;

  Geographic _toGeographic(ll.LatLng point) {
    return Geographic(
      lon: point.longitude,
      lat: point.latitude,
    );
  }

  ll.LatLng _restaurantLocation(Restaurant restaurant) {
    return ll.LatLng(
      double.parse(restaurant.latitude!),
      double.parse(restaurant.longitude!),
    );
  }

  ll.LatLng _addressLocation(AddressModel address) {
    return ll.LatLng(
      double.parse(address.latitude!),
      double.parse(address.longitude!),
    );
  }

  ll.LatLng? _deliveryManLocation(DeliveryMan? deliveryMan) {
    if (deliveryMan == null ||
        deliveryMan.lat == null ||
        deliveryMan.lng == null) {
      return null;
    }

    return ll.LatLng(
      double.parse(deliveryMan.lat!),
      double.parse(deliveryMan.lng!),
    );
  }

  bool _isPickedUp(OrderModel track) {
    return track.orderStatus == 'picked_up' ||
        track.orderStatus == 'delivered' ||
        track.orderStatus == 'handover';
  }

  AddressModel? _getDestinationAddress(OrderModel track) {
    if (track.orderType != 'take_away') {
      return track.deliveryAddress;
    }

    final locationController = Get.find<LocationController>();

    if (locationController.position.latitude == 0) {
      return track.deliveryAddress;
    }

    return AddressModel(
      latitude: locationController.position.latitude.toString(),
      longitude: locationController.position.longitude.toString(),
      address: locationController.address,
    );
  }

  ll.LatLng _getInitialTarget(OrderModel track) {
    final deliveryLocation = _deliveryManLocation(track.deliveryMan);

    if (_isPickedUp(track) && deliveryLocation != null) {
      return deliveryLocation;
    }

    if (track.restaurant?.latitude != null &&
        track.restaurant?.longitude != null) {
      return _restaurantLocation(track.restaurant!);
    }

    if (track.deliveryAddress?.latitude != null &&
        track.deliveryAddress?.longitude != null) {
      return _addressLocation(track.deliveryAddress!);
    }

    return const ll.LatLng(0, 0);
  }

  List<Feature<Point>> _destinationPoints(AddressModel? address) {
    if (address?.latitude == null || address?.longitude == null) {
      return [];
    }

    final point = _addressLocation(address!);

    return [
      Feature<Point>(
        geometry: Point(_toGeographic(point)),
      ),
    ];
  }

  List<Feature<Point>> _restaurantPoints(Restaurant? restaurant) {
    if (restaurant?.latitude == null || restaurant?.longitude == null) {
      return [];
    }

    final point = _restaurantLocation(restaurant!);

    return [
      Feature<Point>(
        geometry: Point(_toGeographic(point)),
      ),
    ];
  }

  List<Feature<Point>> _deliveryManPoints(DeliveryMan? deliveryMan) {
    final point = _deliveryManLocation(deliveryMan);

    if (point == null) {
      return [];
    }

    return [
      Feature<Point>(
        geometry: Point(_toGeographic(point)),
      ),
    ];
  }

  List<Feature<LineString>> _routeFeatures() {
    if (_routePoints.length < 2) {
      return [];
    }

    return [
      Feature<LineString>(
        geometry: LineString(
          PositionSeries.from(
            _routePoints.map(_toGeographic).toList(),
          ),
        ),
      ),
    ];
  }

  List<Layer> _buildLayers(
    Restaurant? restaurant,
    DeliveryMan? deliveryMan,
    AddressModel? address,
  ) {
    return [
      if (_routePoints.length >= 2)
        PolylineLayer(
          polylines: _routeFeatures(),
          color: _routeColor,
          width: 4,
          dashArray: const [5, 3],
        ),

      CircleLayer(
        points: _destinationPoints(address),
        radius: 9,
        color: const Color(0xFF1976D2),
        strokeWidth: 3,
        strokeColor: Colors.white,
      ),

      CircleLayer(
        points: _restaurantPoints(restaurant),
        radius: 10,
        color: const Color(0xFFFF6D00),
        strokeWidth: 3,
        strokeColor: Colors.white,
      ),

      CircleLayer(
        points: _deliveryManPoints(deliveryMan),
        radius: 10,
        color: const Color(0xFF2E7D32),
        strokeWidth: 3,
        strokeColor: Colors.white,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final track = widget.track;

    if (track == null || track.deliveryMan == null) {
      return Container(
        height: 200,
        width: ResponsiveHelper.isMobilePhone()
            ? width
            : 1170.0 - 100.0,
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        child: FittedBox(
          child: Text('no_delivery_man_data_found'.tr),
        ),
      );
    }

    final address = _getDestinationAddress(track);
    final initialTarget = _getInitialTarget(track);

    return Container(
      height: 200,
      width: ResponsiveHelper.isMobilePhone()
          ? width
          : 1170.0 - 100.0,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            child: MapLibreMap(
              options: MapOptions(
                initStyle: _openFreeMapStyle,
                initCenter: _toGeographic(initialTarget),
                initZoom: 15,
                minZoom: 0,
                maxZoom: 16,
              ),
              layers: _buildLayers(
                track.restaurant,
                track.deliveryMan,
                address,
              ),
              onMapCreated: (MapController controller) async {
                _controller = controller;

                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }

                await setMarker(
                  track.restaurant,
                  track.deliveryMan,
                  address,
                  track.orderType == 'take_away',
                );
              },
            ),
          ),

          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> setMarker(
    Restaurant? restaurant,
    DeliveryMan? deliveryMan,
    AddressModel? addressModel,
    bool takeAway,
  ) async {
    try {
      if (addressModel == null) {
        return;
      }

      final bool pickedUp = _isPickedUp(widget.track!);

      ll.LatLng targetLocation;
      final double zoom = GetPlatform.isWeb ? 10 : 15;

      final deliveryLocation = _deliveryManLocation(deliveryMan);

      if (pickedUp && deliveryLocation != null) {
        targetLocation = deliveryLocation;
      } else if (restaurant?.latitude != null &&
          restaurant?.longitude != null) {
        targetLocation = _restaurantLocation(restaurant!);
      } else {
        targetLocation = _addressLocation(addressModel);
      }

      if (!_hasAnimated) {
        await _animateToLocation(targetLocation, zoom);
        _hasAnimated = true;
      } else {
        await _moveToLocation(targetLocation, zoom);
      }

      if (pickedUp) {
        await _updateRouteWithDeliveryMan(widget.track!);
      } else {
        await _createRoutePolyline(widget.track!);
      }
    } catch (e) {
      debugPrint('Tracking map update failed: $e');
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _moveToLocation(
    ll.LatLng targetLocation,
    double zoom,
  ) async {
    final controller = _controller;

    if (controller == null) {
      return;
    }

    await controller.animateCamera(
      center: _toGeographic(targetLocation),
      zoom: zoom,
    );
  }

  Future<void> _animateToLocation(
    ll.LatLng targetLocation,
    double zoom,
  ) async {
    final controller = _controller;

    if (controller == null) {
      return;
    }

    await controller.animateCamera(
      center: _toGeographic(targetLocation),
      zoom: zoom - 5,
    );

    await Future.delayed(const Duration(milliseconds: 300));

    await controller.animateCamera(
      center: _toGeographic(targetLocation),
      zoom: zoom,
    );
  }

  Future<void> _createRoutePolyline(OrderModel track) async {
    if (_restaurantCustomerRouteLoaded) {
      return;
    }

    if (track.restaurant == null ||
        track.restaurant!.latitude == null ||
        track.restaurant!.longitude == null ||
        track.deliveryAddress == null ||
        track.deliveryAddress!.latitude == null ||
        track.deliveryAddress!.longitude == null) {
      return;
    }

    final ll.LatLng restaurantLocation =
        _restaurantLocation(track.restaurant!);

    final ll.LatLng customerLocation =
        _addressLocation(track.deliveryAddress!);

    if (_routeRequestInProgress) {
      return;
    }

    _routeRequestInProgress = true;

    List<ll.LatLng>? routePoints;

    try {
      routePoints =
          await DirectionsHelper.getRestaurantToCustomerRoute(
        restaurant: restaurantLocation,
        customer: customerLocation,
      );
    } catch (e) {
      debugPrint('Guest restaurant route request failed: $e');
    } finally {
      _routeRequestInProgress = false;
    }

    _routePoints = routePoints != null && routePoints.isNotEmpty
        ? routePoints
        : [restaurantLocation, customerLocation];

    _routeColor = Colors.blue;
    _restaurantCustomerRouteLoaded = true;

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _updateRouteWithDeliveryMan(OrderModel track) async {
    if (track.deliveryAddress == null ||
        track.deliveryAddress!.latitude == null ||
        track.deliveryAddress!.longitude == null) {
      return;
    }

    final ll.LatLng customerLocation =
        _addressLocation(track.deliveryAddress!);

    final ll.LatLng? deliveryManLocation =
        _deliveryManLocation(track.deliveryMan);

    if (deliveryManLocation == null) {
      return;
    }

    final DateTime now = DateTime.now();

    if (_lastRouteApiCallAt != null &&
        _lastRouteApiDeliveryLocation != null) {
      final Duration elapsed =
          now.difference(_lastRouteApiCallAt!);

      final double movedMeters = Geolocator.distanceBetween(
        _lastRouteApiDeliveryLocation!.latitude,
        _lastRouteApiDeliveryLocation!.longitude,
        deliveryManLocation.latitude,
        deliveryManLocation.longitude,
      );

      if (elapsed < _routeApiCooldown ||
          movedMeters < _routeApiMinMovementMeters) {
        return;
      }
    }

    if (_routeRequestInProgress) {
      return;
    }

    _routeRequestInProgress = true;

    List<ll.LatLng>? routePoints;

    try {
      routePoints = await DirectionsHelper.getDirections(
        origin: deliveryManLocation,
        destination: customerLocation,
      );

      _lastRouteApiCallAt = DateTime.now();
      _lastRouteApiDeliveryLocation = deliveryManLocation;
    } catch (e) {
      debugPrint('Guest delivery route request failed: $e');

      _lastRouteApiCallAt = DateTime.now();
      _lastRouteApiDeliveryLocation = deliveryManLocation;
    } finally {
      _routeRequestInProgress = false;
    }

    _routePoints = routePoints != null && routePoints.isNotEmpty
        ? routePoints
        : [deliveryManLocation, customerLocation];

    _routeColor = Colors.green;

    if (mounted) {
      setState(() {});
    }
  }
}
