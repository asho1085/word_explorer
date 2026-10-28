import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Dark Theme Palette
  static const Color bgDark = Color(0xFF0A1628);
  static const Color bgMedium = Color(0xFF0F1F3D);
  static const Color bgSurface = Color(0xFF142442);
  static const Color bgCard = Color(0xFF172B4D);
  static const Color bgCardLight = Color(0xFF1E355B);

  // Light / White Theme Palette
  static const Color bgLight = Color(0xFFF0F4F9);
  static const Color bgLightMedium = Color(0xFFE2E8F0);
  static const Color bgLightSurface = Color(0xFFF8FAFC);
  static const Color bgLightCard = Color(0xFFFFFFFF);
  static const Color bgLightCardLight = Color(0xFFF1F5F9);

  // Accents (Consistent across themes for branding)
  static const Color emerald = Color(0xFF2ECC71);
  static const Color emeraldDark = Color(0xFF27AE60);
  static const Color gold = Color(0xFFF1C40F);
  static const Color goldDark = Color(0xFFD4AC0D);
  static const Color blue = Color(0xFF3498DB);
  static const Color blueDark = Color(0xFF2980B9);
  static const Color purple = Color(0xFF9B59B6);
  static const Color orange = Color(0xFFE67E22);
  static const Color red = Color(0xFFE74C3C);

  // Text
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDarkPrimary = Color(0xFF0F172A);
  static const Color textDarkMuted = Color(0xFF64748B);

  // Found word highlighter colors
  static const List<Color> wordColors = [
    Color(0xFF38BDF8), // Cyan / Sky
    Color(0xFF2DD4BF), // Mint / Teal
    Color(0xFFFACC15), // Sunny Yellow
    Color(0xFFA3E635), // Lime Green
    Color(0xFFFB923C), // Coral / Salmon
    Color(0xFFF472B6), // Pink / Rose
    Color(0xFFC084FC), // Lavender / Purple
    Color(0xFFF59E0B), // Amber / Gold
    Color(0xFF60A5FA), // Soft Blue
    Color(0xFFFB7185), // Soft Red
    Color(0xFF10B981), // Emerald Green
    Color(0xFFE879F9), // Fuchsia / Magenta
  ];

  // Helper context-aware methods for seamless dynamic styling
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color getBg(BuildContext context) => isDark(context) ? bgDark : bgLight;
  static Color getSurface(BuildContext context) => isDark(context) ? bgSurface : bgLightSurface;
  static Color getCard(BuildContext context) => isDark(context) ? bgCard : bgLightCard;
  static Color getCardLight(BuildContext context) => isDark(context) ? bgCardLight : bgLightCardLight;
  static Color getText(BuildContext context) => isDark(context) ? textLight : textDarkPrimary;
  static Color getMuted(BuildContext context) => isDark(context) ? textMuted : textDarkMuted;
  static Color getBorder(BuildContext context) =>
      isDark(context) ? Colors.white.withAlpha(25) : Colors.black.withAlpha(20);

  // Dark Theme
  static ThemeData get darkThemeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: emerald,
      cardColor: bgCard,
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme,
      ),
      colorScheme: const ColorScheme.dark(
        primary: emerald,
        secondary: gold,
        surface: bgCard,
      ),
    );
  }

  // Light / White Theme
  static ThemeData get lightThemeData {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      primaryColor: emerald,
      cardColor: bgLightCard,
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.light().textTheme,
      ),
      colorScheme: const ColorScheme.light(
        primary: emerald,
        secondary: gold,
        surface: bgLightCard,
      ),
    );
  }

  // Backward compatibility
  static ThemeData get themeData => darkThemeData;
}
