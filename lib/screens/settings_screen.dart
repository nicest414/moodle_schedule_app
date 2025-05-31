import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/assignments_provider.dart';
import '../providers/auth_provider.dart';
import 'splash_screen.dart';

/// アプリの設定画面
/// 通知設定、テーマ設定、データ管理などを行う
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    _usernameController = TextEditingController(text: authState.username);
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _saveMoodleSettings() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final username = _usernameController.text;
      final password = _passwordController.text;

      ref.read(authProvider.notifier).setUsername(username);
      if (password.isNotEmpty) {
        ref.read(authProvider.notifier).setPassword(password);
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Moodle設定を保存しました！💾')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final assignments = ref.watch(assignmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ 設定'), elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
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
                      ref
                          .read(settingsProvider.notifier)
                          .toggleNotifications(value);
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
                      ref
                          .read(settingsProvider.notifier)
                          .toggleShowCompletedTasks(value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Moodleアカウント設定セクション
            _buildSectionHeader('🎓 Moodleアカウント設定'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Moodleユーザー名',
                        hintText: '学籍番号など',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'ユーザー名を入力してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Moodleパスワード',
                        hintText: '新しいパスワードを入力',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveMoodleSettings,
                        icon: const Icon(Icons.save),
                        label: const Text('Moodle設定を保存'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ログアウトセクション
            _buildSectionHeader('🔐 アカウント管理'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('ログアウト'),
                    subtitle: const Text('現在のセッションを終了してログイン画面に戻る'),
                    onTap: () => _showLogoutDialog(context, ref),
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
                    leading: const Icon(
                      Icons.delete_sweep,
                      color: Colors.orange,
                    ),
                    title: const Text('完了した課題を削除'),
                    subtitle: Text(
                      '${assignments.where((a) => a.isCompleted).length}件の完了済み課題',
                    ),
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

            const SizedBox(height: 16),

            // 統計情報
            _buildSectionHeader('📊 統計情報'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatRow('総課題数', '${assignments.length}件'),
                    _buildStatRow(
                      '完了済み',
                      '${assignments.where((a) => a.isCompleted).length}件',
                    ),
                    _buildStatRow(
                      '未完了',
                      '${assignments.where((a) => !a.isCompleted).length}件',
                    ),
                    _buildStatRow(
                      '優先度高',
                      '${assignments.where((a) => a.priority == 3).length}件',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ローカルストレージ管理セクション
            _buildSectionHeader('💾 ローカルストレージ'),
            Card(
              child: Column(
                children: [
                  FutureBuilder<Map<String, int>>(
                    future:
                        ref.read(assignmentsProvider.notifier).getStorageSize(),
                    builder: (context, snapshot) {
                      final size = snapshot.data;
                      return ListTile(
                        leading: const Icon(
                          Icons.storage,
                          color: Colors.purple,
                        ),
                        title: const Text('ストレージ使用量'),
                        subtitle: Text(
                          size != null
                              ? '課題データ: ${(size['assignments']! / 1024).toStringAsFixed(1)}KB\n'
                                  '設定データ: ${(size['settings']! / 1024).toStringAsFixed(1)}KB'
                              : '計算中...',
                        ),
                        trailing: const Icon(Icons.info_outline),
                      );
                    },
                  ),
                  FutureBuilder<DateTime?>(
                    future:
                        ref
                            .read(assignmentsProvider.notifier)
                            .getLastUpdateTime(),
                    builder: (context, snapshot) {
                      final lastUpdate = snapshot.data;
                      return ListTile(
                        leading: const Icon(Icons.update, color: Colors.blue),
                        title: const Text('最終更新'),
                        subtitle: Text(
                          lastUpdate != null
                              ? '${lastUpdate.year}/${lastUpdate.month}/${lastUpdate.day} '
                                  '${lastUpdate.hour}:${lastUpdate.minute.toString().padLeft(2, '0')}'
                              : '更新データなし',
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.backup, color: Colors.green),
                    title: const Text('データをバックアップから復元'),
                    subtitle: const Text('ローカルストレージからデータを再読み込み'),
                    onTap: () => _restoreFromStorage(context, ref),
                  ),
                  ListTile(
                    leading: const Icon(Icons.restore, color: Colors.orange),
                    title: const Text('設定をリセット'),
                    subtitle: const Text('すべての設定をデフォルトに戻す'),
                    onTap: () => _resetSettingsDialog(context, ref),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                    ),
                    title: const Text('ローカルデータを完全削除'),
                    subtitle: const Text('課題・設定データをすべて削除'),
                    onTap: () => _clearStorageDialog(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// ソートタイプのラベルを取得するメソッド
  String _getSortTypeLabel(SortType sortType) {
    switch (sortType) {
      case SortType.dueDate:
        return '締切日順';
      case SortType.courseName:
        return 'コース順';
      case SortType.priority:
        return '優先度順';
    }
  }

  /// 通知タイミング設定ダイアログを表示
  void _showNotificationTimingDialog(BuildContext context, WidgetRef ref) {
    final currentHours = ref.read(settingsProvider).notificationHours;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('通知タイミング'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  [1, 3, 6, 12, 24, 48].map((hours) {
                    return RadioListTile<int>(
                      title: Text('${hours}時間前'),
                      value: hours,
                      groupValue: currentHours,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(settingsProvider.notifier)
                              .setNotificationHours(value);
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
      builder:
          (context) => AlertDialog(
            title: const Text('デフォルトソート'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  SortType.values.map((sortType) {
                    return RadioListTile<SortType>(
                      title: Text(_getSortTypeLabel(sortType)),
                      value: sortType,
                      groupValue: currentSort,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(settingsProvider.notifier)
                              .setDefaultSortType(value);
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
    final completedCount =
        ref.read(assignmentsProvider).where((a) => a.isCompleted).length;

    if (completedCount == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('削除する完了済み課題がありません')));
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('完了した課題を削除'),
            content: Text('$completedCount件の完了済み課題を削除しますか？\nこの操作は取り消せません。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(assignmentsProvider.notifier)
                      .removeCompletedAssignments();
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
      builder:
          (context) => AlertDialog(
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
      builder:
          (context) => const AlertDialog(
            title: Text('ライセンス情報'),
            content: Text(
              'このアプリはオープンソースソフトウェアです。\n\n'
              '使用しているライブラリ:\n'
              '• Flutter\n'
              '• Riverpod\n'
              '• Table Calendar\n'
              '• その他のDartパッケージ\n\n'
              '詳細なライセンス情報は各パッケージのドキュメントをご確認ください。',
            ),
          ),
    );
  }

  /// バグレポートダイアログを表示
  void _showBugReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('🐛 バグレポート'),
            content: const Text(
              'バグや改善要望がありましたら、\n'
              '以下の情報と一緒にお知らせください:\n\n'
              '• 発生した問題の詳細\n'
              '• 再現手順\n'
              '• 使用している端末情報\n'
              '• アプリのバージョン\n\n'
              'GitHub Issuesまたはメールでご連絡ください。',
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

  /// ローカルストレージからデータを復元
  void _restoreFromStorage(BuildContext context, WidgetRef ref) async {
    try {
      // 課題データを復元
      await ref.read(assignmentsProvider.notifier).refreshFromStorage();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('データを復元しました ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('復元に失敗しました: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// 設定リセット確認ダイアログを表示
  void _resetSettingsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('設定をリセット'),
            content: const Text('すべての設定をデフォルトに戻しますか？\nこの操作は取り消せません。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: 設定リセット機能を実装
                  // ref.read(settingsProvider.notifier).resetToDefaults();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('設定リセット機能は開発中です 🚧'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('リセット'),
              ),
            ],
          ),
    );
  }

  /// ストレージデータ削除確認ダイアログを表示
  void _clearStorageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('⚠️ データ削除'),
            content: const Text('ローカルストレージの課題・設定データをすべて削除しますか？\nこの操作は取り消せません。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(assignmentsProvider.notifier).clearAllStorageData();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ローカルデータを削除しました 🗑️'),
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

  /// ログアウト確認ダイアログを表示
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('🔐 ログアウト'),
            content: const Text(
              'ログアウトしますか？\n'
              'ログイン情報は保持されますが、現在のセッションが終了します。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () {
                  // ログアウト処理を実行
                  ref.read(authProvider.notifier).logout();

                  // ダイアログを閉じる
                  Navigator.pop(context);

                  // スプラッシュ画面に戻る（全ての画面をクリア）
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const SplashScreen(),
                    ),
                    (route) => false,
                  );

                  // ログアウト完了メッセージ
                  Future.delayed(const Duration(milliseconds: 500), () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ログアウトしました 👋'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('ログアウト'),
              ),
            ],
          ),
    );
  }
}
