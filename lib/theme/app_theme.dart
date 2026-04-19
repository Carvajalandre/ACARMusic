import 'package:flutter/material.dart';

class AppTheme {
  // ─── Colores base (Sonic Monolith / ACARMusic) ───────────────────────────
  static const Color background           = Color(0xFF000000);
  static const Color surface             = Color(0xFF0E0E0E);
  static const Color surfaceContainerLow = Color(0xFF131313);
  static const Color surfaceContainerHigh     = Color(0xFF1F1F1F);
  static const Color surfaceContainerHighest  = Color(0xFF262626);
  static const Color surfaceVariant      = Color(0xFF262626);

  static const Color primary             = Color(0xFFC6C6C7);
  static const Color onPrimary           = Color(0xFF3F4041);
  static const Color primaryContainer    = Color(0xFF454747);
  static const Color onPrimaryContainer  = Color(0xFFD0D0D0);

  static const Color tertiary            = Color(0xFFFAF9F9);
  static const Color onTertiary          = Color(0xFF5E5F5F);

  static const Color onSurface          = Color(0xFFE5E5E5);
  static const Color onSurfaceVariant   = Color(0xFFABABAB);
  static const Color outline            = Color(0xFF757575);

  // ─── Tema oscuro de Material ──────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      surface: surface,
      primary: primary,
      onPrimary: onPrimary,
      tertiary: tertiary,
      onTertiary: onTertiary,
      onSurface: onSurface,
    ),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
  );
}