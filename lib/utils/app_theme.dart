import 'package:flutter/material.dart';

/// アプリ全体のテーマ・カラーを管理するクラス
/// UI全体での色の統一感を保つ
class AppTheme {
  // プライバシー強化のためインスタンス化を禁止
  AppTheme._();

  // アプリのメインカラー（わせだ色系）
  static const Color primaryColor = Color(0xFF9B0019); // わせだカラー（濃い赤）
  static const Color secondaryColor = Color(0xFF005CB9); // 青色系（アクセントカラー）
  
  // 課題関連の色
  static const Color overdueColor = Color(0xFFD32F2F); // 期限切れ（赤）
  static const Color urgentColor = Color(0xFFFF9800); // 今日締切（オレンジ）
  static const Color warningColor = Color(0xFFFFC107); // 3日以内（黄色）
  static const Color normalColor = Color(0xFF2196F3); // 通常（青）
  static const Color completeColor = Color(0xFF4CAF50); // 完了（緑）
  
  // テキスト色
  static const Color primaryTextColor = Color(0xFF212121); // メインテキスト
  static const Color secondaryTextColor = Color(0xFF757575); // 補助テキスト
  
  // 背景色
  static const Color scaffoldBackgroundColor = Color(0xFFFAFAFA); // 画面背景
  static const Color cardBackgroundColor = Colors.white; // カード背景
  
  // UI要素
  static const Color dividerColor = Color(0xFFEEEEEE); // 区切り線
  
  /// 残り日数に基づく色を取得
  static Color getDeadlineColor(int daysRemaining) {
    if (daysRemaining < 0) {
      return overdueColor;
    } else if (daysRemaining == 0) {
      return urgentColor;
    } else if (daysRemaining <= 3) {
      return warningColor;
    } else {
      return normalColor;
    }
  }
  
  /// テーマデータを生成（アプリ全体のテーマ設定）
  static ThemeData getThemeData(bool isDarkMode) {
    return isDarkMode ? _getDarkTheme() : _getLightTheme();
  }
  
  /// ライトテーマの設定
  static ThemeData _getLightTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
      ),
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      dividerColor: dividerColor,
      textTheme: _getTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
  
  /// ダークテーマの設定
  static ThemeData _getDarkTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F1F1F),
        elevation: 0,
      ),
    );
  }
  
  /// テキストテーマの設定
  static TextTheme _getTextTheme() {
    return const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: primaryTextColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: primaryTextColor,
      ),
      titleLarge: TextStyle(
        fontSize: 18, 
        fontWeight: FontWeight.w500,
        color: primaryTextColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: primaryTextColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: primaryTextColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: secondaryTextColor,
      ),
    );
  }
}
