import 'package:toto_user/features/profile/controllers/profile_controller.dart';
import 'package:toto_user/features/splash/controllers/splash_controller.dart';
import 'package:toto_user/features/address/domain/models/address_model.dart';
import 'package:toto_user/features/auth/controllers/auth_controller.dart';
import 'package:toto_user/features/location/controllers/location_controller.dart';
import 'package:toto_user/features/location/widgets/serach_location_widget.dart';
import 'package:toto_user/helper/address_helper.dart';
import 'package:toto_user/helper/responsive_helper.dart';
import 'package:toto_user/util/dimensions.dart';
import 'package:toto_user/util/images.dart';
import 'package:toto_user/util/styles.dart';
import 'package:toto_user/common/widgets/custom_button_widget.dart';
import 'package:toto_user/common/widgets/custom_snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre/maplibre.dart';

class PickMapDialog extends StatefulWidget {
  final bool fromSignUp;
  final bool fromAddAddress;
  final bool canRoute;
  final String? route;
  final Function(AddressModel address)? onPicked;

  const PickMapDialog({
    super.key,
    required this.fromSignUp,
    required this.fromAddAddress,
    required this.canRoute,
    required this.route,
    this.onPicked,
  });

  @override
  State<PickMapDialog> createState() => _PickMapDialogState();
}

class _PickMapDialogState extends State<PickMapDialog> {
  static const String _openFreeMapStyle =
      'https://tiles.openfreemap.org/styles/liberty';

  MapController? _mapController;
  late ll.LatLng _initialPosition;
  double _currentZoom = 16.0;

  @override
  void initState() {
    super.initState();

    if (widget.fromAddAddress) {
      Get.find<LocationController>().setPickData();
    }

    Get.find<LocationController>().makeLoadingOff();

    _initialPosition = ll.LatLng(
      double.parse(
        Get.find<SplashController>().configModel!.defaultLocation!.lat ?? '0',
      ),
      double.parse(
        Get.find<SplashController>().configModel!.defaultLocation!.lng ?? '0',
      ),
    );
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

  ll.LatLng _getInitialTarget(LocationController locationController) {
    if (widget.fromAddAddress) {
      return ll.LatLng(
        locationController.position.latitude,
        locationController.position.longitude,
      );
    }

    return _initialPosition;
  }

  Future<void> _moveCamera(
    ll.LatLng target, {
    double? zoom,
  }) async {
    final controller = _mapController;
    if (controller == null) return;

    await controller.animateCamera(
      center: _toGeographic(target),
      zoom: zoom ?? _currentZoom,
    );
  }

  Future<void> _moveToCurrentLocation(
    LocationController locationController,
  ) async {
    final position = await locationController.getCurrentLocation(false);

    final target = ll.LatLng(
      double.parse(position.latitude ?? '0'),
      double.parse(position.longitude ?? '0'),
    );

    await _moveCamera(target, zoom: _currentZoom);
    locationController.updatePosition(target, false);
  }

  void _handleCameraIdle(LocationController locationController) {
    final camera = _mapController?.camera;
    if (camera == null) return;

    _currentZoom = camera.zoom;

    final target = _toLatLng(camera.center);
    locationController.updatePosition(target, false);
  }

  Future<void> _zoomIn() async {
    _currentZoom = (_currentZoom + 1).clamp(0.0, 16.0);

    final camera = _mapController?.camera;
    if (camera == null) return;

    await _mapController!.animateCamera(
      center: camera.center,
      zoom: _currentZoom,
    );
  }

  Future<void> _zoomOut() async {
    _currentZoom = (_currentZoom - 1).clamp(0.0, 16.0);

    final camera = _mapController?.camera;
    if (camera == null) return;

    await _mapController!.animateCamera(
      center: camera.center,
      zoom: _currentZoom,
    );
  }

  Widget _buildMap(LocationController locationController) {
    return MapLibreMap(
      options: MapOptions(
        initStyle: _openFreeMapStyle,
        initCenter: _toGeographic(
          _getInitialTarget(locationController),
        ),
        initZoom: _currentZoom,
        minZoom: 0,
        maxZoom: 16,
      ),
      onMapCreated: (MapController controller) {
        _mapController = controller;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!widget.fromAddAddress) {
            await _moveToCurrentLocation(locationController);
          } else {
            await _moveCamera(
              _getInitialTarget(locationController),
              zoom: _currentZoom,
            );
          }
        });
      },
      onEvent: (event) {
        if (event is MapEventCameraIdle) {
          _handleCameraIdle(locationController);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Container(
        height: ResponsiveHelper.isDesktop(context) ? 500 : null,
        width: ResponsiveHelper.isDesktop(context)
            ? 700
            : Dimensions.webMaxWidth,
        decoration: context.width > 700
            ? BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius:
                    BorderRadius.circular(Dimensions.radiusSmall),
              )
            : null,
        child: GetBuilder<LocationController>(
          builder: (locationController) {
            return ResponsiveHelper.isDesktop(context)
                ? Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.clear),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: Dimensions.paddingSizeSmall,
                          left: Dimensions.paddingSizeExtraLarge,
                          right: Dimensions.paddingSizeExtraLarge,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'pick_your_location'.tr,
                              style: robotoMedium.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                              ),
                            ),
                            Text(
                              'sharing_your_accurate_location'.tr,
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                              ),
                            ),
                            const SizedBox(
                              height: Dimensions.paddingSizeDefault,
                            ),
                            SearchLocationWidget(
                              pickedAddress:
                                  locationController.pickAddress,
                              isEnabled: true,
                              fromDialog: true,
                            ),
                            const SizedBox(
                              height: Dimensions.paddingSizeDefault,
                            ),
                            SizedBox(
                              height: 270,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.radiusDefault,
                                    ),
                                    child: _buildMap(locationController),
                                  ),
                                  Center(
                                    child: !locationController.loading
                                        ? Padding(
                                            padding:
                                                const EdgeInsets.only(
                                              bottom: 30,
                                            ),
                                            child: Image.asset(
                                              Images.newPickMarker,
                                              height: 50,
                                              width: 50,
                                            ),
                                          )
                                        : const CircularProgressIndicator(),
                                  ),
                                  Positioned(
                                    bottom: 25,
                                    right: Dimensions.paddingSizeSmall,
                                    child: FloatingActionButton(
                                      mini: true,
                                      backgroundColor:
                                          Theme.of(context).cardColor,
                                      onPressed: () =>
                                          locationController
                                              .checkPermission(() {
                                        _moveToCurrentLocation(
                                          locationController,
                                        );
                                      }),
                                      child: Icon(
                                        Icons.my_location,
                                        color:
                                            Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 80,
                                    right: Dimensions.paddingSizeSmall,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            Theme.of(context).cardColor,
                                        borderRadius:
                                            BorderRadius.circular(
                                          Dimensions.radiusSmall,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 5,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          IconButton(
                                            onPressed: _zoomIn,
                                            icon: const Icon(Icons.add),
                                          ),
                                          const SizedBox(
                                            height: Dimensions
                                                .paddingSizeExtraSmall,
                                          ),
                                          IconButton(
                                            onPressed: _zoomOut,
                                            icon:
                                                const Icon(Icons.remove),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: Dimensions.paddingSizeDefault,
                            ),
                            CustomButtonWidget(
                              isBold: false,
                              fontSize: Dimensions.fontSizeSmall,
                              width: 300,
                              height: 40,
                              radius: Dimensions.radiusSmall,
                              buttonText: locationController.inZone
                                  ? widget.fromAddAddress
                                      ? 'pick_address'.tr
                                      : 'pick_location'.tr
                                  : 'service_not_available_in_this_area'
                                      .tr,
                              isLoading:
                                  locationController.isLoading,
                              onPressed: locationController.isLoading
                                  ? () {}
                                  : (locationController.buttonDisabled ||
                                          locationController.loading)
                                      ? null
                                      : () {
                                          _onPickAddressButtonPressed(
                                            locationController,
                                          );
                                        },
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      _buildMap(locationController),
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
                        child: SearchLocationWidget(
                          pickedAddress:
                              locationController.pickAddress,
                          isEnabled: null,
                        ),
                      ),
                      Positioned(
                        bottom: 80,
                        right: Dimensions.paddingSizeLarge,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor:
                              Theme.of(context).cardColor,
                          onPressed: () =>
                              locationController.checkPermission(() {
                            _moveToCurrentLocation(
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
                        left: Dimensions.paddingSizeLarge,
                        right: Dimensions.paddingSizeLarge,
                        child: CustomButtonWidget(
                          buttonText: locationController.inZone
                              ? widget.fromAddAddress
                                  ? 'pick_address'.tr
                                  : 'pick_location'.tr
                              : 'service_not_available_in_this_area'
                                  .tr,
                          isLoading: locationController.isLoading,
                          onPressed: locationController.isLoading
                              ? () {}
                              : (locationController.buttonDisabled ||
                                      locationController.loading)
                                  ? null
                                  : () {
                                      _onPickAddressButtonPressed(
                                        locationController,
                                      );
                                    },
                        ),
                      ),
                    ],
                  );
          },
        ),
      ),
    );
  }

  void _onPickAddressButtonPressed(
    LocationController locationController,
  ) {
    if (locationController.pickPosition.latitude != 0 &&
        locationController.pickAddress != null &&
        locationController.pickAddress!.isNotEmpty) {
      if (widget.onPicked != null) {
        AddressModel address = AddressModel(
          latitude:
              locationController.pickPosition.latitude.toString(),
          longitude:
              locationController.pickPosition.longitude.toString(),
          addressType: 'others',
          address: locationController.pickAddress,
          contactPersonName: AddressHelper.getAddressFromSharedPref()
              ?.contactPersonName,
          contactPersonNumber: AddressHelper.getAddressFromSharedPref()
              ?.contactPersonNumber,
        );

        widget.onPicked!(address);
        Get.back();
      } else if (widget.fromAddAddress) {
        locationController.addAddressData();

        Get.back(
          result: ll.LatLng(
            locationController.pickPosition.latitude,
            locationController.pickPosition.longitude,
          ),
        );
      } else {
        AddressModel address = AddressModel(
          latitude:
              locationController.pickPosition.latitude.toString(),
          longitude:
              locationController.pickPosition.longitude.toString(),
          addressType: 'others',
          address: locationController.pickAddress,
        );

        if (!Get.find<AuthController>().isGuestLoggedIn() ||
            !Get.find<AuthController>().isLoggedIn()) {
          Get.find<AuthController>().guestLogin().then((response) {
            if (response.isSuccess) {
              Get.find<ProfileController>().setForceFullyUserEmpty();

              locationController.saveAddressAndNavigate(
                address,
                widget.fromSignUp,
                widget.route,
                widget.canRoute,
                ResponsiveHelper.isDesktop(Get.context),
              );
            }
          });
        } else {
          locationController.saveAddressAndNavigate(
            address,
            widget.fromSignUp,
            widget.route,
            widget.canRoute,
            ResponsiveHelper.isDesktop(context),
          );
        }
      }
    } else {
      showCustomSnackBar('pick_an_address'.tr);
    }
  }
}


