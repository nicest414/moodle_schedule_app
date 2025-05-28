import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 設定の状態を表すクラス
class AppSettings {
  final bool notificationsEnabled;
  final int notificationHours;
  final bool isDarkMode;
  final SortType defaultSortType; // SortType を使う
  final bool showCompletedTasks;

  AppSettings({
    this.notificationsEnabled = true,
    this.notificationHours = 1,
    this.isDarkMode = false,
    this.defaultSortType = SortType.dueDate, // デフォルトは締切日順
    this.showCompletedTasks = true,
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    int? notificationHours,
    bool? isDarkMode,
    SortType? defaultSortType,
    bool? showCompletedTasks,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationHours: notificationHours ?? this.notificationHours,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      defaultSortType: defaultSortType ?? this.defaultSortType,
      showCompletedTasks: showCompletedTasks ?? this.showCompletedTasks,
    );
  }
}

// 並び替えの種類を定義する enum
enum SortType {
  dueDate,
  courseName,
  priority,
}

// 設定を管理する Notifier
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings()) {
    _loadSettings();
  }

  static const _keyNotificationsEnabled = 'notificationsEnabled';
  static const _keyNotificationHours = 'notificationHours';
  static const _keyIsDarkMode = 'isDarkMode';
  static const _keyDefaultSortType = 'defaultSortType';
  static const _keyShowCompletedTasks = 'showCompletedTasks';

  // 設定を読み込む
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      notificationsEnabled: prefs.getBool(_keyNotificationsEnabled) ?? true,
      notificationHours: prefs.getInt(_keyNotificationHours) ?? 1,
      isDarkMode: prefs.getBool(_keyIsDarkMode) ?? false,
      defaultSortType: SortType.values[prefs.getInt(_keyDefaultSortType) ?? SortType.dueDate.index],
      showCompletedTasks: prefs.getBool(_keyShowCompletedTasks) ?? true,
    );
  }

  // 通知の有効/無効を切り替える
  Future<void> toggleNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }

  // 通知時間を設定する
  Future<void> setNotificationHours(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyNotificationHours, hours);
    state = state.copyWith(notificationHours: hours);
  }

  // ダークモードの有効/無効を切り替える
  Future<void> toggleDarkMode(bool darkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsDarkMode, darkMode);
    state = state.copyWith(isDarkMode: darkMode);
  }

  // デフォルトの並び順を設定する
  Future<void> setDefaultSortType(SortType sortType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDefaultSortType, sortType.index);
    state = state.copyWith(defaultSortType: sortType);
  }

  // 完了したタスクの表示/非表示を切り替える
  Future<void> toggleShowCompletedTasks(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowCompletedTasks, show);
    state = state.copyWith(showCompletedTasks: show);
  }
}

// 設定プロバイダー
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
