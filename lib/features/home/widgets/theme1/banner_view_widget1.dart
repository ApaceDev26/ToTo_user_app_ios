import 'package:carousel_slider/carousel_slider.dart';
import 'package:toto_user/design_system/design_system.dart';
import 'package:toto_user/features/home/controllers/home_controller.dart';
import 'package:toto_user/features/splash/controllers/splash_controller.dart';
import 'package:toto_user/features/product/domain/models/basic_campaign_model.dart';
import 'package:toto_user/common/models/product_model.dart';
import 'package:toto_user/common/models/restaurant_model.dart';
import 'package:toto_user/helper/responsive_helper.dart';
import 'package:toto_user/helper/route_helper.dart';
import 'package:toto_user/common/widgets/custom_image_widget.dart';
import 'package:toto_user/common/widgets/product_bottom_sheet_widget.dart';
import 'package:toto_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class BannerViewWidget1 extends StatelessWidget {
  const BannerViewWidget1({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final ValueNotifier<int> currentBannerIndex = ValueNotifier<int>(0);

    return GetBuilder<HomeController>(builder: (homeController) {
      List<String?>? bannerList = homeController.bannerImageList;
      List<dynamic>? bannerDataList = homeController.bannerDataList;

      return (bannerList != null && bannerList.isEmpty)
          ? const SizedBox()
          : Container(
              width: MediaQuery.of(context).size.width,
              height: GetPlatform.isDesktop
                  ? MediaQuery.of(context).size.width * 0.45
                  : MediaQuery.of(context).size.width * 0.45,
              padding: const EdgeInsets.only(top: 0),
              child: bannerList != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: CarouselSlider.builder(
                            options: CarouselOptions(
                              autoPlay: true,
                              enlargeCenterPage: true,
                              disableCenter: true,
                              viewportFraction: 0.95,
                              autoPlayInterval: const Duration(seconds: 7),
                              onPageChanged: (index, reason) {
                                currentBannerIndex.value = index;
                                homeController.setCurrentIndex(index, false);
                              },
                            ),
                            itemCount:
                                bannerList.isEmpty ? 1 : bannerList.length,
                            itemBuilder: (context, index, _) {
                              return InkWell(
                                onTap: () {
                                  if (bannerDataList?[index] is Product) {
                                    Product? product = bannerDataList?[index];
                                    ResponsiveHelper.isMobile(context)
                                        ? showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (con) =>
                                                ProductBottomSheetWidget(
                                                    product: product),
                                          )
                                        : showDialog(
                                            context: context,
                                            builder: (con) => Dialog(
                                                child: ProductBottomSheetWidget(
                                                    product: product)),
                                          );
                                  } else if (bannerDataList?[index]
                                      is Restaurant) {
                                    Restaurant restaurant =
                                        bannerDataList?[index];
                                    Get.toNamed(
                                      RouteHelper.getRestaurantRoute(
                                          restaurant.id),
                                      arguments: RestaurantScreen(
                                          restaurant: restaurant),
                                    );
                                  } else if (bannerDataList?[index]
                                      is BasicCampaignModel) {
                                    BasicCampaignModel campaign =
                                        bannerDataList?[index];
                                    Get.toNamed(
                                        RouteHelper.getBasicCampaignRoute(
                                            campaign));
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: AppRadius.lgAll,
                                    boxShadow: AppShadows.of(context, 2),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: AppRadius.lgAll,
                                    child: GetBuilder<SplashController>(
                                        builder: (splashController) {
                                      return CustomImageWidget(
                                        image: '${bannerList[index]}',
                                        fit: BoxFit.cover,
                                      );
                                    }),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ValueListenableBuilder<int>(
                          valueListenable: currentBannerIndex,
                          builder: (context, activeIndex, _) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: homeController.bannerImageList!
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final index = entry.key;
                                final active = index == activeIndex;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xxs),
                                  child: AnimatedContainer(
                                    duration: AppDurations.fast,
                                    height: 4,
                                    width: active ? 20 : 10,
                                    decoration: BoxDecoration(
                                      borderRadius: AppRadius.pillAll,
                                      color: active
                                          ? colors.accent
                                          : colors.lineStrong,
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    )
                  : Shimmer(
                      duration: const Duration(seconds: 2),
                      enabled: bannerList == null,
                      child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm),
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.lgAll,
                            color: colors.line,
                          )),
                    ),
            );
    });
  }
}