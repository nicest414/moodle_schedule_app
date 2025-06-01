import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/assignments_provider.dart';
import '../utils/assignment_ui_helpers.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../widgets/assignment_details_sheet.dart';

/// タイムライン形式の課題カードウィジェット
/// 日付見出しの下に表示される時間のみの課題カード
class TimelineAssignmentCard extends ConsumerWidget {
  /// 表示する課題データ
  final Assignment assignment;
  
  const TimelineAssignmentCard({
    super.key,
    required this.assignment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 締切日からの残り日数を計算
    final DateTime dueDate = app_date_utils.DateUtils.parseDateTime(assignment.startTime);
    final int daysRemaining = app_date_utils.DateUtils.getDaysRemaining(dueDate);
    
    // 時刻のみを取得
    final String timeText = app_date_utils.DateUtils.formatTime(assignment.startTime);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: InkWell(
        onTap: () => showAssignmentDetailsSheet(context, assignment),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            children: [
              // 左側: 時刻表示 + 縦線
              Container(
                width: 60,
                child: Row(
                  children: [                    // 時刻表示
                    Text(
                      timeText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6), // 8pxから6pxに調整
                    // 縦線
                    Container(
                      width: 2,
                      height: 20,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
              ),
                // チェックボックス（サイズ調整版）
              Transform.scale(
                scale: 0.9, // 少し小さくスケール
                child: Checkbox(
                  value: assignment.isCompleted,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // タップ領域を縮小
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

              const SizedBox(width: 4),              // 右側: 期限バッジ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AssignmentUIHelpers.getTimelineBadgeColor(daysRemaining),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  AssignmentUIHelpers.getTimelineBadgeText(daysRemaining, dueDate),
                  style: const TextStyle(
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
}
