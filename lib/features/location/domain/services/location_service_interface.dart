import 'package:toto_user/features/address/domain/models/address_model.dart';
import 'package:toto_user/features/location/domain/models/prediction_model.dart';
import 'package:toto_user/features/location/domain/models/zone_response_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

abstract class LocationServiceInterface {
  Future<Position> getPosition(LatLng? defaultLatLng, LatLng configLatLng);
  Future<ZoneResponseModel> getZone(String? lat, String? lng);
  void handleTopicSubscription(AddressModel? savedAddress, AddressModel? address);
  Future<LatLng> getLatLng(String id);
  Future<String> getAddressFromGeocode(LatLng latLng);
  Future<List<PredictionModel>> searchLocation(String text);
  void checkLocationPermission(Function onTap);
  void handleRoute(bool fromSignUp, String? route, bool canRoute);
  Future<void> updateZone();
}
