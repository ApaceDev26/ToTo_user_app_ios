import 'package:toto_user/common/widgets/custom_favourite_widget.dart';
import 'package:toto_user/common/widgets/custom_image_widget.dart';
import 'package:toto_user/common/widgets/custom_snackbar_widget.dart';
import 'package:toto_user/common/widgets/product_bottom_sheet_widget.dart';
import 'package:toto_user/design_system/design_system.dart';
import 'package:toto_user/features/cart/controllers/cart_controller.dart';
import 'package:toto_user/common/models/product_model.dart';
import 'package:toto_user/common/models/restaurant_model.dart';
import 'package:toto_user/features/favourite/controllers/favourite_controller.dart';
import 'package:toto_user/features/product/controllers/product_controller.dart';
import 'package:toto_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:toto_user/helper/date_converter.dart';
import 'package:toto_user/helper/price_converter.dart';
import 'package:toto_user/helper/responsive_helper.dart';
import 'package:toto_user/helper/route_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Lumen Atelier list card — content + portrait media (food) or
/// full-bleed cover + glass dock (restaurant). Zero Codecanyon left-thumb DNA.
class ProductWidget extends StatelessWidget {
  final Product? product;
  final Restaurant? restaurant;
  final bool isRestaurant;
  final int index;
  final int? length;
  final bool inRestaurant;
  final bool isCampaign;
  final bool fromCartSuggestion;

  const ProductWidget({
    super.key,
    required this.product,
    required this.isRestaurant,
    required this.restaurant,
    required this.index,
    required this.length,
    this.inRestaurant = false,
    this.isCampaign = false,
    this.fromCartSuggestion = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isRestaurant) {
      return _RestaurantCoverCard(
        restaurant: restaurant!,
        fromCartSuggestion: fromCartSuggestion,
      );
    }
    return _FoodEditorialCard(
      product: product!,
      inRestaurant: inRestaurant,
      isCampaign: isCampaign,
      fromCartSuggestion: fromCartSuggestion,
    );
  }
}

class _FoodEditorialCard extends StatelessWidget {
  const _FoodEditorialCard({
    required this.product,
    required this.inRestaurant,
    required this.isCampaign,
    required this.fromCartSuggestion,
  });

  final Product product;
  final bool inRestaurant;
  final bool isCampaign;
  final bool fromCartSuggestion;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final discount = product.discount ?? 0;
    final discountType = product.discountType;
    final isAvailable = DateConverter.isAvailable(
      product.availableTimeStarts,
      product.availableTimeEnds,
    );
    final hasDiscount = discount > 0;
    final mediaW = ResponsiveHelper.isDesktop(context) ? 128.0 : 112.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: colors.surface,
        borderRadius: AppRadius.lgAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (product.restaurantStatus == 1) {
              ResponsiveHelper.isMobile(context)
                  ? Get.bottomSheet(
                      ProductBottomSheetWidget(
                        product: product,
                        inRestaurantPage: inRestaurant,
                        isCampaign: isCampaign,
                      ),
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                    )
                  : Get.dialog(
                      Dialog(
                        child: ProductBottomSheetWidget(
                          product: product,
                          inRestaurantPage: inRestaurant,
                        ),
                      ),
                    );
            } else {
              showCustomSnackBar('item_is_not_available'.tr);
            }
          },
          child: SizedBox(
            height: ResponsiveHelper.isDesktop(context) ? 136 : 148,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!inRestaurant &&
                            (product.restaurantName?.isNotEmpty ?? false))
                          Text(
                            product.restaurantName!.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.catalogBodySm(colors.inkFaint)
                                .copyWith(letterSpacing: 0.6),
                          ),
                        Text(
                          product.name ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.catalogTitleSm(colors.ink),
                        ),
                        if (inRestaurant &&
                            (product.description?.isNotEmpty ?? false))
                          Text(
                            product.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.catalogBodySm(colors.inkMuted),
                          ),
                        const Spacer(),
                        if ((product.ratingCount ?? 0) > 0)
                          Row(
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 14, color: colors.rating),
                              const SizedBox(width: 2),
                              Text(
                                product.avgRating!.toStringAsFixed(1),
                                style: AppTypography.labelMd(colors.ink),
                              ),
                              Text(
                                ' (${product.ratingCount})',
                                style: AppTypography.bodySm(colors.inkFaint),
                              ),
                            ],
                          ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (hasDiscount)
                                    Text(
                                      PriceConverter.convertPrice(
                                          product.price),
                                      style: AppTypography.priceStrike(
                                          colors.inkFaint),
                                    ),
                                  Text(
                                    PriceConverter.convertPrice(
                                      product.price,
                                      discount: discount,
                                      discountType: discountType,
                                    ),
                                    style: AppTypography.price(colors.accent),
                                  ),
                                ],
                              ),
                            ),
                            if (!fromCartSuggestion)
                              _AddOrQty(product: product),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: mediaW,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomImageWidget(
                        image: product.imageFullUrl ?? '',
                        fit: BoxFit.cover,
                        isFood: true,
                      ),
                      if (hasDiscount)
                        Positioned(
                          left: AppSpacing.sm,
                          bottom: AppSpacing.sm,
                          child: AppTag.discount(
                            label: discountType == 'percent'
                                ? '-${discount.toStringAsFixed(0)}%'
                                : PriceConverter.convertPrice(discount),
                          ),
                        ),
                      if (!fromCartSuggestion)
                        Positioned(
                          top: AppSpacing.sm,
                          right: AppSpacing.sm,
                          child: GetBuilder<FavouriteController>(
                            builder: (fav) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: colors.glass,
                                  shape: BoxShape.circle,
                                ),
                                child: CustomFavouriteWidget(
                                  isWished: fav.wishProductIdList
                                      .contains(product.id),
                                  isRestaurant: false,
                                  product: product,
                                ),
                              );
                            },
                          ),
                        ),
                      if (!isAvailable)
                        ColoredBox(
                          color: colors.overlay,
                          child: Center(
                            child: Text(
                              'closed_now'.tr,
                              style: AppTypography.labelSm(colors.onAccent),
                              textAlign: TextAlign.center,
                            ),
                          ),
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
  }
}

class _AddOrQty extends StatelessWidget {
  const _AddOrQty({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cart) {
      final qty = cart.cartQuantity(product.id!);
      final idx = cart.isExistInCart(product.id, null);
      if (qty == 0 || idx < 0 || idx >= cart.cartList.length) {
        final primary = Theme.of(context).primaryColor;
        return Material(
          color: primary,
          borderRadius: AppRadius.smAll,
          child: InkWell(
            borderRadius: AppRadius.smAll,
            onTap: () => Get.find<ProductController>()
                .productDirectlyAddToCart(product, context),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(Icons.add_rounded, color: Colors.white, size: 20),
            ),
          ),
        );
      }
      final model = cart.cartList[idx];
      return AppQtyStepper(
        quantity: qty,
        onDecrement: cart.isLoading
            ? () {}
            : () {
                if (model.quantity! > 1) {
                  cart.setQuantity(false, model, cartIndex: idx);
                } else {
                  cart.removeFromCart(idx);
                }
              },
        onIncrement: cart.isLoading
            ? () {}
            : () => cart.setQuantity(true, model, cartIndex: idx),
      );
    });
  }
}

/// Restaurant in list grids (~150–200h): full-bleed cover + bottom glass dock.
class _RestaurantCoverCard extends StatelessWidget {
  const _RestaurantCoverCard({
    required this.restaurant,
    required this.fromCartSuggestion,
  });

  final Restaurant restaurant;
  final bool fromCartSuggestion;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final open = restaurant.open == 1 && (restaurant.active ?? false);
    final discount = restaurant.discount?.discount ?? 0;
    final discountType = restaurant.discount?.discountType ?? 'percent';
    final cover = (restaurant.coverPhotoFullUrl?.isNotEmpty ?? false)
        ? restaurant.coverPhotoFullUrl!
        : (restaurant.logoFullUrl ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        borderRadius: AppRadius.lgAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (restaurant.restaurantStatus == 1) {
              Get.toNamed(
                RouteHelper.getRestaurantRoute(restaurant.id),
                arguments: RestaurantScreen(restaurant: restaurant),
              );
            } else {
              showCustomSnackBar('restaurant_is_not_available'.tr);
            }
          },
          child: SizedBox(
            height: ResponsiveHelper.isDesktop(context) ? 142 : 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomImageWidget(
                  image: cover,
                  fit: BoxFit.cover,
                  isRestaurant: true,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colors.ink.withValues(alpha: 0.05),
                        colors.ink.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  top: AppSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
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
                if (discount > 0 || (restaurant.freeDelivery ?? false))
                  Positioned(
                    left: AppSpacing.md,
                    top: AppSpacing.x4l,
                    child: AppTag.discount(
                      label: (restaurant.freeDelivery ?? false)
                          ? 'free_delivery'.tr
                          : discountType == 'percent'
                              ? '-${discount.toStringAsFixed(0)}%'
                              : PriceConverter.convertPrice(discount),
                    ),
                  ),
                if (!fromCartSuggestion)
                  Positioned(
                    top: AppSpacing.md,
                    right: AppSpacing.md,
                    child: GetBuilder<FavouriteController>(
                      builder: (fav) {
                        return Container(
                          decoration: BoxDecoration(
                            color: colors.glass,
                            shape: BoxShape.circle,
                          ),
                          child: CustomFavouriteWidget(
                            isWished:
                                fav.wishRestIdList.contains(restaurant.id),
                            isRestaurant: true,
                            restaurant: restaurant,
                          ),
                        );
                      },
                    ),
                  ),
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.md,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.surface, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CustomImageWidget(
                          image: restaurant.logoFullUrl ?? '',
                          fit: BoxFit.cover,
                          isRestaurant: true,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: AppRadius.smAll,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                restaurant.name ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleSm(colors.ink),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if ((restaurant.ratingCount ?? 0) > 0) ...[
                                    Icon(Icons.star_rounded,
                                        size: 13, color: colors.rating),
                                    Text(
                                      ' ${restaurant.avgRating!.toStringAsFixed(1)}',
                                      style: AppTypography.labelSm(colors.ink),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                  ],
                                  Flexible(
                                    child: Text(
                                      '${'start_from'.tr} ${PriceConverter.convertPrice(restaurant.minimumOrder)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodySm(
                                        colors.ink.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
  }
}
