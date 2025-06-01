import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'screens/splash_screen.dart'; // スプラッシュ画面を表示
import 'providers/settings_provider.dart';
import 'utils/app_theme.dart'; // テーマ設定を統一管理

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        // ダークモード設定を監視
        final isDarkMode =
            ref
                .watch(settingsProvider)
                .isDarkMode; // settingsProviderからisDarkModeを取得

        return MaterialApp(
          title: 'Moodle Schedule App',          // テーマ設定（ライト・ダーク対応）- AppThemeクラスを使用
          theme: AppTheme.getThemeData(false),
          darkTheme: AppTheme.getThemeData(true),
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
          // デバッグバナーを非表示
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
