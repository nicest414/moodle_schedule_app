import 'package:flutter/foundation.dart';

/// アプリ全体のログ出力を管理するユーティリティクラス
/// デバッグ時のみログを出力し、本番環境ではログを無効化
class AppLogger {
  static const String _appTag = '[MoodleApp]';
  
  /// 情報ログを出力するメソッド
  /// 通常の動作ログや成功メッセージに使用
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('$_appTag${tag != null ? '[$tag]' : ''} ℹ️ $message');
    }
  }
  
  /// 成功ログを出力するメソッド
  /// 処理が正常に完了した場合に使用
  static void success(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('$_appTag${tag != null ? '[$tag]' : ''} ✅ $message');
    }
  }
  
  /// 警告ログを出力するメソッド
  /// 問題はないが注意が必要な場合に使用
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('$_appTag${tag != null ? '[$tag]' : ''} ⚠️ $message');
    }
  }
  
  /// エラーログを出力するメソッド
  /// エラーや例外が発生した場合に使用
  static void error(String message, {String? tag, Object? error}) {
    if (kDebugMode) {
      debugPrint('$_appTag${tag != null ? '[$tag]' : ''} ❌ $message');
      if (error != null) {
        debugPrint('$_appTag${tag != null ? '[$tag]' : ''} 🔍 詳細: $error');
      }
    }
  }
  
  /// データ処理ログを出力するメソッド
  /// データの取得、保存、変換処理時に使用
  static void data(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('$_appTag${tag != null ? '[$tag]' : ''} 💾 $message');
    }
  }
  
  /// API通信ログを出力するメソッド
  /// WebViewやHTTP通信時に使用
  static void network(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('$_appTag${tag != null ? '[$tag]' : ''} 🌐 $message');
    }
  }
  
  /// UI操作ログを出力するメソッド
  /// ユーザー操作や画面遷移時に使用
  static void ui(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('$_appTag${tag != null ? '[$tag]' : ''} 🎨 $message');
    }
  }
  
  /// 通知ログを出力するメソッド
  /// プッシュ通知関連の処理時に使用
  static void notification(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('$_appTag${tag != null ? '[$tag]' : ''} 🔔 $message');
    }
  }
  
  /// デバッグ専用ログを出力するメソッド
  /// 詳細なデバッグ情報を出力する場合に使用
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('$_appTag${tag != null ? '[$tag]' : ''} 🐛 $message');
    }
  }
}

/// ログレベルを定義する列挙型
enum LogLevel {
  debug,    // デバッグ情報
  info,     // 一般情報
  warning,  // 警告
  error,    // エラー
}

/// 特定のクラス専用のロガーを提供するミックスイン
/// 各クラスに適用することで、クラス名をタグとして自動設定
mixin LoggerMixin {
  String get _className => runtimeType.toString();
  
  void logInfo(String message) => AppLogger.info(message, tag: _className);
  void logSuccess(String message) => AppLogger.success(message, tag: _className);
  void logWarning(String message) => AppLogger.warning(message, tag: _className);
  void logError(String message, {Object? error}) => AppLogger.error(message, tag: _className, error: error);
  void logData(String message) => AppLogger.data(message, tag: _className);
  void logNetwork(String message) => AppLogger.network(message, tag: _className);
  void logUI(String message) => AppLogger.ui(message, tag: _className);
  void logNotification(String message) => AppLogger.notification(message, tag: _className);
  void logDebug(String message) => AppLogger.debug(message, tag: _className);
}
