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
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Quiet restaurant list card — same language as Menu/Cart/Home chrome.
/// Cover → name → address → text meta. No floating logo, no chip stack, no glass.
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
    final distLabel = r.freeDelivery! ? 'free'.tr : distanceLabel;
    final ratingLabel = (r.ratingCount ?? 0) > 0
        ? '${r.avgRating!.toStringAsFixed(1)} (${r.ratingCount})'
        : null;

    final metaParts = <String>[
      if (ratingLabel != null) ratingLabel,
      distLabel,
      if (eta.isNotEmpty) eta,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.cardGap),
      child: Material(
        color: colors.surface,
        borderRadius: AppRadius.mdAll,
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: colors.line),
              boxShadow: AppShadows.of(context, 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 118,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomImageWidget(
                        image: r.coverPhotoFullUrl ?? '',
                        fit: BoxFit.cover,
                        isRestaurant: true,
                      ),
                      Positioned(
                        left: AppSpacing.sm,
                        top: AppSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: open ? colors.success : colors.danger,
                            borderRadius: AppRadius.smAll,
                          ),
                          child: Text(
                            open ? 'open_now'.tr : 'closed_now'.tr,
                            style: AppTypography.labelSm(colors.onAccent),
                          ),
                        ),
                      ),
                      if (offerLabel != null)
                        Positioned(
                          left: AppSpacing.sm,
                          bottom: AppSpacing.sm,
                          child: AppTag.discount(label: offerLabel),
                        ),
                      Positioned(
                        top: AppSpacing.xs,
                        right: AppSpacing.xs,
                        child: GetBuilder<FavouriteController>(
                          builder: (favouriteController) {
                            final wished = favouriteController.wishRestIdList
                                .contains(r.id);
                            return Material(
                              color: colors.surface,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  if (Get.find<AuthController>().isLoggedIn()) {
                                    wished
                                        ? favouriteController
                                            .removeFromFavouriteList(r.id, true)
                                        : favouriteController
                                            .addToFavouriteList(
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
                                    color: wished ? colors.warm : colors.inkMuted,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
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
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          r.address!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm(colors.inkMuted),
                        ),
                      ],
                      if (metaParts.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          metaParts.join('  ·  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm(colors.inkFaint),
                        ),
                      ],
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
          AppSkeleton(height: 118, radius: AppRadius.md),
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



