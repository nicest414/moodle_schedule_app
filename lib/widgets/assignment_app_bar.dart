import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/assignments_provider.dart';

/// 課題一覧画面のAppBar
/// ソート機能と更新ボタンを提供
class AssignmentAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const AssignmentAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: const Text('課題一覧'),
      actions: [
        // ソートボタン
        PopupMenuButton<AssignmentSortType>(
          icon: const Icon(Icons.sort),
          tooltip: 'ソート',
          onSelected: (sortType) {
            ref.read(assignmentsProvider.notifier).sortAssignments(sortType);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: AssignmentSortType.dueDate,
              child: ListTile(
                leading: Icon(Icons.schedule),
                title: Text('締切日順'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: AssignmentSortType.priority,
              child: ListTile(
                leading: Icon(Icons.priority_high),
                title: Text('優先度順'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: AssignmentSortType.course,
              child: ListTile(
                leading: Icon(Icons.school),
                title: Text('コース順'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: AssignmentSortType.completion,
              child: ListTile(
                leading: Icon(Icons.check_circle),
                title: Text('完了状態順'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        // 更新ボタン
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            // 課題データの再取得処理（後で実装）
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('課題データの更新機能は開発中です 🚧'),
                backgroundColor: Colors.orange,
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
