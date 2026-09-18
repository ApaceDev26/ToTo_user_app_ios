import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:toto_user/features/cart/screens/cart_screen.dart';
import 'package:toto_user/features/cart/controllers/cart_controller.dart';
import 'package:toto_user/features/checkout/widgets/congratulation_dialogue.dart';
import 'package:toto_user/features/dashboard/widgets/registration_success_bottom_sheet.dart';
import 'package:toto_user/features/home/screens/home_screen.dart';
import 'package:toto_user/features/menu/screens/menu_screen.dart';
import 'package:toto_user/features/order/controllers/order_controller.dart';
import 'package:toto_user/features/order/screens/order_screen.dart';
import 'package:toto_user/features/splash/controllers/splash_controller.dart';
import 'package:toto_user/features/order/domain/models/order_model.dart';
import 'package:toto_user/features/auth/controllers/auth_controller.dart';
import 'package:toto_user/features/dashboard/controllers/dashboard_controller.dart';
import 'package:toto_user/features/dashboard/widgets/address_bottom_sheet.dart';
import 'package:toto_user/features/dashboard/widgets/bottom_nav_item.dart';
import 'package:toto_user/features/dashboard/widgets/running_order_view_widget.dart';
import 'package:toto_user/features/dashboard/widgets/delivery_success_popup_widget.dart';
import 'package:toto_user/features/dashboard/widgets/refund_success_popup_widget.dart';
import 'package:toto_user/features/loyalty/controllers/loyalty_controller.dart';
import 'package:toto_user/helper/in_app_messaging_helper.dart';
import 'package:toto_user/helper/responsive_helper.dart';
import 'package:toto_user/util/dimensions.dart';
import 'package:toto_user/util/app_constants.dart';
import 'package:toto_user/helper/route_helper.dart';
import 'package:toto_user/features/order/screens/order_details_screen.dart';
import 'package:toto_user/common/widgets/custom_dialog_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toto_user/util/images.dart';

class DashboardScreen extends StatefulWidget {
  final int pageIndex;
  final bool fromSplash;
  const DashboardScreen(
      {super.key, required this.pageIndex, this.fromSplash = false});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  PageController? _pageController;
  int _pageIndex = 0;
  late List<Widget> _screens;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey();
  bool _canExit = GetPlatform.isWeb ? true : false;
  late bool _isLogin;
  bool active = false;
  bool _isBottomSheetExpanded = false;
  Timer? _orderRefreshTimer;
  Timer? _immediateMessageCheckTimer;
  int? _lastCheckedOrderId;
  bool _isCheckingDeliveredOrder = false;
  bool _isPopupShowing = false;
  int? _lastCheckedRefundOrderId;
  bool _isCheckingRefundedOrder = false;
  bool _isRefundPopupShowing = false;
  bool _isAnyPopupShowing =
      false; // Global flag to prevent any popup from showing if one is already showing

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _isLogin = Get.find<AuthController>().isLoggedIn();

    if (_isLogin) {
      Get.find<OrderController>().showRunningOrders();
    }

    _showRegistrationSuccessBottomSheet();

    if (_isLogin) {
      if (Get.find<SplashController>().configModel!.loyaltyPointStatus == 1 &&
          Get.find<LoyaltyController>().getEarningPint().isNotEmpty &&
          !ResponsiveHelper.isDesktop(Get.context)) {
        Future.delayed(
            const Duration(seconds: 1),
            () => showAnimatedDialog(
                Get.context!, const CongratulationDialogue()));
      }
      _suggestAddressBottomSheet();
      // Load both orders and then check once to avoid duplicate checks
      Future.wait([
        Get.find<OrderController>().getRunningOrders(1, notify: false),
        Get.find<OrderController>().getHistoryOrders(1, notify: false),
      ]).then((_) {
        _checkForDeliveredOrder();
        _checkForRefundedOrder();
      });

      // Start periodic refresh of running orders to update status in real-time
      _startOrderRefreshTimer();
      // Start periodic check for immediate messages when on dashboard
      _startImmediateMessageCheckTimer();
    }

    _pageIndex = widget.pageIndex;

    _pageController = PageController(initialPage: widget.pageIndex);

    // Set collapse callback in OrderController - set after first frame to ensure widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<OrderController>().setCollapseBottomSheetCallback(() {
        if (mounted && _pageIndex == 0) {
          Get.find<OrderController>().setBottomSheetExpanded(false);
          setState(() => _isBottomSheetExpanded = false);
        }
      });
    });

    // Add listener to handle page changes
    _pageController!.addListener(() {
      final currentPage = _pageController!.page?.round() ?? 0;
      if (currentPage == 0 && _isLogin) {
        // Refresh running orders when returning to home page
        // Load both orders and then check once to avoid duplicate checks
        Future.wait([
          Get.find<OrderController>().getRunningOrders(1, notify: true),
          Get.find<OrderController>().getHistoryOrders(1, notify: false),
        ]).then((_) {
          _checkForDeliveredOrder();
          _checkForRefundedOrder();
        });
        // Check for immediate messages when dashboard becomes visible
        InAppMessagingHelper.checkForImmediateMessages();
      }
    });

    _screens = [
      const HomeScreen(),
      const OrderScreen(),
      const CartScreen(fromNav: true),
      const CartScreen(
        fromNav: true,
      ),
      const MenuScreen()
    ];
    // _screens = [
    //   const HomeScreen(),
    //   const Dummy2(),
    //   const Dummy3(),
    //   const Dummy3(),
    //   const MenuScreen()
    // ];

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {});
    });

    // Initialize in-app messaging (starts periodic polling for immediate messages)
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        await InAppMessagingHelper.initialize();
      } catch (e) {
        debugPrint('Error initializing in-app messaging: $e');
      }
    });

    // Check for immediate messages immediately (don't wait for screen-specific messages)
    Future.delayed(const Duration(seconds: 1), () async {
      try {
        await InAppMessagingHelper.checkForImmediateMessages();
      } catch (e) {
        debugPrint('Error checking immediate messages on dashboard load: $e');
      }
    });

    // Trigger in-app message fetch for dashboard screen
    // Delayed by 2 seconds to ensure splash screen is completely gone
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        await InAppMessagingHelper.fetchAndDisplayMessages(
          screen: 'dashboard',
        );
        // Also check for immediate messages again after screen messages
        await InAppMessagingHelper.checkForImmediateMessages();
      } catch (e) {
        debugPrint('Error loading dashboard in-app messages: $e');
      }
    });
  }

  _showRegistrationSuccessBottomSheet() {
    bool canShowBottomSheet =
        Get.find<DashboardController>().getRegistrationSuccessfulSharedPref();
    if (canShowBottomSheet) {
      Future.delayed(const Duration(seconds: 1), () {
        ResponsiveHelper.isDesktop(Get.context)
            ? Get.dialog(const Dialog(child: RegistrationSuccessBottomSheet()))
                .then((value) {
                Get.find<DashboardController>()
                    .saveRegistrationSuccessfulSharedPref(false);
                Get.find<DashboardController>()
                    .saveIsRestaurantRegistrationSharedPref(false);
                setState(() {});
              })
            : showModalBottomSheet(
                context: Get.context!,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (con) => const RegistrationSuccessBottomSheet(),
              ).then((value) {
                Get.find<DashboardController>()
                    .saveRegistrationSuccessfulSharedPref(false);
                Get.find<DashboardController>()
                    .saveIsRestaurantRegistrationSharedPref(false);
                setState(() {});
              });
      });
    }
  }

  Future<void> _suggestAddressBottomSheet() async {
    active = await Get.find<DashboardController>().checkLocationActive();
    if (widget.fromSplash &&
        Get.find<DashboardController>().showLocationSuggestion &&
        active) {
      Future.delayed(const Duration(seconds: 1), () {
        showModalBottomSheet(
          context: Get.context!,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (con) => const AddressBottomSheet(),
        ).then((value) {
          Get.find<DashboardController>().hideSuggestedLocation();
          setState(() {});
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update login state when returning from other pages
    _isLogin = Get.find<AuthController>().isLoggedIn();

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) async {
        debugPrint('$_canExit');
        if (_pageIndex != 0) {
          _setPage(0);
        } else {
          if (_canExit) {
            if (GetPlatform.isAndroid) {
              SystemNavigator.pop();
            } else if (GetPlatform.isIOS) {
              exit(0);
            }
          }
          if (!ResponsiveHelper.isDesktop(context)) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('back_press_again_to_exit'.tr,
                  style: const TextStyle(color: Colors.white)),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            ));
          }
          _canExit = true;

          Timer(const Duration(seconds: 2), () {
            _canExit = false;
          });
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        // Overlay nav in body Stack â€” Scaffold.bottomNavigationBar always paints
        // an opaque canvas strip that kills true transparency.
        bottomNavigationBar: null,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GetBuilder<OrderController>(builder: (orderController) {
              // Check for delivered orders whenever OrderController updates
              // Use flags to prevent multiple simultaneous checks
              if (!_isCheckingDeliveredOrder &&
                  !_isCheckingRefundedOrder &&
                  !_isAnyPopupShowing &&
                  _isLogin &&
                  _pageIndex == 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted &&
                      !_isCheckingDeliveredOrder &&
                      !_isCheckingRefundedOrder &&
                      !_isAnyPopupShowing) {
                    _checkForDeliveredOrder();
                    _checkForRefundedOrder();
                  }
                });
              }

              List<OrderModel> runningOrder =
                  orderController.runningOrderList != null
                      ? orderController.runningOrderList!
                      : [];

              List<OrderModel> reversOrder = List.from(runningOrder.reversed);

              final showRunning = _isLogin &&
                  orderController.runningOrderList != null &&
                  orderController.runningOrderList!.isNotEmpty &&
                  orderController.showBottomSheet &&
                  _pageIndex == 0;

              final hasFloatingNav = !ResponsiveHelper.isDesktop(context);
              final orderBottom =
                  hasFloatingNav ? runningOrderNavClearance(context) : 16.0;

              return Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _screens.length,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return _screens[index];
                    },
                  ),
                  if (showRunning)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: orderBottom,
                      child: RunningOrderViewWidget(
                        reversOrder: reversOrder,
                        isExpanded: _isBottomSheetExpanded,
                        onMoreClick: () {
                          orderController.setBottomSheetExpanded(true);
                          setState(() => _isBottomSheetExpanded = true);
                          if (orderController.showOneOrder) {
                            orderController.showOrders();
                          }
                        },
                        onCollapse: () {
                          orderController.setBottomSheetExpanded(false);
                          setState(() => _isBottomSheetExpanded = false);
                          if (!orderController.showOneOrder) {
                            orderController.showOrders();
                          }
                        },
                      ),
                    ),
                ],
              );
            }),
            if (!ResponsiveHelper.isDesktop(context))
              Positioned(
                // Only the island occupies space â€” side/bottom gaps stay clear
                // so home content shows through around the solid pill.
                left: 16,
                right: 16,
                bottom: MediaQuery.paddingOf(context).bottom + 12,
                child: _buildFloatingBottomNav(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingBottomNav(BuildContext context) {
    final theme = Theme.of(context);
    // Solid floating island; surroundings are transparent (Stack overlay).
    return Material(
      color: theme.cardColor,
      elevation: 14,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 68,
        child: Row(children: [
          BottomNavItem(
              icon: Images.home,
              activeIcon: Images.home_fill,
              label: "home".tr,
              isSelected: _pageIndex == 0,
              onTap: () => _setPage(0)),
          GetBuilder<OrderController>(builder: (orderController) {
            final runningOrderCount =
                orderController.runningOrderList?.length ?? 0;
            return BottomNavItem(
                icon: Images.order,
                activeIcon: Images.order_fill,
                label: "orders".tr,
                isSelected: _pageIndex == 1,
                count: runningOrderCount > 0 ? runningOrderCount : null,
                onTap: () => _setPage(1));
          }),
          GetBuilder<CartController>(builder: (cartController) {
            return BottomNavItem(
                icon: Images.shopping_cart,
                activeIcon: Images.shopping_cart_fill,
                label: 'cart'.tr,
                isSelected: _pageIndex == 3,
                count: cartController.cartList.isNotEmpty
                    ? cartController.cartList.length
                    : null,
                onTap: () {
                  if (cartController.cartList.isNotEmpty) {
                    Get.toNamed(RouteHelper.getCartRoute());
                  } else {
                    _setPage(3);
                  }
                });
          }),
          BottomNavItem(
              icon: Images.profile,
              activeIcon: Images.profile_fill,
              label: 'profile'.tr,
              isSelected: _pageIndex == 4,
              onTap: () => _setPage(4)),
        ]),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _isLogin && _pageIndex == 0) {
      // Refresh running orders when app comes back to foreground
      // Load both orders and then check once to avoid duplicate checks
      Future.wait([
        Get.find<OrderController>().getRunningOrders(1, notify: true),
        Get.find<OrderController>().getHistoryOrders(1, notify: false),
      ]).then((_) {
        _checkForDeliveredOrder();
        _checkForRefundedOrder();
      });
      // Restart timer when app resumes
      _startOrderRefreshTimer();
      // Restart immediate message check timer when app resumes
      _startImmediateMessageCheckTimer();

      // Restart immediate message polling when app resumes
      InAppMessagingHelper.startImmediateMessagePolling();

      // Check for in-app messages when app resumes
      Future.delayed(const Duration(milliseconds: 500), () {
        InAppMessagingHelper.fetchAndDisplayMessages(screen: 'dashboard');
        // Also check for immediate messages immediately
        InAppMessagingHelper.checkForImmediateMessages();
      });
    } else if (state == AppLifecycleState.paused) {
      // Stop timer when app is paused to save resources
      _stopOrderRefreshTimer();
      _stopImmediateMessageCheckTimer();
      // Stop immediate message polling when app is paused
      InAppMessagingHelper.stopImmediateMessagePolling();
    }
  }

  void _startOrderRefreshTimer() {
    // Cancel any existing timer
    _orderRefreshTimer?.cancel();

    // Refresh orders every 5 seconds when on home page and logged in
    _orderRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _isLogin && _pageIndex == 0) {
        // Only refresh if we're on the home page
        // Use silentRefresh=true to prevent flickering - keeps existing list until new data arrives
        Future.wait([
          Get.find<OrderController>()
              .getRunningOrders(1, notify: true, silentRefresh: true),
          Get.find<OrderController>().getHistoryOrders(1, notify: false),
        ]).then((_) {
          _checkForDeliveredOrder();
          _checkForRefundedOrder();
        });
      } else if (!mounted || !_isLogin || _pageIndex != 0) {
        // Stop timer if not on home page or not logged in
        timer.cancel();
      }
    });
  }

  void _checkForDeliveredOrder() async {
    if (!_isLogin ||
        _pageIndex != 0 ||
        !mounted ||
        _isCheckingDeliveredOrder ||
        _isPopupShowing ||
        _isAnyPopupShowing) {
      return;
    }

    _isCheckingDeliveredOrder = true;

    try {
      final orderController = Get.find<OrderController>();
      final dashboardController = Get.find<DashboardController>();

      // Ensure history orders are loaded
      if (orderController.historyOrderList == null) {
        await orderController.getHistoryOrders(1, notify: false);
      }

      OrderModel? deliveredOrder;

      // First check history orders (most likely place for delivered orders)
      if (orderController.historyOrderList != null &&
          orderController.historyOrderList!.isNotEmpty) {
        // Find the most recent delivered order (first one in the list is usually most recent)
        for (var order in orderController.historyOrderList!) {
          if (order.orderStatus == AppConstants.delivered && order.id != null) {
            deliveredOrder = order;
            break; // Get the first (most recent) delivered order
          }
        }
      }

      // Also check running orders in case an order just got delivered
      // (it might still be in running orders before moving to history)
      if (deliveredOrder == null &&
          orderController.runningOrderList != null &&
          orderController.runningOrderList!.isNotEmpty) {
        for (var order in orderController.runningOrderList!) {
          if (order.orderStatus == AppConstants.delivered && order.id != null) {
            deliveredOrder = order;
            break;
          }
        }
      }

      // Check if we have a delivered order that hasn't been dismissed
      if (deliveredOrder != null &&
          deliveredOrder.id != null &&
          !dashboardController.isOrderDismissed(deliveredOrder.id!) &&
          !_isAnyPopupShowing) {
        // Only show if this is a new order we haven't checked yet
        if (_lastCheckedOrderId != deliveredOrder.id) {
          _lastCheckedOrderId = deliveredOrder.id;
          _showDeliverySuccessPopup(deliveredOrder, dashboardController);
        }
      }
    } finally {
      _isCheckingDeliveredOrder = false;
    }
  }

  void _showDeliverySuccessPopup(
      OrderModel order, DashboardController dashboardController) {
    // Prevent showing multiple popups
    if (_isPopupShowing || _isAnyPopupShowing) {
      _isCheckingDeliveredOrder = false;
      return;
    }

    _isPopupShowing = true;
    _isAnyPopupShowing = true;

    // Show popup after a short delay to ensure UI is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isLogin && _pageIndex == 0 && _isPopupShowing) {
        Get.dialog(
          DeliverySuccessPopupWidget(
            order: order,
            onDismiss: () async {
              // Mark order as dismissed
              await dashboardController
                  .addDismissedDeliveryPopupOrder(order.id!);
              _isPopupShowing = false;
              _isAnyPopupShowing = false;
              Get.back();
            },
            onReview: () async {
              // Mark order as dismissed and navigate to order details
              await dashboardController
                  .addDismissedDeliveryPopupOrder(order.id!);
              _isPopupShowing = false;
              _isAnyPopupShowing = false;
              Get.back(); // Close dialog first
              await Get.toNamed(
                RouteHelper.getOrderDetailsRoute(order.id),
                arguments: OrderDetailsScreen(
                  orderId: order.id,
                  orderModel: order,
                ),
              );
            },
          ),
          barrierDismissible: false,
        ).then((_) {
          // Reset flag when dialog is closed
          _isPopupShowing = false;
          _isAnyPopupShowing = false;
        });
      } else {
        _isPopupShowing = false;
        _isAnyPopupShowing = false;
      }
    });
  }

  void _checkForRefundedOrder() async {
    if (!_isLogin ||
        _pageIndex != 0 ||
        !mounted ||
        _isCheckingRefundedOrder ||
        _isRefundPopupShowing ||
        _isPopupShowing ||
        _isAnyPopupShowing) {
      return;
    }

    _isCheckingRefundedOrder = true;

    try {
      final orderController = Get.find<OrderController>();
      final dashboardController = Get.find<DashboardController>();

      // Ensure history orders are loaded
      if (orderController.historyOrderList == null) {
        await orderController.getHistoryOrders(1, notify: false);
      }

      OrderModel? refundedOrder;

      // First check history orders (most likely place for refunded orders)
      if (orderController.historyOrderList != null &&
          orderController.historyOrderList!.isNotEmpty) {
        // Find the most recent refunded order
        for (var order in orderController.historyOrderList!) {
          if (order.orderStatus == 'refunded' && order.id != null) {
            refundedOrder = order;
            break; // Get the first (most recent) refunded order
          }
        }
      }

      // Also check running orders in case an order just got refunded
      if (refundedOrder == null &&
          orderController.runningOrderList != null &&
          orderController.runningOrderList!.isNotEmpty) {
        for (var order in orderController.runningOrderList!) {
          if (order.orderStatus == 'refunded' && order.id != null) {
            refundedOrder = order;
            break;
          }
        }
      }

      // Check if we have a refunded order that hasn't been dismissed
      if (refundedOrder != null &&
          refundedOrder.id != null &&
          !dashboardController.isRefundOrderDismissed(refundedOrder.id!) &&
          !_isAnyPopupShowing) {
        // Only show if this is a new order we haven't checked yet
        if (_lastCheckedRefundOrderId != refundedOrder.id) {
          _lastCheckedRefundOrderId = refundedOrder.id;
          _showRefundSuccessPopup(refundedOrder, dashboardController);
        }
      }
    } finally {
      _isCheckingRefundedOrder = false;
    }
  }

  void _showRefundSuccessPopup(
      OrderModel order, DashboardController dashboardController) {
    // Prevent showing multiple popups
    if (_isRefundPopupShowing || _isPopupShowing || _isAnyPopupShowing) {
      _isCheckingRefundedOrder = false;
      return;
    }

    _isRefundPopupShowing = true;
    _isAnyPopupShowing = true;

    // Show popup immediately (no delay as per user request)
    if (mounted && _isLogin && _pageIndex == 0 && _isRefundPopupShowing) {
      Get.dialog(
        RefundSuccessPopupWidget(
          order: order,
          onDismiss: () async {
            // Mark order as dismissed
            await dashboardController.addDismissedRefundPopupOrder(order.id!);
            _isRefundPopupShowing = false;
            _isAnyPopupShowing = false;
            Get.back();
          },
          onViewOrder: () async {
            // Mark order as dismissed and navigate to order details
            await dashboardController.addDismissedRefundPopupOrder(order.id!);
            _isRefundPopupShowing = false;
            _isAnyPopupShowing = false;
            Get.back(); // Close dialog first
            await Get.toNamed(
              RouteHelper.getOrderDetailsRoute(order.id),
              arguments: OrderDetailsScreen(
                orderId: order.id,
                orderModel: order,
              ),
            );
          },
        ),
        barrierDismissible: false,
      ).then((_) {
        // Reset flag when dialog is closed
        _isRefundPopupShowing = false;
        _isAnyPopupShowing = false;
      });
    } else {
      _isRefundPopupShowing = false;
      _isAnyPopupShowing = false;
    }
  }

  void _stopOrderRefreshTimer() {
    _orderRefreshTimer?.cancel();
    _orderRefreshTimer = null;
  }

  void _startImmediateMessageCheckTimer() {
    // Cancel any existing timer
    _immediateMessageCheckTimer?.cancel();

    // Check for immediate messages every 2 seconds when on dashboard
    _immediateMessageCheckTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _pageIndex == 0) {
        // Only check if we're on the dashboard page
        InAppMessagingHelper.checkForImmediateMessages();
      } else if (!mounted || _pageIndex != 0) {
        // Stop timer if not on dashboard page
        timer.cancel();
      }
    });
  }

  void _stopImmediateMessageCheckTimer() {
    _immediateMessageCheckTimer?.cancel();
    _immediateMessageCheckTimer = null;
  }

  @override
  void dispose() {
    _stopOrderRefreshTimer();
    _stopImmediateMessageCheckTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _setPage(int pageIndex) {
    setState(() {
      _pageController!.jumpToPage(pageIndex);
      _pageIndex = pageIndex;
    });

    // Refresh running orders when returning to home page
    if (pageIndex == 0 && _isLogin) {
      Get.find<OrderController>().showRunningOrders();
      // Load both orders and then check once to avoid duplicate checks
      Future.wait([
        Get.find<OrderController>().getRunningOrders(1, notify: true),
        Get.find<OrderController>().getHistoryOrders(1, notify: false),
      ]).then((_) {
        _checkForDeliveredOrder();
        _checkForRefundedOrder();
      });
      // Restart timer when returning to home page
      _startOrderRefreshTimer();
      // Restart immediate message check timer when returning to dashboard
      _startImmediateMessageCheckTimer();

      // Check for in-app messages when returning to dashboard
      Future.delayed(const Duration(milliseconds: 500), () {
        InAppMessagingHelper.fetchAndDisplayMessages(screen: 'dashboard');
        // Also check for immediate messages immediately
        InAppMessagingHelper.checkForImmediateMessages();
      });
    } else {
      // Stop timer when leaving home page
      _stopOrderRefreshTimer();
      _stopImmediateMessageCheckTimer();
    }
  }
}
