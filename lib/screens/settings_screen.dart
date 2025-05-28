import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodle_schedule_app/providers/settings_provider.dart';
import 'package:moodle_schedule_app/providers/assignments_provider.dart';
import 'package:moodle_schedule_app/providers/auth_provider.dart'; // auth_provider.dart をインポート

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
    final authState = ref.read(authProvider); // authProvider を使用
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

      ref.read(authProvider.notifier).setUsername(username); // authProvider を使用
      if (password.isNotEmpty) {
        ref.read(authProvider.notifier).setPassword(password); // authProvider を使用
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Moodle設定を保存しました！💾')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final assignments = ref.watch(assignmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Text(
                '通知設定',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SwitchListTile(
                title: const Text('通知を有効にする'),
                value: settings.notificationsEnabled,
                onChanged: (bool value) {
                  ref.read(settingsProvider.notifier).toggleNotifications(value);
                },
              ),
              if (settings.notificationsEnabled) ...[
                ListTile(
                  title: const Text('通知時間'),
                  subtitle: Text('締切の${settings.notificationHours}時間前'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    final int? picked = await showDialog<int>(
                      context: context,
                      builder: (BuildContext context) {
                        return SimpleDialog(
                          title: const Text('通知時間を選択'),
                          children: <Widget>[
                            for (int i = 1; i <= 24; i++)
                              SimpleDialogOption(
                                onPressed: () {
                                  Navigator.pop(context, i);
                                },
                                child: Text('$i時間前'),
                              ),
                          ],
                        );
                      },
                    );
                    if (picked != null) {
                      ref.read(settingsProvider.notifier).setNotificationHours(picked);
                    }
                  },
                ),
              ],
              const Divider(),
              Text(
                '表示設定',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SwitchListTile(
                title: const Text('ダークモード'),
                value: settings.isDarkMode,
                onChanged: (bool value) {
                  ref.read(settingsProvider.notifier).toggleDarkMode(value);
                },
              ),
              ListTile(
                title: const Text('デフォルトの並び順'),
                subtitle: Text(_getSortTypeLabel(settings.defaultSortType)),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  final SortType? picked = await showDialog<SortType>(
                    context: context,
                    builder: (BuildContext context) {
                      return SimpleDialog(
                        title: const Text('デフォルトの並び順を選択'),
                        children: SortType.values.map((sortType) {
                          return SimpleDialogOption(
                            onPressed: () {
                              Navigator.pop(context, sortType);
                            },
                            child: Text(_getSortTypeLabel(sortType)),
                          );
                        }).toList(),
                      );
                    },
                  );
                  if (picked != null) {
                    ref.read(settingsProvider.notifier).setDefaultSortType(picked);
                  }
                },
              ),
              SwitchListTile(
                title: const Text('完了した課題を表示'),
                value: settings.showCompletedTasks,
                onChanged: (bool value) {
                  ref.read(settingsProvider.notifier).toggleShowCompletedTasks(value);
                },
              ),
              const Divider(),
              const SizedBox(height: 20),
              Text(
                'Moodleアカウント設定',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Moodleユーザー名',
                  hintText: '学籍番号など',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ユーザー名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Moodleパスワード',
                  hintText: '新しいパスワードを入力',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saveMoodleSettings,
                icon: const Icon(Icons.save),
                label: const Text('Moodle設定を保存'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const Divider(),
              Text(
                'アプリ情報',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ListTile(
                title: const Text('バージョン'),
                subtitle: const Text('1.0.0'), // TODO: 動的に取得
              ),
              ListTile(
                title: const Text('ライセンス'),
                onTap: () {
                  // TODO: ライセンス情報ページへ遷移
                },
              ),
              const Divider(),
              Text(
                '統計情報',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              _buildStatRow('総課題数', '${assignments.length}件'),
              _buildStatRow('完了済み', '${assignments.where((a) => a.isCompleted).length}件'),
              _buildStatRow('未完了', '${assignments.where((a) => !a.isCompleted).length}件'),
              _buildStatRow('優先度高', '${assignments.where((a) => a.priority == 3).length}件'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getSortTypeLabel(SortType sortType) {
    switch (sortType) {
      case SortType.dueDate:
        return '締切日順';
      case SortType.courseName:
        return '科目名順';
      case SortType.priority:
        return '優先度順';
    }
  }
}
