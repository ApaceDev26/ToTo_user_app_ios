import 'package:flutter/material.dart';

/// Lumen Atelier color tokens. No raw hex in feature UI — use these.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.canvas,
    required this.surface,
    required this.surfaceElevated,
    required this.line,
    required this.lineStrong,
    required this.accent,
    required this.accentSoft,
    required this.accentHover,
    required this.warm,
    required this.warmSoft,
    required this.success,
    required this.warning,
    required this.danger,
    required this.rating,
    required this.overlay,
    required this.glass,
    required this.onAccent,
  });

  final Color ink;
  final Color inkMuted;
  final Color inkFaint;
  final Color canvas;
  final Color surface;
  final Color surfaceElevated;
  final Color line;
  final Color lineStrong;
  final Color accent;
  final Color accentSoft;
  final Color accentHover;
  final Color warm;
  final Color warmSoft;
  final Color success;
  final Color warning;
  final Color danger;
  final Color rating;
  final Color overlay;
  final Color glass;
  final Color onAccent;

  static const light = AppColors(
    ink: Color(0xFF1E1B18),
    inkMuted: Color(0xFF6E6861),
    inkFaint: Color(0xFF9E968F),
    canvas: Color(0xFFF9F7F5),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFDFCFA),
    line: Color(0xFFEBE6DD),
    lineStrong: Color(0xFFD4CEBFFF),
    accent: Color(0xFFFF6B00), // Premium Vibrant Branded Food Orange (যেমন আপনার লোগো)
    accentSoft: Color(0xFFFFF0E5),
    accentHover: Color(0xFFE55A00),
    warm: Color(0xFFD35400),
    warmSoft: Color(0xFFFDEBD0),
    success: Color(0xFF27AE60),
    warning: Color(0xFFF1C40F),
    danger: Color(0xFFC0392B),
    rating: Color(0xFFF1C40F),
    overlay: Color(0x731E1B18),
    glass: Color(0xB8FFFFFF),
    onAccent: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    ink: Color(0xFFFDFBF7),
    inkMuted: Color(0xFFB5AEA5),
    inkFaint: Color(0xFF8A8277),
    canvas: Color(0xFF141210),
    surface: Color(0xFF1F1B18),
    surfaceElevated: Color(0xFF28231F),
    line: Color(0xFF38332E),
    lineStrong: Color(0xFF4A443C),
    accent: Color(0xFFFF6B00), // Premium Vibrant Branded Food Orange (যেমন আপনার লোগো)
    accentSoft: Color(0xFF3D2310),
    accentHover: Color(0xFFFF8533),
    warm: Color(0xFFE67E22),
    warmSoft: Color(0xFF3D2A1C),
    success: Color(0xFF2ECC71),
    warning: Color(0xFFF1C40F),
    danger: Color(0xFFE74C3C),
    rating: Color(0xFFF1C40F),
    overlay: Color(0x8C000000),
    glass: Color(0xCC1F1B18),
    onAccent: Color(0xFFFFFFFF),
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

  @override
  AppColors copyWith({
    Color? ink,
    Color? inkMuted,
    Color? inkFaint,
    Color? canvas,
    Color? surface,
    Color? surfaceElevated,
    Color? line,
    Color? lineStrong,
    Color? accent,
    Color? accentSoft,
    Color? accentHover,
    Color? warm,
    Color? warmSoft,
    Color? success,
    Color? warning,
    Color? danger,
    Color? rating,
    Color? overlay,
    Color? glass,
    Color? onAccent,
  }) {
    return AppColors(
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      inkFaint: inkFaint ?? this.inkFaint,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      accentHover: accentHover ?? this.accentHover,
      warm: warm ?? this.warm,
      warmSoft: warmSoft ?? this.warmSoft,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      rating: rating ?? this.rating,
      overlay: overlay ?? this.overlay,
      glass: glass ?? this.glass,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineStrong: Color.lerp(lineStrong, other.lineStrong, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      warm: Color.lerp(warm, other.warm, t)!,
      warmSoft: Color.lerp(warmSoft, other.warmSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      rating: Color.lerp(rating, other.rating, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}
