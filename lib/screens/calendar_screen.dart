import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/assignments_provider.dart';
import '../utils/logger.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../widgets/calendar_assignment_card.dart';

/// カレンダー表示画面
/// 課題を日付ごとに可視化して、締切日の管理を簡単にする
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> with LoggerMixin {
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
      try {        // 課題の締切日を解析（共通ユーティリティを使用）
        final dateTime = app_date_utils.DateUtils.parseDateTime(assignment.startTime);
        final dateKey = _getDateKey(dateTime);
        
        // その日付のリストがなければ作成
        if (!grouped.containsKey(dateKey)) {
          grouped[dateKey] = [];
        }
        // 課題をその日付のリストに追加
        grouped[dateKey]!.add(assignment);
      } catch (e) {
        logError('日付解析エラー: $e');
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
        ),        // 課題リスト
        Expanded(
          child: ListView.builder(
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return CalendarAssignmentCard(assignment: assignment);
            },
          ),
        ),      ],
    );
  }
}
