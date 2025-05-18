import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primaryBlue = isDark ? Colors.blue.shade200 : Colors.blue;
    final accentBlue = isDark ? Colors.blue.shade300 : const Color(0xFF42A5F5);
    final textColor = isDark ? Colors.white : Colors.black87;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE3F2FD);
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    final textTheme = GoogleFonts.latoTextTheme().copyWith(
      bodyLarge: TextStyle(color: textColor),
      bodyMedium: TextStyle(color: textColor.withOpacity(0.87)),
      bodySmall: TextStyle(color: secondaryTextColor),
      titleLarge: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: primaryBlue, fontSize: 18, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(color: secondaryTextColor),
      titleSmall: TextStyle(color: secondaryTextColor),
    );

    return ThemeData(
      brightness: brightness,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: brightness,
        primary: primaryBlue,
        secondary: accentBlue,
        surface: surfaceColor,
        background: backgroundColor,
        onBackground: textColor,
        onSurface: textColor,
        onSecondary: secondaryTextColor,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? surfaceColor : Colors.white,
        selectedItemColor: isDark ? Colors.white : primaryBlue,
        unselectedItemColor: secondaryTextColor,
        selectedIconTheme: isDark ? IconThemeData(
          color: const Color.fromARGB(255, 100, 139, 229),
          size: 24,
        ) : IconThemeData(
          color: primaryBlue,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: secondaryTextColor,
          size: 24,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: isDark ? 0 : 8,
      ),
      listTileTheme: ListTileThemeData(
        selectedTileColor: isDark ? Colors.white.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
        selectedColor: isDark ? Colors.white : Colors.blue,
        iconColor: isDark ? Colors.white70 : Colors.blue,
        textColor: textColor,
        subtitleTextStyle: TextStyle(color: secondaryTextColor),
        tileColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: isDark ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28.0),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: isDark,
        fillColor: isDark ? surfaceColor : null,
        hintStyle: TextStyle(color: secondaryTextColor),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: textColor.withOpacity(0.2)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: primaryBlue, width: 2.0),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryBlue;
          }
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryBlue.withOpacity(0.5);
          }
          return null;
        }),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? surfaceColor : primaryBlue,
        foregroundColor: isDark ? textColor : Colors.white,
        elevation: isDark ? 0 : 2,
      ),
    );
  }
} 