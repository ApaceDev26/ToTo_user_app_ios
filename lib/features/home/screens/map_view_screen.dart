import 'package:geolocator/geolocator.dart';
import 'package:toto_user/common/widgets/custom_snackbar_widget.dart';
import 'package:toto_user/common/widgets/menu_drawer_widget.dart';
import 'package:toto_user/features/address/domain/models/address_model.dart';
import 'package:toto_user/features/dine_in/controllers/dine_in_controller.dart';
import 'package:toto_user/features/home/widgets/google_map_widgets/restaurant_search_widget.dart';
import 'package:toto_user/features/home/widgets/map_custom_info_window_widget.dart';
import 'package:toto_user/features/home/widgets/google_map_widgets/restaurant_details_sheet_widget.dart';
import 'package:toto_user/features/home/widgets/restaurants_view_widget.dart';
import 'package:toto_user/features/location/controllers/location_controller.dart';
import 'package:toto_user/features/location/widgets/permission_dialog.dart';
import 'package:toto_user/features/profile/controllers/profile_controller.dart';
import 'package:toto_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:toto_user/common/models/restaurant_model.dart';
import 'package:toto_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:toto_user/helper/address_helper.dart';
import 'package:toto_user/helper/responsive_helper.dart';
import 'package:toto_user/helper/route_helper.dart';
import 'package:toto_user/util/dimensions.dart';
import 'package:toto_user/common/widgets/custom_app_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre/maplibre.dart';

class MapViewScreen extends StatefulWidget {
  final bool fromDineInScreen;

  const MapViewScreen({
    super.key,
    this.fromDineInScreen = false,
  });

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  static const String _openFreeMapStyle =
      'https://tiles.openfreemap.org/styles/liberty';

  MapController? _controller;
  PageController? _pageController = PageController();

  bool _showLoading = true;
  double _currentZoom = 12;

  Restaurant? _selectedRestaurant;
  bool _showUserInfo = false;

  @override
  void initState() {
    super.initState();

    if (ResponsiveHelper.isDesktop(Get.context)) {
      _pageController = PageController(
        viewportFraction: 0.37,
        initialPage: 0,
      );
    }

    if (widget.fromDineInScreen) {
      Get.find<DineInController>().getDineInRestaurantList(1, false);
    } else {
      Get.find<RestaurantController>()
          .getRestaurantList(1, false, fromMap: true);
    }

    Get.find<RestaurantController>()
        .setNearestRestaurantIndex(-1, notify: false);

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showLoading = false;
      });
    });
  }

  @override
  void dispose() {
_pageController?.dispose();
    super.dispose();
  }

  Geographic _toGeographic(ll.LatLng point) {
    return Geographic(
      lon: point.longitude,
      lat: point.latitude,
    );
  }

ll.LatLng _savedLocation() {
    final address = AddressHelper.getAddressFromSharedPref();

    return ll.LatLng(
      double.tryParse(address?.latitude ?? '') ?? 0,
      double.tryParse(address?.longitude ?? '') ?? 0,
    );
  }

  List<Restaurant> _restaurantList(
    RestaurantController restController,
    DineInController dineInController,
  ) {
    if (widget.fromDineInScreen) {
      return dineInController.dineInModel?.restaurants ?? <Restaurant>[];
    }

    return restController.restaurantModel?.restaurants ?? <Restaurant>[];
  }

  List<Feature<Point>> _restaurantPoints(List<Restaurant> restaurants) {
    final points = <Feature<Point>>[];

    for (final restaurant in restaurants) {
      final lat = double.tryParse(restaurant.latitude ?? '');
      final lng = double.tryParse(restaurant.longitude ?? '');

      if (lat == null || lng == null) continue;

      points.add(
        Feature<Point>(
          geometry: Point(
            Geographic(
              lon: lng,
              lat: lat,
            ),
          ),
        ),
      );
    }

    return points;
  }

  List<Feature<Point>> _userPoints() {
    final location = _savedLocation();

    return [
      Feature<Point>(
        geometry: Point(
          _toGeographic(location),
        ),
      ),
    ];
  }

  List<Layer> _buildLayers(List<Restaurant> restaurants) {
    return [
      CircleLayer(
        points: _userPoints(),
        radius: 9,
        color: const Color(0xFF1976D2),
        strokeWidth: 3,
        strokeColor: Colors.white,
      ),
      CircleLayer(
        points: _restaurantPoints(restaurants),
        radius: 10,
        color: const Color(0xFFFF6D00),
        strokeWidth: 3,
        strokeColor: Colors.white,
      ),
    ];
  }

  Future<void> _moveCamera(
    ll.LatLng target, {
    double zoom = 12,
  }) async {
    final controller = _controller;
    if (controller == null) return;

    _currentZoom = zoom;

    await controller.animateCamera(
      center: _toGeographic(target),
      zoom: zoom,
    );
  }

  Future<void> _zoomIn() async {
    final camera = _controller?.camera;
    if (camera == null) return;

    _currentZoom = (_currentZoom + 1).clamp(0.0, 16.0);

    await _controller!.animateCamera(
      center: camera.center,
      zoom: _currentZoom,
    );
  }

  Future<void> _zoomOut() async {
    final camera = _controller?.camera;
    if (camera == null) return;

    _currentZoom = (_currentZoom - 1).clamp(0.0, 16.0);

    await _controller!.animateCamera(
      center: camera.center,
      zoom: _currentZoom,
    );
  }

  void _handleMapClick(
    Geographic point,
    List<Restaurant> restaurants,
  ) {
    if (restaurants.isEmpty) return;

    final cameraZoom = _controller?.camera?.zoom ?? _currentZoom;

    // Keep the click tolerance tight so a tap cannot accidentally
    // select a nearby different restaurant.
    double tapDistance;

    if (cameraZoom >= 16) {
      tapDistance = 60;
    } else if (cameraZoom >= 14) {
      tapDistance = 100;
    } else if (cameraZoom >= 12) {
      tapDistance = 180;
    } else {
      tapDistance = 300;
    }

    Restaurant? selectedRestaurant;
    int selectedIndex = -1;
    double selectedDistance = double.infinity;

    for (int i = 0; i < restaurants.length; i++) {
      final lat = double.tryParse(restaurants[i].latitude ?? '');
      final lng = double.tryParse(restaurants[i].longitude ?? '');

      if (lat == null || lng == null) continue;

      final distance = Geolocator.distanceBetween(
        point.lat,
        point.lon,
        lat,
        lng,
      );

      if (distance <= tapDistance && distance < selectedDistance) {
        selectedDistance = distance;
        selectedRestaurant = restaurants[i];
        selectedIndex = i;
      }
    }

    if (selectedRestaurant != null && selectedIndex >= 0) {
      _animateMarker(
        selectedRestaurant,
        selectedIndex,
      );
      return;
    }

    Get.find<RestaurantController>()
        .setNearestRestaurantIndex(-1);

    if (mounted) {
      setState(() {
        _selectedRestaurant = null;
        _showUserInfo = false;
      });
    }
  }

  Widget _buildMap(
    List<Restaurant> restaurants,
    RestaurantController restController,
  ) {
    return MapLibreMap(
      options: MapOptions(
        initStyle: _openFreeMapStyle,
        initCenter: _toGeographic(_savedLocation()),
        initZoom: 12,
        minZoom: 0,
        maxZoom: 16,
      ),
      layers: _buildLayers(restaurants),
      onMapCreated: (MapController controller) {
        _controller = controller;
      },
      onEvent: (event) {
        if (event is MapEventClick) {
          _handleMapClick(
            event.point,
            restaurants,
          );
        }

        if (event is MapEventCameraIdle) {
          final camera = _controller?.camera;
          if (camera != null) {
            _currentZoom = camera.zoom;
          }
        }
      },
    );
  }

  Widget _buildInfoWindow() {
    if (_selectedRestaurant == null && !_showUserInfo) {
      return const SizedBox();
    }

    return Positioned(
      top: 80,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _selectedRestaurant == null
                ? null
                : () {
                    Get.toNamed(
                      RouteHelper.getRestaurantRoute(
                        _selectedRestaurant!.id,
                      ),
                      arguments: RestaurantScreen(
                        restaurant: _selectedRestaurant!,
                      ),
                    );
                  },
            child: MapCustomInfoWindowWidget(
              restaurant: _selectedRestaurant,
              userInfoModel: _showUserInfo
                  ? Get.find<ProfileController>().userInfoModel
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomButtons({
    required Color iconColor,
  }) {
    return Column(
      children: [
        FloatingActionButton(
          mini: true,
          backgroundColor: Colors.white,
          elevation: 5,
          onPressed: _zoomIn,
          child: Icon(
            Icons.add,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          mini: true,
          backgroundColor: Colors.white,
          elevation: 5,
          onPressed: _zoomOut,
          child: Icon(
            Icons.remove,
            color: iconColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(
        title: widget.fromDineInScreen
            ? 'restaurants_map'.tr
            : 'nearby_restaurants'.tr,
      ),
      endDrawer: const MenuDrawerWidget(),
      endDrawerEnableOpenDragGesture: false,
      body: GetBuilder<RestaurantController>(
        builder: (restController) {
          return GetBuilder<DineInController>(
            builder: (dineInController) {
              final loaded = widget.fromDineInScreen
                  ? dineInController.dineInModel != null
                  : restController.restaurantModel != null;

              if (!loaded) {
                return const SizedBox();
              }

              final restaurants = _restaurantList(
                restController,
                dineInController,
              );

              if (ResponsiveHelper.isDesktop(context)) {
                return Center(
                  child: Container(
                    width: Dimensions.webMaxWidth,
                    padding: const EdgeInsets.all(
                      Dimensions.paddingSizeExtraLarge,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Get.isDarkMode
                              ? Colors.black.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: PageView.builder(
                            itemCount: restaurants.length,
                            scrollDirection: Axis.vertical,
                            controller: _pageController,
                            padEnds: false,
                            onPageChanged: (int index) {
                              _animateMarker(
                                restaurants[index],
                                index,
                              );
                            },
                            itemBuilder: (context, index) {
                              final isSelected =
                                  restController
                                      .nearestRestaurantIndex ==
                                  index;

                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom:
                                      Dimensions.paddingSizeDefault,
                                ),
                                child: RestaurantView(
                                  restaurant: restaurants[index],
                                  isSelected: isSelected,
                                  onTap: () {
                                    Get.toNamed(
                                      RouteHelper.getRestaurantRoute(
                                        restaurants[index].id,
                                      ),
                                      arguments: RestaurantScreen(
                                        restaurant:
                                            restaurants[index],
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(
                          width: Dimensions.paddingSizeExtraLarge,
                        ),
                        Expanded(
                          flex: 6,
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusDefault,
                                ),
                                child: _buildMap(
                                  restaurants,
                                  restController,
                                ),
                              ),
                              Positioned(
                                top: Dimensions.paddingSizeSmall,
                                left: Dimensions.paddingSizeSmall,
                                right: Dimensions.paddingSizeSmall,
                                child: RestaurantSearchWidget(
                                  restaurantList: restaurants,
                                  callBack: (int index) {
                                    _animateMarker(
                                      restaurants[index],
                                      index,
                                    );
                                  },
                                ),
                              ),
                              _buildInfoWindow(),
                              Positioned(
                                bottom: 30,
                                right: 10,
                                child: _buildZoomButtons(
                                  iconColor:
                                      Theme.of(context).hintColor,
                                ),
                              ),
                              if (_showLoading)
                                const Center(
                                  child:
                                      CircularProgressIndicator(),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Stack(
                children: [
                  _buildMap(
                    restaurants,
                    restController,
                  ),
                  Positioned(
                    top: Dimensions.paddingSizeSmall,
                    left: Dimensions.paddingSizeSmall,
                    right: Dimensions.paddingSizeSmall,
                    child: RestaurantSearchWidget(
                      restaurantList: restaurants,
                      callBack: (int index) {
                        _animateMarker(
                          restaurants[index],
                          index,
                        );
                      },
                    ),
                  ),
                  _buildInfoWindow(),
                  Positioned(
                    bottom:
                        restController.nearestRestaurantIndex != -1
                            ? 270
                            : 80,
                    right: 15,
                    child: _buildZoomButtons(
                      iconColor: Theme.of(context).hintColor,
                    ),
                  ),
                  Positioned(
                    right: 15,
                    bottom:
                        restController.nearestRestaurantIndex != -1
                            ? 210
                            : 20,
                    child: InkWell(
                      onTap: () => _checkPermission(() async {
                        final AddressModel address =
                            await Get.find<LocationController>()
                                .getCurrentLocation(false);

                        if (address.latitude == null ||
                            address.longitude == null) {
                          return;
                        }

                        final target = ll.LatLng(
                          double.tryParse(address.latitude!) ?? 0,
                          double.tryParse(address.longitude!) ?? 0,
                        );

                        await _moveCamera(
                          target,
                          zoom: 15,
                        );

                        if (mounted) {
                          setState(() {
                            _selectedRestaurant = null;
                            _showUserInfo = true;
                          });
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(
                          Dimensions.paddingSizeSmall,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: Colors.white,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.my_location_outlined,
                          color: Theme.of(context).hintColor,
                          size: 25,
                        ),
                      ),
                    ),
                  ),
                  if (restController.nearestRestaurantIndex != -1)
                    Positioned(
                      bottom: 0,
                      child: SizedBox(
                        height: 200,
                        width: context.width,
                        child: PageView.builder(
                          onPageChanged: (int index) {
                            _animateMarker(
                              restaurants[index],
                              index,
                            );
                          },
                          scrollDirection: Axis.horizontal,
                          controller: _pageController,
                          itemCount: restaurants.length,
                          itemBuilder: (context, index) {
                            final active =
                                restController
                                    .nearestRestaurantIndex ==
                                index;

                            return RestaurantDetailsSheetWidget(
                              restaurant: restaurants[index],
                              isActive: active,
                            );
                          },
                        ),
                      ),
                    ),
                  if (_showLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _animateMarker(
    Restaurant restaurant,
    int index,
  ) async {
    Get.find<RestaurantController>()
        .setNearestRestaurantIndex(index);

    final lat = double.tryParse(restaurant.latitude ?? '');
    final lng = double.tryParse(restaurant.longitude ?? '');

    if (lat == null || lng == null) return;

    final latLng = ll.LatLng(lat, lng);

    await _moveCamera(
      latLng,
      zoom: 14,
    );

    if (!_pageController!.hasClients) {
      _pageController = PageController(
        initialPage: index,
      );
    } else {
      final currentPage =
          _pageController!.page?.round();

      if (currentPage != index) {
        _pageController!.animateToPage(
          index,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    }

    if (mounted) {
      setState(() {
        _selectedRestaurant = restaurant;
        _showUserInfo = false;
      });
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
    } else if (permission == LocationPermission.deniedForever) {
      Get.dialog(const PermissionDialog());
    } else {
      onTap();
    }
  }
}



