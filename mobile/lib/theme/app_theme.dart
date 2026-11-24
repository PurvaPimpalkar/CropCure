import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Color Palette (Mutable for Theme Switching) ──────────────────────────
  static Color primary        = const Color(0xFF1B5E20);   // Deep green
  static Color primaryLight   = const Color(0xFF4CAF50);   // Light green
  static Color primaryDark    = const Color(0xFF003300);   // Darker green
  static Color accent         = const Color(0xFF8D6E63);   // Earthy brown/tone
  static Color accentLight    = const Color(0xFFA1887F);
  static Color background     = const Color(0xFFF9FBE7);   // Soft off-white / pale lime
  static Color surface        = const Color(0xFFFFFFFF);   // White surface
  static Color surfaceLight   = const Color(0xFFF1F8E9);   // Very light green surface
  static Color cardColor      = const Color(0xFFFFFFFF);   // White cards
  static Color textPrimary    = const Color(0xFF212121);   // Dark grey text
  static Color textSecondary  = const Color(0xFF424242);   // Medium grey text
  static Color textMuted      = const Color(0xFF757575);   // Muted grey
  static Color error          = const Color(0xFFD32F2F);
  static Color warning        = const Color(0xFFF57C00);
  static Color success        = const Color(0xFF388E3C);
  static Color divider        = const Color(0xFFE0E0E0);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient backgroundGradient = LinearGradient(
    colors: [background, surfaceLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient cardGradient = LinearGradient(
    colors: [surface, surfaceLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: primary.withOpacity(0.02),
      blurRadius: 20,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> primaryShadow = [
    BoxShadow(
      color: primary.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  static void configure(bool isDark) {
    if (isDark) {
      primary        = const Color(0xFF2E7D32);
      primaryLight   = const Color(0xFF4CAF50);
      primaryDark    = const Color(0xFF1B5E20);
      accent         = const Color(0xFFF9A825);
      accentLight    = const Color(0xFFFFD54F);
      background     = const Color(0xFF0D1F10); // Dark grey background
      surface        = const Color(0xFF162B19); 
      surfaceLight   = const Color(0xFF1E3B22);
      cardColor      = const Color(0xFF1A3020);
      textPrimary    = const Color(0xFFFFFFFF); // Pure white for dark mode
      textSecondary  = const Color(0xFFE8F5E9); // Near white light green
      textMuted      = const Color(0xFFA5D6A7); // Visible muted green
      error          = const Color(0xFFEF5350);
      warning        = const Color(0xFFF57C00);
      success        = const Color(0xFF81C784);
      divider        = const Color(0xFF2E4A32);
      cardShadow = [
        BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
        BoxShadow(color: primary.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 2)),
      ];
      primaryShadow = [BoxShadow(color: primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))];
    } else {
      primary        = const Color(0xFF1B5E20);
      primaryLight   = const Color(0xFF4CAF50);
      primaryDark    = const Color(0xFF003300);
      accent         = const Color(0xFF8D6E63);
      accentLight    = const Color(0xFFA1887F);
      background     = const Color(0xFFF9FBE7);
      surface        = const Color(0xFFFFFFFF);
      surfaceLight   = const Color(0xFFF1F8E9);
      cardColor      = const Color(0xFFFFFFFF);
      textPrimary    = const Color(0xFF212121);
      textSecondary  = const Color(0xFF424242);
      textMuted      = const Color(0xFF757575);
      error          = const Color(0xFFD32F2F);
      warning        = const Color(0xFFF57C00);
      success        = const Color(0xFF388E3C);
      divider        = const Color(0xFFE0E0E0);
      cardShadow = [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        BoxShadow(color: primary.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 2)),
      ];
      primaryShadow = [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))];
    }

    primaryGradient = LinearGradient(colors: [primary, primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight);
    backgroundGradient = LinearGradient(colors: [background, surfaceLight], begin: Alignment.topCenter, end: Alignment.bottomCenter);
    cardGradient = LinearGradient(colors: [surface, surfaceLight], begin: Alignment.topLeft, end: Alignment.bottomRight);
    accentGradient = LinearGradient(colors: [accent, accentLight], begin: Alignment.centerLeft, end: Alignment.centerRight);
  }

  // ── Text Styles ───────────────────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5);
  static TextStyle get displayMedium => GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w600, color: textPrimary);
  static TextStyle get headlineLarge => GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary);
  static TextStyle get headlineMedium => GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary);
  static TextStyle get headlineSmall => GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary);
  static TextStyle get bodyLarge => GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary, height: 1.6);
  static TextStyle get bodyMedium => GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400, color: textSecondary, height: 1.5);
  static TextStyle get bodySmall => GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400, color: textMuted);
  static TextStyle get labelLarge => GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: 0.5);
  static TextStyle get labelMedium => GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary);

  // ── Theme Data ────────────────────────────────────────────────────────────
  static ThemeData getTheme(bool isDark) {
    return ThemeData(
      useMaterial3: true,
      brightness:   isDark ? Brightness.dark : Brightness.light,
      colorScheme: isDark ? ColorScheme.dark(primary: primary, secondary: accent, surface: surface, error: error) 
                          : ColorScheme.light(primary: primary, secondary: accent, surface: surface, error: error),
      scaffoldBackgroundColor: background,
      cardColor:  cardColor,
      dividerColor: divider,

      appBarTheme: AppBarTheme(
        backgroundColor:  Colors.transparent,
        elevation:        0,
        centerTitle:      true,
        titleTextStyle:   GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:  primary,
          foregroundColor:  Colors.white,
          elevation:        2,
          shadowColor:      primary.withValues(alpha: 0.4),
          padding:          const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape:            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle:        GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   surface,
        border:      OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primary, width: 2)),
        hintStyle:   GoogleFonts.poppins(color: textMuted, fontSize: 14),
      ),

      iconTheme: IconThemeData(color: primary),
    );
  }
}

