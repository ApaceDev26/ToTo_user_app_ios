import 'package:latlong2/latlong.dart';
import 'package:toto_user/common/widgets/custom_image_widget.dart';
import 'package:toto_user/common/widgets/custom_snackbar_widget.dart';
import 'package:toto_user/common/widgets/hover_widgets/on_hover_widget.dart';
import 'package:toto_user/design_system/design_system.dart';
import 'package:toto_user/features/auth/controllers/auth_controller.dart';
import 'package:toto_user/features/favourite/controllers/favourite_controller.dart';
import 'package:toto_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:toto_user/common/models/restaurant_model.dart';
import 'package:toto_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:toto_user/helper/price_converter.dart';
import 'package:toto_user/helper/route_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Lumen Atelier web restaurant card — cinematic cover, floating logo, meta chips.
class WebRestaurantWidget extends StatelessWidget {
  final Restaurant? restaurant;
  const WebRestaurantWidget({super.key, this.restaurant});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final r = restaurant!;

    return GetBuilder<RestaurantController>(builder: (restoCtrl) {
    final distanceLabel = restoCtrl.formatRestaurantDistance(
      LatLng(double.parse(r.latitude!), double.parse(r.longitude!)),
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

    return OnHoverWidget(
      isItem: true,
      child: Material(
        color: colors.surface,
        borderRadius: AppRadius.xlAll,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 132,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomImageWidget(
                        image: r.coverPhotoFullUrl ?? '',
                        fit: BoxFit.cover,
                        isRestaurant: true,
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colors.ink.withValues(alpha: 0.0),
                              colors.ink.withValues(alpha: 0.35),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.md,
                      top: AppSpacing.md,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: open ? colors.success : colors.danger,
                          borderRadius: AppRadius.pillAll,
                        ),
                        child: Text(
                          open ? 'open_now'.tr : 'closed_now'.tr,
                          style: AppTypography.labelSm(colors.onAccent),
                        ),
                      ),
                    ),
                    if (offerLabel != null)
                      Positioned(
                        left: AppSpacing.md,
                        bottom: AppSpacing.x4l,
                        child: AppTag.discount(label: offerLabel),
                      ),
                    Positioned(
                      top: AppSpacing.md,
                      right: AppSpacing.md,
                      child: GetBuilder<FavouriteController>(
                        builder: (favouriteController) {
                          final wished = favouriteController.wishRestIdList
                              .contains(r.id);
                          return Material(
                            color: colors.glass,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                if (Get.find<AuthController>().isLoggedIn()) {
                                  wished
                                      ? favouriteController
                                          .removeFromFavouriteList(r.id, true)
                                      : favouriteController.addToFavouriteList(
                                          null, r.id, true);
                                } else {
                                  showCustomSnackBar(
                                      'you_are_not_logged_in'.tr);
                                }
                              },
                              child: SizedBox(
                                width: 36,
                                height: 36,
                                child: Icon(
                                  wished
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 18,
                                  color: wished ? colors.warm : colors.ink,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.lg,
                      bottom: -24,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.surface,
                          boxShadow: AppShadows.of(context, 2),
                          border: Border.all(color: colors.surface, width: 3),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CustomImageWidget(
                          image: r.logoFullUrl ?? '',
                          fit: BoxFit.cover,
                          isRestaurant: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.x3l,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSm(colors.ink),
                    ),
                    if (r.address?.isNotEmpty ?? false) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        r.address!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm(colors.inkMuted),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _MetaChip(
                          icon: Icons.star_rounded,
                          iconColor: colors.rating,
                          text:
                              '${r.avgRating!.toStringAsFixed(1)} (${r.ratingCount})',
                        ),
                        _MetaChip(
                          icon: Icons.near_me_outlined,
                          text: r.freeDelivery! ? 'free'.tr : distanceLabel,
                        ),
                        _MetaChip(
                          icon: Icons.schedule_rounded,
                          text: r.deliveryTime?.replaceAll('-min', ' min') ??
                              '',
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
    );
    });
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.text,
    this.iconColor,
  });
  final IconData icon;
  final String text;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor ?? colors.accent),
          const SizedBox(width: 3),
          Text(text, style: AppTypography.labelSm(colors.ink)),
        ],
      ),
    );
  }
}

class WebRestaurantShimmer extends StatelessWidget {
  const WebRestaurantShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSkeleton(height: 132, radius: AppRadius.xl),
        SizedBox(height: AppSpacing.x3l),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton(width: 140, height: 14),
              SizedBox(height: AppSpacing.sm),
              AppSkeleton(width: 100, height: 10),
              SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  AppSkeleton(width: 64, height: 24, radius: AppRadius.pill),
                  SizedBox(width: AppSpacing.sm),
                  AppSkeleton(width: 64, height: 24, radius: AppRadius.pill),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

