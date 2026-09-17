import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre/maplibre.dart' hide Position;

import 'package:toto_user/common/widgets/custom_app_bar_widget.dart';
import 'package:toto_user/common/widgets/custom_asset_image_widget.dart';
import 'package:toto_user/common/widgets/custom_button_widget.dart';
import 'package:toto_user/common/widgets/custom_dropdown_widget.dart';
import 'package:toto_user/common/widgets/custom_snackbar_widget.dart';
import 'package:toto_user/common/widgets/custom_text_field_widget.dart';
import 'package:toto_user/common/widgets/validate_check.dart';
import 'package:toto_user/features/auth/controllers/restaurant_registration_controller.dart';
import 'package:toto_user/features/auth/domain/models/zone_model.dart';
import 'package:toto_user/features/auth/widgets/zone_selection_widget.dart';
import 'package:toto_user/features/location/controllers/location_controller.dart';
import 'package:toto_user/features/location/widgets/location_search_dialog.dart';
import 'package:toto_user/features/location/widgets/permission_dialog.dart';
import 'package:toto_user/features/splash/controllers/splash_controller.dart';
import 'package:toto_user/helper/responsive_helper.dart';
import 'package:toto_user/util/dimensions.dart';
import 'package:toto_user/util/images.dart';
import 'package:toto_user/util/styles.dart';

class SelectLocationViewWidget extends StatefulWidget {
  final bool fromView;
  final MapController? mapController;
  final bool zoneCuisinesView;
  final TextEditingController? addressController;
  final FocusNode? addressFocus;
  final bool inDialog;

  const SelectLocationViewWidget({
    super.key,
    required this.fromView,
    this.mapController,
    this.zoneCuisinesView = false,
    this.addressController,
    this.addressFocus,
    this.inDialog = false,
  });

  @override
  State<SelectLocationViewWidget> createState() =>
      _SelectLocationViewWidgetState();
}

class _SelectLocationViewWidgetState
    extends State<SelectLocationViewWidget> {
  static const String _openFreeMapStyle =
      'https://tiles.openfreemap.org/styles/liberty';

  MapController? _mapController;

  late ll.LatLng _cameraTarget;
  double _currentZoom = 16;

  List<ll.LatLng> _zonePoints = <ll.LatLng>[];

  @override
  void initState() {
    super.initState();

    _cameraTarget = ll.LatLng(
      double.tryParse(
            Get.find<SplashController>()
                    .configModel
                    ?.defaultLocation
                    ?.lat ??
                '0',
          ) ??
          0,
      double.tryParse(
            Get.find<SplashController>()
                    .configModel
                    ?.defaultLocation
                    ?.lng ??
                '0',
          ) ??
          0,
    );
  }

  Geographic _toGeographic(ll.LatLng point) {
    return Geographic(
      lon: point.longitude,
      lat: point.latitude,
    );
  }

  ll.LatLng _fromGeographic(Geographic point) {
    return ll.LatLng(
      point.lat.toDouble(),
      point.lon.toDouble(),
    );
  }

  List<DropdownItem<int>> _generateDropDownZoneList(
    List<ZoneModel>? zoneList,
    List<int>? zoneIds,
  ) {
    List<DropdownItem<int>> dropDownZoneList = [];

    if (zoneList != null && zoneIds != null) {
      for (int index = 0; index < zoneList.length; index++) {
        dropDownZoneList.add(
          DropdownItem<int>(
            value: index,
            child: SizedBox(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('${zoneList[index].name}'.tr),
              ),
            ),
          ),
        );
      }
    }

    return dropDownZoneList;
  }

  List<Feature<LineString>> _zoneFeatures() {
    if (_zonePoints.length < 2) {
      return <Feature<LineString>>[];
    }

    final List<ll.LatLng> closedPoints =
        List<ll.LatLng>.from(_zonePoints);

    if (closedPoints.first.latitude != closedPoints.last.latitude ||
        closedPoints.first.longitude != closedPoints.last.longitude) {
      closedPoints.add(closedPoints.first);
    }

    return <Feature<LineString>>[
      Feature<LineString>(
        geometry: LineString(
          PositionSeries.from(
            closedPoints.map(_toGeographic).toList(),
          ),
        ),
      ),
    ];
  }

  List<Layer> _buildLayers() {
    if (_zonePoints.length < 2) {
      return <Layer>[];
    }

    return <Layer>[
      PolylineLayer(
        polylines: _zoneFeatures(),
        color: Get.theme.colorScheme.primary,
        width: 3,
      ),
    ];
  }

  Future<void> _moveCamera(
    ll.LatLng target, {
    double? zoom,
    MapController? controller,
  }) async {
    final MapController? mapController = controller ?? _mapController;

    if (mapController == null) {
      return;
    }

    final double targetZoom = zoom ?? _currentZoom;

    await mapController.animateCamera(
      center: _toGeographic(target),
      zoom: targetZoom,
    );

    _cameraTarget = target;
    _currentZoom = targetZoom;
  }

  Future<void> _syncParentMap() async {
    final MapController? parentController = widget.mapController;

    if (parentController == null) {
      return;
    }

    await parentController.animateCamera(
      center: _toGeographic(_cameraTarget),
      zoom: _currentZoom,
    );
  }

  Future<void> _handleCameraIdle(
    RestaurantRegistrationController restaurantRegController,
  ) async {
    final camera = _mapController?.camera;

    if (camera == null) {
      return;
    }

    _cameraTarget = _fromGeographic(camera.center);
    _currentZoom = camera.zoom;

    restaurantRegController.setLocation(
      _cameraTarget,
      forRestaurantRegistration: true,
      zoneId: restaurantRegController
          .zoneList![restaurantRegController.selectedZoneIndex!].id,
    );

    if (!widget.fromView) {
      await _syncParentMap();
    }
  }

  Future<void> _goToCurrentLocation(
    RestaurantRegistrationController restaurantRegController,
  ) async {
    final address =
        await Get.find<LocationController>().getCurrentLocation(false);

    final double? lat = double.tryParse(address.latitude ?? '');
    final double? lng = double.tryParse(address.longitude ?? '');

    if (lat == null || lng == null) {
      return;
    }

    final ll.LatLng target = ll.LatLng(lat, lng);

    await _moveCamera(
      target,
      zoom: 16,
    );

    restaurantRegController.setLocation(
      target,
      forRestaurantRegistration: true,
      zoneId: restaurantRegController
          .zoneList![restaurantRegController.selectedZoneIndex!].id,
    );

    if (!widget.fromView) {
      await _syncParentMap();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);

    return GetBuilder<RestaurantRegistrationController>(
      builder: (restaurantRegController) {
        List<DropdownItem<int>> zoneList =
            _generateDropDownZoneList(
          restaurantRegController.zoneList,
          restaurantRegController.zoneIds,
        );

        return Container(
          decoration: widget.fromView && !isDesktop
              ? BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusDefault),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 1),
                    ),
                  ],
                )
              : null,
          height: widget.fromView ? null : context.height,
          padding: widget.fromView && !isDesktop
              ? const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeSmall,
                  vertical: Dimensions.paddingSizeDefault,
                )
              : EdgeInsets.zero,
          child: Center(
            child: SizedBox(
              width: Dimensions.webMaxWidth,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    widget.fromView
                        ? ZoneSelectionWidget(
                            restaurantRegController:
                                restaurantRegController,
                            zoneList: zoneList,
                            callBack: () {
                              _setPolygon(
                                restaurantRegController.zoneList![
                                    restaurantRegController
                                        .selectedZoneIndex!],
                              );
                            },
                          )
                        : const SizedBox(),

                    widget.fromView
                        ? const SizedBox(
                            height:
                                Dimensions.paddingSizeExtraLarge,
                          )
                        : const SizedBox(),

                    mapView(restaurantRegController),

                    !restaurantRegController.inZone
                        ? Padding(
                            padding:
                                const EdgeInsets.only(top: 5.0),
                            child: Row(
                              children: [
                                Text(
                                  '* ',
                                  style: robotoBold.copyWith(
                                    color: Colors.red,
                                  ),
                                ),
                                Text(
                                  'please_place_the_marker_inside_the_zone'
                                      .tr,
                                  style: robotoRegular.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .error,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(),

                    !isDesktop
                        ? SizedBox(
                            height: !widget.fromView
                                ? Dimensions.paddingSizeSmall
                                : 0,
                          )
                        : const SizedBox(),

                    SizedBox(
                      height: widget.fromView
                          ? Dimensions.paddingSizeOverLarge
                          : 0,
                    ),

                    widget.fromView && !isDesktop
                        ? CustomTextFieldWidget(
                            titleText:
                                'write_restaurant_address'.tr,
                            controller:
                                widget.addressController,
                            focusNode: widget.addressFocus,
                            inputAction: TextInputAction.done,
                            inputType: TextInputType.text,
                            capitalization:
                                TextCapitalization.sentences,
                            maxLines: 3,
                            showTitle: isDesktop,
                            required: true,
                            labelText: 'restaurant_address'.tr,
                            validator: (value) =>
                                ValidateCheck.validateEmptyText(
                              value,
                              'restaurant_address_field_is_required'
                                  .tr,
                            ),
                          )
                        : const SizedBox(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget mapView(
    RestaurantRegistrationController restaurantRegController,
  ) {
    final zoneList = restaurantRegController.zoneList;

    if (zoneList == null || zoneList.isEmpty) {
      return const SizedBox();
    }

    return Container(
      height: ResponsiveHelper.isDesktop(context)
          ? widget.fromView
              ? 180
              : MediaQuery.of(context).size.height * 0.8
          : widget.fromView
              ? 150
              : (context.height * 0.87),
      width: MediaQuery.of(context).size.width,
      decoration: widget.fromView
          ? BoxDecoration(
              borderRadius:
                  BorderRadius.circular(Dimensions.radiusSmall),
              border: Border.all(
                width: 1,
                color: Theme.of(context).primaryColor,
              ),
            )
          : null,
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(Dimensions.radiusSmall),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            MapLibreMap(
              options: MapOptions(
                initStyle: _openFreeMapStyle,
                initCenter: _toGeographic(_cameraTarget),
                initZoom: _currentZoom,
                minZoom: 0,
                maxZoom: 16,
              ),
              layers: _buildLayers(),
              onMapCreated: (MapController controller) {
                _mapController = controller;

                _setPolygon(
                  restaurantRegController.zoneList![
                      restaurantRegController
                          .selectedZoneIndex!],
                );
              },
              onEvent: (event) {
                if (event is MapEventCameraIdle) {
                  _handleCameraIdle(
                    restaurantRegController,
                  );
                }
              },
            ),

            const Center(
              child: CustomAssetImageWidget(
                Images.picRestaurantMarker,
                height: 50,
                width: 50,
              ),
            ),

            Positioned(
              top: widget.fromView ? 10 : 20,
              left: widget.fromView ? 10 : 20,
              right: widget.fromView ? null : 20,
              child: LocationSearchDialog(
                pickedLocation:
                    restaurantRegController.restaurantAddress.toString(),
                callBack: (Position? position) {
                  if (position == null) {
                    return;
                  }

                  final ll.LatLng target = ll.LatLng(
                    position.latitude,
                    position.longitude,
                  );

                  _moveCamera(
                    target,
                    zoom: 16,
                  );

                  restaurantRegController.setLocation(
                    target,
                    forRestaurantRegistration: true,
                    zoneId: restaurantRegController
                        .zoneList![restaurantRegController
                            .selectedZoneIndex!]
                        .id,
                  );

                  if (!widget.fromView) {
                    _syncParentMap();
                  }
                },
                child: Container(
                  height: widget.fromView ? 30 : 40,
                  width: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      widget.fromView
                          ? Dimensions.radiusSmall
                          : 50,
                    ),
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: 0.05),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.only(left: 10),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    (GetPlatform.isWeb && !widget.fromView)
                        ? restaurantRegController.restaurantAddress
                            .toString()
                        : 'search'.tr,
                    style: robotoRegular.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ),
            ),

            widget.inDialog
                ? Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.clear),
                    ),
                  )
                : const SizedBox(),

            widget.fromView
                ? Positioned(
                    bottom: 50,
                    right: 0,
                    child: InkWell(
                      onTap: () {
                        if (ResponsiveHelper.isDesktop(context)) {
                          showGeneralDialog(
                            context: context,
                            pageBuilder: (_, __, ___) {
                              return SelectLocationViewWidget(
                                fromView: false,
                                mapController: _mapController,
                                inDialog: true,
                              );
                            },
                          );
                        } else {
                          Get.to(
                            Scaffold(
                              appBar: CustomAppBarWidget(
                                title:
                                    'set_your_store_location'.tr,
                              ),
                              body: SelectLocationViewWidget(
                                fromView: false,
                                mapController: _mapController,
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(
                          Dimensions.paddingSizeExtraSmall,
                        ),
                        margin: const EdgeInsets.only(
                          right: Dimensions.paddingSizeDefault,
                        ),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(50),
                          color: Colors.white,
                        ),
                        child: Icon(
                          Icons.fullscreen,
                          color:
                              Theme.of(context).primaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(),

            Positioned(
              bottom: widget.fromView ? 10 : 210,
              right: 0,
              child: InkWell(
                onTap: () => _checkPermission(
                  () => _goToCurrentLocation(
                    restaurantRegController,
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.all(
                    widget.fromView
                        ? Dimensions.paddingSizeExtraSmall
                        : Dimensions.paddingSizeSmall,
                  ),
                  margin: const EdgeInsets.only(
                    right: Dimensions.paddingSizeDefault,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: Colors.white,
                  ),
                  child: Icon(
                    Icons.my_location_outlined,
                    color: Theme.of(context).primaryColor,
                    size: widget.fromView ? 20 : 25,
                  ),
                ),
              ),
            ),

            !widget.fromView
                ? Positioned(
                    bottom: 100,
                    right: 0,
                    child: Container(
                      margin: const EdgeInsets.only(
                        right: Dimensions.paddingSizeDefault,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusDefault,
                        ),
                        color: Theme.of(context).cardColor,
                      ),
                      padding: const EdgeInsets.all(
                        Dimensions.paddingSizeSmall,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () async {
                              final camera =
                                  _mapController?.camera;

                              if (camera == null) {
                                return;
                              }

                              _cameraTarget =
                                  _fromGeographic(camera.center);

                              final double zoom =
                                  (camera.zoom + 1)
                                      .clamp(0, 16)
                                      .toDouble();

                              await _moveCamera(
                                _cameraTarget,
                                zoom: zoom,
                              );
                            },
                            child: const Icon(
                              Icons.add,
                              size: 25,
                            ),
                          ),
                          const Divider(),
                          InkWell(
                            onTap: () async {
                              final camera =
                                  _mapController?.camera;

                              if (camera == null) {
                                return;
                              }

                              _cameraTarget =
                                  _fromGeographic(camera.center);

                              final double zoom =
                                  (camera.zoom - 1)
                                      .clamp(0, 16)
                                      .toDouble();

                              await _moveCamera(
                                _cameraTarget,
                                zoom: zoom,
                              );
                            },
                            child: const Icon(
                              Icons.remove,
                              size: 25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(),

            !widget.fromView
                ? Positioned(
                    left: 20,
                    right: 20,
                    bottom:
                        ResponsiveHelper.isDesktop(context)
                            ? 40
                            : 20,
                    child: CustomButtonWidget(
                      buttonText:
                          restaurantRegController.inZone
                              ? 'set_location'.tr
                              : 'not_in_zone'.tr,
                      onPressed:
                          restaurantRegController.inZone
                              ? () async {
                                  try {
                                    await _syncParentMap();
                                    Get.back();
                                  } catch (e) {
                                    showCustomSnackBar(
                                      'please_setup_the_marker_in_your_required_location'
                                          .tr,
                                    );
                                  }
                                }
                              : null,
                    ),
                  )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }

  void _setPolygon(ZoneModel zoneModel) {
    final List<ll.LatLng> zoneLatLongList =
        <ll.LatLng>[];

    zoneModel.formatedCoordinates?.forEach((coordinate) {
      if (coordinate.lat != null && coordinate.lng != null) {
        zoneLatLongList.add(
          ll.LatLng(
            coordinate.lat!,
            coordinate.lng!,
          ),
        );
      }
    });

    _zonePoints = zoneLatLongList;

    if (mounted) {
      setState(() {});
    }

    if (_zonePoints.isNotEmpty) {
      Future.delayed(
        const Duration(milliseconds: 500),
        () {
          if (!mounted) {
            return;
          }

          _moveToZone(_zonePoints);
        },
      );
    }
  }

  Future<void> _moveToZone(
    List<ll.LatLng> points,
  ) async {
    if (points.isEmpty || _mapController == null) {
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final ll.LatLng point in points) {
      if (point.latitude < minLat) {
        minLat = point.latitude;
      }
      if (point.latitude > maxLat) {
        maxLat = point.latitude;
      }
      if (point.longitude < minLng) {
        minLng = point.longitude;
      }
      if (point.longitude > maxLng) {
        maxLng = point.longitude;
      }
    }

    final ll.LatLng center = ll.LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    final double latSpan = maxLat - minLat;
    final double lngSpan = maxLng - minLng;
    final double span =
        latSpan > lngSpan ? latSpan : lngSpan;

    double zoom;

    if (span < 0.005) {
      zoom = 16;
    } else if (span < 0.01) {
      zoom = 15;
    } else if (span < 0.02) {
      zoom = 14;
    } else if (span < 0.05) {
      zoom = 13;
    } else if (span < 0.1) {
      zoom = 12;
    } else if (span < 0.2) {
      zoom = 11;
    } else if (span < 0.5) {
      zoom = 10;
    } else {
      zoom = 9;
    }

    await _moveCamera(
      center,
      zoom: zoom,
    );
  }

  void _checkPermission(Function onTap) async {
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
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

