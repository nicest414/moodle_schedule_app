import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/assignments_provider.dart';
import 'package:intl/intl.dart'; // 日付フォーマット用
import 'package:url_launcher/url_launcher.dart'; // URL起動用

// 課題一覧を表示する画面
// Moodleから取得した課題データをリストで表示
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // プロバイダーから課題データを取得
    final assignments = ref.watch(assignmentsProvider);
    
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('課題一覧'),
        actions: [
          // 更新ボタン（後で実装）
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // 課題データの再取得処理（後で実装）
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
                    : Colors.white,
            child: ListTile(
              leading: Icon(taskIcon, color: _getColorForModule(assignment.moduleName), size: 32),
              title: Text(
                assignment.name,
                style: Theme.of(context).textTheme.titleMedium,
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
              trailing: _buildRemainingDaysWidget(daysRemaining),
              onTap: () => _showAssignmentDetails(context, assignment),
            ),
          );
        },
      ),
    );
  }

  // 文字列の日付をDateTimeに変換
  DateTime _parseDateTime(String dateTimeString) {
    try {
      // "M/d/yyyy, h:mm:ss a" 形式の文字列をパース
      return DateFormat('M/d/yyyy, h:mm:ss a').parse(dateTimeString);
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
  void _showAssignmentDetails(BuildContext context, Assignment assignment) {
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
                  const Divider(height: 32),
                  _infoTile('コース', assignment.course),
                  _infoTile('締切日時', _formatDateTime(assignment.startTime)),
                  _infoTile('課題の種類', assignment.moduleName),
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
