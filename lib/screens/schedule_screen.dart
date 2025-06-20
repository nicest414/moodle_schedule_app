import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';
import '../widgets/schedule_table_widget.dart';
import '../widgets/subject_form_widget.dart';
import '../widgets/subject_details_sheet.dart';

/// 時間割表示画面
/// 週間時間割の表示と科目の編集機能を提供
class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(scheduleProvider);
    final currentClass = ref.watch(currentClassProvider);
    final nextClass = ref.watch(nextClassProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📅 時間割'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(scheduleProvider.notifier).refreshFromStorage();
            },
            tooltip: '時間割を更新',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => _showClearConfirmDialog(context, ref),
            tooltip: '時間割をクリア',
          ),
        ],
      ),
      body: Column(
        children: [
          // 現在・次の授業情報
          if (currentClass != null || nextClass != null) ...[
            _buildCurrentClassInfo(currentClass, nextClass),
            const Divider(),
          ],
          
          // 時間割表
          Expanded(
            child: ScheduleTableWidget(
              schedule: schedule,
              onSlotTap: (slot) => _onSlotTap(context, ref, slot),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSubjectForm(context, ref, null),
        child: const Icon(Icons.add),
        tooltip: '科目を追加',
      ),
    );
  }

  /// 現在・次の授業情報を表示するウィジェット（わせジュール風）
  Widget _buildCurrentClassInfo(ScheduleSlot? currentClass, ScheduleSlot? nextClass) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E8), // 薄い緑色
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4CAF50), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (currentClass != null) ...[
            Row(
              children: [
                const Icon(Icons.schedule, color: Color(0xFF2E7D32), size: 20),
                const SizedBox(width: 8),
                const Text(
                  '現在の授業',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildClassInfo(currentClass, isCurrentClass: true),
          ],
          
          if (currentClass != null && nextClass != null)
            const SizedBox(height: 16),
          
          if (nextClass != null) ...[
            Row(
              children: [
                const Icon(Icons.upcoming, color: Color(0xFF388E3C), size: 20),
                const SizedBox(width: 8),
                const Text(
                  '次の授業',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF388E3C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildClassInfo(nextClass, isCurrentClass: false),
          ],
        ],
      ),
    );
  }

  /// 授業情報を表示するウィジェット
  Widget _buildClassInfo(ScheduleSlot slot, {required bool isCurrentClass}) {
    final subject = slot.subject!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: subject.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: subject.color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: subject.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${slot.period.startTime} - ${slot.period.endTime}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          if (subject.teacher.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '👨‍🏫 ${subject.teacher}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          if (subject.classroom.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '🏫 ${subject.classroom}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// スロットタップ時の処理
  void _onSlotTap(BuildContext context, WidgetRef ref, ScheduleSlot slot) {
    if (slot.isNotEmpty) {
      // 既存の授業がある場合は詳細画面を表示
      _showSubjectDetails(context, ref, slot);
    } else {
      // 空のスロットの場合は編集画面を表示
      _showSubjectForm(context, ref, slot);
    }
  }

  /// 科目詳細画面を表示
  void _showSubjectDetails(BuildContext context, WidgetRef ref, ScheduleSlot slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubjectDetailsSheet(
        slot: slot,
        onEdit: () {
          Navigator.pop(context); // 詳細画面を閉じる
          _showSubjectForm(context, ref, slot); // 編集画面を表示
        },
        onDelete: () {
          ref.read(scheduleProvider.notifier).removeSubject(slot.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('科目を削除しました')),
          );
        },
      ),
    );
  }

  /// 科目編集フォームを表示
  void _showSubjectForm(BuildContext context, WidgetRef ref, ScheduleSlot? slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SubjectFormWidget(
            slot: slot,
            scrollController: scrollController,
            onSave: (slotId, subject) {
              ref.read(scheduleProvider.notifier).setSubject(slotId, subject);
              Navigator.pop(context);
            },
            onDelete: slot != null ? () {
              ref.read(scheduleProvider.notifier).removeSubject(slot.id);
              Navigator.pop(context);
            } : null,
          ),
        ),
      ),
    );
  }

  /// 時間割クリア確認ダイアログを表示
  void _showClearConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 確認'),
        content: const Text(
          '時間割をすべてクリアしますか？\n'
          'この操作は元に戻せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref.read(scheduleProvider.notifier).clearSchedule();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('時間割をクリアしました')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('クリア'),
          ),
        ],
      ),
    );
  }
}