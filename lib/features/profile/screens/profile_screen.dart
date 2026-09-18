import 'package:toto_user/common/widgets/custom_app_bar_widget.dart';
import 'package:toto_user/common/widgets/custom_button_widget.dart';
import 'package:toto_user/design_system/design_system.dart';
import 'package:toto_user/features/auth/controllers/auth_controller.dart';
import 'package:toto_user/features/order/controllers/order_controller.dart';
import 'package:toto_user/features/profile/controllers/profile_controller.dart';
import 'package:toto_user/features/profile/widgets/account_deletion_bottom_sheet.dart';
import 'package:toto_user/features/profile/widgets/notification_status_change_bottom_sheet.dart';
import 'package:toto_user/features/profile/widgets/profile_button_widget.dart';
import 'package:toto_user/features/profile/widgets/profile_card_widget.dart';
import 'package:toto_user/features/profile/widgets/web_profile_widget.dart';
import 'package:toto_user/features/splash/controllers/splash_controller.dart';
import 'package:toto_user/features/auth/widgets/auth_dialog_widget.dart';
import 'package:toto_user/helper/date_converter.dart';
import 'package:toto_user/helper/price_converter.dart';
import 'package:toto_user/helper/responsive_helper.dart';
import 'package:toto_user/helper/route_helper.dart';
import 'package:toto_user/util/app_constants.dart';
import 'package:toto_user/util/dimensions.dart';
import 'package:toto_user/util/images.dart';
import 'package:toto_user/common/widgets/custom_image_widget.dart';
import 'package:toto_user/common/widgets/footer_view_widget.dart';
import 'package:toto_user/common/widgets/menu_drawer_widget.dart';
import 'package:toto_user/helper/in_app_messaging_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _initCall();

    // Trigger in-app messages for profile screen
    Future.delayed(const Duration(milliseconds: 800), () {
      InAppMessagingHelper.triggerForScreen('profile');
      // Also check for immediate messages
      InAppMessagingHelper.checkForImmediateMessages();
    });
  }

  void _initCall() {
    if (Get.find<AuthController>().isLoggedIn() &&
        Get.find<ProfileController>().userInfoModel == null) {
      Get.find<ProfileController>().getUserInfo();
    }
    if (Get.find<AuthController>().isLoggedIn() &&
        Get.find<OrderController>().runningOrderList == null) {
      Get.find<OrderController>().getRunningOrders(1, notify: false, limit: 5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    bool isLoggedIn = Get.find<AuthController>().isLoggedIn();
    final bool showWalletCard =
        Get.find<SplashController>().configModel!.customerWalletStatus == 1 ||
            Get.find<SplashController>().configModel!.loyaltyPointStatus == 1;

    return Scaffold(
      appBar: CustomAppBarWidget(title: 'profile'.tr),
      endDrawer: isDesktop ? const MenuDrawerWidget() : null,
      endDrawerEnableOpenDragGesture: false,
      backgroundColor: isDesktop ? colors.surface : colors.canvas,
      body: GetBuilder<OrderController>(builder: (orderController) {
        return GetBuilder<ProfileController>(builder: (profileController) {
          return (isLoggedIn &&
                  profileController.userInfoModel == null &&
                  (orderController.runningOrderList == null))
              ? Center(
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.accent,
                    ),
                  ),
                )
              : Center(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: FooterViewWidget(
                      minHeight: isLoggedIn
                          ? isDesktop
                              ? 0.4
                              : 0.6
                          : 0.35,
                      child: (isLoggedIn && isDesktop)
                          ? WebProfileWidget(
                              profileController: profileController,
                              orderController: orderController)
                          : isLoggedIn
                              ? Container(
                                  color: const Color(0xFFEAF2FC),
                                  width: Dimensions.webMaxWidth,
                                  constraints: BoxConstraints(
                                      minHeight: context.height - 80),
                                  child: Center(
                                    child: Column(children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.fromLTRB(
                                            AppSpacing.x2l,
                                            AppSpacing.x3l,
                                            AppSpacing.x2l,
                                            AppSpacing.x3l + AppSpacing.md),
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF102C55),
                                              Color(0xFF225B99),
                                            ],
                                          ),
                                        ),
                                        child: Row(children: [
                                          Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: colors.accent,
                                                  width: 2),
                                            ),
                                            child: ClipOval(
                                                child: CustomImageWidget(
                                            placeholder: isLoggedIn
                                                ? Images.profilePlaceholder
                                                : Images.guestIcon,
                                            image:
                                                '${(profileController.userInfoModel != null && isLoggedIn) ? profileController.userInfoModel!.imageFullUrl : ''}',
                                            height: 70,
                                            width: 70,
                                            fit: BoxFit.cover,
                                            imageColor: isLoggedIn
                                                ? colors.inkFaint
                                                : null,
                                          )),
                                          ),
                                          const SizedBox(width: AppSpacing.lg),
                                          Expanded(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    isLoggedIn
                                                        ? '${profileController.userInfoModel?.fName ?? ''} ${profileController.userInfoModel?.lName ?? ''}'
                                                        : 'guest_user'.tr,
                                                    style: AppTypography
                                                        .titleMd(Colors.white),
                                                  ),
                                                  const SizedBox(
                                                      height: AppSpacing.xs),
                                                  isLoggedIn
                                                      ? Text(
                                                          profileController
                                                                      .userInfoModel
                                                                      ?.createdAt !=
                                                                  null
                                                              ? '${'joined'.tr} ${DateConverter.containTAndZToUTCFormat(profileController.userInfoModel!.createdAt!)}'
                                                              : '',
                                                          style: AppTypography
                                                              .bodySm(
                                                                  const Color(0xFFD8E9FF)),
                                                        )
                                                      : InkWell(
                                                          onTap: () async {
                                                            if (!isDesktop) {
                                                              await Get.toNamed(
                                                                  RouteHelper
                                                                      .getSignInRoute(
                                                                          Get.currentRoute));
                                                            } else {
                                                              Get.dialog(const Center(
                                                                      child: AuthDialogWidget(
                                                                          exitFromApp:
                                                                              false,
                                                                          backFromThis:
                                                                              false)))
                                                                  .then(
                                                                      (value) {
                                                                _initCall();
                                                                setState(() {});
                                                              });
                                                            }
                                                          },
                                                          child: Text(
                                                            'login_to_view_all_feature'
                                                                .tr,
                                                            style: AppTypography
                                                                .labelMd(colors
                                                                    .accent),
                                                          ),
                                                        ),
                                                ]),
                                          ),
                                          isLoggedIn
                                              ? InkWell(
                                                  onTap: () => Get.toNamed(
                                                      RouteHelper
                                                          .getUpdateProfileRoute()),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: colors.accent,
                                                      boxShadow:
                                                          AppShadows.of(
                                                              context, 1),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.all(
                                                            AppSpacing.sm),
                                                    child: Icon(
                                                        Icons.edit_outlined,
                                                        size: AppIcons.md,
                                                        color: Colors.white),
                                                  ),
                                                )
                                              : InkWell(
                                                  onTap: () async {
                                                    if (!isDesktop) {
                                                      await Get.toNamed(RouteHelper
                                                          .getSignInRoute(Get
                                                              .currentRoute));
                                                    } else {
                                                      Get.dialog(const Center(
                                                              child: AuthDialogWidget(
                                                                  exitFromApp:
                                                                      false,
                                                                  backFromThis:
                                                                      false)))
                                                          .then((value) {
                                                        _initCall();
                                                        setState(() {});
                                                      });
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          AppRadius.mdAll,
                                                      color: colors.accent,
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: AppSpacing.sm,
                                                        horizontal:
                                                            AppSpacing.xl),
                                                    child: Text(
                                                      'login'.tr,
                                                      style: AppTypography
                                                          .labelLg(colors
                                                              .onAccent),
                                                    ),
                                                  ),
                                                ),
                                        ]),
                                      ),
                                      Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                    top: Radius.circular(30)),
                                            color: colors.surface,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.xl,
                                              vertical: AppSpacing.xl),
                                          child: Column(children: [
                                            (showWalletCard && isLoggedIn)
                                                ? Row(children: [
                                                    Get.find<SplashController>()
                                                                .configModel!
                                                                .loyaltyPointStatus ==
                                                            1
                                                        ? Expanded(
                                                            child:
                                                                ProfileCardWidget(
                                                            image: Images
                                                                .loyaltyIcon,
                                                            data: profileController
                                                                        .userInfoModel
                                                                        ?.loyaltyPoint !=
                                                                    null
                                                                ? profileController
                                                                    .userInfoModel!
                                                                    .loyaltyPoint
                                                                    .toString()
                                                                : '0',
                                                            title:
                                                                'loyalty_points'
                                                                    .tr,
                                                          ))
                                                        : const SizedBox(),
                                                    SizedBox(
                                                        width: Get.find<SplashController>()
                                                                    .configModel!
                                                                    .loyaltyPointStatus ==
                                                                1
                                                            ? AppSpacing.sm
                                                            : 0),
                                                    isLoggedIn
                                                        ? Expanded(
                                                            child:
                                                                ProfileCardWidget(
                                                            image: Images
                                                                .shoppingBagIcon,
                                                            data: profileController
                                                                        .userInfoModel
                                                                        ?.orderCount !=
                                                                    null
                                                                ? profileController
                                                                    .userInfoModel!
                                                                    .orderCount
                                                                    .toString()
                                                                : '0',
                                                            title: 'total_order'
                                                                .tr,
                                                          ))
                                                        : const SizedBox(),
                                                    SizedBox(
                                                        width: Get.find<SplashController>()
                                                                    .configModel!
                                                                    .customerWalletStatus ==
                                                                1
                                                            ? AppSpacing.sm
                                                            : 0),
                                                    Get.find<SplashController>()
                                                                .configModel!
                                                                .customerWalletStatus ==
                                                            1
                                                        ? Expanded(
                                                            child:
                                                                ProfileCardWidget(
                                                            image: Images
                                                                .walletProfile,
                                                            data: PriceConverter.convertPrice(profileController
                                                                        .userInfoModel
                                                                        ?.walletBalance !=
                                                                    null
                                                                ? profileController
                                                                    .userInfoModel!
                                                                    .walletBalance
                                                                : 0),
                                                            title:
                                                                'wallet_balance'
                                                                    .tr,
                                                          ))
                                                        : const SizedBox(),
                                                  ])
                                                : const SizedBox(),
                                            const SizedBox(
                                                height: AppSpacing.xl),
                                            isLoggedIn
                                                ? GetBuilder<AuthController>(
                                                    builder: (authController) {
                                                    return ProfileButtonWidget(
                                                      icon: Icons.notifications,
                                                      title: 'notification'.tr,
                                                      isButtonActive:
                                                          authController
                                                              .notification,
                                                      onTap: () {
                                                        Get.bottomSheet(
                                                            const NotificationStatusChangeBottomSheet());
                                                        // authController.setNotificationActive(!authController.notification);
                                                      },
                                                    );
                                                  })
                                                : const SizedBox(),
                                            SizedBox(
                                                height: isLoggedIn
                                                    ? AppSpacing.sm
                                                    : 0),
                                            isLoggedIn
                                                ? ProfileButtonWidget(
                                                    icon: Icons.lock,
                                                    title: 'change_password'.tr,
                                                    onTap: () {
                                                      Get.toNamed(RouteHelper
                                                          .getResetPasswordRoute(
                                                              phone: '',
                                                              email: '',
                                                              token: '',
                                                              page:
                                                                  'password-change'));
                                                    })
                                                : const SizedBox(),
                                            SizedBox(
                                                height: isLoggedIn
                                                    ? AppSpacing.sm
                                                    : 0),
                                            isLoggedIn
                                                ? ProfileButtonWidget(
                                                    icon: Icons.delete,
                                                    iconImage:
                                                        Images.profileDelete,
                                                    title: 'delete_account'.tr,
                                                    onTap: () {
                                                      showModalBottomSheet(
                                                        isScrollControlled:
                                                            true,
                                                        useRootNavigator: true,
                                                        context: Get.context!,
                                                        backgroundColor:
                                                            colors.surface,
                                                        shape:
                                                            const RoundedRectangleBorder(
                                                          borderRadius:
                                                              AppRadius
                                                                  .sheetTop,
                                                        ),
                                                        builder: (context) {
                                                          return ConstrainedBox(
                                                            constraints: BoxConstraints(
                                                                maxHeight: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .height *
                                                                    0.8),
                                                            child:
                                                                AccountDeletionBottomSheet(
                                                              profileController:
                                                                  profileController,
                                                              isRunningOrderAvailable: orderController
                                                                          .runningOrderList !=
                                                                      null &&
                                                                  orderController
                                                                      .runningOrderList!
                                                                      .isNotEmpty,
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                                  )
                                                : const SizedBox(),
                                            SizedBox(
                                                height: isLoggedIn
                                                    ? AppSpacing.xl
                                                    : 0),
                                            const SizedBox(height: AppSpacing.x2l),
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text('${'version'.tr}:',
                                                      style: AppTypography
                                                          .labelSm(colors
                                                              .inkFaint)),
                                                  const SizedBox(
                                                      width: AppSpacing.xs),
                                                  Text(
                                                      AppConstants.appVersion
                                                          .toString(),
                                                      style: AppTypography
                                                          .labelSm(
                                                              colors.inkMuted)),
                                                ]),
                                          ]),
                                      ),
                                    ]),
                                  ),
                                )
                              : Container(
                                  width: Dimensions.webMaxWidth,
                                  height: context.height - 87,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF102C55),
                                        Color(0xFF225B99),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 360,
                                      margin: const EdgeInsets.all(AppSpacing.xl),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.x2l,
                                          vertical: AppSpacing.x3l),
                                      decoration: BoxDecoration(
                                        color: colors.surface,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x33091B36),
                                            blurRadius: 26,
                                            offset: Offset(0, 12),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: colors.accent,
                                                  width: 2),
                                            ),
                                            child: ClipOval(
                                                child: CustomImageWidget(
                                            placeholder: isLoggedIn
                                                ? Images.profilePlaceholder
                                                : Images.guestIcon,
                                            image:
                                                '${(profileController.userInfoModel != null && isLoggedIn) ? profileController.userInfoModel!.imageFullUrl : ''}',
                                            height: 70,
                                            width: 70,
                                            fit: BoxFit.cover,
                                            imageColor: isLoggedIn
                                                ? colors.inkFaint
                                                : null,
                                          )),
                                          ),
                                          const SizedBox(
                                              height: AppSpacing.sm),
                                          Text(
                                            'guest_user'.tr,
                                            style: AppTypography.titleMd(
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? colors.ink
                                                    : const Color(0xFF102C55)),
                                          ),
                                          const SizedBox(
                                              height: AppSpacing.sm),
                                          Text(
                                              'currently_you_are_in_guest_mode_please_login_to_view_all_the_features'
                                                  .tr,
                                              style: AppTypography.bodySm(
                                                  colors.inkMuted),
                                              textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(
                                              height: AppSpacing.x3l),
                                          CustomButtonWidget(
                                            buttonText: 'login'.tr,
                                            width: 150,
                                            onPressed: () async {
                                              if (!isDesktop) {
                                                await Get.toNamed(RouteHelper
                                                        .getSignInRoute(
                                                            Get.currentRoute))
                                                    ?.then((value) {
                                                  _initCall();
                                                  setState(() {});
                                                });
                                              } else {
                                                Get.dialog(const Center(
                                                        child: AuthDialogWidget(
                                                            exitFromApp: false,
                                                            backFromThis:
                                                                false)))
                                                    .then((value) {
                                                  _initCall();
                                                  setState(() {});
                                                });
                                              }
                                            },
                                          ),
                                        ]),
                                    ),
                                  ),
                                ),
                    ),
                  ),
                );
        });
      }),
    );
  }
}
