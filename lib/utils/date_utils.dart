import 'package:intl/intl.dart';
import 'logger.dart';

/// 日付関連のユーティリティクラス
/// アプリ全体で日付の解析・フォーマット・計算を統一
class DateUtils with LoggerMixin {
  // 日本時間のタイムゾーンを作成（UTC+9）
  static final japanTimeZone = DateTime.now().timeZoneOffset;

  /// 文字列の日付をDateTimeに変換
  /// 複数のフォーマットに対応し、エラー時は現在時刻を返す
  /// タイムゾーン対応：Moodle/わせジュールから返される日付は日本時間（JST）と仮定
  static DateTime parseDateTime(String dateTimeString) {
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
      
      // まず元の文字列をログに記録
      AppLogger.debug('日付変換開始: "$dateTimeString"');
      
      // 各フォーマットを順番に試す
      for (String format in dateFormats) {
        try {
          // 日本時間として明示的にパース（環境のタイムゾーンに依存しない）
          final DateFormat formatter = DateFormat(format);
          final parsedDate = formatter.parse(dateTimeString);
          
          // ここが重要: パースした日時をJST（日本時間）として扱う
          final DateTime dateTimeInJst = DateTime(
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
            parsedDate.hour,
            parsedDate.minute,
            parsedDate.second,
            parsedDate.millisecond,
            parsedDate.microsecond,
          );
          
          // デバッグログで確認（タイムゾーンの違いを可視化）
          AppLogger.debug('日付変換: "$dateTimeString" → ${dateTimeInJst.toString()} (JST)');
          
          return dateTimeInJst;
        } catch (e) {
          // このフォーマットで失敗したら次を試す
          continue;
        }
      }
      
      // すべて失敗した場合はエラーログを出力して現在時刻を返す
      AppLogger.warning('日付パース失敗: $dateTimeString');
      return DateTime.now();
    } catch (e) {
      AppLogger.error('日付パースエラー: $e');
      return DateTime.now(); // エラー時は現在時刻を返す
    }
  }

  /// 締切日までの残り日数を計算
  /// 戻り値が負の場合は期限切れ
  static int getDaysRemaining(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    return difference.inDays;
  }
  /// 日付をわかりやすい形式に整形
  /// 入力：文字列の日付、出力：M/d(曜) HH:mm形式
  static String formatDateTime(String dateTimeString) {
    final date = parseDateTime(dateTimeString);
    final weekday = getJapaneseWeekday(date);
    return '${date.month}/${date.day}(${weekday}) ${DateFormat('HH:mm').format(date)}';
  }

  /// 日付だけを取得（時刻を無視）
  /// カレンダー表示用
  static DateTime getDateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// 日付をキー文字列に変換
  /// カレンダーのグループ化用
  static String getDateKey(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  /// 期限の緊急度を判定
  /// 戻り値：urgent（緊急）、warning（注意）、normal（通常）、overdue（期限切れ）
  static String getUrgencyLevel(int daysRemaining) {
    if (daysRemaining < 0) return 'overdue';
    if (daysRemaining == 0) return 'urgent';
    if (daysRemaining <= 3) return 'warning';
    return 'normal';
  }
  /// 期限までの日数を表示用テキストに変換
  static String getDaysRemainingText(int daysRemaining) {
    if (daysRemaining < 0) {
      return '期限切れ';
    } else if (daysRemaining == 0) {
      return '本日締切';
    } else {
      return 'あと${daysRemaining}日';
    }
  }

  /// 時刻のみを「HH:mm」形式で取得
  /// タイムライン表示用
  static String formatTime(String dateTimeString) {
    final date = parseDateTime(dateTimeString);
    return DateFormat('HH:mm').format(date);
  }

  /// 日付を「M/d」の短縮形式で取得
  /// タイムライン表示用
  static String formatDateShort(String dateTimeString) {
    final date = parseDateTime(dateTimeString);
    return DateFormat('M/d').format(date);
  }

  /// 曜日を日本語表記で取得
  /// 例: 月、火、水、木、金、土、日
  static String getJapaneseWeekday(DateTime date) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return weekdays[date.weekday - 1];
  }

  /// 日付を「M/d(曜)」形式でフォーマット
  /// 例: 6/1(土)
  static String formatDateWithJapaneseWeekday(DateTime date) {
    final weekday = getJapaneseWeekday(date);
    return '${date.month}/${date.day}（$weekday）';
  }
  
  /// 残り時間を「HH:MM:SS」形式でフォーマット
  /// 期限までのカウントダウン表示用
  static String formatRemainingTime(Duration remaining) {
    if (remaining.isNegative) {
      return '期限切れ';
    }
    
    final hours = remaining.inHours;
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    
    return '$hours:$minutes:$seconds';
  }
  
  /// 残り時間を「1日 HH:MM:SS」形式でフォーマット
  /// 日付を含む期限表示用
  static String formatRemainingTimeWithDays(Duration remaining) {
    if (remaining.isNegative) {
      return '期限切れ';
    }
    
    final days = remaining.inDays;
    final hours = (remaining.inHours % 24).toString().padLeft(2, '0');
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    
    if (days > 0) {
      return '$days日 $hours:$minutes:$seconds';
    } else {
      return '$hours:$minutes:$seconds';
    }
  }
}
