import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/assignments_provider.dart';
import '../utils/assignment_ui_helpers.dart';
import '../utils/date_utils.dart' as app_date_utils;
import 'expandable_description.dart';

/// 課題詳細を表示するボトムシート
/// 課題の詳細情報表示、優先度変更、Moodleでの開く機能を提供
class AssignmentDetailsSheet extends ConsumerWidget {
  /// 表示する課題データ
  final Assignment assignment;

  const AssignmentDetailsSheet({
    super.key,
    required this.assignment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ドラッグハンドル
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // 課題タイトルとアイコン
                Row(
                  children: [
                    Icon(
                      AssignmentUIHelpers.getIconForModule(assignment.moduleName),
                      color: AssignmentUIHelpers.getColorForModule(assignment.moduleName),
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        assignment.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                
                // 基本情報セクション
                _InfoTile(title: 'コース', content: assignment.course),
                _InfoTile(
                  title: '締切日時',
                  content: app_date_utils.DateUtils.formatDateTime(assignment.startTime),
                ),
                  // 説明セクション（内容がある場合のみ）
                if (assignment.description.isNotEmpty)
                  ExpandableDescription(
                    title: '説明',
                    text: assignment.description,
                  ),
                
                const SizedBox(height: 20),
                
                // MoodleでURLを開くボタン（URLがある場合のみ）
                if (assignment.url.isNotEmpty)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Moodleで開く'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () => _openInMoodle(context, assignment.url),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// MoodleでURLを開く処理
  /// エラーハンドリング付きでブラウザまたは外部アプリで開く
  Future<void> _openInMoodle(BuildContext context, String url) async {
    Navigator.pop(context); // ボトムシートを閉じる
    
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // URLが開けない場合
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('URLを開けませんでした😭')),
          );
        }
      }
    } catch (e) {
      // 例外が発生した場合
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
  }
}

/// 情報を表示するためのタイル
/// 課題詳細の各項目を統一された形式で表示
class _InfoTile extends StatelessWidget {
  /// 項目名（例：「コース」「締切日時」）
  final String title;
  
  /// 表示内容
  final String content;

  const _InfoTile({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

/// ボトムシートを表示するためのヘルパー関数
/// 課題詳細を表示する標準的な方法を提供
void showAssignmentDetailsSheet(BuildContext context, Assignment assignment) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => AssignmentDetailsSheet(assignment: assignment),
  );
}
