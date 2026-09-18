import 'package:toto_user/design_system/app_colors.dart';
import 'package:toto_user/design_system/app_icons.dart';
import 'package:toto_user/design_system/app_spacing.dart';
import 'package:toto_user/design_system/app_typography.dart';
import 'package:toto_user/helper/responsive_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProfileButtonWidget extends StatelessWidget {
  final IconData? icon;
  final String title;
  final bool? isButtonActive;
  final Function onTap;
  final Color? color;
  final String? iconImage;
  final bool isThemeSwitchButton;
  const ProfileButtonWidget(
      {super.key,
      this.icon,
      required this.title,
      required this.onTap,
      this.isButtonActive,
      this.color,
      this.iconImage,
      this.isThemeSwitchButton = false});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = color ??
        (icon == Icons.delete
            ? colors.danger
            : isDark
                ? const Color(0xFF8BBEFF)
                : const Color(0xFF1B4D86));

    return InkWell(
      onTap: onTap as void Function()?,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: isThemeSwitchButton ? 48 : 64,
        padding: EdgeInsets.symmetric(
          horizontal: isThemeSwitchButton ? 0 : AppSpacing.lg,
          vertical: isButtonActive != null ? AppSpacing.xs : AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isThemeSwitchButton ? Colors.transparent : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isDesktop || isThemeSwitchButton
              ? null
              : Border.all(
                  color: isDark ? colors.line : const Color(0xFFDCE8F7)),
          boxShadow: isThemeSwitchButton
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x10102C55),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Row(children: [
          Container(
            width: isThemeSwitchButton ? 28 : 38,
            height: isThemeSwitchButton ? 28 : 38,
            alignment: Alignment.center,
            decoration: isThemeSwitchButton
                ? null
                : BoxDecoration(
                    color: icon == Icons.delete
                        ? colors.danger.withValues(alpha: 0.08)
                        : isDark
                            ? const Color(0xFF263C57)
                            : const Color(0xFFEAF2FC),
                    borderRadius: BorderRadius.circular(11),
                  ),
            child: iconImage != null
                ? Image.asset(iconImage!, height: 20, width: 20)
                : Icon(icon,
                    size: isThemeSwitchButton ? AppIcons.sm : AppIcons.md,
                    color: iconColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
              child: Text(title,
                  style: AppTypography.bodyMd(
                      isThemeSwitchButton || isDark
                          ? colors.ink
                          : const Color(0xFF102C55)))),
          isButtonActive != null
              ? CupertinoSwitch(
                  value: isButtonActive!,
                  activeTrackColor: colors.accent,
                  onChanged: (bool? value) => onTap(),
                  inactiveTrackColor: colors.lineStrong,
                )
              : Icon(Icons.chevron_right_rounded,
                  color: colors.accent, size: AppIcons.md)
        ]),
      ),
    );
  }
}
