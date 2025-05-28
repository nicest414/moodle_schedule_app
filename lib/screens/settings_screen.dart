import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/assignments_provider.dart';

/// アプリの設定画面
/// 通知設定、テーマ設定、データ管理などを行う
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final assignments = ref.watch(assignmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ 設定'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 通知設定セクション
          _buildSectionHeader('🔔 通知設定'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('プッシュ通知'),
                  subtitle: const Text('課題の締切前に通知'),
                  value: settings.notificationsEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleNotifications(value);
                  },
                ),
                if (settings.notificationsEnabled) ...[
                  ListTile(
                    title: const Text('通知タイミング'),
                    subtitle: Text('締切の${settings.notificationHours}時間前'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showNotificationTimingDialog(context, ref),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 表示設定セクション
          _buildSectionHeader('🎨 表示設定'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('ダークモード'),
                  subtitle: const Text('暗いテーマを使用'),
                  value: settings.isDarkMode,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleDarkMode(value);
                  },
                ),
                ListTile(
                  title: const Text('課題のソート'),
                  subtitle: Text(_getSortTypeLabel(settings.defaultSortType)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showSortOptionsDialog(context, ref),
                ),
                SwitchListTile(
                  title: const Text('完了した課題を表示'),
                  subtitle: const Text('チェック済みの課題も一覧に表示'),
                  value: settings.showCompletedTasks,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleShowCompletedTasks(value);
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // データ管理セクション
          _buildSectionHeader('💾 データ管理'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh, color: Colors.blue),
                  title: const Text('課題データを更新'),
                  subtitle: const Text('Moodleから最新の課題を取得'),
                  onTap: () => _refreshAssignments(context, ref),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_sweep, color: Colors.orange),
                  title: const Text('完了した課題を削除'),
                  subtitle: Text('${assignments.where((a) => a.isCompleted).length}件の完了済み課題'),
                  onTap: () => _showDeleteCompletedDialog(context, ref),
                ),
                ListTile(
                  leading: const Icon(Icons.clear_all, color: Colors.red),
                  title: const Text('全ての課題データを削除'),
                  subtitle: const Text('すべての課題データをクリア'),
                  onTap: () => _showClearAllDataDialog(context, ref),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // アプリ情報セクション
          _buildSectionHeader('ℹ️ アプリ情報'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info, color: Colors.blue),
                  title: Text('バージョン'),
                  subtitle: Text('1.0.0'),
                ),
                ListTile(
                  leading: const Icon(Icons.code, color: Colors.green),
                  title: const Text('ライセンス'),
                  subtitle: const Text('オープンソースライセンス'),
                  onTap: () => _showLicenseDialog(context),
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report, color: Colors.orange),
                  title: const Text('バグレポート'),
                  subtitle: const Text('問題を報告する'),
                  onTap: () => _showBugReportDialog(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 統計情報
          _buildSectionHeader('📊 統計情報'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatRow('総課題数', '${assignments.length}件'),
                  _buildStatRow('完了済み', '${assignments.where((a) => a.isCompleted).length}件'),
                  _buildStatRow('未完了', '${assignments.where((a) => !a.isCompleted).length}件'),
                  _buildStatRow('優先度高', '${assignments.where((a) => a.priority == 3).length}件'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// セクションヘッダーを構築するメソッド
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  /// 統計情報の行を構築するメソッド
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// ソートタイプのラベルを取得するメソッド
  String _getSortTypeLabel(AssignmentSortType sortType) {
    switch (sortType) {
      case AssignmentSortType.dueDate:
        return '締切日順';
      case AssignmentSortType.priority:
        return '優先度順';
      case AssignmentSortType.course:
        return 'コース順';
      case AssignmentSortType.completion:
        return '完了状態順';
    }
  }

  /// 通知タイミング設定ダイアログを表示
  void _showNotificationTimingDialog(BuildContext context, WidgetRef ref) {
    final currentHours = ref.read(settingsProvider).notificationHours;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('通知タイミング'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [1, 3, 6, 12, 24, 48].map((hours) {
            return RadioListTile<int>(
              title: Text('${hours}時間前'),
              value: hours,
              groupValue: currentHours,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setNotificationHours(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  /// ソートオプションダイアログを表示
  void _showSortOptionsDialog(BuildContext context, WidgetRef ref) {
    final currentSort = ref.read(settingsProvider).defaultSortType;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('デフォルトソート'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AssignmentSortType.values.map((sortType) {
            return RadioListTile<AssignmentSortType>(
              title: Text(_getSortTypeLabel(sortType)),
              value: sortType,
              groupValue: currentSort,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setDefaultSortType(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 課題データ更新処理
  void _refreshAssignments(BuildContext context, WidgetRef ref) {
    // TODO: ログイン画面に戻って再取得する処理を実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('課題データの更新機能は開発中です 🚧'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// 完了課題削除確認ダイアログを表示
  void _showDeleteCompletedDialog(BuildContext context, WidgetRef ref) {
    final completedCount = ref.read(assignmentsProvider).where((a) => a.isCompleted).length;
    
    if (completedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('削除する完了済み課題がありません')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('完了した課題を削除'),
        content: Text('$completedCount件の完了済み課題を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(assignmentsProvider.notifier).removeCompletedAssignments();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$completedCount件の課題を削除しました ✅')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  /// 全データ削除確認ダイアログを表示
  void _showClearAllDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 全データ削除'),
        content: const Text('すべての課題データを削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(assignmentsProvider.notifier).clearAssignments();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('全ての課題データを削除しました 🗑️'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  /// ライセンスダイアログを表示
  void _showLicenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('ライセンス情報'),
        content: Text(
          'このアプリはオープンソースソフトウェアです。\n\n'
          '使用しているライブラリ:\n'
          '• Flutter\n'
          '• Riverpod\n'
          '• Table Calendar\n'
          '• その他のDartパッケージ\n\n'
          '詳細なライセンス情報は各パッケージのドキュメントをご確認ください。'
        ),
      ),
    );
  }

  /// バグレポートダイアログを表示
  void _showBugReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🐛 バグレポート'),
        content: const Text(
          'バグや改善要望がありましたら、\n'
          '以下の情報と一緒にお知らせください:\n\n'
          '• 発生した問題の詳細\n'
          '• 再現手順\n'
          '• 使用している端末情報\n'
          '• アプリのバージョン\n\n'
          'GitHub Issuesまたはメールでご連絡ください。'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}
