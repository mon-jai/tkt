import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/navi/navi_screen.dart';
import 'services/storage_service.dart';
import 'services/course_service.dart';
import 'services/calendar_service.dart';
import 'services/ntust_auth_service.dart';
import 'services/notification_service.dart';
import 'providers/theme_provider.dart';
import 'providers/announcement_provider.dart';
import 'providers/language_provider.dart';
import 'config/theme.dart';
import 'config/language.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化通知服務
  await NotificationService.initialize();
  
  // 請求通知權限
  try {
    final hasPermission = await NotificationService.areNotificationsEnabled();
    if (!hasPermission) {
      await NotificationService.requestPermissions();
    }
  } catch (e) {
    print('請求通知權限時發生錯誤: $e');
  }
  
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<NtustAuthService>(
          create: (_) => NtustAuthService(),
          lazy: false,
        ),
        Provider<StorageService>(
          create: (_) => storageService,
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(storageService),
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
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        return MaterialApp(
          title: languageProvider.translate('app_name'),
          theme: AppTheme.buildTheme(Brightness.light),
          darkTheme: AppTheme.buildTheme(Brightness.dark),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          locale: languageProvider.currentLocale,
          supportedLocales: AppLanguage.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: FutureBuilder(
            future: Future.delayed(const Duration(seconds: 2)), // 初始化載入時間
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('系統初始化中...'),
                      ],
                    ),
                  ),
                );
              }
              return const NaviScreen();
            },
          ),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}