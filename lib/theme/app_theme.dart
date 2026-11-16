import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Dark Theme Palette (Matching Web CSS Tokens)
  static const Color bgDark = Color(0xFF041522);
  static const Color bgMedium = Color(0xFF081D33);
  static const Color bgSurface = Color(0xFF0C2139);
  static const Color bgCard = Color(0xFF0B2039);
  static const Color bgCardLight = Color(0xFF132A49);

  // Light / White Theme Palette
  static const Color bgLight = Color(0xFFF0F4F9);
  static const Color bgLightMedium = Color(0xFFE2E8F0);
  static const Color bgLightSurface = Color(0xFFF8FAFC);
  static const Color bgLightCard = Color(0xFFFFFFFF);
  static const Color bgLightCardLight = Color(0xFFF1F5F9);

  // Accents (Consistent across themes for branding)
  static const Color emerald = Color(0xFF00DF91);
  static const Color emeraldDark = Color(0xFF00AD76);
  static const Color gold = Color(0xFFFFD12E);
  static const Color goldDark = Color(0xFFD4AC0D);
  static const Color blue = Color(0xFF32B9EF);
  static const Color blueDark = Color(0xFF2980B9);
  static const Color royalBlue = Color(0xFF4169E1);
  static const Color royalBlueDark = Color(0xFF2563EB);
  static const Color purple = royalBlue; // Replaced with royal blue
  static const Color orange = Color(0xFFFFA01C);
  static const Color red = Color(0xFFFF424F);

  // Text
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFFA5B8D7);
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
    Color(0xFF4169E1), // Royal Blue
    Color(0xFFF59E0B), // Amber / Gold
    Color(0xFF60A5FA), // Soft Blue
    Color(0xFFFB7185), // Soft Red
    Color(0xFF10B981), // Emerald Green
    Color(0xFFE879F9), // Fuchsia / Magenta
  ];

  // Helper context-aware methods for seamless dynamic styling
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color getBg(BuildContext context) =>
      isDark(context) ? bgDark : bgLight;
  static Color getSurface(BuildContext context) =>
      isDark(context) ? bgSurface : bgLightSurface;
  static Color getCard(BuildContext context) =>
      isDark(context) ? bgCard : bgLightCard;
  static Color getCardLight(BuildContext context) =>
      isDark(context) ? bgCardLight : bgLightCardLight;
  static Color getText(BuildContext context) =>
      isDark(context) ? textLight : textDarkPrimary;
  static Color getMuted(BuildContext context) =>
      isDark(context) ? textMuted : textDarkMuted;
  static Color getBorder(BuildContext context) =>
      isDark(context) ? Colors.white.withAlpha(25) : Colors.black.withAlpha(20);

  // Dark Theme
  static ThemeData get darkThemeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: emerald,
      cardColor: bgCard,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
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
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
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
