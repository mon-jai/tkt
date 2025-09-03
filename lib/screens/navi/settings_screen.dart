import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ...existing imports...
import 'package:tkt/screens/account_storage_page.dart';
import '../../providers/theme_provider.dart';
import '../../providers/demo_mode_provider.dart';
import '../setting/about/about_screen.dart';
import '../setting/notification/notification_screen.dart';





class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        elevation: 0,
      ),
      body: Consumer2<ThemeProvider, DemoModeProvider>(
        builder: (context, themeProvider, demoModeProvider, child) {
          return ListView(
            children: [
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('通知設定'),
                subtitle: const Text('課程提醒設定'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                },
              ),

              const Divider(),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('深色模式'),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (bool value) {
                    themeProvider.toggleTheme();
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.preview,
                  color: demoModeProvider.isDemoModeEnabled 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
                ),
                title: const Text('演示模式'),
                subtitle: Text(
                  demoModeProvider.isDemoModeEnabled 
                    ? 'Apple審核用演示模式 (已啟用)' 
                    : '提供演示數據供App Store審核使用',
                ),
                trailing: Switch(
                  value: demoModeProvider.isDemoModeEnabled,
                  onChanged: demoModeProvider.isLoading 
                    ? null 
                    : (bool value) async {
                        await demoModeProvider.toggleDemoMode();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value ? '演示模式已啟用' : '演示模式已停用',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                ),
              ),
              const Divider(),
              // 登入測試項目已移除
              ListTile(
                leading: const Icon(Icons.fingerprint),
                title: const Text('校園系統帳號'),
                subtitle: const Text('儲存校園系統帳號'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountStoragePage(),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('關於'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
} 