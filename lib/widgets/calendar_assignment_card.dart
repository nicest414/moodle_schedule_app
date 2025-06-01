import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/assignments_provider.dart';
import '../utils/assignment_ui_helpers.dart';
import '../utils/date_utils.dart' as app_date_utils;
import 'assignment_details_sheet.dart';

/// カレンダー画面用の課題カードウィジェット
/// シンプルなリスト表示に特化し、時刻表示のみ
class CalendarAssignmentCard extends StatelessWidget {
  /// 表示する課題データ
  final Assignment assignment;

  const CalendarAssignmentCard({
    super.key,
    required this.assignment,
  });

  @override
  Widget build(BuildContext context) {
    // 課題の種類に応じてアイコンと色を取得
    final IconData icon = AssignmentUIHelpers.getIconForModule(assignment.moduleName);
    final Color color = AssignmentUIHelpers.getColorForModule(assignment.moduleName);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          assignment.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(assignment.course),
            const SizedBox(height: 2),
            Text(
              '⏰ ${DateFormat('HH:mm').format(app_date_utils.DateUtils.parseDateTime(assignment.startTime))}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () {
          // 課題詳細をボトムシートで表示
          _showAssignmentDetails(context, assignment);
        },
      ),
    );
  }

  /// 課題詳細をボトムシートで表示
  void _showAssignmentDetails(BuildContext context, Assignment assignment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AssignmentDetailsSheet(assignment: assignment),
    );
  }
}
