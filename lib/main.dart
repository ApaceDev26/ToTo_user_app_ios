import 'dart:async';
import 'dart:io';
import 'package:toto_user/features/auth/controllers/auth_controller.dart';
import 'package:toto_user/features/cart/controllers/cart_controller.dart';
import 'package:toto_user/features/language/controllers/localization_controller.dart';
import 'package:toto_user/features/notification/domain/models/notification_body_model.dart';
import 'package:toto_user/features/splash/controllers/splash_controller.dart';
import 'package:toto_user/features/splash/controllers/theme_controller.dart';
import 'package:toto_user/features/favourite/controllers/favourite_controller.dart';
import 'package:toto_user/features/splash/domain/models/deep_link_body.dart';
import 'package:toto_user/helper/notification_helper.dart';
import 'package:toto_user/helper/responsive_helper.dart';
import 'package:toto_user/helper/route_helper.dart';
import 'package:toto_user/helper/system_ui_helper.dart';
import 'package:toto_user/design_system/app_theme.dart';
import 'package:toto_user/util/app_constants.dart';
import 'package:toto_user/util/messages.dart';
import 'package:toto_user/common/widgets/cookies_view_widget.dart';
import 'package:toto_user/common/widgets/not_found_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:meta_seo/meta_seo.dart';
import 'package:url_strategy/url_strategy.dart';
import 'firebase_options.dart';
import 'helper/get_di.dart' as di;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  if (ResponsiveHelper.isMobilePhone()) {
    HttpOverrides.global = MyHttpOverrides();
  }
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  // // Pass all uncaught "fatal" errors from the framework to Crashlytics
  // FlutterError.onError = (errorDetails) {
  //   FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  // };
  // // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  // PlatformDispatcher.instance.onError = (error, stack) {
  //   FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  //   return true;
  // };

  // Note: Navigation bar styling is now handled per-screen using AnnotatedRegion
  // in the build method below. This ensures theme-aware colors and proper
  // Android 10+ compatibility.

  DeepLinkBody? linkBody;

  // Initialize Firebase with proper error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (GetPlatform.isWeb) {
      MetaSEO().config();
    }
  } catch (e) {
    // If Firebase is already initialized, that's fine
    if (e.toString().contains('duplicate-app')) {
      // Firebase already initialized, continue normally
      if (GetPlatform.isWeb) {
        MetaSEO().config();
      }
    } else {
      // Re-throw other errors
      rethrow;
    }
  }

  // Prefetch Lumen Atelier fonts (non-blocking failure)
  try {
    await AppTheme.prefetchFonts();
  } catch (_) {}

  // Initialize dependencies and load languages concurrently with app startup
  Map<String, Map<String, String>> languages = await di.init();

  NotificationBodyModel? body;
  try {
    if (GetPlatform.isMobile) {
      final RemoteMessage? remoteMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (remoteMessage != null) {
        body = NotificationHelper.convertNotification(remoteMessage.data);
      }
      await NotificationHelper.initialize(flutterLocalNotificationsPlugin);
      FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
    }
  } catch (_) {}

  if (ResponsiveHelper.isWeb()) {
    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: "452131619626499",
      cookie: true,
      xfbml: true,
      version: "v13.0",
    );
  }
  runApp(MyApp(languages: languages, body: body, linkBody: linkBody));
}

class MyApp extends StatefulWidget {
  final Map<String, Map<String, String>>? languages;
  final NotificationBodyModel? body;
  final DeepLinkBody? linkBody;
  const MyApp(
      {super.key,
      required this.languages,
      required this.body,
      required this.linkBody});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _initialRoute;
  bool _isRouteValid = false;
  bool _shouldShowNotFound = false;

  @override
  void initState() {
    super.initState();

    // Capture browser URL BEFORE GetMaterialApp renders
    if (GetPlatform.isWeb) {
      _initialRoute = _getCurrentWebRoute();
      _isRouteValid = _checkRouteExists(_initialRoute);
      _shouldShowNotFound = !_isRouteValid &&
          _initialRoute != null &&
          _initialRoute != RouteHelper.initial;
    }

    _route();
  }

  String? _getCurrentWebRoute() {
    try {
      // Get current browser path
      final uri = Uri.base;
      String path = uri.path;

      // Remove leading slash if it's just '/'
      if (path == '/') {
        return RouteHelper.initial;
      }

      // Return the path with query parameters if any
      if (uri.query.isNotEmpty) {
        return '$path?${uri.query}';
      }

      return path;
    } catch (e) {
      return null;
    }
  }

  bool _checkRouteExists(String? route) {
    if (route == null) return false;
    if (route == RouteHelper.initial || route == '/') return true;

    // Extract path without query parameters
    final uri = Uri.tryParse(route);
    if (uri == null) return false;

    String path = uri.path;
    if (path.isEmpty || path == '/') return true;

    // Get all route names
    final allRouteNames = RouteHelper.routes.map((r) => r.name).toList();

    // Check exact match first
    if (allRouteNames.contains(path)) {
      return true;
    }

    // Check if path starts with any route name (for parameterized routes)
    for (var routeName in allRouteNames) {
      if (routeName == '/' || routeName == RouteHelper.initial) continue;

      if (path.startsWith(routeName)) {
        // Check if it's a valid parameterized route
        final remaining = path.substring(routeName.length);
        if (remaining.isEmpty ||
            remaining.startsWith('/') ||
            remaining.startsWith('?')) {
          return true;
        }
      }
    }

    return false;
  }

  Future<void> _route() async {
    if (GetPlatform.isWeb) {
      Get.find<SplashController>().initSharedData();
      if (!Get.find<AuthController>().isLoggedIn() &&
          !Get.find<AuthController>()
              .isGuestLoggedIn() /*&& !ResponsiveHelper.isDesktop(Get.context!)*/) {
        await Get.find<AuthController>().guestLogin();
      }
      if (Get.find<AuthController>().isLoggedIn() ||
          Get.find<AuthController>().isGuestLoggedIn()) {
        Get.find<CartController>().getCartDataOnline();
      }
      Get.find<SplashController>().getConfigData(fromMainFunction: true);
      if (Get.find<AuthController>().isLoggedIn()) {
        Get.find<AuthController>().updateToken();
        await Get.find<FavouriteController>().getFavouriteList();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(builder: (themeController) {
      return GetBuilder<LocalizationController>(builder: (localizeController) {
        return GetBuilder<SplashController>(builder: (splashController) {
          // CRITICAL FIX: Show NotFoundWidget for unknown routes BEFORE GetMaterialApp
          // This check happens in initState, so it's available immediately
          if (GetPlatform.isWeb &&
              _shouldShowNotFound &&
              splashController.configModel != null) {
            return MaterialApp(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: themeController.darkTheme
                  ? AppTheme.dark()
                  : AppTheme.light(),
              home: const Scaffold(
                body: NotFoundWidget(),
              ),
            );
          }

          return (GetPlatform.isWeb && splashController.configModel == null)
              ? const SizedBox()
              : GetMaterialApp(
                  title: AppConstants.appName,
                  debugShowCheckedModeBanner: false,
                  navigatorKey: Get.key,
                  scrollBehavior: const MaterialScrollBehavior().copyWith(
                    dragDevices: {
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.touch
                    },
                  ),
                  theme: themeController.darkTheme
                      ? AppTheme.dark()
                      : AppTheme.light(),
                  locale: localizeController.locale,
                  translations: Messages(languages: widget.languages),
                  fallbackLocale: Locale(
                      AppConstants.languages[0].languageCode!,
                      AppConstants.languages[0].countryCode),
                  // Always use captured browser URL for web
                  // The pre-check above will handle unknown routes
                  initialRoute: GetPlatform.isWeb
                      ? (_initialRoute ?? RouteHelper.initial)
                      : RouteHelper.getSplashRoute(
                          widget.body, widget.linkBody),
                  getPages: RouteHelper.routes,
                  unknownRoute: GetPage(
                    name: '/notfound',
                    page: () => const NotFoundWidget(),
                  ),
                  defaultTransition: Transition.topLevel,
                  transitionDuration: const Duration(milliseconds: 500),
                  builder: (BuildContext context, widget) {
                    // CRITICAL: If route is unknown, replace widget with NotFoundWidget
                    if (GetPlatform.isWeb &&
                        _shouldShowNotFound &&
                        splashController.configModel != null) {
                      // Check current browser URL to confirm we're still on unknown route
                      final currentPath = Uri.base.path;
                      final expectedPath = _initialRoute != null
                          ? Uri.parse(_initialRoute!).path
                          : '';

                      if (currentPath == expectedPath &&
                          currentPath != '/' &&
                          currentPath.isNotEmpty) {
                        // Return NotFoundWidget directly instead of the routed widget
                        return const Scaffold(
                          body: NotFoundWidget(),
                        );
                      }
                    }

                    // জেসচার বারকে সম্পূর্ণ ট্রান্সপারেন্ট করা হলো যাতে অ্যাপের কন্টেন্ট একদম স্ক্রিনের শেষ প্রান্ত পর্যন্ত দেখা যায়
                    const Color navBarColor = Colors.transparent;

                    return MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: const TextScaler.linear(1)),
                      child: SystemUIHelper.wrapWithSystemUI(
                        navigationBarColor: navBarColor,
                        // Icon brightness is automatically calculated based on color luminance
                        // You can override it by passing: iconBrightness: Brightness.light
                        child: Material(
                            child: SafeArea(
                          top: false,
                          bottom: false, // Edge-to-edge এর ব্যাকগ্রাউন্ড ম্যাচ করার জন্য কন্টেন্টকে বটম সেফএরিয়া লক থেকে মুক্ত করা হলো
                          child: Stack(children: [
                            widget!,
                            GetBuilder<SplashController>(
                                builder: (splashController) {
                              if (!splashController.savedCookiesData ||
                                  !splashController.getAcceptCookiesStatus(
                                      splashController
                                              .configModel?.cookiesText ??
                                          "")) {
                                return ResponsiveHelper.isWeb()
                                    ? const Align(
                                        alignment: Alignment.bottomCenter,
                                        child: CookiesViewWidget())
                                    : const SizedBox();
                              } else {
                                return const SizedBox();
                              }
                            })
                          ]),
                        )),
                      ),
                    );
                  });
        });
      });
    });
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
