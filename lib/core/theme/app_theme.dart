import 'package:flutter/material.dart';

class AppTheme {
  // Paleta principal — verde escuro
  static const Color primary       = Color(0xFF2D6A4F);
  static const Color primaryLight  = Color(0xFF52B788);
  static const Color primaryPale   = Color(0xFFD8F3DC);
  static const Color primaryDark   = Color(0xFF1B4332);

  // Acento — âmbar
  static const Color accent        = Color(0xFFF4A261);

  // Fundos
  static const Color background    = Color(0xFFFEFAE0); // creme
  static const Color backgroundAlt = Color(0xFFF0EAD2); // creme escuro

  // Textos
  static const Color textDark      = Color(0xFF1A1A1A);
  static const Color textMedium    = Color(0xFF6B7280);

  // Cores por bloco (badge colorido)
  static const _blocoII   = BlocoPalette(Color(0xFFEAF5EE), Color(0xFF1B6535), Color(0xFF2D6A4F));
  static const _blocoIII  = BlocoPalette(Color(0xFFE8F4FD), Color(0xFF1A5276), Color(0xFF2980B9));
  static const _blocoIV   = BlocoPalette(Color(0xFFFEF5E7), Color(0xFF7D6608), Color(0xFFF39C12));
  static const _blocoV    = BlocoPalette(Color(0xFFF9EBEA), Color(0xFF78281F), Color(0xFFC0392B));

  static BlocoPalette blocoColor(String bloco) {
    if (bloco.contains('II'))  return _blocoII;
    if (bloco.contains('III')) return _blocoIII;
    if (bloco.contains('IV'))  return _blocoIV;
    return _blocoV;
  }

  static ThemeData get theme => _buildTheme(Brightness.light);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bgColor       = isDark ? const Color(0xFF121812) : background;
    final surfaceColor  = isDark ? const Color(0xFF1E2A1E) : Colors.white;
    final cardColor     = isDark ? const Color(0xFF243024) : Colors.white;
    final inputFill     = isDark ? const Color(0xFF1A251A) : const Color(0xFFFAFAF8);
    final inputBorder   = isDark ? const Color(0xFF3A4F3A) : const Color(0xFFE5DFD3);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        secondary: accent,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: bgColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: primaryLight, width: 2),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorder, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        color: cardColor,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return null;
        }),
      ),
    );
  }
}

class BlocoPalette {
  final Color background;
  final Color text;
  final Color dot;
  const BlocoPalette(this.background, this.text, this.dot);
}
