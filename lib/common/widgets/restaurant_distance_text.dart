import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:toto_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:toto_user/helper/address_helper.dart';

/// Road-distance label (DRIVE) with cache + rebuild via [RestaurantController].
class RestaurantDistanceText extends StatefulWidget {
  final String latitude;
  final String longitude;
  final TextStyle? style;
  final int fractionDigits;
  final double maxKm;
  final String? suffix;

  const RestaurantDistanceText({
    super.key,
    required this.latitude,
    required this.longitude,
    this.style,
    this.fractionDigits = 1,
    this.maxKm = 100,
    this.suffix,
  });

  @override
  State<RestaurantDistanceText> createState() =>
      _RestaurantDistanceTextState();
}

class _RestaurantDistanceTextState extends State<RestaurantDistanceText> {
  LatLng? _restaurantLatLng;
  String? _loadedUserLocationKey;
  bool _loading = false;

  String _currentUserLocationKey() {
    final address = AddressHelper.getAddressFromSharedPref();

    return '${address?.latitude ?? ''}_${address?.longitude ?? ''}';
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDistance();
    });
  }

  @override
  void didUpdateWidget(covariant RestaurantDistanceText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _loading = false;
      _restaurantLatLng = null;
      _loadedUserLocationKey = null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadDistance();
        }
      });
    }
  }

  Future<void> _loadDistance() async {
    if (_loading) return;

    final latitude = double.tryParse(widget.latitude);
    final longitude = double.tryParse(widget.longitude);

    if (latitude == null || longitude == null) {
      return;
    }

    final userLocationKey = _currentUserLocationKey();

    debugPrint('DISTANCE LOAD START -> RESTAURANT: $latitude, $longitude USER_KEY: $userLocationKey');
    final latLng = LatLng(latitude, longitude);

    _restaurantLatLng = latLng;
    _loadedUserLocationKey = userLocationKey;
    _loading = true;

    try {
      final controller = Get.find<RestaurantController>();

      await controller.loadRoadDistance(
        latLng,
        notify: true,
      );
    } finally {
      _loading = false;
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserLocationKey = _currentUserLocationKey();

    if (_loadedUserLocationKey != currentUserLocationKey && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadDistance();
        }
      });
    }

    return GetBuilder<RestaurantController>(
      builder: (controller) {
        final latLng = _restaurantLatLng;

        if (latLng == null) {
          return Text(
            '-- ${'km'.tr}',
            style: widget.style,
          );
        }

        final label = controller.formatRestaurantDistance(
          latLng,
          fractionDigits: widget.fractionDigits,
          maxKm: widget.maxKm,
        );

        debugPrint(
          'DISTANCE UI -> RESTAURANT: ${latLng.latitude}, ${latLng.longitude}, LABEL: $label',
        );

        return Text(
          widget.suffix == null ? label : '$label${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}



