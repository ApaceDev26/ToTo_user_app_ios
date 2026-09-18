import 'package:latlong2/latlong.dart';
import 'package:toto_user/common/widgets/custom_image_widget.dart';
import 'package:toto_user/common/widgets/custom_snackbar_widget.dart';
import 'package:toto_user/design_system/design_system.dart';
import 'package:toto_user/features/auth/controllers/auth_controller.dart';
import 'package:toto_user/features/favourite/controllers/favourite_controller.dart';
import 'package:toto_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:toto_user/common/models/restaurant_model.dart';
import 'package:toto_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:toto_user/helper/price_converter.dart';
import 'package:toto_user/helper/route_helper.dart';
import 'package:toto_user/util/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RestaurantWidget extends StatelessWidget {
  final Restaurant? restaurant;
  final int index;
  final bool inStore;

  const RestaurantWidget({
    super.key,
    required this.restaurant,
    required this.index,
    this.inStore = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final r = restaurant!;

    return GetBuilder<RestaurantController>(builder: (restoCtrl) {
      final restaurantLatLng = LatLng(
        double.parse(r.latitude!),
        double.parse(r.longitude!),
      );

      if (!restoCtrl.hasRoadDistance(restaurantLatLng)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          restoCtrl.loadRoadDistance(
            restaurantLatLng,
            notify: true,
          );
        });
      }

      final distanceLabel = restoCtrl.formatRestaurantDistance(
        restaurantLatLng,
      );
      final open = restoCtrl.isOpenNow(r);
      final discount = restoCtrl.getDiscount(r) ?? 0;
      final discountType = restoCtrl.getDiscountType(r);

      String? offerLabel;
      if (r.freeDelivery ?? false) {
        offerLabel = 'free_delivery'.tr;
      } else if (discount > 0) {
        offerLabel = discountType == 'percent'
            ? '${discount.toStringAsFixed(0)}% OFF'
            : '-${PriceConverter.convertPrice(discount)}';
      }

      final eta = r.deliveryTime?.replaceAll('-min', ' min') ?? '';
      // যদি ডিস্ট্যান্স এখনো লোড না হয় তবে '...' দেখাবে যাতে ইউজার বুঝতে পারে ডেটা আসছে
      final distLabel = r.freeDelivery! ? 'free'.tr : (distanceLabel.isNotEmpty ? distanceLabel : '...');
      final ratingLabel = (r.ratingCount ?? 0) > 0
          ? r.avgRating!.toStringAsFixed(1)
          : '0.0';

      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.cardGap),
        child: Material(
          color: colors.surface,
          borderRadius: AppRadius.lgAll,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (r.restaurantStatus == 1) {
                Get.toNamed(
                  RouteHelper.getRestaurantRoute(r.id),
                  arguments: RestaurantScreen(restaurant: r),
                );
              } else {
                showCustomSnackBar('restaurant_is_not_available'.tr);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: colors.line.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: colors.ink.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                        child: CustomImageWidget(
                          image: r.coverPhotoFullUrl ?? '',
                          height: 125,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          isRestaurant: true,
                        ),
                      ),
                      
                      // Gradient Overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.35),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Status Badge
                      Positioned(
                        left: AppSpacing.sm,
                        top: AppSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: open ? colors.success : colors.danger,
                            borderRadius: AppRadius.smAll,
                            boxShadow: AppShadows.of(context, 1),
                          ),
                          child: Text(
                            open ? 'open_now'.tr : 'closed_now'.tr,
                            style: AppTypography.labelSm(Colors.white).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      
                      // Offer Tag
                      if (offerLabel != null)
                        Positioned(
                          right: AppSpacing.sm,
                          bottom: AppSpacing.sm,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.accent,
                              borderRadius: AppRadius.smAll,
                            ),
                            child: Text(
                              offerLabel,
                              style: AppTypography.labelSm(Colors.white).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                      // Favorite Button
                      Positioned(
                        top: AppSpacing.xs,
                        right: AppSpacing.xs,
                        child: GetBuilder<FavouriteController>(
                          builder: (favouriteController) {
                            final wished = favouriteController.wishRestIdList.contains(r.id);
                            return Material(
                              color: colors.surface.withValues(alpha: 0.9),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  if (Get.find<AuthController>().isLoggedIn()) {
                                    wished
                                        ? favouriteController.removeFromFavouriteList(r.id, true)
                                        : favouriteController.addToFavouriteList(null, r.id, true);
                                  } else {
                                    showCustomSnackBar('you_are_not_logged_in'.tr);
                                  }
                                },
                                child: SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Icon(
                                    wished ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    size: 16,
                                    color: wished ? colors.accent : colors.inkMuted,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Branded Logo (Increased Size: 64)
                      Positioned(
                        left: AppSpacing.md,
                        bottom: -22,
                        child: Container(
                          height: 64,
                          width: 64,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: CustomImageWidget(
                              image: r.logoFullUrl ?? '',
                              fit: BoxFit.cover,
                              isRestaurant: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.x3l, AppSpacing.md, AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                r.name ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleSm(colors.ink).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.accentSoft,
                                borderRadius: AppRadius.xsAll,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded, color: colors.accent, size: 14),
                                  const SizedBox(width: 2),
                                  Text(
                                    ratingLabel,
                                    style: AppTypography.labelMd(colors.accent),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 6),
                        
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 12, color: colors.inkFaint),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                r.address ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySm(colors.inkMuted),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Branded Meta Info Row (Fixed Distance KM)
                        Row(
                          children: [
                            _buildMetaItem(
                              context, 
                              Images.distanceKm, 
                              distLabel, 
                              colors.inkMuted,
                              isDistance: true,
                            ),
                            const SizedBox(width: AppSpacing.xl),
                            _buildMetaItem(
                              context, 
                              Images.restaurantDeliveryTimeIcon, 
                              eta, 
                              colors.inkMuted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMetaItem(BuildContext context, String imagePath, String label, Color color, {bool isDistance = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ডিস্ট্যান্স আইকনের জন্য কালার ফিল্টার সরিয়ে নেওয়া হলো যদি সেটি অরিজিনাল কালারড আইকন হয়
        Image.asset(imagePath, height: 16, width: 16, color: isDistance ? null : color),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.labelMd(color).copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class RestaurantShimmer extends StatelessWidget {
  final bool isEnable;
  const RestaurantShimmer({super.key, required this.isEnable});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.cardGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(height: 125, radius: AppRadius.lg),
          SizedBox(height: AppSpacing.md),
          AppSkeleton(width: 160, height: 14),
          SizedBox(height: AppSpacing.sm),
          AppSkeleton(width: 120, height: 12),
          SizedBox(height: AppSpacing.sm),
          AppSkeleton(width: 140, height: 12),
        ],
      ),
    );
  }
}
