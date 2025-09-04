import 'package:flutter/material.dart';
import 'package:tkt/connector/ntust_connector.dart';
import 'package:tkt/tasks/ntust_login_task.dart';

class NtustLoginPromptDialog extends StatelessWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const NtustLoginPromptDialog({super.key, this.onConfirm, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('尚未登入'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('您尚未登入台科大系統。是否現在前往登入？'),
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
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: const Text('前往登入'),
          onPressed: () async {
            final result = await LoginTask.loginWithFallback(context);
            if (result['status'] == NTUSTLoginStatus.success) {
              Navigator.of(context).pop(true);
              if (onConfirm != null) onConfirm!();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message']?.toString() ?? '登入失敗'),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
