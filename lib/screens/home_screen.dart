import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 仮データ：後でAPIから取得して置き換える
    final assignments = [
      {
        "title": "宿題（〆切：4月15日13時）",
        "deadline": "2025/4/15 13:00",
        "course": "計算機工学Ⅰ（前期）",
      },
      {
        "title": "小テスト02（4/15）",
        "deadline": "2025/4/15 23:59",
        "course": "電気磁気学（前期）",
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('課題一覧')),
      body: ListView.builder(
        itemCount: assignments.length,
        itemBuilder: (context, index) {
          final item = assignments[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              title: Text(item['title'] ?? ''),
              subtitle: Text('${item['course']}\n締切: ${item['deadline']}'),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // タップ時のアクション（詳細画面など）今後追加
              },
            ),
          );
        },
      ),
    );
  }
}
