import 'dart:async';

import 'package:expandable_bottom_sheet/expandable_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre/maplibre.dart';

import 'package:toto_user/common/models/restaurant_model.dart';
import 'package:toto_user/common/widgets/custom_app_bar_widget.dart';
import 'package:toto_user/common/widgets/custom_snackbar_widget.dart';
import 'package:toto_user/common/widgets/menu_drawer_widget.dart';
import 'package:toto_user/features/address/domain/models/address_model.dart';
import 'package:toto_user/features/chat/domain/models/conversation_model.dart';
import 'package:toto_user/features/location/controllers/location_controller.dart';
import 'package:toto_user/features/location/widgets/permission_dialog.dart';
import 'package:toto_user/features/notification/domain/models/notification_body_model.dart';
import 'package:toto_user/features/order/controllers/order_controller.dart';
import 'package:toto_user/features/order/domain/models/order_model.dart';
import 'package:toto_user/features/order/widgets/dine_in_restaurants_card_widget.dart';
import 'package:toto_user/features/order/widgets/track_details_view.dart';
import 'package:toto_user/helper/address_helper.dart';
import 'package:toto_user/helper/directions_helper.dart';
import 'package:toto_user/helper/route_helper.dart';
import 'package:toto_user/util/dimensions.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String? orderID;
  final String? contactNumber;

  const OrderTrackingScreen({
    super.key,
    required this.orderID,
    this.contactNumber,
  });

  @override
  OrderTrackingScreenState createState() => OrderTrackingScreenState();
}

class OrderTrackingScreenState extends State<OrderTrackingScreen>
    with WidgetsBindingObserver {
  static const String _openFreeMapStyle =
      'https://tiles.openfreemap.org/styles/liberty';

  MapController? _controller;

  bool _isLoading = true;
  bool _hasAnimated = false;

  Timer? _timer;

  List<ll.LatLng> _routePoints = <ll.LatLng>[];
  Color _routeColor = Colors.blue;

  Restaurant? _mapRestaurant;
  DeliveryMan? _mapDeliveryMan;
  AddressModel? _mapDestination;
  AddressModel? _currentAddress;

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

  ll.LatLng? _parseLocation(String? latitude, String? longitude) {
    final double? lat = double.tryParse(latitude ?? '');
    final double? lng = double.tryParse(longitude ?? '');

    if (lat == null || lng == null) {
      return null;
    }

    return ll.LatLng(lat, lng);
  }

  ll.LatLng? _restaurantLocation(Restaurant? restaurant) {
    return _parseLocation(
      restaurant?.latitude,
      restaurant?.longitude,
    );
  }

  ll.LatLng? _addressLocation(AddressModel? address) {
    return _parseLocation(
      address?.latitude,
      address?.longitude,
    );
  }

  ll.LatLng? _deliveryManLocation(DeliveryMan? deliveryMan) {
    return _parseLocation(
      deliveryMan?.lat,
      deliveryMan?.lng,
    );
  }

  bool _isPickedUp(OrderModel track) {
    return track.orderStatus == 'picked_up' ||
        track.orderStatus == 'delivered' ||
        track.orderStatus == 'handover';
  }

  AddressModel? _getTrackingAddress(OrderModel track) {
    if (track.orderType != 'take_away') {
      return track.deliveryAddress;
    }

    final LocationController locationController =
        Get.find<LocationController>();

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
    final ll.LatLng? restaurant = _restaurantLocation(track.restaurant);

    if (restaurant != null) {
      return restaurant;
    }

    final ll.LatLng? deliveryMan = _deliveryManLocation(track.deliveryMan);

    if (_isPickedUp(track) && deliveryMan != null) {
      return deliveryMan;
    }

    final ll.LatLng? address = _addressLocation(track.deliveryAddress);

    if (address != null) {
      return address;
    }

    final savedAddress = AddressHelper.getAddressFromSharedPref();

    final ll.LatLng? savedLocation = _parseLocation(
      savedAddress?.latitude,
      savedAddress?.longitude,
    );

    return savedLocation ?? const ll.LatLng(23.8103, 90.4125);
  }

  List<Feature<Point>> _pointFeature(ll.LatLng? point) {
    if (point == null) {
      return <Feature<Point>>[];
    }

    return <Feature<Point>>[
      Feature<Point>(
        geometry: Point(_toGeographic(point)),
      ),
    ];
  }

  List<Feature<LineString>> _routeFeatures() {
    if (_routePoints.length < 2) {
      return <Feature<LineString>>[];
    }

    return <Feature<LineString>>[
      Feature<LineString>(
        geometry: LineString(
          PositionSeries.from(
            _routePoints.map(_toGeographic).toList(),
          ),
        ),
      ),
    ];
  }

  List<Layer> _buildMapLayers() {
    final ll.LatLng? destination = _currentAddress != null
        ? _addressLocation(_currentAddress)
        : _addressLocation(_mapDestination);

    final ll.LatLng? restaurant =
        _restaurantLocation(_mapRestaurant);

    final ll.LatLng? deliveryMan =
        _deliveryManLocation(_mapDeliveryMan);

    return <Layer>[
      if (_routePoints.length >= 2)
        PolylineLayer(
          polylines: _routeFeatures(),
          color: _routeColor,
          width: 4,
          dashArray: const <int>[5, 3],
        ),

      CircleLayer(
        points: _pointFeature(destination),
        radius: 9,
        color: const Color(0xFF1976D2),
        strokeWidth: 3,
        strokeColor: Colors.white,
      ),

      CircleLayer(
        points: _pointFeature(restaurant),
        radius: 10,
        color: const Color(0xFFFF6D00),
        strokeWidth: 3,
        strokeColor: Colors.white,
      ),

      CircleLayer(
        points: _pointFeature(deliveryMan),
        radius: 10,
        color: const Color(0xFF2E7D32),
        strokeWidth: 3,
        strokeColor: Colors.white,
      ),
    ];
  }

  Future<void> _loadData() async {
    final savedAddress = AddressHelper.getAddressFromSharedPref();

    final ll.LatLng? defaultLocation = _parseLocation(
      savedAddress?.latitude,
      savedAddress?.longitude,
    );

    await Get.find<LocationController>().getCurrentLocation(
      true,
      notify: false,
      defaultLatLng: defaultLocation,
    );

    await Get.find<OrderController>().trackOrder(
      widget.orderID,
      null,
      true,
      contactNumber: widget.contactNumber,
    );

    _timerTrackOrder();
  }

  void _timerTrackOrder() {
    final OrderModel? track =
        Get.find<OrderController>().trackModel;

    if (track == null) {
      return;
    }

    if (track.orderStatus != 'delivered' &&
        track.orderStatus != 'failed' &&
        track.orderStatus != 'canceled') {
      Get.find<OrderController>().timerTrackOrder(
        widget.orderID.toString(),
        contactNumber: widget.contactNumber,
      );

      _timer?.cancel();

      _timer = Timer.periodic(
        const Duration(seconds: 10),
        (timer) async {
          if (Get.currentRoute.contains(RouteHelper.orderDetails) ||
              Get.currentRoute.contains(RouteHelper.orderTracking)) {
            await Get.find<OrderController>().timerTrackOrder(
              widget.orderID.toString(),
              contactNumber: widget.contactNumber,
            );

            final OrderModel? updatedTrack =
                Get.find<OrderController>().trackModel;

            if (updatedTrack != null) {
              await updateMarker(
                updatedTrack.restaurant,
                updatedTrack.deliveryMan,
                _getTrackingAddress(updatedTrack),
                updatedTrack.orderType == 'take_away',
                track: updatedTrack,
              );
            }
          } else {
            _timer?.cancel();
          }
        },
      );
    } else {
      Get.find<OrderController>().timerTrackOrder(
        widget.orderID.toString(),
        contactNumber: widget.contactNumber,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _timerTrackOrder();
    } else if (state == AppLifecycleState.paused) {
      Get.find<OrderController>().cancelTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    Get.find<OrderController>().cancelTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(
        title: '${'order'.tr} #${widget.orderID.toString()}',
      ),
      endDrawer: const MenuDrawerWidget(),
      endDrawerEnableOpenDragGesture: false,
      body: GetBuilder<OrderController>(
        builder: (orderController) {
          final OrderModel? track = orderController.trackModel;

          if (track == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final AddressModel? trackingAddress =
              _getTrackingAddress(track);

          _mapRestaurant ??= track.restaurant;
          _mapDeliveryMan ??= track.deliveryMan;
          _mapDestination ??= trackingAddress;

          return Center(
            child: SizedBox(
              width: Dimensions.webMaxWidth,
              child: ExpandableBottomSheet(
                background: Stack(
                  children: [
                    MapLibreMap(
                      options: MapOptions(
                        initStyle: _openFreeMapStyle,
                        initCenter:
                            _toGeographic(_getInitialTarget(track)),
                        initZoom: 13,
                        minZoom: 0,
                        maxZoom: 16,
                      ),
                      layers: _buildMapLayers(),
                      onMapCreated: (MapController controller) async {
                        _controller = controller;

                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }

                        await Future.delayed(
                          const Duration(milliseconds: 500),
                        );

                        await setMarker(
                          track.restaurant,
                          track.deliveryMan,
                          trackingAddress,
                          track.orderType == 'take_away',
                          track: track,
                        );
                      },
                    ),

                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      ),

                    Positioned(
                      right: 15,
                      bottom: track.orderType != 'take_away' &&
                              track.deliveryMan == null
                          ? 150
                          : 190,
                      child: InkWell(
                        onTap: () => _checkPermission(() async {
                          final AddressModel address =
                              await Get.find<LocationController>()
                                  .getCurrentLocation(false);

                          await setMarker(
                            track.restaurant,
                            track.deliveryMan,
                            trackingAddress,
                            track.orderType == 'take_away',
                            currentAddress: address,
                            fromCurrentLocation: true,
                            track: track,
                          );
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(
                            Dimensions.paddingSizeSmall,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.white,
                          ),
                          child: Icon(
                            Icons.my_location_outlined,
                            color: Theme.of(context).primaryColor,
                            size: 25,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                persistentContentHeight: 170,
                expandableContent: track.orderType == 'dine_in'
                    ? DineInRestaurantsCardWidget(
                        restaurant: track.restaurant!,
                      )
                    : Padding(
                        padding: const EdgeInsets.only(
                          left: Dimensions.paddingSizeSmall,
                          right: Dimensions.paddingSizeSmall,
                          bottom: Dimensions.paddingSizeSmall,
                        ),
                        child: TrackDetailsView(
                          track: track,
                          callback: () async {
                            final bool takeAway =
                                track.orderType == 'take_away';

                            orderController.cancelTimer();

                            await Get.toNamed(
                              RouteHelper.getChatRoute(
                                notificationBody: takeAway
                                    ? NotificationBodyModel(
                                        restaurantId:
                                            track.restaurant!.id,
                                        orderId:
                                            int.parse(widget.orderID!),
                                      )
                                    : NotificationBodyModel(
                                        deliverymanId:
                                            track.deliveryMan!.id,
                                        orderId:
                                            int.parse(widget.orderID!),
                                      ),
                                user: User(
                                  id: takeAway
                                      ? track.restaurant!.id
                                      : track.deliveryMan!.id,
                                  fName: takeAway
                                      ? track.restaurant!.name
                                      : track.deliveryMan!.fName,
                                  lName: takeAway
                                      ? ''
                                      : track.deliveryMan!.lName,
                                  imageFullUrl: takeAway
                                      ? track.restaurant!.logoFullUrl
                                      : track.deliveryMan!.imageFullUrl,
                                ),
                              ),
                            );

                            _timerTrackOrder();
                          },
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> setMarker(
    Restaurant? restaurant,
    DeliveryMan? deliveryMan,
    AddressModel? addressModel,
    bool takeAway, {
    AddressModel? currentAddress,
    bool fromCurrentLocation = false,
    OrderModel? track,
  }) async {
    try {
      _mapRestaurant = restaurant;
      _mapDeliveryMan = deliveryMan;
      _mapDestination = addressModel;
      _currentAddress = currentAddress;

      if (fromCurrentLocation && currentAddress != null) {
        final ll.LatLng? currentLocation =
            _addressLocation(currentAddress);

        if (currentLocation != null) {
          await _moveToLocation(currentLocation, 15);
        }
      } else {
        ll.LatLng? targetLocation;

        if (restaurant != null) {
          targetLocation = _restaurantLocation(restaurant);
        }

        targetLocation ??= _addressLocation(addressModel);

        if (targetLocation != null) {
          if (!_hasAnimated) {
            await _animateToLocation(targetLocation, 15);
            _hasAnimated = true;
          } else {
            await _moveToLocation(targetLocation, 15);
          }
        }
      }

      if (track != null) {
        if (_isPickedUp(track)) {
          await _updateRouteWithDeliveryMan(track);
        } else {
          await _createRoutePolyline(track);
        }
      }
    } catch (e) {
      debugPrint('Tracking map marker update failed: $e');
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> updateMarker(
    Restaurant? restaurant,
    DeliveryMan? deliveryMan,
    AddressModel? addressModel,
    bool takeAway, {
    AddressModel? currentAddress,
    bool fromCurrentLocation = false,
    OrderModel? track,
  }) async {
    try {
      _mapRestaurant = restaurant;
      _mapDeliveryMan = deliveryMan;
      _mapDestination = addressModel;

      if (currentAddress != null) {
        _currentAddress = currentAddress;
      }

      if (fromCurrentLocation && currentAddress != null) {
        final ll.LatLng? currentLocation =
            _addressLocation(currentAddress);

        if (currentLocation != null) {
          await _moveToLocation(currentLocation, 15);
        }
      } else {
        ll.LatLng? targetLocation;

        final bool pickedUp =
            track != null && _isPickedUp(track);

        if (pickedUp) {
          targetLocation =
              _deliveryManLocation(deliveryMan);
        }

        targetLocation ??=
            _restaurantLocation(restaurant);

        targetLocation ??=
            _addressLocation(addressModel);

        if (targetLocation != null) {
          await _moveToLocation(targetLocation, 15);
        }
      }

      if (track != null) {
        if (_isPickedUp(track)) {
          await _updateRouteWithDeliveryMan(track);
        } else {
          await _createRoutePolyline(track);
        }
      }
    } catch (e) {
      debugPrint('Tracking map live update failed: $e');
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _moveToLocation(
    ll.LatLng targetLocation,
    double zoom,
  ) async {
    final MapController? controller = _controller;

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
    final MapController? controller = _controller;

    if (controller == null) {
      return;
    }

    await controller.animateCamera(
      center: _toGeographic(targetLocation),
      zoom: zoom - 5,
    );

    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    await controller.animateCamera(
      center: _toGeographic(targetLocation),
      zoom: zoom,
    );
  }

  Future<void> _createRoutePolyline(OrderModel track) async {
    if (_restaurantCustomerRouteLoaded) {
      return;
    }

    final ll.LatLng? restaurantLocation =
        _restaurantLocation(track.restaurant);

    final ll.LatLng? customerLocation =
        _addressLocation(track.deliveryAddress);

    if (restaurantLocation == null ||
        customerLocation == null) {
      return;
    }

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
      debugPrint(
        'Restaurant to customer route request failed: $e',
      );
    } finally {
      _routeRequestInProgress = false;
    }

    if (routePoints != null && routePoints.isNotEmpty) {
      _routePoints = routePoints;
    } else {
      _routePoints = DirectionsHelper.createCurvedPath(
        restaurantLocation,
        customerLocation,
        segments: 25,
      );
    }

    _routeColor = Colors.blue;
    _restaurantCustomerRouteLoaded = true;

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _updateRouteWithDeliveryMan(
    OrderModel track,
  ) async {
    final ll.LatLng? customerLocation =
        _addressLocation(track.deliveryAddress);

    if (customerLocation == null) {
      return;
    }

    final ll.LatLng? deliveryManLocation =
        _deliveryManLocation(track.deliveryMan);

    if (deliveryManLocation == null) {
      if (!_restaurantCustomerRouteLoaded) {
        await _createRoutePolyline(track);
      }
      return;
    }

    final DateTime now = DateTime.now();

    if (_lastRouteApiCallAt != null &&
        _lastRouteApiDeliveryLocation != null) {
      final Duration elapsed =
          now.difference(_lastRouteApiCallAt!);

      final double movedMeters =
          Geolocator.distanceBetween(
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

      _lastRouteApiCallAt = now;
      _lastRouteApiDeliveryLocation =
          deliveryManLocation;
    } catch (e) {
      debugPrint(
        'Delivery route request failed: $e',
      );

      _lastRouteApiCallAt = now;
      _lastRouteApiDeliveryLocation =
          deliveryManLocation;
    } finally {
      _routeRequestInProgress = false;
    }

    if (routePoints != null && routePoints.isNotEmpty) {
      _routePoints = routePoints;
    } else {
      _routePoints = DirectionsHelper.createCurvedPath(
        deliveryManLocation,
        customerLocation,
        segments: 25,
      );
    }

    _routeColor = Colors.green;

    if (mounted) {
      setState(() {});
    }
  }

  void _checkPermission(Function onTap) async {
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      showCustomSnackBar('you_have_to_allow'.tr);
    } else if (permission ==
        LocationPermission.deniedForever) {
      Get.dialog(const PermissionDialog());
    } else {
      onTap();
    }
  }
}
