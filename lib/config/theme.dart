import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 包豪斯風格的配色方案 - 稍微柔和版本
  static const Color bauhausBlack = Color(0xFF2D2D2D); // 稍微柔和的黑色
  static const Color bauhausWhite = Color(0xFFFFFFFF);
  static const Color bauhausGrey = Color(0xFF6B6B6B); // 更溫暖的灰色
  static const Color bauhausLightGrey = Color(0xFFF8F8F8); // 更溫暖的淺灰
  static const Color bauhausRed = Color(0xFFE53E3E);
  static const Color bauhausBlue = Color(0xFF3182CE);
  static const Color bauhausYellow = Color(0xFFD69E2E);
  static const Color bauhausBorder = Color(0xFFE5E5E5); // 柔和的邊框色

  static ThemeData buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    // 包豪斯風格強調對比，不管深色淺色都使用強烈對比
    final primaryColor = isDark ? bauhausWhite : bauhausBlack;
    final backgroundColor = isDark ? bauhausBlack : bauhausWhite;
    final surfaceColor = isDark ? Color(0xFF1A1A1A) : bauhausWhite;
    final textColor = isDark ? bauhausWhite : bauhausBlack;
    final secondaryTextColor = isDark ? Color(0xFFB0B0B0) : bauhausGrey;
    final borderColor = isDark ? Color(0xFF404040) : bauhausBorder;

    // 使用更現代、簡潔的字體
    final textTheme = GoogleFonts.robotoTextTheme().copyWith(
      // 標題使用更輕的字重
      headlineLarge: TextStyle(
        color: textColor, 
        fontSize: 28, 
        fontWeight: FontWeight.w300,
        letterSpacing: 1.5,
      ),
      headlineMedium: TextStyle(
        color: textColor, 
        fontSize: 24, 
        fontWeight: FontWeight.w300,
        letterSpacing: 1.2,
      ),
      headlineSmall: TextStyle(
        color: textColor, 
        fontSize: 20, 
        fontWeight: FontWeight.w300,
        letterSpacing: 1.0,
      ),
      titleLarge: TextStyle(
        color: textColor, 
        fontSize: 18, 
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      titleMedium: TextStyle(
        color: textColor, 
        fontSize: 16, 
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      titleSmall: TextStyle(
        color: secondaryTextColor, 
        fontSize: 14, 
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
      ),
      bodyLarge: TextStyle(
        color: textColor, 
        fontSize: 16, 
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
      ),
      bodyMedium: TextStyle(
        color: textColor, 
        fontSize: 14, 
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
      ),
      bodySmall: TextStyle(
        color: secondaryTextColor, 
        fontSize: 12, 
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
      ),
      labelLarge: TextStyle(
        color: textColor, 
        fontSize: 14, 
        fontWeight: FontWeight.w500,
        letterSpacing: 0.8,
      ),
      labelMedium: TextStyle(
        color: textColor, 
        fontSize: 12, 
        fontWeight: FontWeight.w500,
        letterSpacing: 0.8,
      ),
      labelSmall: TextStyle(
        color: secondaryTextColor, 
        fontSize: 10, 
        fontWeight: FontWeight.w500,
        letterSpacing: 0.8,
      ),
    );

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? bauhausBlack : bauhausLightGrey,
      textTheme: textTheme,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: backgroundColor,
        secondary: bauhausGrey,
        onSecondary: bauhausWhite,
        error: bauhausRed,
        onError: bauhausWhite,
        background: backgroundColor,
        onBackground: textColor,
        surface: surfaceColor,
        onSurface: textColor,
      ),
      // AppBar 包豪斯風格
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        titleTextStyle: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w300,
          letterSpacing: 2.0,
        ),
      ),
      // 卡片風格 - 輕微圓角，柔和邊框
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // 輕微圓角
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      // 按鈕風格 - 柔和圓角
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6), // 輕微圓角
            side: BorderSide(color: primaryColor, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: textTheme.labelLarge,
        ),
      ),
      // 文字按鈕風格
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: textTheme.labelMedium,
        ),
      ),
      // 底部導航
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: textColor,
        unselectedItemColor: secondaryTextColor,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      // 列表項目
      listTileTheme: ListTileThemeData(
        selectedTileColor: Colors.transparent,
        selectedColor: textColor,
        iconColor: textColor,
        textColor: textColor,
        subtitleTextStyle: textTheme.bodySmall,
        tileColor: Colors.transparent,
      ),
      // 輸入框 - 柔和圓角
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6), // 輕微圓角
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: textColor, width: 2),
        ),
        hintStyle: TextStyle(color: secondaryTextColor),
      ),
      // 開關
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return textColor;
          }
          return secondaryTextColor;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return textColor.withOpacity(0.3);
          }
          return secondaryTextColor.withOpacity(0.3);
        }),
      ),
    );
  }
} 