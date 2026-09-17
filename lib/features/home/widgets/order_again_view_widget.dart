import 'package:toto_user/features/home/widgets/arrow_icon_button_widget.dart';
import 'package:toto_user/features/home/widgets/restaurants_card_widget.dart';
import 'package:toto_user/features/language/controllers/localization_controller.dart';
import 'package:toto_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:toto_user/helper/responsive_helper.dart';
import 'package:toto_user/helper/route_helper.dart';
import 'package:toto_user/util/dimensions.dart';
import 'package:toto_user/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderAgainViewWidget extends StatelessWidget {
  const OrderAgainViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RestaurantController>(builder: (restController) {
      return (restController.orderAgainRestaurantList != null &&
              restController.orderAgainRestaurantList!.isNotEmpty)
          ? Padding(
              padding: EdgeInsets.symmetric(
                  vertical: ResponsiveHelper.isMobile(context)
                      ? Dimensions.paddingSizeDefault
                      : Dimensions.paddingSizeLarge),
              child: SizedBox(
                height: ResponsiveHelper.isDesktop(context) ? 245 : 225,
                width: Dimensions.webMaxWidth,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveHelper.isMobile(context)
                                ? Dimensions.paddingSizeDefault
                                : 0),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  ResponsiveHelper.isMobile(context)
                                      ? CrossAxisAlignment.start
                                      : CrossAxisAlignment.center,
                              children: [
                                Text('order_again'.tr,
                                    style: robotoBold.copyWith(
                                        fontSize: Dimensions.fontSizeExtraLarge,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                    '${'recently_you_ordered_from'.tr} ${restController.orderAgainRestaurantList!.length} ${'restaurants'.tr}',
                                    style: robotoRegular.copyWith(
                                        color: Theme.of(context).disabledColor,
                                        fontSize: Dimensions.fontSizeSmall)),
                              ],
                            ),
                          ),
                          ArrowIconButtonWidget(
                            onTap: () => Get.toNamed(
                                RouteHelper.getAllRestaurantRoute(
                                    'order_again')),
                          ),
                        ]),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      SizedBox(
                        height: ResponsiveHelper.isDesktop(context) ? 165 : 160,
                        child: ListView.builder(
                          itemCount:
                              restController.orderAgainRestaurantList!.length,
                          padding: EdgeInsets.only(
                              right: ResponsiveHelper.isMobile(context)
                                  ? Dimensions.paddingSizeDefault
                                  : 0),
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(
                                left: (ResponsiveHelper.isDesktop(context) &&
                                        index == 0 &&
                                        Get.find<LocalizationController>()
                                            .isLtr)
                                    ? 0
                                    : Dimensions.paddingSizeDefault,
                                top: ResponsiveHelper.isMobile(context)
                                    ? Dimensions.paddingSizeSmall
                                    : 0,
                                bottom: ResponsiveHelper.isMobile(context)
                                    ? Dimensions.paddingSizeSmall
                                    : 0,
                              ),
                              child: RestaurantsCardWidget(
                                isNewOnStackFood: false,
                                restaurant: restController
                                    .orderAgainRestaurantList![index],
                              ),
                            );
                          },
                        ),
                      ),
                    ]),
              ),
            )
          : const SizedBox();
    });
  }
}
