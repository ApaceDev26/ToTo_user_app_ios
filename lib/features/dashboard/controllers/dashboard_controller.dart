import 'dart:convert';
import 'package:toto_user/features/address/domain/models/address_model.dart';
import 'package:toto_user/features/checkout/controllers/checkout_controller.dart';
import 'package:toto_user/features/dashboard/domain/services/dashboard_service_interface.dart';
import 'package:toto_user/features/location/controllers/location_controller.dart';
import 'package:toto_user/helper/address_helper.dart';
import 'package:toto_user/util/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardController extends GetxController implements GetxService {
  final DashboardServiceInterface dashboardServiceInterface;
  final SharedPreferences sharedPreferences;
  DashboardController({
    required this.dashboardServiceInterface,
    required this.sharedPreferences,
  });

  bool _showLocationSuggestion = true;
  bool get showLocationSuggestion => _showLocationSuggestion;

  void hideSuggestedLocation() {
    _showLocationSuggestion = !_showLocationSuggestion;
  }

  Future<bool> checkLocationActive() async {
    bool isActiveLocation = await Geolocator.isLocationServiceEnabled();
    if (isActiveLocation) {
      AddressModel currentAddress =
          await Get.find<LocationController>().getCurrentLocation(true);
      AddressModel? selectedAddress = AddressHelper.getAddressFromSharedPref();

      double? distance = await Get.find<CheckoutController>().getDistanceInKM(
        LatLng(double.parse(currentAddress.latitude!),
            double.parse(currentAddress.longitude!)),
        LatLng(double.parse(selectedAddress!.latitude!),
            double.parse(selectedAddress.longitude!)),
        fromDashboard: true,
      );
      if (kDebugMode) {
        print('======== distance is : $distance');
      }
      return dashboardServiceInterface.checkDistanceForAddressPopup(distance);
    } else {
      return false;
    }
  }

  Future<bool> saveRegistrationSuccessfulSharedPref(bool status) async {
    return await dashboardServiceInterface.saveRegistrationSuccessful(status);
  }

  Future<bool> saveIsRestaurantRegistrationSharedPref(bool status) async {
    return await dashboardServiceInterface.saveIsRestaurantRegistration(status);
  }

  bool getRegistrationSuccessfulSharedPref() {
    return dashboardServiceInterface.getRegistrationSuccessful();
  }

  bool getIsRestaurantRegistrationSharedPref() {
    return dashboardServiceInterface.getIsRestaurantRegistration();
  }

  // Methods to track dismissed delivery popup orders
  List<int> getDismissedDeliveryPopupOrders() {
    List<String>? list = [];
    if (sharedPreferences
        .containsKey(AppConstants.dismissedDeliveryPopupOrders)) {
      list = sharedPreferences
          .getStringList(AppConstants.dismissedDeliveryPopupOrders);
    }
    List<int> dismissedOrderIds = [];
    for (var id in list!) {
      dismissedOrderIds.add(jsonDecode(id));
    }
    return dismissedOrderIds;
  }

  Future<void> addDismissedDeliveryPopupOrder(int orderId) async {
    List<int> dismissedOrders = getDismissedDeliveryPopupOrders();
    if (!dismissedOrders.contains(orderId)) {
      dismissedOrders.add(orderId);
      List<String> list = [];
      for (int id in dismissedOrders) {
        list.add(jsonEncode(id));
      }
      await sharedPreferences.setStringList(
          AppConstants.dismissedDeliveryPopupOrders, list);
    }
  }

  bool isOrderDismissed(int orderId) {
    return getDismissedDeliveryPopupOrders().contains(orderId);
  }

  // Methods to track dismissed refund popup orders
  List<int> getDismissedRefundPopupOrders() {
    List<String>? list = [];
    if (sharedPreferences
        .containsKey(AppConstants.dismissedRefundPopupOrders)) {
      list = sharedPreferences
          .getStringList(AppConstants.dismissedRefundPopupOrders);
    }
    List<int> dismissedOrderIds = [];
    for (var id in list!) {
      dismissedOrderIds.add(jsonDecode(id));
    }
    return dismissedOrderIds;
  }

  Future<void> addDismissedRefundPopupOrder(int orderId) async {
    List<int> dismissedOrders = getDismissedRefundPopupOrders();
    if (!dismissedOrders.contains(orderId)) {
      dismissedOrders.add(orderId);
      List<String> list = [];
      for (int id in dismissedOrders) {
        list.add(jsonEncode(id));
      }
      await sharedPreferences.setStringList(
          AppConstants.dismissedRefundPopupOrders, list);
    }
  }

  bool isRefundOrderDismissed(int orderId) {
    return getDismissedRefundPopupOrders().contains(orderId);
  }
}

