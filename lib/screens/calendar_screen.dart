import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/assignments_provider.dart';

/// カレンダー表示画面
/// 課題を日付ごとに可視化して、締切日の管理を簡単にする
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  // カレンダーで選択された日付を管理
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();
  // カレンダーの表示形式（月表示、2週間表示など）
  CalendarFormat calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    // プロバイダーから課題データを取得
    final assignments = ref.watch(assignmentsProvider);
    
    // 課題を日付ごとにグループ化
    final assignmentsByDate = _groupAssignmentsByDate(assignments);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('📅 課題カレンダー'),
        actions: [
          // 今日の日付に戻るボタン
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                selectedDay = DateTime.now();
                focusedDay = DateTime.now();
              });
            },
            tooltip: '今日に戻る',
          ),
        ],
      ),
      body: Column(
        children: [
          // カレンダーウィジェット
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TableCalendar<Assignment>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: focusedDay,
              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              calendarFormat: calendarFormat,
              // 課題データをカレンダーのイベントとして設定
              eventLoader: (day) => assignmentsByDate[_getDateKey(day)] ?? [],
              // 日付が選択された時の処理
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  this.selectedDay = selectedDay;
                  this.focusedDay = focusedDay;
                });
              },
              // カレンダーの表示形式が変更された時の処理
              onFormatChanged: (format) {
                setState(() {
                  calendarFormat = format;
                });
              },
              // 月が変更された時の処理
              onPageChanged: (focusedDay) {
                this.focusedDay = focusedDay;
              },
              // カレンダーのスタイル設定
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.red[400]),
                holidayTextStyle: TextStyle(color: Colors.red[400]),
                // 今日の日付のスタイル
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                // 選択された日付のスタイル
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                // イベント（課題）があるマーカーのスタイル
                markerDecoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3, // 最大3つまでマーカーを表示
              ),
              // ヘッダーのスタイル設定
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
                formatButtonTextStyle: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 選択された日付の課題リスト
          Expanded(
            child: _buildSelectedDayAssignments(assignmentsByDate[_getDateKey(selectedDay)] ?? []),
          ),
        ],
      ),
    );
  }

  /// 課題を日付ごとにグループ化するメソッド
  /// Map<String, List<Assignment>> 形式で返す（日付文字列をキーとする）
  Map<String, List<Assignment>> _groupAssignmentsByDate(List<Assignment> assignments) {
    final Map<String, List<Assignment>> grouped = {};
    
    for (final assignment in assignments) {
      try {
        // 課題の締切日を解析
        final dateTime = _parseDateTime(assignment.startTime);
        final dateKey = _getDateKey(dateTime);
        
        // その日付のリストがなければ作成
        if (!grouped.containsKey(dateKey)) {
          grouped[dateKey] = [];
        }
        
        // 課題をその日付のリストに追加
        grouped[dateKey]!.add(assignment);
      } catch (e) {
        print('日付解析エラー: $e');
        // エラーの場合は今日の日付に追加
        final todayKey = _getDateKey(DateTime.now());
        if (!grouped.containsKey(todayKey)) {
          grouped[todayKey] = [];
        }
        grouped[todayKey]!.add(assignment);
      }
    }
    
    return grouped;
  }

  /// 日付からキー文字列を生成するメソッド
  /// yyyy-MM-dd形式の文字列を返す
  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
  /// 文字列の日付をDateTimeに変換するメソッド
  /// 複数の日付形式に対応
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
      print('⚠️ CalendarScreen日付パース失敗: $dateTimeString');
      return DateTime.now();
    } catch (e) {
      // パースに失敗した場合は現在時刻を返す
      return DateTime.now();
    }
  }

  /// 選択された日付の課題リストを構築するメソッド
  /// その日の課題がない場合は適切なメッセージを表示
  Widget _buildSelectedDayAssignments(List<Assignment> assignments) {
    if (assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '${DateFormat('M月d日').format(selectedDay)}は',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '課題はありません',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 選択日のヘッダー
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            '${DateFormat('M月d日(E)').format(selectedDay)} - ${assignments.length}件の課題',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // 課題リスト
        Expanded(
          child: ListView.builder(
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return _buildAssignmentCard(assignment);
            },
          ),
        ),
      ],
    );
  }

  /// 課題カードを構築するメソッド
  /// 課題の種類に応じて色分けとアイコンを設定
  Widget _buildAssignmentCard(Assignment assignment) {
    final IconData icon = _getIconForModule(assignment.moduleName);
    final Color color = _getColorForModule(assignment.moduleName);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          assignment.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(assignment.course),
            const SizedBox(height: 2),
            Text(
              '⏰ ${DateFormat('HH:mm').format(_parseDateTime(assignment.startTime))}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () {
          // 課題詳細表示（既存のHomeScreenの機能を流用）
          _showAssignmentDetails(assignment);
        },
      ),
    );
  }

  /// 課題詳細を表示するメソッド
  /// ボトムシートで詳細情報を表示
  void _showAssignmentDetails(Assignment assignment) {
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
                // 課題タイトル
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
                // 詳細情報
                _buildInfoTile('コース', assignment.course),
                _buildInfoTile('締切日時', DateFormat('M月d日(E) HH:mm').format(_parseDateTime(assignment.startTime))),
                _buildInfoTile('課題の種類', assignment.moduleName),
                if (assignment.description.isNotEmpty)
                  _buildInfoTile('説明', assignment.description),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 情報タイルを構築するメソッド
  /// ラベルと値のペアを表示
  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// モジュール（課題の種類）に応じたアイコンを返すメソッド
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

  /// モジュール（課題の種類）に応じた色を返すメソッド
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
}
