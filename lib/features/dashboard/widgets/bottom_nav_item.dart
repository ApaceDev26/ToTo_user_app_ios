import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:toto_user/design_system/app_colors.dart';
import 'package:toto_user/design_system/app_durations.dart';
import 'package:toto_user/design_system/app_radius.dart';
import 'package:toto_user/design_system/app_typography.dart';

/// Bottom nav item â€” Lumen Atelier tokens. SVG assets kept.
class BottomNavItem extends StatelessWidget {
  final String icon;
  final String activeIcon;
  final String label;
  final VoidCallback? onTap;
  final bool isSelected;
  final int? cartCount;
  final int? count;

  const BottomNavItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.onTap,
    this.isSelected = false,
    this.cartCount,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final badge = count ?? cartCount;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: badge != null && badge > 0 ? '$label, $badge' : label,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdAll,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SvgPicture.asset(
                      isSelected ? activeIcon : icon,
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(
                        isSelected
                            ? const Color(0xFFE44732)
                            : const Color(0xFF9E9E9E),
                        BlendMode.srcIn,
                      ),
                    ),
                    if (badge != null && badge > 0)
                      Positioned(
                        top: -6,
                        right: -8,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: AppRadius.pillAll,
                          ),
                          child: Text(
                            badge.toString(),
                            style: AppTypography.labelSm(Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTypography.labelSm(
                    isSelected
                        ? const Color(0xFFE44732)
                        : const Color(0xFF9E9E9E),
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
