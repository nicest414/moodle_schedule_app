import 'package:flutter/material.dart';
import 'date_utils.dart' as app_date_utils;
import 'app_theme.dart';

/// UI関連のヘルパー機能を提供するクラス
/// アイコン、色、優先度表示などの共通UI要素を管理
class AssignmentUIHelpers {
  
  /// モジュール（課題の種類）によってアイコンを返す
  /// 課題の種類を視覚的に分かりやすく表示
  static IconData getIconForModule(String moduleName) {
    switch (moduleName.toLowerCase()) {
      case 'quiz':
        return Icons.quiz;
      case 'assign':
        return Icons.assignment;
      case 'forum':
        return Icons.forum;
      case 'resource':
        return Icons.description;
      default:
        return Icons.event_note;
    }
  }

  /// モジュール（課題の種類）によって色を返す
  /// 課題の種類を色で区別しやすく
  static Color getColorForModule(String moduleName) {
    switch (moduleName.toLowerCase()) {
      case 'quiz':
        return Colors.purple;
      case 'assign':
        return Colors.blue;
      case 'forum':
        return Colors.green;
      case 'resource':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  /// 優先度に応じた色を返すメソッド
  /// 優先度の視覚的な区別に使用
  static Color getPriorityColor(int priority) {
    switch (priority) {
      case 3: // 高優先度
        return Colors.red;
      case 2: // 中優先度
        return Colors.orange;
      case 1: // 低優先度
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// 優先度のラベルを返すメソッド
  /// UI表示用の短いテキスト
  static String getPriorityLabel(int priority) {
    switch (priority) {
      case 3:
        return '高';
      case 2:
        return '中';
      case 1:
        return '低';
      default:
        return '中';
    }
  }

  /// 優先度のアイコンを返すメソッド
  /// 優先度を直感的に表現
  static IconData getPriorityIcon(int priority) {
    switch (priority) {
      case 3: // 高優先度
        return Icons.priority_high;
      case 2: // 中優先度
        return Icons.remove;
      case 1: // 低優先度
        return Icons.keyboard_arrow_down;
      default:
        return Icons.remove;
    }
  }
  /// 期限に応じたカードの背景色を返す
  /// 緊急度を背景色で表現
  static Color getCardBackgroundColor(int daysRemaining) {
    if (daysRemaining < 0) {
      // 締切過ぎた
      return AppTheme.overdueColor.withOpacity(0.1);
    } else if (daysRemaining <= 3 && daysRemaining >= 0) {
      // 締切が近い
      return AppTheme.warningColor.withOpacity(0.1);
    } else {
      // 通常
      return AppTheme.cardBackgroundColor;
    }
  }
  /// 残り日数表示用のバッジ色を返す
  /// 緊急度に応じた色分け
  static Color getRemainingDaysBadgeColor(int daysRemaining) {
    // AppThemeクラスの色を使用
    if (daysRemaining < 0) {
      return AppTheme.overdueColor;
    } else if (daysRemaining == 0) {
      return AppTheme.urgentColor;
    } else if (daysRemaining <= 3) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.completeColor.withOpacity(0.7);
    }
  }

  /// 残り日数表示用のテキスト色を返す
  /// バッジ内のテキストの可読性を確保
  static Color getRemainingDaysTextColor(int daysRemaining) {
    if (daysRemaining < 0 || daysRemaining == 0) {
      return Colors.white;
    } else if (daysRemaining <= 3) {
      return Colors.black;
    } else {
      return Colors.black87;
    }
  }

  /// 課題完了時の装飾を適用
  /// 完了した課題の見た目を調整
  static TextStyle getCompletedTextStyle(bool isCompleted, {TextStyle? baseStyle}) {
    final style = baseStyle ?? const TextStyle();
    return style.copyWith(
      decoration: isCompleted ? TextDecoration.lineThrough : null,
      color: isCompleted ? Colors.grey : style.color,
    );
  }

  /// アイコンの色を課題の完了状態に応じて調整
  /// 完了した課題は薄くグレー表示
  static Color getIconColor(String moduleName, bool isCompleted) {
    if (isCompleted) {
      return Colors.grey;
    }
    return getColorForModule(moduleName);
  }
    /// タイムライン表示用のバッジ色を取得
  /// 残り日数に応じた色分け
  static Color getTimelineBadgeColor(int daysRemaining) {
    return AppTheme.getDeadlineColor(daysRemaining);
  }
    /// タイムライン表示用の期限バッジテキストを取得
  static String getTimelineBadgeText(int daysRemaining, DateTime dueDate) {
    if (daysRemaining < 0) {
      return '期限切れ';
    } else if (daysRemaining == 0) {
      // 今日の場合は残り時間を表示
      final now = DateTime.now();
      final remaining = dueDate.difference(now);
      
      if (remaining.isNegative) {
        return '期限切れ';
      }
      
      // 新しく追加したDateUtilsのメソッドを使用
      return app_date_utils.DateUtils.formatRemainingTime(remaining);
    } else if (daysRemaining == 1) {
      // 1日後の場合は時間も表示
      final now = DateTime.now();
      final remaining = dueDate.difference(now);
      
      // 新しく追加したDateUtilsのメソッドを使用
      return app_date_utils.DateUtils.formatRemainingTimeWithDays(remaining);
    } else {
      return '${daysRemaining}日';
    }
  }
}
