import 'package:toto_user/common/widgets/custom_ink_well_widget.dart';
import 'package:toto_user/design_system/design_system.dart';
import 'package:toto_user/features/language/controllers/localization_controller.dart';
import 'package:toto_user/features/category/controllers/category_controller.dart';
import 'package:toto_user/helper/responsive_helper.dart';
import 'package:toto_user/helper/route_helper.dart';
import 'package:toto_user/common/widgets/custom_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class WhatOnYourMindViewWidget extends StatelessWidget {
  const WhatOnYourMindViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isLtr = Get.find<LocalizationController>().isLtr;
    final isMobile = ResponsiveHelper.isMobile(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return GetBuilder<CategoryController>(builder: (categoryController) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.only(
            top: isMobile ? AppSpacing.sm : AppSpacing.xl,
            left: isLtr ? AppSpacing.xs : 0,
            right: isLtr ? 0 : AppSpacing.xs,
            bottom: isMobile ? AppSpacing.sm : AppSpacing.lg,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: isDesktop ? 0 : AppSpacing.sm,
              right: isDesktop ? 0 : AppSpacing.lg,
            ),
            child: Text(
              'what_on_your_mind'.tr,
              style: AppTypography.displayMd(colors.ink).copyWith(
                fontSize: isDesktop ? 24 : 22,
                height: 1.2,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ),
        SizedBox(
          height: isMobile ? 122 : 175,
          child: categoryController.categoryList != null
              ? ListView.builder(
                  physics: isMobile
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: AppSpacing.xl),
                  itemCount: categoryController.categoryList!.length > 10
                      ? 10
                      : categoryController.categoryList!.length,
                  itemBuilder: (context, index) {
                    if (index == 9) {
                      return isDesktop
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm),
                              child: SizedBox(
                                width: 70,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: InkWell(
                                    hoverColor: Colors.transparent,
                                    onTap: () => Get.toNamed(
                                        RouteHelper.getCategoryRoute()),
                                    child: Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: colors.surface,
                                        border: Border.all(color: colors.line),
                                        boxShadow: AppShadows.of(context, 1),
                                      ),
                                      child: Icon(Icons.arrow_forward_rounded,
                                          color: colors.accent, size: 18),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox();
                    }

                    final size = isMobile ? 64.0 : 88.0;

                    return Padding(
                      padding: const EdgeInsets.only(
                          bottom: AppSpacing.sm, right: AppSpacing.lg),
                      child: SizedBox(
                        width: isMobile ? 72 : 100,
                        child: CustomInkWellWidget(
                          onTap: () =>
                              Get.toNamed(RouteHelper.getCategoryProductRoute(
                            categoryController.categoryList![index].id,
                            categoryController.categoryList![index].name!,
                          )),
                          radius: AppRadius.md,
                          child: Column(children: [
                            Container(
                              width: size,
                              height: size,
                              padding: const EdgeInsets.all(AppSpacing.xxs),
                              decoration: BoxDecoration(
                                borderRadius: AppRadius.mdAll, // সার্কেল থেকে প্রিমিয়াম রাউন্ডেড স্কয়ারে রূপান্তর
                                color: colors.accentSoft,
                                border: Border.all(
                                  color: colors.line.withValues(alpha: 0.7),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: AppRadius.smAll, // ইমেজের কোণাগুলো সুন্দরভাবে রাউন্ড করার জন্য
                                child: CustomImageWidget(
                                  image:
                                      '${categoryController.categoryList![index].imageFullUrl}',
                                  height: size,
                                  width: size,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                categoryController.categoryList![index].name!,
                                style: AppTypography.catalogLabelMd(
                                    colors.inkMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ]),
                        ),
                      ),
                    );
                  },
                )
              : WebWhatOnYourMindViewShimmer(
                  categoryController: categoryController),
        ),
        const SizedBox(height: AppSpacing.xs),
      ]);
    });
  }
}

class WebWhatOnYourMindViewShimmer extends StatelessWidget {
  final CategoryController categoryController;
  const WebWhatOnYourMindViewShimmer(
      {super.key, required this.categoryController});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return SizedBox(
      height: isMobile ? 122 : 175,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: 10,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(
              bottom: AppSpacing.sm,
              right: AppSpacing.sm,
              top: AppSpacing.sm,
            ),
            child: SizedBox(
              width: isMobile ? 70 : 108,
              child: Column(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: AppRadius.mdAll,
                    child: Shimmer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.mdAll,
                          color: colors.line,
                        ),
                        height: isMobile ? 64 : 80,
                        width: isMobile ? 64 : 80,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: AppRadius.xsAll,
                  child: Shimmer(
                    child: Container(
                      height: isMobile ? 10 : 15,
                      width: 56,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.xsAll,
                        color: colors.line,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}
