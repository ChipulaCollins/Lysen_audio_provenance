import 'package:flutter/material.dart';

/// Lysen Monochromatic Warm Luxury Palette & Glassmorphism Theme.
/// Palette: #000000 (Pure Black), #D1D0D0 (Metallic Silver), #988686 (Warm Taupe), #5C4E4E (Deep Espresso)
class LysenTheme {
  // Color Tokens
  static const Color bgDark = Color(0xFF000000);
  static const Color bgCard = Color(0xFF0D0A0A);
  static const Color surfaceGlass = Color(0x1AD1D0D0);
  static const Color borderGlass = Color(0x40988686);

  // Brand Palette Accents
  static const Color silverAcc = Color(0xFFD1D0D0);
  static const Color taupeAcc = Color(0xFF988686);
  static const Color espressoAcc = Color(0xFF5C4E4E);
  static const Color pureBlack = Color(0xFF000000);

  // Status Indicators (tailored to palette)
  static const Color successSilver = Color(0xFFE2E8F0);
  static const Color warningTaupe = Color(0xFFB09B9B);
  static const Color errorEspresso = Color(0xFF8B4545);

  // Text Tokens
  static const Color textPrimary = Color(0xFFF4F4F4);
  static const Color textSecondary = Color(0xFFD1D0D0);
  static const Color textMuted = Color(0xFF988686);

  // Luxury Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFD1D0D0), Color(0xFF988686)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient luxuryGradient = LinearGradient(
    colors: [Color(0xFF988686), Color(0xFF5C4E4E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient espressoGradient = LinearGradient(
    colors: [Color(0xFF5C4E4E), Color(0xFF1A1414)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x33D1D0D0), Color(0x0A988686)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bgDark,
      primaryColor: silverAcc,
      colorScheme: const ColorScheme.dark(
        primary: silverAcc,
        secondary: taupeAcc,
        surface: bgCard,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgCard,
        selectedItemColor: silverAcc,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: borderGlass, width: 1.2),
        ),
      ),
    );
  }
}
