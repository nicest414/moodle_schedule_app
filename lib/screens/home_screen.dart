import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/assignments_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/logger.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../widgets/timeline_assignment_card.dart';
import '../widgets/assignment_app_bar.dart';

/// 課題一覧を表示する画面
/// Moodleから取得した課題データをリストで表示
class HomeScreen extends ConsumerWidget with LoggerMixin {
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
        appBar: const AssignmentAppBar(),
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
    }    // 課題を日付ごとにグループ化し、日付順にソート
    final groupedAssignments = _groupAssignmentsByDate(assignments);
    final sortedDates = groupedAssignments.keys.toList()..sort();

    return Scaffold(
      appBar: const AssignmentAppBar(),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final dateKey = sortedDates[index];
          final dateAssignments = groupedAssignments[dateKey]!;
          
          return _buildDateSection(context, DateTime.parse(dateKey), dateAssignments);
        },
      ),
    );
  }
  /// 課題を日付ごとにグループ化するメソッド
  Map<String, List<Assignment>> _groupAssignmentsByDate(List<Assignment> assignments) {
    final Map<String, List<Assignment>> grouped = {};
    for (final assignment in assignments) {
      String dateKey;
      try {
        final dateTime = app_date_utils.DateUtils.parseDateTime(assignment.startTime);
        dateKey = app_date_utils.DateUtils.getDateKey(dateTime);
      } catch (e, stackTrace) {
        // より詳細なエラー情報をログに出力
        logWarning('課題「${assignment.name}」(ID: ${assignment.id})の日付解析に失敗したため、今日の日付に割り当てます。'
            '対象日付文字列: ${assignment.startTime}');
        logError('日付解析の詳細エラー', error: '$e\n$stackTrace');
        dateKey = app_date_utils.DateUtils.getDateKey(DateTime.now());
      }
      // putIfAbsent を使用して、キーが存在しない場合は新しいリストを作成し、課題を追加
      grouped.putIfAbsent(dateKey, () => []).add(assignment);
    }
    return grouped;
  }  /// 日付セクションを構築するメソッド
  Widget _buildDateSection(BuildContext context, DateTime date, List<Assignment> assignments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日付見出し
        _buildDateHeader(date),
        // その日の課題リスト
        ...assignments.map((assignment) => TimelineAssignmentCard(assignment: assignment)),
        // 下部区切り線
        const Divider(height: 1, thickness: 1, color: Colors.grey),
        const SizedBox(height: 16),
      ],
    );
  }
  
  /// 日付の見出し部分を構築するメソッド
  Widget _buildDateHeader(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        app_date_utils.DateUtils.formatDateWithJapaneseWeekday(date),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
