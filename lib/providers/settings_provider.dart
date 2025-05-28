import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'assignments_provider.dart';

/// アプリの設定データを管理するクラス
/// ユーザーの好みや通知設定などを保存
class AppSettings {
  final bool notificationsEnabled; // 通知の有効/無効
  final int notificationHours; // 通知を送る時間（締切の何時間前）
  final bool isDarkMode; // ダークモードの有効/無効
  final AssignmentSortType defaultSortType; // デフォルトのソート方法
  final bool showCompletedTasks; // 完了した課題を表示するか

  const AppSettings({
    this.notificationsEnabled = true,
    this.notificationHours = 24,
    this.isDarkMode = false,
    this.defaultSortType = AssignmentSortType.dueDate,
    this.showCompletedTasks = false,
  });

  /// 設定をコピーして一部の値を変更するメソッド
  AppSettings copyWith({
    bool? notificationsEnabled,
    int? notificationHours,
    bool? isDarkMode,
    AssignmentSortType? defaultSortType,
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

  /// 設定をMapに変換（ローカルストレージ保存用）
  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'notificationHours': notificationHours,
      'isDarkMode': isDarkMode,
      'defaultSortType': defaultSortType.index,
      'showCompletedTasks': showCompletedTasks,
    };
  }

  /// Mapから設定を復元するファクトリメソッド
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      notificationHours: map['notificationHours'] ?? 24,
      isDarkMode: map['isDarkMode'] ?? false,
      defaultSortType: AssignmentSortType.values[map['defaultSortType'] ?? 0],
      showCompletedTasks: map['showCompletedTasks'] ?? false,
    );
  }
}

/// 設定を管理するNotifier
/// ユーザーの設定変更を処理し、状態を更新
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());

  /// 通知の有効/無効を切り替え
  void toggleNotifications(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
    _saveSettings();
  }

  /// 通知時間を設定
  void setNotificationHours(int hours) {
    state = state.copyWith(notificationHours: hours);
    _saveSettings();
  }

  /// ダークモードの有効/無効を切り替え
  void toggleDarkMode(bool enabled) {
    state = state.copyWith(isDarkMode: enabled);
    _saveSettings();
  }

  /// デフォルトソート方法を設定
  void setDefaultSortType(AssignmentSortType sortType) {
    state = state.copyWith(defaultSortType: sortType);
    _saveSettings();
  }

  /// 完了課題表示の有効/無効を切り替え
  void toggleShowCompletedTasks(bool show) {
    state = state.copyWith(showCompletedTasks: show);
    _saveSettings();
  }

  /// 設定をローカルストレージに保存
  /// TODO: shared_preferencesを使用して実際に保存する
  void _saveSettings() {
    // 現在はメモリ上での管理のみ
    // 後でshared_preferencesを使って永続化する
    print('設定を保存: ${state.toMap()}');
  }

  /// 設定をローカルストレージから読み込み
  /// TODO: shared_preferencesから読み込む
  void loadSettings() {
    // 現在はデフォルト設定を使用
    // 後で実際の保存データから復元する
  }
}

/// 設定プロバイダー
/// アプリ全体で設定データを共有
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

/// テーマプロバイダー
/// ダークモード設定に基づいてテーマを提供
final themeProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.isDarkMode;
});
