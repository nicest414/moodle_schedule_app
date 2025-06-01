import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/assignments_provider.dart';
import '../utils/assignment_ui_helpers.dart';
import '../utils/date_utils.dart' as app_date_utils;
import 'assignment_details_sheet.dart';

/// 課題カードウィジェット
/// 課題一覧で使用する個別の課題表示カード
class AssignmentCard extends ConsumerWidget {
  /// 表示する課題データ
  final Assignment assignment;
  const AssignmentCard({
    super.key,
    required this.assignment,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 締切日からの残り日数を計算
    final DateTime dueDate = app_date_utils.DateUtils.parseDateTime(assignment.startTime);
    final int daysRemaining = app_date_utils.DateUtils.getDaysRemaining(dueDate);
      // 日付と時刻を一行で表示（「5/28(水) 11:25」形式）
    final DateTime dateTime = app_date_utils.DateUtils.parseDateTime(assignment.startTime);
    final String weekday = ['月', '火', '水', '木', '金', '土', '日'][dateTime.weekday - 1];
    final String dateTimeText = '${dateTime.month}/${dateTime.day}($weekday) ${app_date_utils.DateUtils.formatTime(assignment.startTime)}';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: InkWell(
        onTap: () => showAssignmentDetailsSheet(context, assignment),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              // 左側: 日付と時刻表示（縦線付き）
              Container(
                width: 100,
                child: Row(
                  children: [
                    // 日付と時刻を一行表示
                    Text(
                      dateTimeText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 縦線
                    Container(
                      width: 2,
                      height: 24,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
              ),              
              const SizedBox(width: 8),
              
              // チェックボックス
              Checkbox(
                value: assignment.isCompleted,
                onChanged: (value) {
                  ref.read(assignmentsProvider.notifier)
                      .toggleAssignmentCompletion(assignment.id);
                  
                  // 完了時のフィードバック
                  if (value == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('「${assignment.name}」を完了しました ✅'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              
              const SizedBox(width: 4),
              
              // 中央: 課題情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 課題名
                    Text(
                      assignment.name,
                      style: AssignmentUIHelpers.getCompletedTextStyle(
                        assignment.isCompleted,
                        baseStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // コース名
                    Text(
                      assignment.course,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // 右側: 期限バッジ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getBadgeColor(daysRemaining),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getBadgeText(daysRemaining, dueDate),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 期限バッジの色を取得
  Color _getBadgeColor(int daysRemaining) {
    if (daysRemaining < 0) {
      return Colors.red; // 期限切れ
    } else if (daysRemaining == 0) {
      return Colors.orange; // 今日
    } else if (daysRemaining <= 3) {
      return Colors.orange; // 3日以内
    } else {
      return Colors.blue; // それ以外
    }
  }
  
  /// 期限バッジのテキストを取得
  String _getBadgeText(int daysRemaining, DateTime dueDate) {
    if (daysRemaining < 0) {
      return '期限切れ';
    } else if (daysRemaining == 0) {
      // 今日の場合は残り時間を表示
      final now = DateTime.now();
      final remaining = dueDate.difference(now);
      
      if (remaining.isNegative) {
        return '期限切れ';
      }
      
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes % 60;
      final seconds = remaining.inSeconds % 60;
      
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else if (daysRemaining == 1) {
      // 1日後の場合は時間も表示
      final now = DateTime.now();
      final remaining = dueDate.difference(now);
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes % 60;
      final seconds = remaining.inSeconds % 60;
      
      return '1日 ${hours % 24}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${daysRemaining}日';
    }
  }
}
