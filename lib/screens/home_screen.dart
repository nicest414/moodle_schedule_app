import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/assignments_provider.dart';
import '../providers/settings_provider.dart';
import 'package:intl/intl.dart'; // 日付フォーマット用
import 'package:url_launcher/url_launcher.dart'; // URL起動用

// 課題一覧を表示する画面
// Moodleから取得した課題データをリストで表示
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // プロバイダーから課題データと設定を取得
    final allAssignments = ref.watch(assignmentsProvider);
    final settings = ref.watch(settingsProvider);
    
    // 設定に基づいて課題をフィルタリング
    final assignments = settings.showCompletedTasks 
        ? allAssignments 
        : allAssignments.where((assignment) => !assignment.isCompleted).toList();
    
    // データが空の場合
    if (assignments.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('課題一覧')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('課題がないか、データを取得中...🔍'),
            ],
          ),
        ),
      );
    }

    return Scaffold(      appBar: AppBar(
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
      ),
      body: ListView.builder(
        itemCount: assignments.length,
        itemBuilder: (context, index) {
          final assignment = assignments[index];
          
          // 締切日からの残り日数を計算
          final DateTime dueDate = _parseDateTime(assignment.startTime);
          final int daysRemaining = _getDaysRemaining(dueDate);
          final bool isUrgent = daysRemaining <= 3 && daysRemaining >= 0;
          final bool isOverdue = daysRemaining < 0;
          
          // 課題の種類によってアイコンを変更
          IconData taskIcon = _getIconForModule(assignment.moduleName);
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            // 締切が近いか過ぎている場合は色を変える
            color: isOverdue 
                ? Colors.red.shade50
                : isUrgent 
                    ? Colors.orange.shade50
                    : Colors.white,            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 完了チェックボックス
                  Checkbox(
                    value: assignment.isCompleted,
                    onChanged: (value) {
                      ref.read(assignmentsProvider.notifier).toggleAssignmentCompletion(assignment.id);
                      
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
                  const SizedBox(width: 8),
                  // 課題アイコン
                  Icon(
                    taskIcon,
                    color: assignment.isCompleted 
                        ? Colors.grey 
                        : _getColorForModule(assignment.moduleName),
                    size: 32,
                  ),
                ],
              ),              title: Text(
                assignment.name,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  decoration: assignment.isCompleted ? TextDecoration.lineThrough : null,
                  color: assignment.isCompleted ? Colors.grey : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(assignment.course, 
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text('締切: ${_formatDateTime(assignment.startTime)}'),
                ],
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 優先度インジケーター
                  _buildPriorityIndicator(assignment.priority),
                  const SizedBox(width: 8),
                  // 残り日数表示
                  _buildRemainingDaysWidget(daysRemaining),
                ],
              ),
              onTap: () => _showAssignmentDetails(context, assignment, ref),
            ),
          );
        },
      ),
    );
  }

  // 文字列の日付をDateTimeに変換
  DateTime _parseDateTime(String dateTimeString) {
    try {
      // 実際に来るデータの形式に合わせたフォーマットリスト
      final List<String> dateFormats = [
        'yyyy/MM/dd HH:mm',          // メイン形式: 2025/06/03 15:00
        'yyyy/MM/dd H:mm',           // 時刻が1桁の場合: 2025/06/03 4:00
        'yyyy/M/dd HH:mm',           // 月が1桁の場合: 2025/6/03 15:00
        'yyyy/M/dd H:mm',            // 月と時刻が1桁: 2025/6/03 4:00
        'yyyy/MM/d HH:mm',           // 日が1桁の場合: 2025/06/3 15:00
        'yyyy/MM/d H:mm',            // 日と時刻が1桁: 2025/06/3 4:00
        'yyyy/M/d HH:mm',            // 月と日が1桁: 2025/6/3 15:00
        'yyyy/M/d H:mm',             // 月、日、時刻が1桁: 2025/6/3 4:00
        'M/d/yyyy, h:mm:ss a',       // 旧形式（互換性のため）
        'yyyy-MM-dd HH:mm:ss',       // ISO形式（バックアップ）
        'yyyy-MM-dd HH:mm',          // ISO形式（秒なし）
      ];
      
      // 各フォーマットを順番に試す
      for (String format in dateFormats) {
        try {
          return DateFormat(format).parse(dateTimeString);
        } catch (e) {
          // このフォーマットで失敗したら次を試す
          continue;
        }
      }
      
      // すべて失敗した場合はエラーログを出力して現在時刻を返す
      print('⚠️ HomeScreen日付パース失敗: $dateTimeString');
      return DateTime.now();
    } catch (e) {
      print('日付パースエラー: $e');
      return DateTime.now(); // エラー時は現在時刻を返す
    }
  }

  // 締切日までの残り日数を計算
  int _getDaysRemaining(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    return difference.inDays;
  }

  // 日付をわかりやすい形式に整形
  String _formatDateTime(String dateTimeString) {
    final date = _parseDateTime(dateTimeString);
    return DateFormat('M/d(E) HH:mm').format(date);
  }

  // モジュール（課題の種類）によってアイコンを返す
  IconData _getIconForModule(String moduleName) {
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

  // モジュール（課題の種類）によって色を返す
  Color _getColorForModule(String moduleName) {
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

  // 優先度インジケーターを構築するメソッド
  Widget _buildPriorityIndicator(int priority) {
    Color color;
    IconData icon;
    
    switch (priority) {
      case 3: // 高優先度
        color = Colors.red;
        icon = Icons.priority_high;
        break;
      case 2: // 中優先度
        color = Colors.orange;
        icon = Icons.remove;
        break;
      case 1: // 低優先度
        color = Colors.green;
        icon = Icons.keyboard_arrow_down;
        break;
      default:
        color = Colors.grey;
        icon = Icons.remove;
    }
    
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
    );  }

  // 優先度に応じた色を返すメソッド
  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // 優先度のラベルを返すメソッド
  String _getPriorityLabel(int priority) {
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

  // 残り日数を表示するウィジェットを構築
  Widget _buildRemainingDaysWidget(int daysRemaining) {
    if (daysRemaining < 0) {
      // 締切過ぎた
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          '期限切れ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    } else if (daysRemaining == 0) {
      // 今日が締切
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          '本日締切',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    } else if (daysRemaining <= 3) {
      // 3日以内
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'あと${daysRemaining}日',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    } else {
      // それ以外
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'あと${daysRemaining}日',
          style: const TextStyle(color: Colors.black87),
        ),
      );
    }
  }
  // 課題詳細を表示
  void _showAssignmentDetails(BuildContext context, Assignment assignment, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
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
                  Row(
                    children: [
                      Icon(
                        _getIconForModule(assignment.moduleName),
                        color: _getColorForModule(assignment.moduleName),
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
                  const Divider(height: 32),                  _infoTile('コース', assignment.course),
                  _infoTile('締切日時', _formatDateTime(assignment.startTime)),
                  _infoTile('課題の種類', assignment.moduleName),
                  // 優先度設定
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
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
                              final isSelected = assignment.priority == priority;
                              return GestureDetector(
                                onTap: () {
                                  ref.read(assignmentsProvider.notifier).updateAssignmentPriority(assignment.id, priority);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? _getPriorityColor(priority) : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _getPriorityColor(priority),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    _getPriorityLabel(priority),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : _getPriorityColor(priority),
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
                    ),
                  ),
                  if (assignment.description.isNotEmpty)
                    _infoTile('説明', assignment.description, isHtml: true),
                  const SizedBox(height: 20),
                  if (assignment.url.isNotEmpty)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Moodleで開く'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: () async {
                        // URLを開く処理
                        Navigator.pop(context);
                        final Uri url = Uri.parse(assignment.url);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } else {
                          // URLが開けない場合
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('URLを開けませんでした😭'))
                            );
                          }
                        }
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 情報を表示するためのタイル
  Widget _infoTile(String title, String content, {bool isHtml = false}) {
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
