import 'package:flutter/material.dart';
import '../models/schedule_model.dart';

/// 時間割表を表示するウィジェット（わせジュール風デザイン）
class ScheduleTableWidget extends StatelessWidget {
  final List<ScheduleSlot> schedule;
  final Function(ScheduleSlot) onSlotTap;

  const ScheduleTableWidget({
    super.key,
    required this.schedule,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // 画面サイズに応じてセルサイズを計算
    final timeColumnWidth = 40.0;
    final availableWidth = screenWidth - timeColumnWidth - 20;
    final cellWidth = (availableWidth / DefaultScheduleConfig.weekdays.length);
    final cellHeight = (screenHeight - 200) / (DefaultScheduleConfig.defaultPeriods.length + 1);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          // ヘッダー行（曜日）
          _buildHeaderRow(timeColumnWidth, cellWidth, 35),
          // 時間割の各行
          ...DefaultScheduleConfig.defaultPeriods.map(
            (period) => _buildPeriodRow(period, timeColumnWidth, cellWidth, cellHeight),
          ),
        ],
      ),
    );
  }

  /// ヘッダー行を構築（わせジュール風）
  Widget _buildHeaderRow(double timeColumnWidth, double cellWidth, double cellHeight) {
    return Container(
      height: cellHeight,
      child: Row(
        children: [
          // 空の時限列
          Container(
            width: timeColumnWidth,
            height: cellHeight,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
            ),
          ),
          // 曜日列
          ...DefaultScheduleConfig.weekdays.map(
            (weekday) => _buildHeaderCell(weekday.shortName, cellWidth, cellHeight),
          ),
        ],
      ),
    );
  }

  /// 各時限の行を構築
  Widget _buildPeriodRow(Period period, double timeColumnWidth, double cellWidth, double cellHeight) {
    return Container(
      height: cellHeight,
      child: Row(
        children: [
          // 時限情報セル
          _buildPeriodCell(period, timeColumnWidth, cellHeight),
          // 各曜日のセル
          ...DefaultScheduleConfig.weekdays.map(
            (weekday) => _buildScheduleCell(weekday, period, cellWidth, cellHeight),
          ),
        ],
      ),
    );
  }

  /// ヘッダーセルを構築
  Widget _buildHeaderCell(String text, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32), // 深緑色（わせジュール風）
        border: Border.all(color: Colors.white, width: 0.5),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// 時限情報セルを構築
  Widget _buildPeriodCell(Period period, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Center(
        child: Text(
          '${period.number}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  /// 時間割セルを構築（わせジュール風）
  Widget _buildScheduleCell(Weekday weekday, Period period, double width, double height) {
    final slot = _findSlot(weekday, period);
    
    return GestureDetector(
      onTap: () => onSlotTap(slot),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: slot.isNotEmpty 
              ? slot.subject!.color.withOpacity(0.15)
              : Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: slot.isNotEmpty
            ? _buildSubjectCell(slot.subject!, width, height)
            : _buildEmptyCell(height),
      ),
    );
  }

  /// 科目があるセルの内容を構築（わせジュール風）
  Widget _buildSubjectCell(Subject subject, double width, double height) {
    return Container(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 科目名（上部）
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              child: Text(
                subject.name,
                style: TextStyle(
                  fontSize: width < 65 ? 8 : 9,
                  fontWeight: FontWeight.bold,
                  color: subject.color.withOpacity(0.9),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // 教室情報（下部）
          if (subject.classroom.isNotEmpty)
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                child: Text(
                  subject.classroom,
                  style: TextStyle(
                    fontSize: width < 65 ? 7 : 8,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 空のセルの内容を構築
  Widget _buildEmptyCell(double height) {
    return Container(
      child: Center(
        child: Icon(
          Icons.add_circle_outline,
          color: Colors.grey.shade400,
          size: height > 60 ? 16 : 12,
        ),
      ),
    );
  }

  /// 指定した曜日・時限のスロットを検索
  ScheduleSlot _findSlot(Weekday weekday, Period period) {
    try {
      return schedule.firstWhere(
        (slot) => slot.weekday == weekday && slot.period.number == period.number,
      );
    } catch (e) {
      // 見つからない場合は空のスロットを作成
      return ScheduleSlot(
        id: '${weekday.name}_${period.number}',
        weekday: weekday,
        period: period,
        subject: null,
      );
    }
  }
}