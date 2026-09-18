import 'package:toto_user/design_system/app_colors.dart';
import 'package:toto_user/util/dimensions.dart';
import 'package:toto_user/util/styles.dart';
import 'package:flutter/material.dart';

class ProfileCardWidget extends StatelessWidget {
  final String image;
  final String title;
  final String data;
  const ProfileCardWidget({super.key, required this.data, required this.title, required this.image});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 112,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colors.surface,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14102C55),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(
            color: isDark ? colors.line : const Color(0xFFDCE8F7)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.accentSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Image.asset(image, fit: BoxFit.contain),
          ),
          const SizedBox(height: 6),
          Text(data,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: isDark ? colors.ink : const Color(0xFF102C55),
              )),
          const SizedBox(height: 2),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: colors.inkMuted,
              )),
        ]),
      ),
    );
  }
}
