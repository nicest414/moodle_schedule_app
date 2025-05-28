import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'assignments_provider.dart';
import '../utils/logger.dart'; // ロガーをインポート

/// ローカルストレージを管理するクラス
/// 課題データの永続化と復元を担当
class StorageService {
  static const String _assignmentsKey = 'assignments_data';
  static const String _lastUpdateKey = 'last_update_time';
  static const String _userSettingsKey = 'user_settings';

  /// 課題データをローカルストレージに保存するメソッド
  /// 課題リストをJSON形式で永続化
  static Future<bool> saveAssignments(List<Assignment> assignments) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 課題リストをMapのリストに変換
      final assignmentMaps = assignments.map((assignment) => assignment.toMap()).toList();
      
      // JSON文字列に変換して保存
      final jsonString = jsonEncode(assignmentMaps);
      final result = await prefs.setString(_assignmentsKey, jsonString);
        // 最終更新時刻も保存
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      
      AppLogger.success('課題データ保存完了: ${assignments.length}件', tag: 'Storage');
      return result;
    } catch (e) {
      AppLogger.error('課題データ保存エラー', tag: 'Storage', error: e);
      return false;
    }
  }

  /// ローカルストレージから課題データを復元するメソッド
  /// 保存されたJSON形式のデータを課題オブジェクトに変換
  static Future<List<Assignment>> loadAssignments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_assignmentsKey);
        if (jsonString == null || jsonString.isEmpty) {
        AppLogger.info('保存された課題データなし', tag: 'Storage');
        return [];
      }
      
      // JSON文字列をデコード
      final List<dynamic> assignmentMaps = jsonDecode(jsonString);
      
      // Mapのリストを課題オブジェクトのリストに変換
      final assignments = assignmentMaps
          .map((map) => Assignment.fromMap(Map<String, dynamic>.from(map)))
          .toList();
      
      AppLogger.success('課題データ復元完了: ${assignments.length}件', tag: 'Storage');
      return assignments;
    } catch (e) {
      AppLogger.error('課題データ復元エラー', tag: 'Storage', error: e);
      return [];
    }
  }

  /// 最終更新時刻を取得するメソッド
  /// データの新しさを確認するために使用
  static Future<DateTime?> getLastUpdateTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString(_lastUpdateKey);
      
      if (timeString == null) {
        return null;
      }
        return DateTime.parse(timeString);
    } catch (e) {
      AppLogger.error('最終更新時刻取得エラー', tag: 'Storage', error: e);
      return null;
    }
  }

  /// ユーザー設定を保存するメソッド
  /// アプリの各種設定を永続化
  static Future<bool> saveUserSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(settings);      final result = await prefs.setString(_userSettingsKey, jsonString);
      
      AppLogger.success('ユーザー設定保存完了', tag: 'Storage');
      return result;
    } catch (e) {
      AppLogger.error('ユーザー設定保存エラー', tag: 'Storage', error: e);
      return false;
    }
  }

  /// ユーザー設定を復元するメソッド
  /// 保存された設定情報を読み込み
  static Future<Map<String, dynamic>> loadUserSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_userSettingsKey);
        if (jsonString == null || jsonString.isEmpty) {
        AppLogger.info('保存されたユーザー設定なし - デフォルト設定を使用', tag: 'Storage');
        return _getDefaultSettings();
      }
      
      final settings = Map<String, dynamic>.from(jsonDecode(jsonString));
      AppLogger.success('ユーザー設定復元完了', tag: 'Storage');
      return settings;
    } catch (e) {
      AppLogger.error('ユーザー設定復元エラー - デフォルト設定を使用', tag: 'Storage', error: e);
      return _getDefaultSettings();
    }
  }

  /// デフォルトのユーザー設定を取得するメソッド
  /// 初回起動時や設定ファイルが破損した場合に使用
  static Map<String, dynamic> _getDefaultSettings() {
    return {
      'isDarkMode': false,
      'showCompletedTasks': true,
      'defaultSortType': 'dueDate',
      'notificationEnabled': true,
      'notificationHoursBefore': 24,
      'autoRefreshEnabled': true,
      'autoRefreshInterval': 30, // 分
    };
  }

  /// 保存されたデータをすべて削除するメソッド
  /// アプリリセット時や初期化時に使用
  static Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_assignmentsKey);
      await prefs.remove(_lastUpdateKey);      await prefs.remove(_userSettingsKey);
      
      AppLogger.success('すべてのローカルデータをクリア完了', tag: 'Storage');
      return true;
    } catch (e) {
      AppLogger.error('データクリアエラー', tag: 'Storage', error: e);
      return false;
    }
  }

  /// データのサイズ情報を取得するメソッド
  /// ストレージ使用量の確認用
  static Future<Map<String, int>> getDataSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final assignmentsData = prefs.getString(_assignmentsKey) ?? '';
      final settingsData = prefs.getString(_userSettingsKey) ?? '';
      
      return {
        'assignments': assignmentsData.length,
        'settings': settingsData.length,        'total': assignmentsData.length + settingsData.length,
      };
    } catch (e) {
      AppLogger.error('データサイズ取得エラー', tag: 'Storage', error: e);
      return {'assignments': 0, 'settings': 0, 'total': 0};
    }
  }
}

/// ストレージサービスのプロバイダー
/// アプリ全体でストレージ機能にアクセスするための単一インスタンス
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
