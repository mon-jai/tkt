import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/course_service.dart';
import 'services/calendar_service.dart';
import 'providers/theme_provider.dart';
import 'providers/announcement_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<StorageService>(
          create: (_) => storageService,
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(storageService),
        ),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
        ChangeNotifierProvider(create: (_) => CourseService()),
        ChangeNotifierProvider(create: (_) => CalendarService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: '台科通',
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: Consumer<AuthService>(
            builder: (context, authService, child) {
              if (authService.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return authService.isLoggedIn ? const MainScreen() : const LoginScreen();
            },
          ),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primaryBlue = isDark ? Colors.blue.shade200 : Colors.blue;
    final accentBlue = isDark ? Colors.blue.shade300 : const Color(0xFF42A5F5);
    final textColor = isDark ? Colors.white : Colors.black87;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE3F2FD);

    return ThemeData(
      brightness: brightness,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.latoTextTheme().copyWith(
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: textColor.withOpacity(0.87)),
        titleLarge: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: primaryBlue, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: brightness,
        primary: primaryBlue,
        secondary: accentBlue,
        surface: surfaceColor,
        background: backgroundColor,
        onBackground: textColor,
        onSurface: textColor,
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
        hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
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