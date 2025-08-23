import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/course_model.dart';

class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  String _statusText = '準備測試通知...';
  bool _isLoading = false;
  bool? _permissionStatus;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
      _statusText = '檢查通知權限中...';
    });

    try {
      await NotificationService.initialize();
      final hasPermission = await NotificationService.areNotificationsEnabled();
      
      setState(() {
        _permissionStatus = hasPermission;
        _statusText = hasPermission ? '✅ 通知權限已開啟' : '❌ 通知權限未開啟';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusText = '❌ 檢查權限時發生錯誤: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
      _statusText = '請求通知權限中...';
    });

    try {
      final granted = await NotificationService.requestPermissions();
      
      setState(() {
        _permissionStatus = granted;
        _statusText = granted ? '✅ 通知權限已獲得' : '❌ 通知權限被拒絕';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusText = '❌ 請求權限時發生錯誤: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() {
      _isLoading = true;
      _statusText = '發送測試通知中...';
    });

    try {
      await NotificationService.sendTestNotification();
      
      setState(() {
        _statusText = '✅ 測試通知已發送！請檢查通知中心';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusText = '❌ 發送通知時發生錯誤: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _scheduleTestNotification() async {
    setState(() {
      _isLoading = true;
      _statusText = '安排定時通知中...';
    });

    try {
      // 創建一個 5 秒後的測試課程
      final testCourse = Course(
        id: 'scheduled_test_${DateTime.now().millisecondsSinceEpoch}',
        name: '定時測試課程',
        teacher: '測試老師',
        classroom: '測試教室',
        dayOfWeek: DateTime.now().weekday,
        startSlot: 1,
        endSlot: 2,
        note: '這是一個定時測試通知',
      );

      final scheduledTime = DateTime.now().add(const Duration(seconds: 5));
      
      await NotificationService.scheduleNotification(
        course: testCourse,
        scheduledTime: scheduledTime,
        title: '定時測試通知',
        body: '這是一個 5 秒後的定時通知測試',
      );
      
      setState(() {
        _statusText = '✅ 定時通知已安排！將在 5 秒後顯示';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusText = '❌ 安排定時通知時發生錯誤: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知測試'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '通知狀態',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusText,
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkPermissions,
              icon: const Icon(Icons.refresh),
              label: const Text('重新檢查權限'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _requestPermissions,
              icon: const Icon(Icons.notifications_active),
              label: const Text('請求通知權限'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton.icon(
              onPressed: (_isLoading || _permissionStatus != true) ? null : _sendTestNotification,
              icon: const Icon(Icons.send),
              label: const Text('發送即時測試通知'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton.icon(
              onPressed: (_isLoading || _permissionStatus != true) ? null : _scheduleTestNotification,
              icon: const Icon(Icons.schedule),
              label: const Text('安排定時測試通知 (5秒後)'),
            ),
            
            const SizedBox(height: 20),
            
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '測試說明',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. 首先檢查並請求通知權限\n'
                      '2. 如果權限被拒絕，請到設定中手動開啟\n'
                      '3. 測試即時通知和定時通知功能\n'
                      '4. 如果 iOS 沒有顯示通知，請檢查:\n'
                      '   - 設定 > 通知 > 您的App\n'
                      '   - 確保允許通知已開啟\n'
                      '   - 確保提醒樣式不是「無」',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
