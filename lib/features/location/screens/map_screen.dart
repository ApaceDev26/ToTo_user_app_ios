import 'package:geolocator/geolocator.dart';
import 'package:toto_user/common/models/restaurant_model.dart';
import 'package:toto_user/common/widgets/custom_snackbar_widget.dart';
import 'package:toto_user/common/widgets/menu_drawer_widget.dart';
import 'package:toto_user/features/address/domain/models/address_model.dart';
import 'package:toto_user/features/home/widgets/google_map_widgets/restaurant_details_sheet_widget.dart';
import 'package:toto_user/features/location/controllers/location_controller.dart';
import 'package:toto_user/features/location/widgets/permission_dialog.dart';
import 'package:toto_user/helper/address_helper.dart';
import 'package:toto_user/util/dimensions.dart';
import 'package:toto_user/util/styles.dart';
import 'package:toto_user/common/widgets/custom_app_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre/maplibre.dart' hide Position;
import 'package:url_launcher/url_launcher_string.dart';

class MapScreen extends StatefulWidget {
  final AddressModel address;
  final bool fromRestaurant;
  final String? restaurantName;
  final bool fromOrder;
  final Restaurant? restaurant;
  final bool fromDineInOrder;

  const MapScreen({
    super.key,
    required this.address,
    this.fromRestaurant = false,
    this.restaurantName,
    this.fromOrder = false,
    this.restaurant,
    this.fromDineInOrder = false,
  });

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  static const String _openFreeMapStyle =
      'https://tiles.openfreemap.org/styles/liberty';

  late ll.LatLng _latLng;
  MapController? _mapController;

  ll.LatLng? _myLocation;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();

    _latLng = ll.LatLng(
      double.parse(widget.address.latitude!),
      double.parse(widget.address.longitude!),
    );

    if (!widget.fromDineInOrder) {
      final savedAddress = AddressHelper.getAddressFromSharedPref();

      if (savedAddress?.latitude != null && savedAddress?.longitude != null) {
        _myLocation = ll.LatLng(
          double.parse(savedAddress!.latitude!),
          double.parse(savedAddress.longitude!),
        );
      }
    }
  }

  Geographic _toGeographic(ll.LatLng point) {
    return Geographic(
      lon: point.longitude,
      lat: point.latitude,
    );
  }

  Future<void> _moveCamera(
    ll.LatLng target, {
    double zoom = 15,
  }) async {
    final controller = _mapController;
    if (controller == null) return;

    await controller.animateCamera(
      center: _toGeographic(target),
      zoom: zoom,
    );
  }

  List<Layer> _buildMarkerLayers() {
    final List<Layer> layers = [];

    layers.add(
      CircleLayer(
        points: [
          Feature<Point>(
            geometry: Point(_toGeographic(_latLng)),
          ),
        ],
        color: Theme.of(context).primaryColor,
        radius: 9,
        strokeColor: Colors.white,
        strokeWidth: 3,
      ),
    );

    if (!widget.fromDineInOrder && _myLocation != null) {
      layers.add(
        CircleLayer(
          points: [
            Feature<Point>(
              geometry: Point(_toGeographic(_myLocation!)),
            ),
          ],
          color: Colors.blue,
          radius: 8,
          strokeColor: Colors.white,
          strokeWidth: 3,
        ),
      );
    }

    return layers;
  }

  Future<void> _setCurrentLocation() async {
    AddressModel address =
        await Get.find<LocationController>().getCurrentLocation(false);

    if (address.latitude == null || address.longitude == null) {
      return;
    }

    final currentLocation = ll.LatLng(
      double.parse(address.latitude!),
      double.parse(address.longitude!),
    );

    if (!mounted) return;

    setState(() {
      _myLocation = currentLocation;
    });

    await _moveCamera(
      currentLocation,
      zoom: GetPlatform.isWeb ? 7 : 15,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(
        title: widget.fromRestaurant || widget.fromOrder
            ? widget.restaurantName!
            : 'location'.tr,
      ),
      endDrawer: const MenuDrawerWidget(),
      endDrawerEnableOpenDragGesture: false,
      body: Center(
        child: SizedBox(
          width: Dimensions.webMaxWidth,
          child: Stack(
            children: [
              MapLibreMap(
                options: MapOptions(
                  initStyle: _openFreeMapStyle,
                  initCenter: _toGeographic(_latLng),
                  initZoom: 17,
                  minZoom: 0,
                  maxZoom: 18,
                ),
                layers: _buildMarkerLayers(),
                onMapCreated: (MapController controller) {
                  _mapController = controller;

                  if (mounted) {
                    setState(() {
                      _mapReady = true;
                    });
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showInitialLocations();
                  });
                },
              ),

              Positioned(
                left: Dimensions.paddingSizeLarge,
                right: Dimensions.paddingSizeLarge,
                bottom: Dimensions.paddingSizeLarge,
                child: Column(
                  children: [
                    widget.fromDineInOrder
                        ? const SizedBox()
                        : Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: () => _checkPermission(() async {
                                await _setCurrentLocation();
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

                    const SizedBox(
                      height: Dimensions.paddingSizeLarge,
                    ),

                    widget.restaurant != null
                        ? RestaurantDetailsSheetWidget(
                            restaurant: widget.restaurant!,
                            isActive: true,
                            fromOrder: true,
                          )
                        : InkWell(
                            onTap: () {
                              if (_mapReady) {
                                _moveCamera(_latLng, zoom: 17);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(
                                Dimensions.paddingSizeSmall,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusSmall,
                                ),
                                color: Theme.of(context).cardColor,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: widget.fromRestaurant
                                  ? Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            widget.address.address ?? '',
                                            style: robotoMedium,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(
                                          width:
                                              Dimensions.paddingSizeDefault,
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            final String url =
                                                'https://www.google.com/maps/dir/?api=1&destination=${widget.address.latitude},${widget.address.longitude}&mode=d';

                                            if (await canLaunchUrlString(url)) {
                                              await launchUrlString(
                                                url,
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            } else {
                                              showCustomSnackBar(
                                                'unable_to_launch_google_map'.tr,
                                              );
                                            }
                                          },
                                          child:
                                              const Icon(Icons.directions),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              widget.address.addressType ==
                                                      'home'
                                                  ? Icons.home_outlined
                                                  : widget.address
                                                              .addressType ==
                                                          'office'
                                                      ? Icons.work_outline
                                                      : Icons.location_on,
                                              size: 30,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    widget.address
                                                        .addressType!.tr,
                                                    style:
                                                        robotoRegular.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeSmall,
                                                      color: Theme.of(context)
                                                          .disabledColor,
                                                    ),
                                                  ),
                                                  Text(
                                                    widget.address.address!,
                                                    style: robotoMedium,
                                                  ),
                                                  (widget.address.road !=
                                                              null &&
                                                          widget.address.road!
                                                              .isNotEmpty)
                                                      ? Text(
                                                          '${'street_number'.tr}: ${widget.address.road}',
                                                          style:
                                                              robotoMedium,
                                                        )
                                                      : const SizedBox
                                                          .shrink(),
                                                  (widget.address.house !=
                                                              null &&
                                                          widget.address.house!
                                                              .isNotEmpty)
                                                      ? Text(
                                                          '${'house'.tr}: ${widget.address.house}',
                                                          style:
                                                              robotoMedium,
                                                        )
                                                      : const SizedBox
                                                          .shrink(),
                                                  (widget.address.floor !=
                                                              null &&
                                                          widget.address.floor!
                                                              .isNotEmpty)
                                                      ? Text(
                                                          '${'floor'.tr}: ${widget.address.floor}',
                                                          style:
                                                              robotoMedium,
                                                        )
                                                      : const SizedBox
                                                          .shrink(),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '- ${widget.address.contactPersonName}',
                                          style: robotoMedium.copyWith(
                                            color: Theme.of(context)
                                                .primaryColor,
                                            fontSize:
                                                Dimensions.fontSizeLarge,
                                          ),
                                        ),
                                        Text(
                                          '- ${widget.address.contactPersonNumber}',
                                          style: robotoRegular,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showInitialLocations() async {
    if (_mapController == null) return;

    // When viewing a restaurant, always open directly on the restaurant pin.
    if (widget.fromRestaurant || widget.restaurant != null) {
      await _moveCamera(_latLng, zoom: 17);
      return;
    }

    if (_myLocation == null) {
      await _moveCamera(_latLng, zoom: 17);
      return;
    }

    final center = ll.LatLng(
      (_latLng.latitude + _myLocation!.latitude) / 2,
      (_latLng.longitude + _myLocation!.longitude) / 2,
    );

    await _moveCamera(
      center,
      zoom: GetPlatform.isWeb ? 7 : 15,
    );
  }

  void _checkPermission(Function onTap) async {
    LocationPermission permission = await Geolocator.checkPermission();

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




