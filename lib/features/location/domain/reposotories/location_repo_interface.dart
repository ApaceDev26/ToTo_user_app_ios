import 'package:toto_user/features/location/domain/models/zone_response_model.dart';
import 'package:toto_user/interface/repository_interface.dart';
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:latlong2/latlong.dart';

abstract class LocationRepoInterface extends RepositoryInterface {
  Future<ZoneResponseModel> getZone(String? lat, String? lng);
  Future<String> getAddressFromGeocode(LatLng latLng);
  Future<Response> searchLocation(String text);
  Future<Response> updateZone();
}
