import 'package:toto_user/common/widgets/custom_ink_well_widget.dart';
import 'package:toto_user/design_system/design_system.dart';
import 'package:toto_user/features/order/controllers/order_controller.dart';
import 'package:toto_user/features/order/screens/order_details_screen.dart';
import 'package:toto_user/features/order/widgets/order_shimmer_widget.dart';
import 'package:toto_user/features/order/domain/models/order_model.dart';
import 'package:toto_user/helper/date_converter.dart';
import 'package:toto_user/helper/responsive_helper.dart';
import 'package:toto_user/helper/route_helper.dart';
import 'package:toto_user/util/dimensions.dart';
import 'package:toto_user/util/images.dart';
import 'package:toto_user/common/widgets/custom_image_widget.dart';
import 'package:toto_user/common/widgets/footer_view_widget.dart';
import 'package:toto_user/common/widgets/no_data_screen_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderViewWidget extends StatelessWidget {
  final bool isRunning;
  final bool isSubscription;
  final bool showRefundOnly;
  final String searchQuery;
  const OrderViewWidget(
      {super.key,
      required this.isRunning,
      this.isSubscription = false,
      this.showRefundOnly = false,
      this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final ScrollController scrollController = ScrollController();

    return Scaffold(
      backgroundColor: colors.canvas,
      body: GetBuilder<OrderController>(builder: (orderController) {
        List<OrderModel>? orderList;
        bool paginate = false;
        int pageSize = 1;
        int offset = 1;
        if (orderController.runningOrderList != null &&
            orderController.historyOrderList != null) {
          List<OrderModel>? baseList = isSubscription
              ? orderController.runningSubscriptionOrderList
              : isRunning
                  ? orderController.runningOrderList
                  : orderController.historyOrderList;

          // Filter for refund orders if showRefundOnly is true
          if (showRefundOnly && baseList != null) {
            orderList = baseList
                .where((order) =>
                    order.orderStatus == 'refund_requested' ||
                    order.orderStatus == 'refunded' ||
                    order.orderStatus == 'refund_request_canceled')
                .toList();
          } else {
            orderList = baseList;
          }

          // Filter by order ID if search query is provided
          if (searchQuery.isNotEmpty && orderList != null) {
            orderList = orderList
                .where((order) =>
                    order.id != null &&
                    order.id.toString().contains(searchQuery))
                .toList();
          }
          paginate = isSubscription
              ? orderController.runningSubscriptionPaginate
              : isRunning
                  ? orderController.runningPaginate
                  : orderController.historyPaginate;
          pageSize = isSubscription
              ? (orderController.runningSubscriptionPageSize! / 10).ceil()
              : isRunning
                  ? (orderController.runningPageSize! / 10).ceil()
                  : (orderController.historyPageSize! / 10).ceil();
          offset = isSubscription
              ? orderController.runningSubscriptionOffset
              : isRunning
                  ? orderController.runningOffset
                  : orderController.historyOffset;
        }
        scrollController.addListener(() {
          if (scrollController.position.pixels ==
                  scrollController.position.maxScrollExtent &&
              orderList != null &&
              !paginate) {
            if (offset < pageSize) {
              Get.find<OrderController>()
                  .setOffset(offset + 1, isRunning, isSubscription);
              debugPrint('end of the page');
              Get.find<OrderController>()
                  .showBottomLoader(isRunning, isSubscription);
              if (isRunning) {
                Get.find<OrderController>()
                    .getRunningOrders(offset + 1, limit: 10);
              } else if (isSubscription) {
                Get.find<OrderController>()
                    .getRunningSubscriptionOrders(offset + 1);
              } else {
                Get.find<OrderController>().getHistoryOrders(offset + 1);
              }
            }
          }
        });

        return orderList != null
            ? orderList.isNotEmpty
                ? RefreshIndicator(
                    onRefresh: () async {
                      if (isRunning) {
                        await orderController.getRunningOrders(1);
                      } else {
                        await orderController.getHistoryOrders(1);
                      }
                    },
                    child: SingleChildScrollView(
                      controller: scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Center(
                          child: FooterViewWidget(
                        child: SizedBox(
                          width: Dimensions.webMaxWidth,
                          child: Column(
                            children: [
                              GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisSpacing:
                                      ResponsiveHelper.isDesktop(context)
                                          ? Dimensions.paddingSizeLarge
                                          : Dimensions.paddingSizeLarge,
                                  mainAxisSpacing:
                                      ResponsiveHelper.isDesktop(context)
                                          ? Dimensions.paddingSizeSmall
                                          : 0,
                                  crossAxisCount:
                                      ResponsiveHelper.isMobile(context)
                                          ? 1
                                          : 2,
                                  mainAxisExtent:
                                      ResponsiveHelper.isDesktop(context)
                                          ? 140
                                          : 125,
                                ),
                                padding: ResponsiveHelper.isDesktop(context)
                                    ? const EdgeInsets.symmetric(
                                        vertical: AppSpacing.xl)
                                    : const EdgeInsets.all(AppSpacing.sm),
                                itemCount: orderList.length,
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: AppSpacing.cardGap),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: colors.surface,
                                        borderRadius: AppRadius.mdAll,
                                        boxShadow: AppShadows.of(context, 2),
                                      ),
                                      child: CustomInkWellWidget(
                                        onTap: () {
                                          Get.toNamed(
                                            RouteHelper.getOrderDetailsRoute(
                                                orderList![index].id),
                                            arguments: OrderDetailsScreen(
                                                orderId: orderList[index].id,
                                                orderModel: orderList[index]),
                                          );
                                        },
                                        radius: AppRadius.md,
                                        child: Padding(
                                          padding: const EdgeInsets.all(
                                              AppSpacing.md),
                                          child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Row(children: [
                                                  Container(
                                                    width: 80,
                                                    padding:
                                                        const EdgeInsets.all(1),
                                                    decoration: BoxDecoration(
                                                      color: colors.accentSoft,
                                                      borderRadius:
                                                          AppRadius.smAll,
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          AppRadius.smAll,
                                                      child: CustomImageWidget(
                                                        image:
                                                            '${orderList![index].restaurant != null ? orderList[index].restaurant!.logoFullUrl : ''}',
                                                        height: 80,
                                                        width: 80,
                                                        fit: BoxFit.cover,
                                                        isRestaurant: true,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      width: AppSpacing.sm),
                                                  Expanded(
                                                    child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                              '${orderList[index].restaurant?.name ?? ''}',
                                                              style: AppTypography
                                                                  .labelLg(
                                                                      colors
                                                                          .ink),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              maxLines: 1),
                                                          const SizedBox(
                                                              height: AppSpacing
                                                                  .xs),
                                                          Text(
                                                              '${'order'.tr} # ${orderList[index].id}',
                                                              style: AppTypography
                                                                  .labelMd(colors
                                                                      .inkMuted),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              maxLines: 1),
                                                          const SizedBox(
                                                              height: AppSpacing
                                                                  .xs),
                                                          Text(
                                                            DateConverter
                                                                .dateTimeStringToDateTimeToLines(
                                                                    orderList[
                                                                            index]
                                                                        .createdAt!),
                                                            style: AppTypography
                                                                .bodySm(colors
                                                                    .inkFaint),
                                                          ),
                                                        ]),
                                                  ),
                                                  const SizedBox(
                                                      width: AppSpacing.sm),
                                                  Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        isRunning ||
                                                                isSubscription
                                                            ? Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .end,
                                                                children: [
                                                                    Builder(builder:
                                                                        (context) {
                                                                      String?
                                                                          status =
                                                                          orderList![index]
                                                                              .orderStatus;
                                                                      bool
                                                                          isDineIn =
                                                                          orderList[index].orderType ==
                                                                              'dine_in';
                                                                      if (isDineIn) {
                                                                        status = orderList[index].orderStatus ==
                                                                                'processing'
                                                                            ? 'cooking'.tr
                                                                            : orderList[index].orderStatus == 'handover'
                                                                                ? 'ready_to_serve'.tr
                                                                                : orderList[index].orderStatus == 'pending'
                                                                                    ? 'pending'.tr
                                                                                    : orderList[index].orderStatus == 'canceled'
                                                                                        ? 'canceled'.tr
                                                                                        : orderList[index].orderStatus == 'confirmed'
                                                                                            ? 'confirmed'.tr
                                                                                            : 'served'.tr;
                                                                      }
                                                                      return Container(
                                                                        padding: const EdgeInsets
                                                                            .symmetric(
                                                                            horizontal:
                                                                                AppSpacing.sm,
                                                                            vertical: AppSpacing.xs),
                                                                        margin: EdgeInsets.only(
                                                                            bottom: ResponsiveHelper.isDesktop(context)
                                                                                ? AppSpacing.x3l
                                                                                : AppSpacing.lg),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          borderRadius:
                                                                              AppRadius.xsAll,
                                                                          color: orderList[index].orderStatus == 'pending' || orderList[index].orderStatus == 'processing'
                                                                              ? colors.accentSoft
                                                                              : orderList[index].orderStatus == 'accepted' || orderList[index].orderStatus == 'confirmed' || orderList[index].orderStatus == 'handover'
                                                                                  ? colors.success.withValues(alpha: 0.12)
                                                                                  : colors.accentSoft,
                                                                        ),
                                                                        child: Text(
                                                                            isDineIn
                                                                                ? status ?? ''
                                                                                : orderList[index].orderStatus!.tr,
                                                                            style: AppTypography.labelSm(
                                                                              orderList[index].orderStatus == 'pending' || orderList[index].orderStatus == 'processing'
                                                                                  ? colors.accent
                                                                                  : orderList[index].orderStatus == 'accepted' || orderList[index].orderStatus == 'confirmed' || orderList[index].orderStatus == 'handover'
                                                                                      ? colors.success
                                                                                      : colors.accent,
                                                                            )),
                                                                      );
                                                                    }),
                                                                    orderList[index].orderType ==
                                                                            'delivery'
                                                                        ? InkWell(
                                                                            onTap: () =>
                                                                                Get.toNamed(RouteHelper.getOrderTrackingRoute(orderList![index].id, null)),
                                                                            child:
                                                                                Container(
                                                                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 7),
                                                                              decoration: BoxDecoration(
                                                                                borderRadius: AppRadius.xsAll,
                                                                                color: colors.accent,
                                                                              ),
                                                                              child: Row(children: [
                                                                                Text('track_order'.tr,
                                                                                    style: AppTypography.labelMd(
                                                                                      colors.onAccent,
                                                                                    )),
                                                                                const SizedBox(width: AppSpacing.xs),
                                                                                Image.asset(Images.tracking, height: 20, width: 20, color: colors.onAccent),
                                                                              ]),
                                                                            ),
                                                                          )
                                                                        : const SizedBox(),
                                                                  ])
                                                            : Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .end,
                                                                children: [
                                                                    Container(
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal: AppSpacing
                                                                              .sm,
                                                                          vertical:
                                                                              AppSpacing.xs),
                                                                      margin: const EdgeInsets
                                                                          .only(
                                                                          bottom:
                                                                              AppSpacing.x3l),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        borderRadius:
                                                                            AppRadius.xsAll,
                                                                        color: orderList[index].orderStatus ==
                                                                                'delivered'
                                                                            ? colors.success.withValues(alpha: 0.12)
                                                                            : colors.danger.withValues(alpha: 0.12),
                                                                      ),
                                                                      child: Text(
                                                                          orderList[index]
                                                                              .orderStatus!
                                                                              .tr,
                                                                          style:
                                                                              AppTypography.labelSm(
                                                                            orderList[index].orderStatus == 'delivered'
                                                                                ? colors.success
                                                                                : colors.danger,
                                                                          )),
                                                                    ),
                                                                    Text(
                                                                      '${orderList[index].detailsCount} ${orderList[index].detailsCount! > 1 ? 'items'.tr : 'item'.tr}',
                                                                      style: AppTypography.bodySm(
                                                                          colors.inkFaint),
                                                                    ),
                                                                  ]),
                                                      ]),
                                                ]),
                                              ]),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              paginate
                                  ? const Center(
                                      child: Padding(
                                      padding: EdgeInsets.all(
                                          Dimensions.paddingSizeSmall),
                                      child: CircularProgressIndicator(),
                                    ))
                                  : const SizedBox(),
                            ],
                          ),
                        ),
                      )),
                    ),
                  )
                : SingleChildScrollView(
                    child: FooterViewWidget(
                        child: NoDataScreen(
                            title: 'no_order_yet'.tr, isEmptyOrder: true)))
            : OrderShimmerWidget(orderController: orderController);
      }),
    );
  }
}
