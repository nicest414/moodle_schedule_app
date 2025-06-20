import 'package:flutter/material.dart';
import '../models/schedule_model.dart';

/// 科目詳細を表示するボトムシート（わせジュール風）
class SubjectDetailsSheet extends StatelessWidget {
  final ScheduleSlot slot;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SubjectDetailsSheet({
    super.key,
    required this.slot,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final subject = slot.subject!;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ドラッグハンドル
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // メインコンテンツ
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 科目名（大きな文字）
                Text(
                  subject.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 20),
                
                // 時間情報
                _buildInfoRow(
                  icon: Icons.schedule,
                  label: '時間',
                  value: '${slot.weekday.fullName} ${slot.period.number}限 (${slot.period.startTime}-${slot.period.endTime})',
                ),
                
                // 担当教員（入力されている場合）
                if (subject.teacher.isNotEmpty)
                  _buildInfoRow(
                    icon: Icons.person,
                    label: '担当教員',
                    value: subject.teacher,
                  ),
                
                // 教室（入力されている場合）
                if (subject.classroom.isNotEmpty)
                  _buildInfoRow(
                    icon: Icons.location_on,
                    label: '教室',
                    value: subject.classroom,
                  ),
                
                // 説明（入力されている場合）
                if (subject.description != null && subject.description!.isNotEmpty)
                  _buildInfoRow(
                    icon: Icons.note,
                    label: '説明',
                    value: subject.description!,
                  ),
                
                const SizedBox(height: 30),
                
                // ボタンエリア
                Row(
                  children: [
                    // 編集ボタン
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('編集'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 削除ボタン
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeleteConfirmDialog(context),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('削除'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 情報行を構築
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF2E7D32),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 削除確認ダイアログを表示
  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('科目を削除'),
        content: Text('「${slot.subject!.name}」を削除しますか？\nこの操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ダイアログを閉じる
              Navigator.pop(context); // ボトムシートを閉じる
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}