import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final String text;
  final String iconAssetPath; // 本地圖片資源路徑
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    required this.text,
    required this.iconAssetPath,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 建立基礎的 OutlinedButton 樣式
    final ButtonStyle baseOutlineStyle = OutlinedButton.styleFrom(
      foregroundColor: colorScheme.primary, // 文字和圖示顏色 (橙黃色)
      side: BorderSide(color: colorScheme.primary, width: 1.5), // 邊框顏色 (橙黃色)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28.0), // 圓角
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), // 內邊距
      textStyle: textTheme.labelLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600), // 設定文字樣式
    ).merge( // 合併按下時的波紋效果
      ButtonStyle(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return colorScheme.primary.withOpacity(0.12); // 按下時的波紋顏色
            }
            return null; // 使用預設值
          },
        ),
      )
    );

    // 為了讓 OutlinedButton 背景透明並移除陰影，我們可以這樣做：
    // OutlinedButton 預設背景就是透明的，我們只需要確保沒有不必要的 ElevatedButton 特性。
    // 如果您想要更精確地控制，可以直接使用 ButtonStyle 來設定。

    return OutlinedButton(
      style: baseOutlineStyle, // 直接應用我們定義好的樣式
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset(
            iconAssetPath,
            height: 24.0,
            width: 24.0,
            errorBuilder: (context, error, stackTrace) { // 處理圖示載入失敗
              return Icon(Icons.login, color: colorScheme.primary, size: 24.0); // 預設圖示
            },
          ),
          const SizedBox(width: 12),
          Text(text), // 文字會自動應用 OutlinedButton 的 textStyle (已在 baseOutlineStyle 中設定)
        ],
      ),
    );
  }
}
