import 'package:flutter/material.dart';
import '../utils/assignment_ui_helpers.dart';
import '../utils/date_utils.dart' as app_date_utils;

/// 残り日数を表示するウィジェット
/// 期限の緊急度に応じて色分けされたバッジ形式で表示
class RemainingDaysWidget extends StatelessWidget {
  /// 残り日数（負の場合は期限切れ）
  final int daysRemaining;

  const RemainingDaysWidget({
    super.key,
    required this.daysRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = AssignmentUIHelpers.getRemainingDaysBadgeColor(daysRemaining);
    final textColor = AssignmentUIHelpers.getRemainingDaysTextColor(daysRemaining);
    final text = app_date_utils.DateUtils.getDaysRemainingText(daysRemaining);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: daysRemaining <= 3 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
