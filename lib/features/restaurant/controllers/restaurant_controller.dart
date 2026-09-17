import 'package:toto_user/common/enums/data_source_enum.dart';
import 'package:toto_user/common/models/product_model.dart';
import 'package:toto_user/common/widgets/custom_snackbar_widget.dart';
import 'package:toto_user/features/category/controllers/category_controller.dart';
import 'package:toto_user/features/checkout/controllers/checkout_controller.dart';
import 'package:toto_user/features/language/controllers/localization_controller.dart';
import 'package:toto_user/features/restaurant/domain/models/cart_suggested_item_model.dart';
import 'package:toto_user/features/restaurant/domain/models/recommended_product_model.dart';
import 'package:toto_user/common/models/restaurant_model.dart';
import 'package:toto_user/features/category/domain/models/category_model.dart';
import 'package:toto_user/features/restaurant/domain/services/restaurant_service_interface.dart';
import 'package:toto_user/helper/address_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class RestaurantController extends GetxController implements GetxService {
  final RestaurantServiceInterface restaurantServiceInterface;

  RestaurantController({required this.restaurantServiceInterface});

  RestaurantModel? _restaurantModel;
  RestaurantModel? get restaurantModel => _restaurantModel;

  List<Restaurant>? _restaurantList;
  List<Restaurant>? get restaurantList => _restaurantList;

  List<Restaurant>? _popularRestaurantList;
  List<Restaurant>? get popularRestaurantList => _popularRestaurantList;

  List<Restaurant>? _latestRestaurantList;
  List<Restaurant>? get latestRestaurantList => _latestRestaurantList;

  List<Restaurant>? _recentlyViewedRestaurantList;
  List<Restaurant>? get recentlyViewedRestaurantList =>
      _recentlyViewedRestaurantList;

  Restaurant? _restaurant;
  Restaurant? get restaurant => _restaurant;

  List<Product>? _restaurantProducts;
  List<Product>? get restaurantProducts => _restaurantProducts;

  ProductModel? _restaurantProductModel;
  ProductModel? get restaurantProductModel => _restaurantProductModel;

  ProductModel? _restaurantSearchProductModel;
  ProductModel? get restaurantSearchProductModel =>
      _restaurantSearchProductModel;

  int _categoryIndex = 0;
  int get categoryIndex => _categoryIndex;

  List<CategoryModel>? _categoryList;
  List<CategoryModel>? get categoryList => _categoryList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _restaurantType = 'all';
  String get restaurantType => _restaurantType;

  bool _foodPaginate = false;
  bool get foodPaginate => _foodPaginate;

  int? _foodPageSize;
  int? get foodPageSize => _foodPageSize;

  List<int> _foodOffsetList = [];

  int _foodOffset = 1;
  int get foodOffset => _foodOffset;

  String _type = 'all';
  String get type => _type;

  String _searchType = 'all';
  String get searchType => _searchType;

  String _searchText = '';
  String get searchText => _searchText;

  RecommendedProductModel? _recommendedProductModel;
  RecommendedProductModel? get recommendedProductModel =>
      _recommendedProductModel;

  CartSuggestItemModel? _cartSuggestItemModel;
  CartSuggestItemModel? get cartSuggestItemModel => _cartSuggestItemModel;

  List<Product>? _suggestedItems;
  List<Product>? get suggestedItems => _suggestedItems;

  int? _foodPageOffset;
  int? get foodPageOffset => _foodPageOffset;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  List<Restaurant>? _orderAgainRestaurantList;
  List<Restaurant>? get orderAgainRestaurantList => _orderAgainRestaurantList;

  int _topRated = 0;
  int get topRated => _topRated;

  int _discount = 0;
  int get discount => _discount;

  int _veg = 0;
  int get veg => _veg;

  int _nonVeg = 0;
  int get nonVeg => _nonVeg;

  int _nearestRestaurantIndex = -1;
  int get nearestRestaurantIndex => _nearestRestaurantIndex;

  void setNearestRestaurantIndex(int index, {bool notify = true}) {
    _nearestRestaurantIndex = index;
    if (notify) {
      update();
    }
  }

  final Map<String, double> _roadDistanceCache = {};
  final Map<String, DateTime> _roadDistanceCacheTime = {};
  final Map<String, Future<double?>> _roadDistanceRequests = {};

  static const Duration _roadDistanceCacheDuration =
      Duration(minutes: 10);

  String _restaurantDistanceKey(LatLng restaurantLatLng) {
    final address = AddressHelper.getAddressFromSharedPref();

    final userLat = double.tryParse(address?.latitude ?? '');
    final userLng = double.tryParse(address?.longitude ?? '');

    return '${userLat?.toStringAsFixed(5) ?? '0'}_'
        '${userLng?.toStringAsFixed(5) ?? '0'}_'
        '${restaurantLatLng.latitude.toStringAsFixed(5)}_'
        '${restaurantLatLng.longitude.toStringAsFixed(5)}';
  }


  bool hasRoadDistance(LatLng restaurantLatLng) {
    return _roadDistanceCache.containsKey(
      _restaurantDistanceKey(restaurantLatLng),
    );
  }

  double? getCachedRoadDistance(LatLng restaurantLatLng) {
    final key = _restaurantDistanceKey(restaurantLatLng);
    final cachedAt = _roadDistanceCacheTime[key];

    if (cachedAt != null &&
        DateTime.now().difference(cachedAt) <
            _roadDistanceCacheDuration) {
      return _roadDistanceCache[key];
    }

    // Keep the last valid road distance visible even after cache expiry.
    // loadRoadDistance() can still refresh it from the road-distance API.
    return _roadDistanceCache[key];
  }

  Future<double?> loadRoadDistance(
    LatLng restaurantLatLng, {
    bool notify = true,
  }) async {
    final key = _restaurantDistanceKey(restaurantLatLng);

    final cachedAt = _roadDistanceCacheTime[key];
    final cached = _roadDistanceCache[key];

    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _roadDistanceCacheDuration) {
      return cached;
    }

    final existingRequest = _roadDistanceRequests[key];
    if (existingRequest != null) {
      return existingRequest;
    }

    final request = restaurantServiceInterface
        .getRoadDistanceFromUser(restaurantLatLng);

    _roadDistanceRequests[key] = request;

    try {
      final distance = await request;

      if (distance != null && distance > 0) {
        _roadDistanceCache[key] = distance;
        _roadDistanceCacheTime[key] = DateTime.now();

        debugPrint(
          'ROAD CACHE SAVE -> KEY: $key, DISTANCE: $distance',
        );

        if (notify) {
          update();
        }

        return distance;
      }

      // Road route distance only.
      // Do not use straight-line distance as fallback.
      return null;
    } finally {
      _roadDistanceRequests.remove(key);
    }
  }

  double getRestaurantDistance(LatLng restaurantLatLng) {
    final distance = getCachedRoadDistance(restaurantLatLng);
    return distance ?? 0;
  }

  String formatRestaurantDistance(
    LatLng restaurantLatLng, {
    int fractionDigits = 1,
    double maxKm = 100,
  }) {
    final distance = getRestaurantDistance(restaurantLatLng);

    if (distance <= 0) {
      return '-- ${'km'.tr}';
    }

    final value = distance > maxKm
        ? '$maxKm+'
        : distance.toStringAsFixed(fractionDigits);

    return '$value ${'km'.tr}';
  }
  String filteringUrl(String slug) {
    return restaurantServiceInterface.filterRestaurantLinkUrl(
        slug, _restaurant?.id, _restaurant?.zoneId);
  }

  Future<void> getOrderAgainRestaurantList(bool reload,
      {DataSourceEnum dataSource = DataSourceEnum.local}) async {
    if (reload) {
      _orderAgainRestaurantList = null;
      update();
    }
    List<Restaurant>? orderAgainRestaurantList;
    if (dataSource == DataSourceEnum.local) {
      orderAgainRestaurantList = await restaurantServiceInterface
          .getOrderAgainRestaurantList(source: DataSourceEnum.local);
      _prepareOrderAgainRestaurantList(orderAgainRestaurantList);
      getOrderAgainRestaurantList(false, dataSource: DataSourceEnum.client);
    } else {
      orderAgainRestaurantList = await restaurantServiceInterface
          .getOrderAgainRestaurantList(source: DataSourceEnum.client);
      _prepareOrderAgainRestaurantList(orderAgainRestaurantList);
    }
  }

  _prepareOrderAgainRestaurantList(List<Restaurant>? restaurantList) {
    if (restaurantList != null) {
      _orderAgainRestaurantList = [];
      _orderAgainRestaurantList = restaurantList;
    }
    update();
  }

  Future<void> getRecentlyViewedRestaurantList(
      bool reload, String type, bool notify,
      {DataSourceEnum dataSource = DataSourceEnum.local,
      bool fromRecall = false}) async {
    _type = type;
    if (reload && !fromRecall) {
      _recentlyViewedRestaurantList = null;
    }
    if (notify) {
      update();
    }
    List<Restaurant>? recentlyViewedRestaurantList;
    if (_recentlyViewedRestaurantList == null || reload || fromRecall) {
      if (dataSource == DataSourceEnum.local) {
        recentlyViewedRestaurantList = await restaurantServiceInterface
            .getRecentlyViewedRestaurantList(type,
                source: DataSourceEnum.local);
        _prepareRecentlyViewedRestaurantList(recentlyViewedRestaurantList);
        getRecentlyViewedRestaurantList(false, type, false,
            dataSource: DataSourceEnum.client, fromRecall: true);
      } else {
        recentlyViewedRestaurantList = await restaurantServiceInterface
            .getRecentlyViewedRestaurantList(type,
                source: DataSourceEnum.client);
        _prepareRecentlyViewedRestaurantList(recentlyViewedRestaurantList);
      }
    }
  }

  _prepareRecentlyViewedRestaurantList(List<Restaurant>? restaurantList) {
    if (restaurantList != null) {
      _recentlyViewedRestaurantList = [];
      _recentlyViewedRestaurantList = restaurantList;
    }
    update();
  }

  Future<void> getRestaurantRecommendedItemList(
      int? restaurantId, bool reload) async {
    _recommendedProductModel = null;
    if (reload) {
      _restaurantModel = null;
      update();
    }
    _recommendedProductModel = await restaurantServiceInterface
        .getRestaurantRecommendedItemList(restaurantId);
    update();
  }

  Future<void> getRestaurantList(int offset, bool reload,
      {bool fromMap = false,
      DataSourceEnum source = DataSourceEnum.local}) async {
    if (reload) {
      _restaurantModel = null;
      update();
    }

    RestaurantModel? restaurantModel;
    if (source == DataSourceEnum.local && offset == 1) {
      restaurantModel = await restaurantServiceInterface.getRestaurantList(
          offset, _restaurantType, _topRated, _discount, _veg, _nonVeg,
          fromMap: fromMap, source: DataSourceEnum.local);
      _prepareRestaurantList(restaurantModel, offset);
      getRestaurantList(1, false,
          fromMap: fromMap, source: DataSourceEnum.client);
    } else {
      restaurantModel = await restaurantServiceInterface.getRestaurantList(
          offset, _restaurantType, _topRated, _discount, _veg, _nonVeg,
          fromMap: fromMap, source: DataSourceEnum.client);
      _prepareRestaurantList(restaurantModel, offset);
    }
  }

  _prepareRestaurantList(RestaurantModel? restaurantModel, int offset) {
    if (restaurantModel != null) {
      if (offset == 1) {
        _restaurantModel = restaurantModel;
      } else {
        _restaurantModel!.totalSize = restaurantModel.totalSize;
        _restaurantModel!.offset = restaurantModel.offset;
        _restaurantModel!.restaurants!.addAll(restaurantModel.restaurants!);
      }
      update();
    }
  }

  void setRestaurantType(String type) {
    _restaurantType = type;
    getRestaurantList(1, true);
  }

  void setTopRated() {
    _topRated = restaurantServiceInterface.setTopRated(_topRated);
    getRestaurantList(1, true);
  }

  void setDiscount() {
    _discount = restaurantServiceInterface.setDiscounted(_discount);
    getRestaurantList(1, true);
  }

  void setVeg() {
    _veg = restaurantServiceInterface.setVeg(_veg);
    getRestaurantList(1, true);
  }

  void setNonVeg() {
    _nonVeg = restaurantServiceInterface.setNonVeg(_nonVeg);
    getRestaurantList(1, true);
  }

  Future<void> getPopularRestaurantList(bool reload, String type, bool notify,
      {DataSourceEnum dataSource = DataSourceEnum.local,
      bool fromRecall = false}) async {
    _type = type;
    if (reload) {
      _popularRestaurantList = null;
    }
    if (notify) {
      update();
    }
    List<Restaurant>? popularRestaurantList;
    if (_popularRestaurantList == null || reload || fromRecall) {
      if (dataSource == DataSourceEnum.local) {
        popularRestaurantList = await restaurantServiceInterface
            .getPopularRestaurantList(type, source: DataSourceEnum.local);
        _preparePopularRestaurantList(popularRestaurantList);
        getPopularRestaurantList(false, type, false,
            dataSource: DataSourceEnum.client, fromRecall: true);
      } else {
        popularRestaurantList = await restaurantServiceInterface
            .getPopularRestaurantList(type, source: DataSourceEnum.client);
        _preparePopularRestaurantList(popularRestaurantList);
      }
    }
  }

  _preparePopularRestaurantList(List<Restaurant>? restaurantList) {
    if (restaurantList != null) {
      _popularRestaurantList = [];
      _popularRestaurantList!.addAll(restaurantList);
    }
    update();
  }

  Future<void> getLatestRestaurantList(bool reload, String type, bool notify,
      {DataSourceEnum dataSource = DataSourceEnum.local,
      bool fromRecall = false}) async {
    _type = type;
    if (reload) {
      _latestRestaurantList = null;
    }
    if (notify) {
      update();
    }

    List<Restaurant>? latestRestaurantList;
    if (_latestRestaurantList == null || reload || fromRecall) {
      if (dataSource == DataSourceEnum.local) {
        latestRestaurantList = await restaurantServiceInterface
            .getLatestRestaurantList(type, source: DataSourceEnum.local);
        _prepareLatestRestaurantList(latestRestaurantList);
        getLatestRestaurantList(false, type, false,
            dataSource: DataSourceEnum.client, fromRecall: true);
      } else {
        latestRestaurantList = await restaurantServiceInterface
            .getLatestRestaurantList(type, source: DataSourceEnum.client);
        _prepareLatestRestaurantList(latestRestaurantList);
      }
    }
  }

  _prepareLatestRestaurantList(List<Restaurant>? restaurantList) {
    if (restaurantList != null) {
      _latestRestaurantList = [];
      _latestRestaurantList = restaurantList;
    }
    update();
  }

  void setCategoryList() {
    if (_restaurant == null) return;
    final globalCategories = Get.find<CategoryController>().categoryList;
    if (globalCategories != null) {
      _categoryList = restaurantServiceInterface.setCategories(
          globalCategories, _restaurant!);
    } else {
      _categoryList ??= [];
    }
  }

  Future<Restaurant?> getRestaurantDetails(Restaurant restaurant,
      {bool fromCart = false, String slug = '', bool notify = true}) async {
    _categoryIndex = 0;
    if (restaurant.name != null) {
      _restaurant = restaurant;
      if (notify) {
        update();
      }
      return _restaurant;
    }

    _isLoading = true;
    // Keep same-id seed on screen while details load (avoid full-page shimmer flash).
    if (_restaurant?.id != restaurant.id) {
      _restaurant = null;
      if (notify) {
        update();
      }
    }

    try {
      final fetched = await restaurantServiceInterface.getRestaurantDetails(
          restaurant.id.toString(),
          slug,
          Get.find<LocalizationController>().locale.languageCode);
      if (fetched != null) {
        _restaurant = fetched;
        if (_restaurant!.latitude != null && _restaurant!.longitude != null) {
          try {
            await _setRequiredDataAfterRestaurantGet(slug, fromCart);
          } catch (e, s) {
            debugPrint('post-restaurant setup failed: $e\n$s');
          }
        }
        Get.find<CheckoutController>().setOrderType(
          (_restaurant!.delivery != null)
              ? _restaurant!.delivery!
                  ? 'delivery'
                  : 'take_away'
              : 'delivery',
          notify: false,
        );
      }
    } catch (e, s) {
      debugPrint('getRestaurantDetails failed: $e\n$s');
      if (_restaurant?.id != restaurant.id) {
        _restaurant = null;
      }
    } finally {
      _isLoading = false;
      update();
    }
    return _restaurant;
  }

  Future<void> _setRequiredDataAfterRestaurantGet(
      String slug, bool fromCart) async {
    Get.find<CheckoutController>().initializeTimeSlot(_restaurant!);
    if (!fromCart && slug.isEmpty) {
      final address = AddressHelper.getAddressFromSharedPref();
      if (address?.latitude != null && address?.longitude != null) {
        Get.find<CheckoutController>().getDistanceInKM(
          LatLng(
            double.parse(address!.latitude!),
            double.parse(address.longitude!),
          ),
          LatLng(double.parse(_restaurant!.latitude!),
              double.parse(_restaurant!.longitude!)),
        );
      }
    }
    // Do NOT overwrite the user's saved location with the restaurant location.
    // The user's selected address must remain unchanged.
  }

  void makeEmptyRestaurant({bool willUpdate = true}) {
    _restaurant = null;
    if (willUpdate) {
      update();
    }
  }

  Future<void> getCartRestaurantSuggestedItemList(int? restaurantID) async {
    _suggestedItems = await restaurantServiceInterface
        .getCartRestaurantSuggestedItemList(restaurantID);
    update();
  }

  Future<void> getRestaurantProductList(
      int? restaurantID, int offset, String type, bool notify) async {
    _foodOffset = offset;
    if (offset == 1 || _restaurantProducts == null) {
      _type = type;
      _foodOffsetList = [];
      _restaurantProducts = null;
      _foodOffset = 1;
      if (notify) {
        update();
      }
    }
    if (!_foodOffsetList.contains(offset)) {
      _foodOffsetList.add(offset);
      // Always fetch all products (no category filter) since we show them grouped by category
      ProductModel? productModel =
          await restaurantServiceInterface.getRestaurantProductList(
              restaurantID,
              offset,
              0, // Always pass 0 to get all products
              type);

      if (productModel != null) {
        if (offset == 1) {
          _restaurantProducts = [];
        }
        _restaurantProducts!.addAll(productModel.products ?? []);
        _foodPageSize = productModel.totalSize;
        _foodPageOffset = productModel.offset;
        _foodPaginate = false;

        if (offset == 1 &&
            (productModel.totalSize ?? 0) > 12 &&
            restaurantID != null) {
          // Ensure category list is set so we can check coverage
          setCategoryList();
          // Load more pages until every category has at least one product,
          // so all sections (e.g. Snacks) show on first open instead of only after scroll.
          const int maxPages = 10;
          int nextOffset = 2;
          bool fillCategories =
              _categoryList != null && _categoryList!.isNotEmpty;
          while (fillCategories && nextOffset <= maxPages) {
            final totalSize = _foodPageSize ?? 0;
            if (totalSize <= 0 || _restaurantProducts!.length >= totalSize) {
              break;
            }
            final categoryIds = _categoryList!
                .where((c) => c.id != null)
                .map((c) => c.id!)
                .toSet();
            final productCategoryIds = _restaurantProducts!
                .where((p) => p.categoryId != null)
                .map((p) => p.categoryId!)
                .toSet();
            final missingIds = categoryIds.difference(productCategoryIds);
            if (missingIds.isEmpty) break;
            if (_foodOffsetList.contains(nextOffset)) {
              nextOffset++;
              continue;
            }
            _foodOffsetList.add(nextOffset);
            final nextModel = await restaurantServiceInterface
                .getRestaurantProductList(restaurantID, nextOffset, 0, type);
            if (nextModel != null && nextModel.products != null) {
              _restaurantProducts!.addAll(nextModel.products!);
              _foodPageSize = nextModel.totalSize;
              _foodPageOffset = nextModel.offset;
            }
            nextOffset++;
          }
          if (fillCategories) {
            update();
            return;
          }
          // Not fill path: prefetch pages 2–3 for a fuller first view
          if (!_foodOffsetList.contains(2)) {
            await getRestaurantProductList(restaurantID, 2, type, false);
            if ((productModel.totalSize ?? 0) > 24 &&
                !_foodOffsetList.contains(3)) {
              await getRestaurantProductList(restaurantID, 3, type, false);
            }
          }
        }
        update();
      }
    } else {
      if (_foodPaginate) {
        _foodPaginate = false;
        update();
      }
    }
  }

  void showFoodBottomLoader() {
    _foodPaginate = true;
    update();
  }

  void setFoodOffset(int offset) {
    _foodOffset = offset;
  }

  void showBottomLoader() {
    _isLoading = true;
    update();
  }

  Future<void> getRestaurantSearchProductList(
      String searchText, String? storeID, int offset, String type) async {
    if (searchText.isEmpty) {
      showCustomSnackBar('write_item_name'.tr);
    } else {
      _isSearching = true;
      _searchText = searchText;
      if (offset == 1 || _restaurantSearchProductModel == null) {
        _searchType = type;
        _restaurantSearchProductModel = null;
        update();
      }
      ProductModel? productModel = await restaurantServiceInterface
          .getRestaurantSearchProductList(searchText, storeID, offset, type);
      if (productModel != null) {
        if (offset == 1) {
          _restaurantSearchProductModel = productModel;
        } else {
          _restaurantSearchProductModel!.products!
              .addAll(productModel.products!);
          _restaurantSearchProductModel!.totalSize = productModel.totalSize;
          _restaurantSearchProductModel!.offset = productModel.offset;
        }
      }
      update();
    }
  }

  void changeSearchStatus({bool isUpdate = true}) {
    _isSearching = !_isSearching;
    if (isUpdate) {
      update();
    }
  }

  void initSearchData() {
    _restaurantSearchProductModel = ProductModel(products: []);
    _searchText = '';
    _searchType = 'all';
  }

  void setCategoryIndex(int index) {
    // No longer filters products - just updates index for scrolling/highlighting
    // Products are always shown grouped by category
    _categoryIndex = index;
    update();
  }

  void updateCategoryIndexFromScroll(int index, {bool notify = true}) {
    if (_categoryIndex != index) {
      _categoryIndex = index;
      if (notify) {
        update();
      }
    }
  }

  bool isRestaurantClosed(
      DateTime dateTime, bool active, List<Schedules>? schedules,
      {int? customDateDuration}) {
    return restaurantServiceInterface.isRestaurantClosed(
        dateTime, active, schedules);
  }

  bool isRestaurantOpenNow(bool active, List<Schedules>? schedules) {
    return restaurantServiceInterface.isRestaurantOpenNow(active, schedules);
  }

  bool isOpenNow(Restaurant restaurant) =>
      restaurant.open == 1 && restaurant.active!;

  double? getDiscount(Restaurant restaurant) =>
      restaurant.discount != null ? restaurant.discount!.discount : 0;

  String? getDiscountType(Restaurant restaurant) => restaurant.discount != null
      ? restaurant.discount!.discountType
      : 'percent';
}














