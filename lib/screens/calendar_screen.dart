import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/calendar_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    // 在進入頁面時自動載入行事曆
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalendarService>().fetchCalendars();
    });
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('無法開啟網址: $url');
    }
  }

  Widget _buildInstructionCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, 
                  color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('如何使用',
                  style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            const Text('1. 選擇想要的學年度行事曆'),
            const Text('2. 點擊下載按鈕'),
            const Text('3. 檔案會自動下載到您的裝置'),
            const Text('4. 使用 Excel 或其他試算表軟體開啟'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('行事曆下載'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CalendarService>().refresh();
            },
          ),
        ],
      ),
      body: Consumer<CalendarService>(
        builder: (context, calendarService, child) {
          if (calendarService.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (calendarService.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(calendarService.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      calendarService.refresh();
                    },
                    child: const Text('重試'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => calendarService.refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: calendarService.calendars.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildInstructionCard();
                }

                final calendar = calendarService.calendars[index - 1];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(calendar.title),
                    subtitle: calendar.description != null
                        ? Text(calendar.description!,
                            style: const TextStyle(fontSize: 12))
                        : null,
                    trailing: ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('下載'),
                      onPressed: () async {
                        try {
                          await _launchURL(calendar.url);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('無法下載行事曆: $e'),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
} 