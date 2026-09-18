import 'package:toto_user/common/widgets/custom_favourite_widget.dart';
import 'package:toto_user/common/widgets/custom_image_widget.dart';
import 'package:toto_user/common/widgets/custom_snackbar_widget.dart';
import 'package:toto_user/common/models/restaurant_model.dart';
import 'package:toto_user/design_system/design_system.dart';
import 'package:toto_user/features/address/domain/models/address_model.dart';
import 'package:toto_user/features/favourite/controllers/favourite_controller.dart';
import 'package:toto_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:toto_user/features/splash/controllers/splash_controller.dart';
import 'package:toto_user/helper/price_converter.dart';
import 'package:toto_user/helper/responsive_helper.dart';
import 'package:toto_user/helper/route_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

/// Editorial restaurant identity + quiet metadata for Restaurant Details.
class InfoViewWidget extends StatelessWidget {
  final Restaurant restaurant;
  final RestaurantController restController;
  final double scrollingRate;
  final bool showLogo;
  final bool compact;

  const InfoViewWidget({
    super.key,
    required this.restaurant,
    required this.restController,
    required this.scrollingRate,
    this.showLogo = true,
    this.compact = false,
  });

  bool get _isOpen => restController.isRestaurantOpenNow(
        restaurant.active!,
        restaurant.schedules,
      );

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final collapse = compact ? 1.0 : scrollingRate.clamp(0.0, 1.0);
    final logoSize = compact
        ? 40.0
        : (isDesktop ? 72.0 : 56.0) - (collapse * (isDesktop ? 20 : 12));

    if (compact) {
      return Row(
        children: [
          if (showLogo) ...[
            _RestaurantLogo(
              imageUrl: restaurant.logoFullUrl,
              size: logoSize,
              isOpen: _isOpen,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              restaurant.name ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleSm(colors.ink),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _ActionCluster(
            restaurant: restaurant,
            collapse: 1,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLogo && !isDesktop) ...[
              _RestaurantLogo(
                imageUrl: restaurant.logoFullUrl,
                size: logoSize,
                isOpen: _isOpen,
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name ?? '',
                          maxLines: collapse > 0.6 ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleSm(colors.ink),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _ActionCluster(
                        restaurant: restaurant,
                        collapse: collapse,
                      ),
                    ],
                  ),
                  if ((restaurant.address ?? '').isNotEmpty &&
                      collapse < 0.85) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      restaurant.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm(colors.inkMuted),
                    ),
                  ],
                  if (collapse < 0.7) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _MetaRail(
                      restaurant: restaurant,
                      isOpen: _isOpen,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RestaurantLogo extends StatelessWidget {
  const _RestaurantLogo({
    required this.imageUrl,
    required this.size,
    required this.isOpen,
  });

  final String? imageUrl;
  final double size;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: colors.line),
        boxShadow: AppShadows.of(context, 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomImageWidget(
            image: imageUrl ?? '',
            fit: BoxFit.cover,
            isRestaurant: true,
          ),
          if (!isOpen)
            Container(
              color: colors.overlay,
              alignment: Alignment.center,
              child: Text(
                'closed_now'.tr,
                textAlign: TextAlign.center,
                style: AppTypography.labelSm(colors.onAccent),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionCluster extends StatelessWidget {
  const _ActionCluster({
    required this.restaurant,
    required this.collapse,
  });

  final Restaurant restaurant;
  final double collapse;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final iconSize = AppIcons.sm - (collapse * 4);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GetBuilder<FavouriteController>(builder: (favouriteController) {
          final isWished =
              favouriteController.wishRestIdList.contains(restaurant.id);
          return CustomFavouriteWidget(
            isWished: isWished,
            isRestaurant: true,
            restaurant: restaurant,
            size: iconSize + 2,
          );
        }),
        Builder(builder: (context) {
          final shareUrl =
              Get.find<SplashController>().configModel?.appUrlAndroid?.trim();
          if (shareUrl == null || shareUrl.isEmpty) {
            return const SizedBox.shrink();
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: AppSpacing.xs),
              _QuietIconButton(
                icon: Icons.ios_share_rounded,
                size: iconSize,
                semanticLabel: 'share'.tr,
                onTap: () {
                  if (isDesktop) {
                    Clipboard.setData(ClipboardData(text: shareUrl));
                    showCustomSnackBar('restaurant_url_copied'.tr, isError: false);
                  } else {
                    Share.share(shareUrl);
                  }
                },
                color: colors.inkMuted,
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _MetaRail extends StatelessWidget {
  const _MetaRail({
    required this.restaurant,
    required this.isOpen,
  });

  final Restaurant restaurant;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final items = <Widget>[];
    final rating = restaurant.avgRating;
    final ratingLabel = (rating != null && rating > 0)
        ? '${rating.toStringAsFixed(1)}'
            '${restaurant.ratingCount != null ? ' (${restaurant.ratingCount})' : ''}'
        : 'ratings'.tr;

    items.add(
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color:
              isOpen ? colors.success.withValues(alpha: 0.12) : colors.warmSoft,
          borderRadius: AppRadius.xsAll,
        ),
        child: Text(
          isOpen ? 'open_now'.tr : 'closed_now'.tr,
          style: AppTypography.labelSm(isOpen ? colors.success : colors.warm),
        ),
      ),
    );

    items.add(_TextAction(
      icon: Icons.star_rounded,
      label: ratingLabel,
      iconColor: colors.rating,
      onTap: () => Get.toNamed(RouteHelper.getRestaurantReviewRoute(
        restaurant.id,
        restaurant.name,
        restaurant,
      )),
    ));

    items.add(_TextAction(
      icon: Icons.place_outlined,
      label: 'location'.tr,
      onTap: () => Get.toNamed(RouteHelper.getMapRoute(
        AddressModel(
          id: restaurant.id,
          address: restaurant.address,
          latitude: restaurant.latitude,
          longitude: restaurant.longitude,
          contactPersonNumber: '',
          contactPersonName: '',
          addressType: '',
        ),
        'restaurant',
        restaurantName: restaurant.name,
        restaurant: restaurant,
      )),
    ));

    if ((restaurant.deliveryTime ?? '').isNotEmpty) {
      items.add(_TextAction(
        icon: Icons.schedule_rounded,
        label: restaurant.deliveryTime!,
      ));
    }

    if (restaurant.minimumOrder != null && restaurant.minimumOrder! > 0) {
      items.add(Text(
        '${'start_from'.tr} ${PriceConverter.convertPrice(restaurant.minimumOrder)}',
        style: AppTypography.bodySm(colors.inkMuted),
      ));
    }

    if (restaurant.delivery == true && restaurant.freeDelivery == true) {
      items.add(AppTag(label: 'free_delivery'.tr));
    }

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: items,
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor ?? colors.inkMuted),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTypography.labelMd(colors.inkMuted)),
      ],
    );

    if (onTap == null) return row;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.xsAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: row,
      ),
    );
  }
}

class _QuietIconButton extends StatelessWidget {
  const _QuietIconButton({
    required this.icon,
    required this.onTap,
    required this.size,
    required this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillAll,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}
