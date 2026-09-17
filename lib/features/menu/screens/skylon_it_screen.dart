import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:toto_user/common/widgets/custom_app_bar_widget.dart';
import 'package:toto_user/common/widgets/custom_snackbar_widget.dart';
import 'package:toto_user/common/widgets/menu_drawer_widget.dart';
import 'package:toto_user/design_system/design_system.dart';
import 'package:toto_user/util/images.dart';

class SkylonItScreen extends StatelessWidget {
  static const String websiteUrl = 'https://skylon-it.com/';
  static const String facebookUrl = 'https://www.facebook.com/skylonit';
  static const String phonePrimary = '+8801743233833';
  static const String phoneSecondary = '+8801783197788';

  const SkylonItScreen({super.key});

  Future<void> _openWebsite() async {
    if (await canLaunchUrlString(websiteUrl)) {
      await launchUrlString(websiteUrl, mode: LaunchMode.externalApplication);
    } else {
      showCustomSnackBar('${'can_not_launch'.tr} $websiteUrl');
    }
  }

  Future<void> _launchUri(String uri) async {
    if (await canLaunchUrlString(uri)) {
      await launchUrlString(uri, mode: LaunchMode.externalApplication);
    } else {
      showCustomSnackBar('${'can_not_launch'.tr} $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: CustomAppBarWidget(title: 'skylon_it'.tr),
      endDrawer: const MenuDrawerWidget(),
      endDrawerEnableOpenDragGesture: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.x2l,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: colors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: AppRadius.smAll,
                      child: Image.asset(
                        Images.skylonItLogo,
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'skylon_it_tagline'.tr,
                    style: AppTypography.bodyMd(colors.inkMuted),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'skylon_it_description'.tr,
                    style: AppTypography.bodyMd(colors.ink),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x2l),
            Text(
              'contact_info'.tr,
              style: AppTypography.labelMd(colors.inkFaint),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: colors.line),
              ),
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.location_on_outlined,
                    title: 'address'.tr,
                    value: 'skylon_it_address'.tr,
                  ),
                  const AppDivider(),
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    title: 'phone'.tr,
                    value: '(+880)1743233833',
                    onCall: () => _launchUri('tel:$phonePrimary'),
                    onWhatsapp: () => _launchUri(
                      'https://wa.me/${phonePrimary.replaceAll('+', '')}',
                    ),
                  ),
                  const AppDivider(),
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    title: 'phone'.tr,
                    value: '(+880)1783197788',
                    onCall: () => _launchUri('tel:$phoneSecondary'),
                    onWhatsapp: () => _launchUri(
                      'https://wa.me/${phoneSecondary.replaceAll('+', '')}',
                    ),
                  ),
                  const AppDivider(),
                  _InfoTile(
                    icon: Icons.email_outlined,
                    title: 'email'.tr,
                    value: 'skylonit@gmail.com',
                    onTap: () => _launchUri('mailto:skylonit@gmail.com'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x2l),
            Text(
              'services'.tr,
              style: AppTypography.labelMd(colors.inkFaint),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: colors.line),
              ),
              child: Column(
                children: [
                  _ServiceRow(label: 'skylon_service_mobile'.tr),
                  const SizedBox(height: AppSpacing.md),
                  _ServiceRow(label: 'skylon_service_web'.tr),
                  const SizedBox(height: AppSpacing.md),
                  _ServiceRow(label: 'skylon_service_saas'.tr),
                  const SizedBox(height: AppSpacing.md),
                  _ServiceRow(label: 'skylon_service_pos'.tr),
                  const SizedBox(height: AppSpacing.md),
                  _ServiceRow(label: 'skylon_service_management'.tr),
                  const SizedBox(height: AppSpacing.md),
                  _ServiceRow(label: 'skylon_service_support'.tr),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Material(
        color: colors.surface,
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'visit_website'.tr,
                    icon: Icons.open_in_new_rounded,
                    height: 44,
                    onPressed: _openWebsite,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _CompactActionButton(
                    label: 'facebook'.tr,
                    icon: Icons.facebook,
                    foreground: Colors.white,
                    background: const Color(0xFF1877F2),
                    height: 44,
                    iconSize: 16,
                    onPressed: () => _launchUri(facebookUrl),
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
    this.onCall,
    this.onWhatsapp,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsapp;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final hasActions = onCall != null && onWhatsapp != null;
    return InkWell(
      onTap: hasActions ? null : onTap,
      borderRadius: AppRadius.xsAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: AppIcons.sm, color: colors.inkMuted),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.labelSm(colors.inkFaint)),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(value, style: AppTypography.bodyMd(colors.ink)),
                  if (hasActions) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _CompactActionButton(
                            label: 'call'.tr,
                            icon: Icons.call_outlined,
                            foreground: colors.ink,
                            background: colors.surface,
                            border: colors.lineStrong,
                            onPressed: onCall!,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _CompactActionButton(
                            label: 'whatsapp'.tr,
                            icon: Icons.chat,
                            foreground: Colors.white,
                            background: const Color(0xFF25D366),
                            onPressed: onWhatsapp!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!hasActions && onTap != null)
              Icon(Icons.chevron_right_rounded,
                  size: AppIcons.md, color: colors.inkFaint),
          ],
        ),
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.onPressed,
    this.border,
    this.height = 32,
    this.iconSize = 14,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color? border;
  final VoidCallback onPressed;
  final double height;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Material(
        color: background,
        borderRadius: AppRadius.xsAll,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.xsAll,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: AppRadius.xsAll,
              border: border != null ? Border.all(color: border!) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: iconSize, color: foreground),
                const SizedBox(width: AppSpacing.xs),
                Text(label, style: AppTypography.labelSm(foreground)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Icon(Icons.check_circle_outline, size: AppIcons.sm, color: colors.accent),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(label, style: AppTypography.bodyMd(colors.ink)),
        ),
      ],
    );
  }
}
