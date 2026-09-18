import 'dart:async';

import 'package:toto_user/common/enums/data_source_enum.dart';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/rendering.dart';
import 'package:iconsax/iconsax.dart';
import 'package:toto_user/common/widgets/cart_widget.dart';
import 'package:toto_user/common/widgets/menu_drawer_widget.dart';
import 'package:toto_user/common/widgets/paginated_list_view_widget.dart';
import 'package:toto_user/common/widgets/product_view_widget.dart';
import 'package:toto_user/features/dine_in/controllers/dine_in_controller.dart';
import 'package:toto_user/features/home/controllers/advertisement_controller.dart';
import 'package:toto_user/features/home/widgets/dine_in_widget.dart';
import 'package:toto_user/features/home/widgets/highlight_widget_view.dart';
import 'package:toto_user/features/home/widgets/refer_bottom_sheet_widget.dart';
import 'package:toto_user/features/home/widgets/theme1/cuisine_widget1.dart';
import 'package:toto_user/features/home/widgets/theme1/new_popular_store_widget1.dart';
import 'package:toto_user/features/product/controllers/campaign_controller.dart';
import 'package:toto_user/features/home/controllers/home_controller.dart';
import 'package:toto_user/features/home/screens/web_home_screen.dart';
import 'package:toto_user/features/home/widgets/all_restaurant_filter_widget.dart';
import 'package:toto_user/features/home/widgets/all_restaurant_food_view_widget.dart';
import 'package:toto_user/features/home/widgets/enjoy_off_banner_view_widget.dart';
import 'package:toto_user/features/home/widgets/location_banner_view_widget.dart';
import 'package:toto_user/features/home/widgets/new_on_stackfood_view_widget.dart';
import 'package:toto_user/features/home/widgets/order_again_view_widget.dart';
import 'package:toto_user/features/home/widgets/popular_restaurants_view_widget.dart';
import 'package:toto_user/features/home/widgets/refer_banner_view_widget.dart';
import 'package:toto_user/features/home/screens/theme1_home_screen.dart';
import 'package:toto_user/features/home/widgets/today_trends_view_widget.dart';
import 'package:toto_user/features/home/widgets/what_on_your_mind_view_widget.dart';
import 'package:toto_user/features/language/controllers/localization_controller.dart';
import 'package:toto_user/features/order/controllers/order_controller.dart';
import 'package:toto_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:toto_user/features/notification/controllers/notification_controller.dart';
import 'package:toto_user/features/profile/controllers/profile_controller.dart';
import 'package:toto_user/common/widgets/customizable_space_bar_widget.dart';
import 'package:toto_user/features/splash/controllers/splash_controller.dart';
import 'package:toto_user/features/splash/controllers/theme_controller.dart';
import 'package:toto_user/features/splash/domain/models/config_model.dart';
import 'package:toto_user/features/address/controllers/address_controller.dart';
import 'package:toto_user/features/auth/controllers/auth_controller.dart';
import 'package:toto_user/features/category/controllers/category_controller.dart';
import 'package:toto_user/features/cuisine/controllers/cuisine_controller.dart';
import 'package:toto_user/features/location/controllers/location_controller.dart';
import 'package:toto_user/features/product/controllers/product_controller.dart';
import 'package:toto_user/features/review/controllers/review_controller.dart';
import 'package:toto_user/helper/address_helper.dart';
import 'package:toto_user/helper/auth_helper.dart';
import 'package:toto_user/helper/responsive_helper.dart';
import 'package:toto_user/helper/route_helper.dart';
import 'package:toto_user/design_system/design_system.dart';
import 'package:toto_user/util/dimensions.dart';
import 'package:toto_user/common/widgets/web_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/new_best_review_item_view_widget.dart';
import '../widgets/new_popular_foods_nearby_view_widget.dart';
import '../widgets/theme1/banner_view_widget1.dart';

class HomeScreen extends StatefulWidget {
  final bool fromDineIn;
  const HomeScreen({super.key, this.fromDineIn = false});

  static Future<void> loadData(bool reload) async {
    Get.find<HomeController>().getBannerList(reload);
    Get.find<CategoryController>().getCategoryList(reload);
    Get.find<CuisineController>().getCuisineList();
    Get.find<AdvertisementController>().getAdvertisementList();
    Get.find<DineInController>().getDineInRestaurantList(1, reload);
    if (Get.find<SplashController>().configModel!.popularRestaurant == 1) {
      Get.find<RestaurantController>()
          .getPopularRestaurantList(reload, 'all', false);
    }
    Get.find<CampaignController>().getItemCampaignList(reload);
    if (Get.find<SplashController>().configModel!.popularFood == 1) {
      Get.find<ProductController>().getPopularProductList(reload, 'all', false);
    }
    if (Get.find<SplashController>().configModel!.newRestaurant == 1) {
      Get.find<RestaurantController>()
          .getLatestRestaurantList(reload, 'all', false);
    }
    if (Get.find<SplashController>().configModel!.mostReviewedFoods == 1) {
      Get.find<ReviewController>().getReviewedProductList(reload, 'all', false);
    }
    Get.find<RestaurantController>().getRestaurantList(1, reload);
    if (Get.find<AuthController>().isLoggedIn()) {
      await Get.find<ProfileController>().getUserInfo();
      Get.find<RestaurantController>()
          .getRecentlyViewedRestaurantList(reload, 'all', false);
      Get.find<RestaurantController>().getOrderAgainRestaurantList(reload);
      Get.find<NotificationController>().getNotificationList(reload);
      Get.find<OrderController>().getRunningOrders(1, notify: false);
      Get.find<AddressController>().getAddressList();
      Get.find<HomeController>().getCashBackOfferList();
    }
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final ConfigModel? _configModel = Get.find<SplashController>().configModel;
  bool _isLogin = false;
  Timer? _scrollCollapseTimer;
  Timer? _restaurantStatusTimer;
  bool _restaurantStatusRefreshRunning = false;
  bool _hasScrolled = false;
  bool _showBackToTop = false;

  /// When app went to background (paused/inactive).
  DateTime? _backgroundTime;

  /// Full-screen refresh shown when returning from background after some time.
  bool _isRefreshingFromResume = false;
  static const Duration _minBackgroundDurationToRefresh = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _isLogin = Get.find<AuthController>().isLoggedIn();

    _restaurantStatusTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshRestaurantStatusSilently(),
    );
    HomeScreen.loadData(false).then((value) {
      Get.find<SplashController>().getReferBottomSheetStatus();

      if ((Get.find<ProfileController>().userInfoModel?.isValidForDiscount ??
              false) &&
          Get.find<SplashController>().showReferBottomSheet) {
        Future.delayed(
            const Duration(milliseconds: 500), () => _showReferBottomSheet());
      }
    });

    _scrollController.addListener(() {
      // Show/hide back to top button based on scroll position
      if (_scrollController.hasClients) {
        final shouldShow = _scrollController.position.pixels > 200;
        if (shouldShow != _showBackToTop) {
          setState(() {
            _showBackToTop = shouldShow;
          });
        }
      }

      // Detect scroll movement - check if user is actively scrolling
      // Use isScrollingNotifier to detect when user is actively dragging
      if (_scrollController.position.isScrollingNotifier.value) {
        // Collapse bottom sheet when scrolling (debounced to avoid excessive calls)
        if (!_hasScrolled) {
          _hasScrolled = true;
          Get.find<OrderController>().collapseBottomSheet();
        }

        // Reset flag after scroll ends
        _scrollCollapseTimer?.cancel();
        _scrollCollapseTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted) {
            _hasScrolled = false;
          }
        });
      }
    });
  }
  Future<void> _refreshRestaurantStatusSilently() async {
    if (!mounted || _restaurantStatusRefreshRunning) return;

    _restaurantStatusRefreshRunning = true;

    try {
      final restaurantController = Get.find<RestaurantController>();

      await restaurantController.refreshRestaurantStatus();

      if (_configModel?.popularRestaurant == 1) {
        await restaurantController.getPopularRestaurantList(
          false,
          'all',
          false,
          dataSource: DataSourceEnum.client,
          fromRecall: true,
        );
      }

      if (_configModel?.newRestaurant == 1) {
        await restaurantController.getLatestRestaurantList(
          false,
          'all',
          false,
          dataSource: DataSourceEnum.client,
          fromRecall: true,
        );
      }
    } catch (e) {
      debugPrint('Restaurant status silent refresh failed: $e');
    } finally {
      _restaurantStatusRefreshRunning = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed && _backgroundTime != null) {
      final duration = DateTime.now().difference(_backgroundTime!);
      if (duration >= _minBackgroundDurationToRefresh) {
        _backgroundTime = null;
        _refreshFromResume();
      } else {
        _backgroundTime = null;
      }
    }
  }

  Future<void> _refreshFromResume() async {
    if (!mounted) return;
    setState(() => _isRefreshingFromResume = true);
    try {
      await HomeScreen.loadData(true);
    } finally {
      if (mounted) {
        setState(() => _isRefreshingFromResume = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollCollapseTimer?.cancel();
    _restaurantStatusTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _showReferBottomSheet() {
    ResponsiveHelper.isDesktop(context)
        ? Get.dialog(
            Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusExtraLarge)),
              insetPadding: const EdgeInsets.all(22),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: const ReferBottomSheetWidget(),
            ),
            useSafeArea: false,
          ).then((value) =>
            Get.find<SplashController>().saveReferBottomSheetStatus(false))
        : showModalBottomSheet(
            isScrollControlled: true,
            useRootNavigator: true,
            context: Get.context!,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(Dimensions.radiusExtraLarge),
                  topRight: Radius.circular(Dimensions.radiusExtraLarge)),
            ),
            builder: (context) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8),
                child: const ReferBottomSheetWidget(),
              );
            },
          ).then((value) =>
            Get.find<SplashController>().saveReferBottomSheetStatus(false));
  }

  @override
  Widget build(BuildContext context) {
    double scrollPoint = 0.0;
    final colors = AppColors.of(context);

    return GetBuilder<HomeController>(builder: (homeController) {
      return GetBuilder<LocalizationController>(
          builder: (localizationController) {
        return Scaffold(
          appBar:
              ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
          endDrawer: const MenuDrawerWidget(),
          endDrawerEnableOpenDragGesture: false,
          backgroundColor: colors.canvas,
          body: Stack(
            children: [
              SafeArea(
                top: (Get.find<SplashController>().configModel!.theme == 2),
                bottom: false, // বটম সেফএরিয়া অফ করা হলো যাতে লিস্টটি একদম নেভিগেশন বারের তলা পর্যন্ত বিস্তৃত হয়
                child: RefreshIndicator(
                  key: ValueKey<String>(
                    ResponsiveHelper.isDesktop(context)
                        ? 'home_web'
                        : (Get.find<SplashController>().configModel!.theme == 2
                            ? 'home_theme1'
                            : 'home_default'),
                  ),
                  onRefresh: () async {
                    await Get.find<HomeController>().getBannerList(true);
                    await Get.find<CategoryController>().getCategoryList(true);
                    await Get.find<CuisineController>().getCuisineList();
                    Get.find<AdvertisementController>().getAdvertisementList();
                    await Get.find<RestaurantController>()
                        .getPopularRestaurantList(true, 'all', false);
                    await Get.find<CampaignController>()
                        .getItemCampaignList(true);
                    await Get.find<ProductController>()
                        .getPopularProductList(true, 'all', false);
                    await Get.find<RestaurantController>()
                        .getLatestRestaurantList(true, 'all', false);
                    await Get.find<ReviewController>()
                        .getReviewedProductList(true, 'all', false);
                    await Get.find<RestaurantController>()
                        .getRestaurantList(1, true);
                    if (Get.find<AuthController>().isLoggedIn()) {
                      await Get.find<ProfileController>().getUserInfo();
                      await Get.find<NotificationController>()
                          .getNotificationList(true);
                      await Get.find<RestaurantController>()
                          .getRecentlyViewedRestaurantList(true, 'all', false);
                      await Get.find<RestaurantController>()
                          .getOrderAgainRestaurantList(true);
                    }
                  },
                  child: ResponsiveHelper.isDesktop(context)
                      ? WebHomeScreen(
                          scrollController: _scrollController,
                        )
                      : (Get.find<SplashController>().configModel!.theme == 2)
                          ? Theme1HomeScreen(
                              scrollController: _scrollController,
                            )
                          : CustomScrollView(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                /// App Bar
                                SliverAppBar(
                                  pinned: true,
                                  toolbarHeight: 5,
                                  expandedHeight:
                                      ResponsiveHelper.isTab(context)
                                          ? 78
                                          : GetPlatform.isWeb
                                              ? 78
                                              : 60, // à¦“à¦ªà¦°à§‡ à¦à¦¬à¦‚ à¦¸à¦¾à¦°à§à¦šà¦¬à¦¾à¦°à§‡à¦° à¦®à¦¾à¦à¦–à¦¾à¦¨à§‡à¦° à¦¸à§à¦ªà§‡à¦¸ à¦à¦•à¦¦à¦® à¦•à¦®à¦¿à§Ÿà§‡ à¦«à§‡à¦²à¦¾ à¦¹à¦²à§‹
                                  floating: false,
                                  elevation: 0,
                                  backgroundColor:
                                      ResponsiveHelper.isDesktop(context)
                                          ? Colors.transparent
                                          : colors.accent,
                                  surfaceTintColor: colors.accent,
                                  flexibleSpace: FlexibleSpaceBar(
                                      titlePadding: EdgeInsets.zero,
                                      centerTitle: true,
                                      expandedTitleScale: 1,
                                      title: CustomizableSpaceBarWidget(
                                        builder: (context, scrollingRate) {
                                          scrollPoint = scrollingRate;
                                          return Center(
                                              child: Container(
                                            width: Dimensions.webMaxWidth,
                                            color: colors.accent,
                                            padding:
                                                const EdgeInsets.only(top: 14, bottom: 0), // à¦Ÿà¦ª à¦ªà§à¦¯à¦¾à¦¡à¦¿à¦‚à¦“ à¦Ÿà§à¦°à¦¿à¦® à¦•à¦°à¦¾ à¦¹à¦²à§‹ à¦¯à¦¾à¦¤à§‡ à¦•à¦¨à§à¦Ÿà§‡à¦¨à§à¦Ÿ à¦Ÿà¦¾à¦‡à¦Ÿ à¦¥à¦¾à¦•à§‡
                                            child: Opacity(
                                              opacity: 1 - scrollPoint,
                                              child: Row(children: [
                                                Expanded(
                                                    child: Transform.translate(
                                                  offset: Offset(
                                                      0, -(scrollingRate * 20)),
                                                  child: InkWell(
                                                    onTap: () => Get.toNamed(
                                                        RouteHelper
                                                            .getAccessLocationRoute(
                                                                'home')),
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal:
                                                              AppSpacing.sm),
                                                      child: GetBuilder<
                                                              LocationController>(
                                                          builder:
                                                              (locationController) {
                                                        return Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              if (scrollingRate <
                                                                  0.2)
                                                                Row(children: [
                                                                  Icon(
                                                                    Icons
                                                                        .location_on_rounded,
                                                                    size: 18,
                                                                    color: Colors.white, // à¦…à¦°à§‡à¦žà§à¦œ à¦¬à§à¦¯à¦¾à¦•à¦—à§à¦°à¦¾à¦‰à¦¨à§à¦¡à§‡ à¦¸à¦¾à¦¦à¦¾ à¦†à¦‡à¦•à¦¨ à¦¸à§à¦¨à§à¦¦à¦° à¦²à¦¾à¦—à¦¬à§‡
                                                                  ),
                                                                  const SizedBox(
                                                                      width: AppSpacing
                                                                          .xs),
                                                                  Text(
                                                                    (AuthHelper.isLoggedIn() &&
                                                                            AddressHelper.getAddressFromSharedPref()!.addressType !=
                                                                                'others')
                                                                        ? AddressHelper.getAddressFromSharedPref()!
                                                                            .addressType!
                                                                            .tr
                                                                        : 'your_location'
                                                                            .tr,
                                                                    style: AppTypography
                                                                        .labelMd(Colors.white), // à¦…à¦°à§‡à¦žà§à¦œ à¦¬à§à¦¯à¦¾à¦•à¦—à§à¦°à¦¾à¦‰à¦¨à§à¦¡à§‡ à¦¸à¦¾à¦¦à¦¾ à¦Ÿà§‡à¦•à§à¦¸à¦Ÿ à¦ªà§à¦°à¦¿à¦®à¦¿à§Ÿà¦¾à¦® à¦²à¦¾à¦—à¦¬à§‡
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ]),
                                                              SizedBox(
                                                                  height:
                                                                      (scrollingRate <
                                                                              0.15)
                                                                          ? 2
                                                                          : 0),
                                                              if (scrollingRate <
                                                                  0.8)
                                                                Padding(
                                                                  padding: const EdgeInsets
                                                                      .only(
                                                                      left: AppSpacing
                                                                          .xs),
                                                                  child: Row(
                                                                    children: [
                                                                      SizedBox(
                                                                        width:
                                                                            200,
                                                                        child:
                                                                            Row(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.start,
                                                                          children: [
                                                                            Flexible(
                                                                              child: Text(
                                                                                AddressHelper.getAddressFromSharedPref()!.address!,
                                                                                style: AppTypography.bodySm(Colors.white70), // à¦¹à¦¾à¦²à¦•à¦¾ à¦¸à¦¾à¦¦à¦¾ à¦Ÿà§‡à¦•à§à¦¸à¦Ÿ à¦à¦¡à§à¦°à§‡à¦¸à§‡à¦° à¦œà¦¨à§à¦¯
                                                                                maxLines: 1,
                                                                                overflow: TextOverflow.ellipsis,
                                                                              ),
                                                                            ),
                                                                            Icon(
                                                                              Icons.keyboard_arrow_down_rounded,
                                                                              color: Colors.white70,
                                                                              size: 18,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                            ]);
                                                      }),
                                                    ),
                                                  ),
                                                )),
                                                Transform.translate(
                                                  offset: Offset(
                                                      0, -(scrollingRate * 10)),
                                                  child: InkWell(
                                                    child: GetBuilder<
                                                            NotificationController>(
                                                        builder:
                                                            (notificationController) {
                                                      return Container(
                                                        width: 42,
                                                        height: 42,
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withValues(alpha: 0.96),
                                                          borderRadius: BorderRadius.circular(14),
                                                          border: Border.all(
                                                            color: Colors.white.withValues(alpha: 0.80),
                                                            width: 1.2,
                                                          ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.black.withValues(alpha: 0.10),
                                                              blurRadius: 12,
                                                              offset: const Offset(0, 4),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Stack(
                                                          clipBehavior: Clip.none,
                                                          alignment: Alignment.center,
                                                          children: [
                                                            Icon(
                                                              Iconsax.notification,
                                                              size: 22,
                                                              color: colors.accent,
                                                            ),
                                                            if (notificationController.hasNotification)
                                                              Positioned(
                                                                top: 6,
                                                                right: 6,
                                                                child: Container(
                                                                  width: 10,
                                                                  height: 10,
                                                                  decoration: BoxDecoration(
                                                                    color: colors.warm,
                                                                    shape: BoxShape.circle,
                                                                    border: Border.all(
                                                                      color: Colors.white,
                                                                      width: 2,
                                                                    ),
                                                                    boxShadow: [
                                                                      BoxShadow(
                                                                        color: colors.warm.withValues(alpha: 0.35),
                                                                        blurRadius: 5,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      );
                                                    }),
                                                    onTap: () => Get.toNamed(
                                                        RouteHelper
                                                            .getNotificationRoute()),
                                                  ),
                                                ),
                                                const SizedBox(
                                                    width: AppSpacing.sm),
                                              ]),
                                            ),
                                          ));
                                        },
                                      )),
                                  actions: const [SizedBox()],
                                ),

                                SliverPersistentHeader(
                                  pinned: true,
                                  delegate: SliverDelegate(
                                    height: 72, // à¦¸à¦¾à¦°à§à¦šà¦¬à¦¾à¦°à§‡à¦° à¦‰à¦šà§à¦šà¦¤à¦¾ à¦¸à§à¦¨à§à¦¦à¦° à¦à¦¬à¦‚ à¦¬à§œ à¦°à¦¾à¦–à¦¾ à¦¹à¦²à§‹
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => Get.toNamed(
                                          RouteHelper.getSearchRoute()),
                                      child: Container(
                                        color: colors.accent,
                                        alignment: Alignment.topCenter, // à¦¸à¦¾à¦°à§à¦šà¦¬à¦¾à¦°à¦Ÿà¦¿à¦•à§‡ à¦à¦•à¦¦à¦® à¦“à¦ªà¦°à§‡à¦° à¦¬à¦°à§à¦¡à¦¾à¦°à§‡ à¦ªà§à¦¶ à¦•à¦°à¦¾ à¦¹à¦²à§‹
                                        child: SizedBox(
                                          width: Dimensions.webMaxWidth,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: AppSpacing.xl,
                                              right: AppSpacing.xl,
                                              top: 0, // à¦“à¦ªà¦°à§‡à¦° à¦ªà§à¦¯à¦¾à¦¡à¦¿à¦‚ à§¦ à¦•à¦°à¦¾ à¦¹à¦²à§‹ à¦¯à¦¾à¦¤à§‡ à¦²à§‹à¦•à§‡à¦¶à¦¨à§‡à¦° à¦¸à¦¾à¦¥à§‡ à¦—à§à¦¯à¦¾à¦ª à¦à¦•à¦¦à¦® à¦®à¦¿à¦¶à§‡ à¦¯à¦¾à§Ÿ
                                              bottom: AppSpacing.xl,
                                            ),
                                            child: Container(
                                              height: 52, // à¦†à¦ªà¦¨à¦¾à¦° à¦•à¦¾à¦™à§à¦•à§à¦·à¦¿à¦¤ à¦®à¦¡à¦¾à¦°à§à¦¨ à¦¬à§œ à§«à§¨ à¦¸à¦¾à¦‡à¦œà§‡à¦° à¦¸à¦¾à¦°à§à¦šà¦¬à¦¾à¦°
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.md,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: AppRadius.mdAll,
                                                boxShadow:
                                                    AppShadows.of(context, 2), // à¦—à¦­à§€à¦° à¦¶à§à¦¯à¦¾à¦¡à§‹ à¦ªà§à¦°à¦¿à¦®à¦¿à§Ÿà¦¾à¦® à¦²à§à¦•à§‡à¦° à¦œà¦¨à§à¦¯
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.search_rounded,
                                                    color: colors.inkMuted,
                                                    size: 24,
                                                  ),
                                                  const SizedBox(
                                                      width: AppSpacing.sm),
                                                  Text(
                                                    '${'search_for'.tr} ',
                                                    style: AppTypography.bodyMd(
                                                        colors.inkFaint),
                                                  ),
                                                  Expanded(
                                                    child: IgnorePointer(
                                                      child: AnimatedTextKit(
                                                        repeatForever: true,
                                                        pause: const Duration(
                                                            milliseconds: 1000),
                                                        animatedTexts: [
                                                          TypewriterAnimatedText(
                                                            'are_you_hungry'.tr,
                                                            textStyle:
                                                                AppTypography
                                                                    .bodyMd(colors
                                                                        .accent),
                                                            speed:
                                                                const Duration(
                                                                    milliseconds:
                                                                        100),
                                                          ),
                                                          TypewriterAnimatedText(
                                                            'pizza'.tr,
                                                            textStyle:
                                                                AppTypography
                                                                    .bodyMd(colors
                                                                        .accent),
                                                            speed:
                                                                const Duration(
                                                                    milliseconds:
                                                                        100),
                                                          ),
                                                          TypewriterAnimatedText(
                                                            'burger'.tr,
                                                            textStyle:
                                                                AppTypography
                                                                    .bodyMd(colors
                                                                        .accent),
                                                            speed:
                                                                const Duration(
                                                                    milliseconds:
                                                                        100),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    width: 40,
                                                    height: 40,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: colors.accentSoft,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Icon(
                                                      Icons.tune_rounded,
                                                      color: colors.accent,
                                                      size: 22,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                SliverToBoxAdapter(
                                  child: Center(
                                      child: SizedBox(
                                    width: Dimensions.webMaxWidth,
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const WhatOnYourMindViewWidget(),
                                          const BannerViewWidget1(),
                                          const TodayTrendsViewWidget(),
                                          const AllRestaurantFoodViewWidget(),
                                          const LocationBannerViewWidget(),
                                          const HighlightWidgetView(),
                                          _isLogin
                                              ? const OrderAgainViewWidget()
                                              : const SizedBox(),
                                          _configModel?.popularFood == 1 &&
                                                  _configModel
                                                          ?.mostReviewedFoods ==
                                                      1
                                              ? const NewPopularFoodsNearbyViewWidget()
                                              : const SizedBox(),
                                          _configModel!.dineInOrderOption!
                                              ? DineInWidget()
                                              : const SizedBox(),
                                          const CuisinesWidget1(),
                                          _configModel!.mostReviewedFoods == 1
                                              ? NewBestReviewItemViewWidget(
                                                  isPopular: true,
                                                )
                                              : const SizedBox(),
                                          // _configModel.popularFood == 1
                                          //     ? const PopularFoodNearbyViewWidget()
                                          //     : const SizedBox(),
                                          _configModel.popularRestaurant == 1
                                              ? NewPopularStoreWidget1(
                                                  isPopular: true)
                                              : const SizedBox(),
                                          const ReferBannerViewWidget(),
                                          _isLogin
                                              ? const PopularRestaurantsViewWidget(
                                                  isRecentlyViewed: true)
                                              : const SizedBox(),
                                          _configModel.newRestaurant == 1
                                              ? const NewOnStackFoodViewWidget(
                                                  isLatest: true)
                                              : const SizedBox(),
                                          const PromotionalBannerViewWidget(),
                                        ]),
                                  )),
                                ),

                                SliverPersistentHeader(
                                  pinned: true,
                                  delegate: SliverDelegate(
                                    height: 45,
                                    child: GetBuilder<ThemeController>(
                                      builder: (themeController) {
                                        return Container(
                                          color: colors.canvas,
                                          child:
                                              const AllRestaurantFilterWidget(),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                SliverToBoxAdapter(
                                  child: GetBuilder<ThemeController>(
                                    builder: (themeController) {
                                      return Container(
                                        color: colors.canvas,
                                        child: GetBuilder<RestaurantController>(
                                            builder: (restaurantController) {
                                          return GetBuilder<OrderController>(
                                              builder: (orderController) {
                                            final bool addBottomPadding =
                                                orderController
                                                            .runningOrderList !=
                                                        null &&
                                                    orderController
                                                        .runningOrderList!
                                                        .isNotEmpty &&
                                                    orderController
                                                        .showBottomSheet;
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                  bottom: addBottomPadding
                                                      ? 100
                                                      : 0),
                                              child: PaginatedListViewWidget(
                                                scrollController:
                                                    _scrollController,
                                                totalSize: restaurantController
                                                    .restaurantModel?.totalSize,
                                                offset: restaurantController
                                                    .restaurantModel?.offset,
                                                onPaginate: (int?
                                                        offset) async =>
                                                    await restaurantController
                                                        .getRestaurantList(
                                                            offset!, false),
                                                productView: ProductViewWidget(
                                                  isRestaurant: true,
                                                  products: null,
                                                  showTheme1Restaurant: true,
                                                  restaurants:
                                                      restaurantController
                                                          .restaurantModel
                                                          ?.restaurants,
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: ResponsiveHelper
                                                            .isDesktop(context)
                                                        ? Dimensions
                                                            .paddingSizeExtraSmall
                                                        : Dimensions
                                                            .paddingSizeSmall,
                                                    vertical: ResponsiveHelper
                                                            .isDesktop(context)
                                                        ? Dimensions
                                                            .paddingSizeExtraSmall
                                                        : 0,
                                                  ),
                                                ),
                                              ),
                                            );
                                          });
                                        }),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
              // Back to top button overlay for mobile
              if (!ResponsiveHelper.isDesktop(context) && _showBackToTop)
                GetBuilder<OrderController>(builder: (orderController) {
                  final bool hasBottomSheet =
                      orderController.runningOrderList != null &&
                          orderController.runningOrderList!.isNotEmpty &&
                          orderController.showBottomSheet;
                  final double bottomPosition = hasBottomSheet ? 120 : 20;

                  return Positioned(
                    right: AppSpacing.xl,
                    bottom: bottomPosition,
                    child: InkWell(
                      onTap: () {
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                      borderRadius: AppRadius.smAll,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.of(context, 2),
                        ),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          size: 18,
                          color: colors.onAccent,
                        ),
                      ),
                    ),
                  );
                }),
              if (_isRefreshingFromResume)
                Positioned.fill(
                  child: Container(
                    color: colors.canvas.withValues(alpha: 0.88),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.accent,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Refreshing...'.tr,
                            style: AppTypography.bodyMd(colors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: ResponsiveHelper.isDesktop(context)
              ? Stack(
                  children: [
                    // Cart button
                    Material(
                      elevation: 3,
                      shape: const CircleBorder(),
                      child: FloatingActionButton(
                        backgroundColor: colors.surface,
                        onPressed: () {
                          if (Get.currentRoute.contains(RouteHelper.checkout)) {
                            Get.offNamed(RouteHelper.getCartRoute(
                                fromDineIn: widget.fromDineIn));
                          } else {
                            Get.toNamed(RouteHelper.getCartRoute(
                                fromDineIn: widget.fromDineIn));
                          }
                        },
                        child: CartWidget(color: colors.accent, size: 30),
                      ),
                    ),
                    // Back to top button
                    if (_showBackToTop)
                      GetBuilder<OrderController>(builder: (orderController) {
                        final bool hasBottomSheet =
                            orderController.runningOrderList != null &&
                                orderController.runningOrderList!.isNotEmpty &&
                                orderController.showBottomSheet;
                        final double bottomPosition = hasBottomSheet ? 180 : 80;

                        return Positioned(
                          right: 0,
                          bottom: bottomPosition,
                          child: InkWell(
                            onTap: () {
                              _scrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            },
                            borderRadius: AppRadius.smAll,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colors.accent,
                                shape: BoxShape.circle,
                                boxShadow: AppShadows.of(context, 2),
                              ),
                              child: Icon(
                                Icons.arrow_upward_rounded,
                                size: 18,
                                color: colors.onAccent,
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                )
              : const SizedBox.shrink(),
        );
      });
    });
  }
}

class SliverDelegate extends SliverPersistentHeaderDelegate {
  Widget child;
  double height;

  SliverDelegate({required this.child, this.height = 50});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverDelegate oldDelegate) {
    return oldDelegate.maxExtent != height ||
        oldDelegate.minExtent != height ||
        child != oldDelegate.child;
  }
}





