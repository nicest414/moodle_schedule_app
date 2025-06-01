import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/assignments_provider.dart';
import '../utils/assignment_ui_helpers.dart';

/// 優先度選択用のUIウィジェット
/// 課題の優先度を直感的に設定できるボタン群
class PrioritySelector extends StatelessWidget {
  /// 現在選択されている優先度
  final int selectedPriority;
  
  /// 課題のID（優先度変更時に使用）
  final String assignmentId;
  
  /// 優先度変更時のコールバック（オプション）
  final Function(int)? onPriorityChanged;

  const PrioritySelector({
    super.key,
    required this.selectedPriority,
    required this.assignmentId,
    this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                '優先度',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [1, 2, 3].map((priority) {
                  final isSelected = selectedPriority == priority;
                  return GestureDetector(
                    onTap: () {
                      // プロバイダーの優先度を更新
                      ref.read(assignmentsProvider.notifier)
                          .updateAssignmentPriority(assignmentId, priority);
                      
                      // コールバックがある場合は実行
                      if (onPriorityChanged != null) {
                        onPriorityChanged!(priority);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AssignmentUIHelpers.getPriorityColor(priority) 
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AssignmentUIHelpers.getPriorityColor(priority),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        AssignmentUIHelpers.getPriorityLabel(priority),
                        style: TextStyle(
                          color: isSelected 
                              ? Colors.white 
                              : AssignmentUIHelpers.getPriorityColor(priority),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 優先度インジケーター（表示専用）
/// リスト表示などで優先度を示すためのコンパクトなウィジェット
class PriorityIndicator extends StatelessWidget {
  /// 表示する優先度
  final int priority;

  const PriorityIndicator({
    super.key,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final color = AssignmentUIHelpers.getPriorityColor(priority);
    final icon = AssignmentUIHelpers.getPriorityIcon(priority);
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }
}
