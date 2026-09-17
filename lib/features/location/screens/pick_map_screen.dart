import 'package:toto_user/common/widgets/custom_snackbar_widget.dart';
import 'package:toto_user/features/splash/controllers/splash_controller.dart';
import 'package:toto_user/features/address/domain/models/address_model.dart';
import 'package:toto_user/features/location/controllers/location_controller.dart';
import 'package:toto_user/features/location/widgets/location_search_dialog.dart';
import 'package:toto_user/features/location/widgets/permission_dialog.dart';
import 'package:toto_user/helper/responsive_helper.dart';
import 'package:toto_user/helper/address_helper.dart';
import 'package:toto_user/util/dimensions.dart';
import 'package:toto_user/util/images.dart';
import 'package:toto_user/common/widgets/custom_button_widget.dart';
import 'package:toto_user/common/widgets/web_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre/maplibre.dart' hide Position;

class PickMapScreen extends StatefulWidget {
  final bool fromSignUp;
  final bool fromSplash;
  final bool fromAddAddress;
  final bool canRoute;
  final String? route;

  const PickMapScreen({
    super.key,
    required this.fromSignUp,
    required this.fromAddAddress,
    required this.canRoute,
    required this.route,
    required this.fromSplash,
  });

  @override
  State<PickMapScreen> createState() => _PickMapScreenState();
}

class _PickMapScreenState extends State<PickMapScreen> {
  static const String _openFreeMapStyle =
      'https://tiles.openfreemap.org/styles/liberty';

  MapController? _mapController;
  late ll.LatLng _initialPosition;
  late ll.LatLng _cameraTarget;
  double _cameraZoom = 16;

  @override
  void initState() {
    super.initState();

    final locationController = Get.find<LocationController>();
    locationController.makeLoadingOff();

    if (widget.fromAddAddress) {
      locationController.setPickData();
    }

    _initialPosition = ll.LatLng(
      double.parse(
        Get.find<SplashController>()
                .configModel!
                .defaultLocation!
                .lat ??
            '0',
      ),
      double.parse(
        Get.find<SplashController>()
                .configModel!
                .defaultLocation!
                .lng ??
            '0',
      ),
    );

    if (widget.fromAddAddress) {
      _cameraTarget = ll.LatLng(
        locationController.position.latitude,
        locationController.position.longitude,
      );
    } else {
      final savedAddress = AddressHelper.getAddressFromSharedPref();

      final savedLat = double.tryParse(savedAddress?.latitude ?? '');
      final savedLng = double.tryParse(savedAddress?.longitude ?? '');

      if (savedLat != null && savedLng != null) {
        _cameraTarget = ll.LatLng(savedLat, savedLng);

        locationController.updatePosition(
          _cameraTarget,
          false,
        );
      } else {
        _cameraTarget = _initialPosition;
      }
    }
  }

  Geographic _toGeographic(ll.LatLng point) {
    return Geographic(
      lon: point.longitude,
      lat: point.latitude,
    );
  }

  ll.LatLng _toLatLng(Geographic point) {
    return ll.LatLng(point.lat, point.lon);
  }

  Future<void> _moveCamera(
    ll.LatLng target, {
    double zoom = 16,
  }) async {
    _cameraTarget = target;
    _cameraZoom = zoom;

    final controller = _mapController;
    if (controller == null) return;

    await controller.animateCamera(
      center: _toGeographic(target),
      zoom: zoom,
    );
  }

  Future<void> _moveToCurrentLocation(
    LocationController locationController,
  ) async {
    final AddressModel address =
        await locationController.getCurrentLocation(false);

    if (address.latitude == null || address.longitude == null) {
      return;
    }

    final location = ll.LatLng(
      double.parse(address.latitude!),
      double.parse(address.longitude!),
    );

    await _moveCamera(location);

    locationController.updatePosition(location, false);
  }

  Future<void> _handleCameraIdle(
    LocationController locationController,
  ) async {
    final controller = _mapController;
    if (controller == null) return;

    final camera = controller.camera;
    if (camera == null) return;

    final center = _toLatLng(camera.center);

    _cameraTarget = center;
    _cameraZoom = camera.zoom;

    locationController.updatePosition(center, false);
  }

  Future<void> _openSearch(
    LocationController locationController,
  ) async {
    final Position? result = await Get.dialog<Position>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: LocationSearchDialog(
          pickedLocation: locationController.pickAddress,
          fromAddress: true,
          callBack: (Position position) {
            if (Get.isDialogOpen == true) {
              Get.back(result: position);
            }
          },
        ),
      ),
    );

    if (result != null) {
      final location = ll.LatLng(
        result.latitude,
        result.longitude,
      );

      await _moveCamera(location);
      locationController.updatePosition(location, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: Dimensions.webMaxWidth,
            child: GetBuilder<LocationController>(
              builder: (locationController) {
                return Stack(
                  children: [
                    MapLibreMap(
                      options: MapOptions(
                        initStyle: _openFreeMapStyle,
                        initCenter: _toGeographic(_cameraTarget),
                        initZoom: _cameraZoom,
                        minZoom: 0,
                        maxZoom: 16,
                      ),
                      onMapCreated: (MapController controller) {
                        _mapController = controller;

                        if (!widget.fromAddAddress &&
                            widget.route != 'splash') {
                          WidgetsBinding.instance
                              .addPostFrameCallback((_) async {
                            final savedAddress =
                                AddressHelper.getAddressFromSharedPref();

                            final savedLat = double.tryParse(
                              savedAddress?.latitude ?? '',
                            );
                            final savedLng = double.tryParse(
                              savedAddress?.longitude ?? '',
                            );

                            if (savedLat != null && savedLng != null) {
                              final savedLocation =
                                  ll.LatLng(savedLat, savedLng);

                              await _moveCamera(savedLocation);

                              locationController.updatePosition(
                                savedLocation,
                                false,
                              );
                            } else {
                              await _moveToCurrentLocation(
                                locationController,
                              );
                            }

                            if (widget.fromSplash) {
                              _onPickAddressButtonPressed(
                                locationController,
                              );
                            }
                          });
                        }
                      },
                      onEvent: (event) {

                        if (event is MapEventCameraIdle) {
                          _handleCameraIdle(locationController);
                        }
                      },
                    ),

                    Center(
                      child: !locationController.loading
                          ? Image.asset(
                              Images.pickMarker,
                              height: 50,
                              width: 50,
                            )
                          : const CircularProgressIndicator(),
                    ),

                    Positioned(
                      top: Dimensions.paddingSizeLarge,
                      left: Dimensions.paddingSizeSmall,
                      right: Dimensions.paddingSizeSmall,
                      child: GestureDetector(
                        onTap: () => _openSearch(locationController),
                        child: AbsorbPointer(
                          child: LocationSearchDialog(
                            pickedLocation:
                                locationController.pickAddress,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 80,
                      right: Dimensions.paddingSizeSmall,
                      child: FloatingActionButton(
                        mini: true,
                        backgroundColor:
                            Theme.of(context).cardColor,
                        onPressed: () => _checkPermission(() async {
                          await _moveToCurrentLocation(
                            locationController,
                          );
                        }),
                        child: Icon(
                          Icons.my_location,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: Dimensions.paddingSizeLarge,
                      left: Dimensions.paddingSizeSmall,
                      right: Dimensions.paddingSizeSmall,
                      child: CustomButtonWidget(
                        buttonText: locationController.inZone
                            ? widget.fromAddAddress
                                ? 'pick_address'.tr
                                : 'pick_location'.tr
                            : 'service_not_available_in_this_area'.tr,
                        isLoading: locationController.isLoading,
                        onPressed: (locationController.buttonDisabled ||
                                locationController.loading)
                            ? null
                            : () => _onPickAddressButtonPressed(
                                  locationController,
                                ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _onPickAddressButtonPressed(
    LocationController locationController,
  ) {
    if (locationController.pickPosition.latitude != 0 &&
        locationController.pickAddress!.isNotEmpty) {
      if (widget.fromAddAddress) {
        locationController.addAddressData();

        Get.back(
          result: ll.LatLng(
            locationController.pickPosition.latitude,
            locationController.pickPosition.longitude,
          ),
        );
      } else {
        final AddressModel address = AddressModel(
          latitude:
              locationController.pickPosition.latitude.toString(),
          longitude:
              locationController.pickPosition.longitude.toString(),
          addressType: 'others',
          address: locationController.pickAddress,
        );

        locationController.saveAddressAndNavigate(
          address,
          widget.fromSignUp,
          widget.route,
          widget.canRoute,
          ResponsiveHelper.isDesktop(Get.context),
        );
      }
    } else {
      showCustomSnackBar('pick_an_address'.tr);
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




