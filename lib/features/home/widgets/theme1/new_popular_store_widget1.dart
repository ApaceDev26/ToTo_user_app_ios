import 'package:toto_user/common/widgets/custom_image_widget.dart';
import 'package:toto_user/common/widgets/custom_snackbar_widget.dart';
import 'package:toto_user/common/widgets/title_widget.dart';
import 'package:toto_user/design_system/design_system.dart';
import 'package:toto_user/features/auth/controllers/auth_controller.dart';
import 'package:toto_user/features/favourite/controllers/favourite_controller.dart';
import 'package:toto_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:toto_user/common/models/restaurant_model.dart';
import 'package:toto_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:toto_user/helper/price_converter.dart';
import 'package:toto_user/helper/route_helper.dart';
import 'package:toto_user/util/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Popular / latest / recent restaurant rail — same quiet DNA as RestaurantWidget.
class NewPopularStoreWidget1 extends StatelessWidget {
  final bool isPopular;
  final bool isRecentlyViewed;
  final bool isOrderAgainViewed;

  const NewPopularStoreWidget1({
    super.key,
    required this.isPopular,
    this.isRecentlyViewed = false,
    this.isOrderAgainViewed = false,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RestaurantController>(builder: (restaurantController) {
      final List<Restaurant>? restaurant = isPopular
          ? restaurantController.popularRestaurantList
          : isRecentlyViewed
              ? restaurantController.recentlyViewedRestaurantList
              : isOrderAgainViewed
                  ? restaurantController.orderAgainRestaurantList
                  : restaurantController.latestRestaurantList;

      if (restaurant != null && restaurant.isEmpty) {
        return const SizedBox();
      }

      final title = isPopular
          ? 'popular_restaurants'.tr
          : isRecentlyViewed
              ? 'recently_viewed_restaurants'.tr
              : isOrderAgainViewed
                  ? 'order_again'.tr
                  : '${'new_on'.tr} ${AppConstants.appName}';

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: TitleWidget(
              title: title,
              onTap: () => Get.toNamed(
                RouteHelper.getAllRestaurantRoute(
                  isPopular
                      ? 'popular'
                      : isRecentlyViewed
                          ? 'recently_viewed'
                          : isOrderAgainViewed
                              ? 'order_again'
                              : 'latest',
                ),
              ),
            ),
          ),
          SizedBox(
            height: 188,
            child: restaurant != null
                ? ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    itemCount: restaurant.length > 10 ? 10 : restaurant.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, index) {
                      return _StoreTile(
                        restaurant: restaurant[index],
                        controller: restaurantController,
                      );
                    },
                  )
                : PopularStoreShimmer(
                    restaurantController: restaurantController),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      );
    });
  }
}

class _StoreTile extends StatelessWidget {
  const _StoreTile({
    required this.restaurant,
    required this.controller,
  });

  final Restaurant restaurant;
  final RestaurantController controller;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final open = controller.isOpenNow(restaurant);
    final discount = controller.getDiscount(restaurant) ?? 0;
    final discountType = controller.getDiscountType(restaurant);
    final tileW = (MediaQuery.sizeOf(context).width * 0.55).clamp(180.0, 220.0);

    String? offer;
    if (restaurant.freeDelivery ?? false) {
      offer = 'free_delivery'.tr;
    } else if (discount > 0) {
      offer = discountType == 'percent'
          ? '${discount.toStringAsFixed(0)}% OFF'
          : '-${PriceConverter.convertPrice(discount)}';
    }

    final eta = restaurant.deliveryTime?.replaceAll('-min', ' min') ?? '';
    final rating = (restaurant.ratingCount ?? 0) > 0
        ? restaurant.avgRating!.toStringAsFixed(1)
        : null;
    final meta = [
      if (rating != null) '★ $rating',
      if (eta.isNotEmpty) eta,
    ].join('  ·  ');

    return SizedBox(
      width: tileW,
      child: Material(
        color: colors.surface,
        borderRadius: AppRadius.mdAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Get.toNamed(
              RouteHelper.getRestaurantRoute(restaurant.id),
              arguments: RestaurantScreen(restaurant: restaurant),
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: colors.line),
              boxShadow: AppShadows.of(context, 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomImageWidget(
                        image: restaurant.coverPhotoFullUrl ?? '',
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
                      if (offer != null)
                        Positioned(
                          left: AppSpacing.sm,
                          bottom: AppSpacing.sm,
                          child: AppTag.discount(label: offer),
                        ),
                      Positioned(
                        top: AppSpacing.xs,
                        right: AppSpacing.xs,
                        child: GetBuilder<FavouriteController>(
                          builder: (favouriteController) {
                            final wished = favouriteController.wishRestIdList
                                .contains(restaurant.id);
                            return Material(
                              color: colors.surface,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  if (Get.find<AuthController>().isLoggedIn()) {
                                    wished
                                        ? favouriteController
                                            .removeFromFavouriteList(
                                                restaurant.id, true)
                                        : favouriteController
                                            .addToFavouriteList(
                                                null, restaurant.id, true);
                                  } else {
                                    showCustomSnackBar(
                                        'you_are_not_logged_in'.tr);
                                  }
                                },
                                child: SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Icon(
                                    wished
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 16,
                                    color:
                                        wished ? colors.warm : colors.inkMuted,
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
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.catalogTitleSm(colors.ink),
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          meta,
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
  }
}

class PopularStoreShimmer extends StatelessWidget {
  final RestaurantController restaurantController;
  const PopularStoreShimmer({super.key, required this.restaurantController});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
      itemBuilder: (_, __) => const SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSkeleton(height: 100, radius: AppRadius.md),
            SizedBox(height: AppSpacing.md),
            AppSkeleton(width: 140, height: 14),
            SizedBox(height: AppSpacing.sm),
            AppSkeleton(width: 100, height: 12),
          ],
        ),
      ),
    );
  }
}
