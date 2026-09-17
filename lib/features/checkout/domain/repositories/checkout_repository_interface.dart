import 'package:toto_user/features/checkout/domain/models/offline_method_model.dart';
import 'package:toto_user/features/checkout/domain/models/place_order_body_model.dart';
import 'package:toto_user/interface/repository_interface.dart';
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:latlong2/latlong.dart';

abstract class CheckoutRepositoryInterface extends RepositoryInterface {
  Future<int?> getDmTipMostTapped();
  Future<List<OfflineMethodModel>> getOfflineMethodList();
  Future<double> getExtraCharge(double? distance);
  Future<bool> saveOfflineInfo(String data);
  Future<Response> placeOrder(PlaceOrderBodyModel orderBody);
  Future<Response> sendNotificationRequest(String orderId, String? guestId);
  Future<Response> getDistanceInMeter(LatLng originLatLng, LatLng destinationLatLng);
  Future<bool> updateOfflineInfo(String data);
  Future<bool> checkRestaurantValidation({required Map<String, dynamic> data});
  Future<Response> getOrderTax(PlaceOrderBodyModel placeOrderBody);
  Future<bool> saveDmTipIndex(String index);
  String getDmTipIndex();
}
