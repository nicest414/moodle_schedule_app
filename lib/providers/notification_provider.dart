import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'assignments_provider.dart';
import 'settings_provider.dart';
import '../utils/logger.dart'; // ロガーをインポート

/// 通知サービスを管理するクラス
/// 課題の締切通知を処理
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// 通知サービスを初期化するメソッド
  /// アプリ起動時に一度だけ呼び出す
  static Future<void> initialize() async {
    if (_initialized) return;

    // Android用の設定
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS用の設定
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    // 初期化設定
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 通知プラグインを初期化
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }
  /// 通知がタップされた時の処理
  static void _onNotificationTapped(NotificationResponse response) {
    AppLogger.ui('通知がタップされました: ${response.payload}', tag: 'Notification');
    // TODO: 特定の課題詳細画面に遷移する処理を実装
  }

  /// 課題の締切通知をスケジュールするメソッド
  /// 設定された時間前に通知を送信
  static Future<void> scheduleAssignmentNotification({
    required Assignment assignment,
    required int hoursBeforeDeadline,
  }) async {
    try {
      // 締切日時を解析
      final deadline = _parseDateTime(assignment.startTime);
      // 通知時刻を計算（締切の指定時間前）
      final notificationTime = deadline.subtract(Duration(hours: hoursBeforeDeadline));
      
      // 現在時刻より前の場合は通知しない
      if (notificationTime.isBefore(DateTime.now())) {
        return;
      }

      // 通知ID（課題IDから生成）
      final notificationId = assignment.id.hashCode;

      // 通知の詳細設定
      const androidDetails = AndroidNotificationDetails(
        'assignment_reminders', // チャンネルID
        '課題リマインダー', // チャンネル名
        channelDescription: '課題の締切をお知らせします',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        sound: 'default',
        badgeNumber: 1,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );      // 通知を即座に表示（デモ用）
      // 実際の実装では timezone パッケージと zonedSchedule を使用してください
      await _notifications.show(
        notificationId,
        '📚 課題の締切が近づいています',
        '${assignment.name}\n締切: ${DateFormat('M月d日 HH:mm').format(deadline)}',
        notificationDetails,
        payload: assignment.id, // 課題IDをペイロードとして設定
      );      AppLogger.notification('通知をスケジュール: ${assignment.name} at $notificationTime');
    } catch (e) {
      AppLogger.error('通知スケジュールエラー', tag: 'Notification', error: e);
    }
  }

  /// 特定の課題の通知をキャンセルするメソッド
  static Future<void> cancelAssignmentNotification(String assignmentId) async {
    final notificationId = assignmentId.hashCode;
    await _notifications.cancel(notificationId);
  }

  /// 全ての通知をキャンセルするメソッド
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }  /// 日付文字列をDateTimeに変換するヘルパーメソッド
  static DateTime _parseDateTime(String dateTimeString) {
    try {
      // 実際に来るデータの形式に合わせたフォーマットリスト
      final List<String> dateFormats = [
        'yyyy/MM/dd HH:mm',          // メイン形式: 2025/06/03 15:00
        'yyyy/MM/dd H:mm',           // 時刻が1桁の場合: 2025/06/03 4:00
        'yyyy/M/dd HH:mm',           // 月が1桁の場合: 2025/6/03 15:00
        'yyyy/M/dd H:mm',            // 月と時刻が1桁: 2025/6/03 4:00
        'yyyy/MM/d HH:mm',           // 日が1桁の場合: 2025/06/3 15:00
        'yyyy/MM/d H:mm',            // 日と時刻が1桁: 2025/06/3 4:00
        'yyyy/M/d HH:mm',            // 月と日が1桁: 2025/6/3 15:00
        'yyyy/M/d H:mm',             // 月、日、時刻が1桁: 2025/6/3 4:00
        'M/d/yyyy, h:mm:ss a',       // 旧形式（互換性のため）
        'yyyy-MM-dd HH:mm:ss',       // ISO形式（バックアップ）
        'yyyy-MM-dd HH:mm',          // ISO形式（秒なし）
      ];
      
      // 各フォーマットを順番に試す
      for (String format in dateFormats) {
        try {
          return DateFormat(format).parse(dateTimeString);
        } catch (e) {
          // このフォーマットで失敗したら次を試す
          continue;
        }
      }
        // すべて失敗した場合はエラーログを出力して現在時刻を返す
      AppLogger.warning('NotificationProvider日付パース失敗: $dateTimeString', tag: 'Notification');
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  /// 通知権限をリクエストするメソッド（Android 13+）
  static Future<bool> requestPermissions() async {
    final result = await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return result ?? false;
  }
}

/// 通知管理を行うNotifier
/// 課題データと設定に基づいて通知をスケジュール
class NotificationNotifier extends StateNotifier<bool> {
  NotificationNotifier(this._ref) : super(false) {
    _initialize();
  }

  final Ref _ref;

  /// 通知サービスを初期化
  Future<void> _initialize() async {
    await NotificationService.initialize();
    state = true;
  }

  /// 全ての課題の通知を更新するメソッド
  /// 設定変更時や課題データ更新時に呼び出す
  Future<void> updateAllNotifications() async {
    final assignments = _ref.read(assignmentsProvider);
    final settings = _ref.read(settingsProvider);

    // 既存の通知をクリア
    await NotificationService.cancelAllNotifications();

    // 通知が無効な場合は処理終了
    if (!settings.notificationsEnabled) {
      return;
    }

    // 未完了の課題に対して通知をスケジュール
    for (final assignment in assignments) {
      if (!assignment.isCompleted) {
        await NotificationService.scheduleAssignmentNotification(
          assignment: assignment,
          hoursBeforeDeadline: settings.notificationHours,
        );
      }
    }
  }

  /// 特定の課題の通知を更新
  Future<void> updateAssignmentNotification(Assignment assignment) async {
    final settings = _ref.read(settingsProvider);

    // 既存の通知をキャンセル
    await NotificationService.cancelAssignmentNotification(assignment.id);

    // 通知が有効で、課題が未完了の場合のみ再スケジュール
    if (settings.notificationsEnabled && !assignment.isCompleted) {
      await NotificationService.scheduleAssignmentNotification(
        assignment: assignment,
        hoursBeforeDeadline: settings.notificationHours,
      );
    }
  }

  /// 課題完了時の通知キャンセル
  Future<void> cancelNotificationForCompletedAssignment(String assignmentId) async {
    await NotificationService.cancelAssignmentNotification(assignmentId);
  }
}

/// 通知管理プロバイダー
final notificationProvider = StateNotifierProvider<NotificationNotifier, bool>((ref) {
  return NotificationNotifier(ref);
});
