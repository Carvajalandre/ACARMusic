import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Color tokens extraídos de los HTMLs del proyecto Stitch ───
  static const Color background        = Color(0xFF000000);
  static const Color surface           = Color(0xFF0E0E0E);
  static const Color surfaceDim        = Color(0xFF0E0E0E);
  static const Color surfaceContainerLowest = Color(0xFF000000);
  static const Color surfaceContainerLow   = Color(0xFF131313);
  static const Color surfaceContainer      = Color(0xFF191919);
  static const Color surfaceContainerHigh  = Color(0xFF1F1F1F);
  static const Color surfaceContainerHighest = Color(0xFF262626);
  static const Color surfaceBright     = Color(0xFF2C2C2C);
  static const Color surfaceVariant    = Color(0xFF262626);

  static const Color primary           = Color(0xFFC6C6C7);
  static const Color onPrimary         = Color(0xFF3F4041);
  static const Color primaryContainer  = Color(0xFF454747);
  static const Color onPrimaryContainer = Color(0xFFD0D0D0);

  static const Color secondary         = Color(0xFF9F9D9D);
  static const Color onSecondary       = Color(0xFF202020);
  static const Color secondaryContainer = Color(0xFF3C3B3B);
  static const Color onSecondaryContainer = Color(0xFFC1BFBE);

  static const Color tertiary          = Color(0xFFFAF9F9); // botón play
  static const Color onTertiary        = Color(0xFF5E5F5F);

  static const Color onSurface        = Color(0xFFE5E5E5);
  static const Color onSurfaceVariant = Color(0xFFABABAB);
  static const Color onBackground     = Color(0xFFE5E5E5);

  static const Color outline          = Color(0xFF757575);
  static const Color outlineVariant   = Color(0xFF484848);

  static const Color error            = Color(0xFFEC7C8A);
  static const Color onError          = Color(0xFF490013);
  static const Color errorContainer   = Color(0xFF7F2737);

  // ─── ThemeData ───────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.manropeTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        surface: surface,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.manrope(
          color: onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: onSurface,
        unselectedItemColor: Color(0xFF757575),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: tertiary,
        inactiveTrackColor: surfaceVariant.withOpacity(0.5),
        thumbColor: Colors.white,
        overlayColor: Colors.white.withOpacity(0.1),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? onPrimary : outline),
        trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? primary : surfaceVariant),
      ),
      iconTheme: const IconThemeData(color: onSurface, size: 24),
      dividerColor: outlineVariant.withOpacity(0.3),
      splashColor: Colors.white.withOpacity(0.04),
      highlightColor: Colors.transparent,
    );
  }
}
