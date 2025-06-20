import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'assignments_provider.dart';
import '../models/schedule_model.dart';
import '../utils/logger.dart';

/// ローカルストレージを管理するクラス
/// 課題データと時間割データの永続化と復元を担当
class StorageService {
  static const String _assignmentsKey = 'assignments_data';
  static const String _lastUpdateKey = 'last_update_time';
  static const String _userSettingsKey = 'user_settings';
  static const String _scheduleKey = 'schedule_data';

  /// 課題データをローカルストレージに保存するメソッド
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

  /// 時間割データをローカルストレージに保存するメソッド
  static Future<bool> saveSchedule(List<ScheduleSlot> schedule) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 時間割リストをMapのリストに変換
      final scheduleMaps = schedule.map((slot) => slot.toMap()).toList();
      
      // JSON文字列に変換して保存
      final jsonString = jsonEncode(scheduleMaps);
      final result = await prefs.setString(_scheduleKey, jsonString);
      
      AppLogger.success('時間割データ保存完了: ${schedule.length}件', tag: 'Storage');
      return result;
    } catch (e) {
      AppLogger.error('時間割データ保存エラー', tag: 'Storage', error: e);
      return false;
    }
  }

  /// ローカルストレージから時間割データを復元するメソッド
  static Future<List<ScheduleSlot>> loadSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_scheduleKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        AppLogger.info('保存された時間割データなし', tag: 'Storage');
        return [];
      }
      
      // JSON文字列をデコード
      final List<dynamic> scheduleMaps = jsonDecode(jsonString);
      
      // Mapのリストを時間割オブジェクトのリストに変換
      final schedule = scheduleMaps
          .map((map) => ScheduleSlot.fromMap(Map<String, dynamic>.from(map)))
          .toList();
      
      AppLogger.success('時間割データ復元完了: ${schedule.length}件', tag: 'Storage');
      return schedule;
    } catch (e) {
      AppLogger.error('時間割データ復元エラー', tag: 'Storage', error: e);
      return [];
    }
  }

  /// 最終更新時刻を取得するメソッド
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
  static Future<bool> saveUserSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(settings);
      final result = await prefs.setString(_userSettingsKey, jsonString);
      
      AppLogger.success('ユーザー設定保存完了', tag: 'Storage');
      return result;
    } catch (e) {
      AppLogger.error('ユーザー設定保存エラー', tag: 'Storage', error: e);
      return false;
    }
  }

  /// ユーザー設定を復元するメソッド
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
  static Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_assignmentsKey);
      await prefs.remove(_lastUpdateKey);
      await prefs.remove(_userSettingsKey);
      await prefs.remove(_scheduleKey);
      
      AppLogger.success('すべてのローカルデータをクリア完了', tag: 'Storage');
      return true;
    } catch (e) {
      AppLogger.error('データクリアエラー', tag: 'Storage', error: e);
      return false;
    }
  }

  /// データのサイズ情報を取得するメソッド
  static Future<Map<String, int>> getDataSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final assignmentsData = prefs.getString(_assignmentsKey) ?? '';
      final settingsData = prefs.getString(_userSettingsKey) ?? '';
      final scheduleData = prefs.getString(_scheduleKey) ?? '';
      
      return {
        'assignments': assignmentsData.length,
        'settings': settingsData.length,
        'schedule': scheduleData.length,
        'total': assignmentsData.length + settingsData.length + scheduleData.length,
      };
    } catch (e) {
      AppLogger.error('データサイズ取得エラー', tag: 'Storage', error: e);
      return {
        'assignments': 0,
        'settings': 0,
        'schedule': 0,
        'total': 0,
      };
    }
  }
}
