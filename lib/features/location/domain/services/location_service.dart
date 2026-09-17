import 'package:toto_user/features/location/domain/models/prediction_model.dart';
import 'package:toto_user/features/location/domain/models/zone_response_model.dart';
import 'package:toto_user/features/address/domain/models/address_model.dart';
import 'package:toto_user/features/location/domain/reposotories/location_repo_interface.dart';
import 'package:toto_user/features/location/domain/services/location_service_interface.dart';
import 'package:toto_user/features/location/widgets/permission_dialog.dart';
import 'package:toto_user/features/splash/controllers/splash_controller.dart';
import 'package:toto_user/helper/route_helper.dart';
import 'package:toto_user/common/widgets/custom_snackbar_widget.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:toto_user/util/app_constants.dart';

class LocationService implements LocationServiceInterface {
  final LocationRepoInterface locationRepoInterface;
  LocationService({required this.locationRepoInterface});

  @override
  Future<Position> getPosition(
      LatLng? defaultLatLng, LatLng configLatLng) async {
    Position myPosition;
    try {
      await Geolocator.requestPermission();
      Position newLocalData = await Geolocator.getCurrentPosition();
      myPosition = newLocalData;
    } catch (e) {
      myPosition = Position(
        latitude: defaultLatLng != null
            ? defaultLatLng.latitude
            : configLatLng.latitude,
        longitude: defaultLatLng != null
            ? defaultLatLng.longitude
            : configLatLng.longitude,
        timestamp: DateTime.now(),
        accuracy: 1,
        altitude: 1,
        heading: 1,
        speed: 1,
        speedAccuracy: 1,
        altitudeAccuracy: 1,
        headingAccuracy: 1,
      );
    }
    return myPosition;
  }

  @override
  Future<ZoneResponseModel> getZone(String? lat, String? lng) async {
    return await locationRepoInterface.getZone(lat, lng);
  }

  @override
  void handleTopicSubscription(
      AddressModel? savedAddress, AddressModel? address) {
    if (!GetPlatform.isWeb) {
      if (Get.find<SplashController>().configModel!.demo!) {
        FirebaseMessaging.instance
            .subscribeToTopic(AppConstants.demoResetTopic);
      } else {
        FirebaseMessaging.instance
            .unsubscribeFromTopic(AppConstants.demoResetTopic);
      }
      if (savedAddress != null) {
        if (savedAddress.zoneIds != null) {
          for (int zoneID in savedAddress.zoneIds!) {
            FirebaseMessaging.instance
                .unsubscribeFromTopic('zone_${zoneID}_customer');
          }
        } else {
          FirebaseMessaging.instance
              .unsubscribeFromTopic('zone_${savedAddress.zoneId}_customer');
        }
      } else {
        FirebaseMessaging.instance
            .subscribeToTopic('zone_${address!.zoneId}_customer');
      }
      if (address!.zoneIds != null) {
        for (int zoneID in address.zoneIds!) {
          FirebaseMessaging.instance
              .subscribeToTopic('zone_${zoneID}_customer');
        }
      } else {
        FirebaseMessaging.instance
            .subscribeToTopic('zone_${address.zoneId}_customer');
      }
    }
  }

  @override
  Future<LatLng> getLatLng(String id) async {
    LatLng latLng = const LatLng(0, 0);
    Response? response = await locationRepoInterface.get(id);
    if (response?.statusCode == 200) {
      /*PlaceDetailsModel placeDetails = PlaceDetailsModel.fromJson(response?.body);
      if(placeDetails.status == 'OK') {
        latLng = LatLng(placeDetails.result!.geometry!.location!.lat!, placeDetails.result!.geometry!.location!.lng!);
      }*/
      final data = response?.body;
      final location = data['location'];
      final double lat = location['latitude'];
      final double lng = location['longitude'];
      latLng = LatLng(lat, lng);
    }
    return latLng;
  }

  @override
  Future<String> getAddressFromGeocode(LatLng latLng) async {
    return await locationRepoInterface.getAddressFromGeocode(latLng);
  }

  @override
  Future<List<PredictionModel>> searchLocation(String text) async {
    List<PredictionModel> predictionList = [];
    Response response = await locationRepoInterface.searchLocation(text);
    if (response.statusCode == 200 &&
        response.body != null /*&& response.body['status'] == 'OK'*/) {
      predictionList = [];
      response.body['suggestions'].forEach((prediction) =>
          predictionList.add(PredictionModel.fromJson(prediction)));
    } else {
      String errorMessage = response.statusText ?? 'Unknown error occurred';
      if (response.body != null &&
          response.body is Map &&
          response.body.containsKey('error_message')) {
        errorMessage = response.body['error_message'];
      } else if (response.bodyString != null &&
          response.bodyString!.isNotEmpty) {
        errorMessage = response.bodyString!;
      }
      showCustomSnackBar(errorMessage);
    }
    return predictionList;
  }

  @override
  void checkLocationPermission(Function onTap) async {
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

  @override
  void handleRoute(bool fromSignUp, String? route, bool canRoute) {
    if (fromSignUp) {
      Get.offAllNamed(RouteHelper.getInterestRoute());
    } else {
      if (route != null && canRoute) {
        Get.offAllNamed(route);
      } else {
        Get.offAllNamed(RouteHelper.getInitialRoute());
      }
    }
  }

  @override
  Future<void> updateZone() async {
    await locationRepoInterface.updateZone();
  }
}

