import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tkt/connector/ntust_connector.dart';
import 'package:tkt/tasks/ntust_login_task.dart';
import '../providers/demo_mode_provider.dart';
import '../services/demo_service.dart';
import '../services/ntust_auth_service.dart';

class NtustLoginPromptDialog extends StatelessWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const NtustLoginPromptDialog({super.key, this.onConfirm, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<DemoModeProvider>(
      builder: (context, demoModeProvider, child) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('尚未登入'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('您尚未登入台科大系統。是否現在前往登入？'),
              if (demoModeProvider.isDemoModeEnabled) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.preview,
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '演示模式：無需真實登入',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              onPressed: () {
                Navigator.of(context).pop(false);
                if (onCancel != null) onCancel!();
              },
            ),
            if (demoModeProvider.isDemoModeEnabled)
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                ),
                child: const Text('展示功能'),
                onPressed: () async {
                  try {
                    // 在演示模式下，直接設置登入狀態而不進行真實的台科大登入
                    final ntustAuthService = context.read<NtustAuthService>();
                    
                    // 顯示載入指示器
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return const AlertDialog(
                          content: Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 20),
                              Text('啟用演示模式...'),
                            ],
                          ),
                        );
                      },
                    );
                    
                    final result = await ntustAuthService.login(
                      DemoService.getDemoStudentId(),
                      "demo_password",
                    );
                    
                    // 關閉載入指示器
                    Navigator.of(context).pop();
                    
                    if (result.contains('演示模式已啟用') || result.contains('成功')) {
                      Navigator.of(context).pop(true);
                      if (onConfirm != null) onConfirm!();
                      
                      // 顯示演示模式提示
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('演示模式已啟用 - 所有資料僅供展示'),
                          backgroundColor: theme.colorScheme.primary,
                          duration: const Duration(seconds: 3),
                        )
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result))
                      );
                    }
                  } catch (e) {
                    // 關閉可能還開著的載入指示器
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('演示模式啟用失敗: $e'))
                    );
                  }
                },
              ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: const Text('前往登入'),
              onPressed: () async {
                // 可加 loading
                final result = await LoginTask.loginWithFallback(context);
                if (result['status'] == NTUSTLoginStatus.success) {
                  Navigator.of(context).pop(true);
                  if (onConfirm != null) onConfirm!();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(result['message']?.toString() ?? '登入失敗')));
                }
              },
            ),
          ],
        );
      },
    );
  }
}
