import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/schedule_model.dart';
import '../utils/logger.dart';
import 'storage_provider.dart';

/// 時間割を管理するNotifier
class ScheduleNotifier extends StateNotifier<List<ScheduleSlot>> with LoggerMixin {
  ScheduleNotifier() : super([]) {
    _initializeDefaultSchedule();
    _loadFromStorage();
  }

  /// デフォルトの空の時間割を初期化
  void _initializeDefaultSchedule() {
    final slots = <ScheduleSlot>[];
    
    for (final weekday in DefaultScheduleConfig.weekdays) {
      for (final period in DefaultScheduleConfig.defaultPeriods) {
        slots.add(ScheduleSlot(
          id: '${weekday.name}_${period.number}',
          weekday: weekday,
          period: period,
          subject: null,
        ));
      }
    }
    
    state = slots;
  }

  /// ローカルストレージから時間割データを復元
  Future<void> _loadFromStorage() async {
    try {
      final savedSchedule = await StorageService.loadSchedule();
      if (savedSchedule.isNotEmpty) {
        state = savedSchedule;
        logData('ローカルストレージから${savedSchedule.length}件の時間割を復元');
      }
    } catch (e) {
      logError('時間割データ復元エラー', error: e);
    }
  }

  /// データをローカルストレージに保存
  Future<void> _saveToStorage() async {
    try {
      await StorageService.saveSchedule(state);
      logData('時間割データを保存しました');
    } catch (e) {
      logError('時間割データ保存エラー', error: e);
    }
  }

  /// 指定したコマに科目を設定
  void setSubject(String slotId, Subject? subject) {
    state = state.map((slot) {
      if (slot.id == slotId) {
        return slot.copyWith(subject: subject);
      }
      return slot;
    }).toList();
    _saveToStorage();
  }

  /// 指定したコマの科目を削除
  void removeSubject(String slotId) {
    setSubject(slotId, null);
  }

  /// 科目を更新
  void updateSubject(String subjectId, Subject updatedSubject) {
    state = state.map((slot) {
      if (slot.subject?.id == subjectId) {
        return slot.copyWith(subject: updatedSubject);
      }
      return slot;
    }).toList();
    _saveToStorage();
  }

  /// 指定した曜日の時間割を取得
  List<ScheduleSlot> getSlotsByWeekday(Weekday weekday) {
    return state.where((slot) => slot.weekday == weekday).toList()
      ..sort((a, b) => a.period.number.compareTo(b.period.number));
  }

  /// 指定した時限の時間割を取得
  List<ScheduleSlot> getSlotsByPeriod(int periodNumber) {
    return state.where((slot) => slot.period.number == periodNumber).toList()
      ..sort((a, b) => a.weekday.index.compareTo(b.weekday.index));
  }

  /// 指定したコマの時間割を取得
  ScheduleSlot? getSlot(Weekday weekday, int periodNumber) {
    try {
      return state.firstWhere(
        (slot) => slot.weekday == weekday && slot.period.number == periodNumber,
      );
    } catch (e) {
      return null;
    }
  }

  /// すべての科目を取得（重複なし）
  List<Subject> getAllSubjects() {
    final subjects = <String, Subject>{};
    for (final slot in state) {
      if (slot.subject != null) {
        subjects[slot.subject!.id] = slot.subject!;
      }
    }
    return subjects.values.toList();
  }

  /// 時間割をクリア
  void clearSchedule() {
    _initializeDefaultSchedule();
    _saveToStorage();
  }

  /// 手動でローカルストレージからデータを復元
  Future<void> refreshFromStorage() async {
    await _loadFromStorage();
  }

  /// 今日の時間割を取得
  List<ScheduleSlot> getTodaySchedule() {
    final now = DateTime.now();
    final today = _getWeekdayFromDateTime(now);
    if (today == null) return [];
    
    return getSlotsByWeekday(today);
  }

  /// 次の授業を取得
  ScheduleSlot? getNextClass() {
    final now = DateTime.now();
    final today = _getWeekdayFromDateTime(now);
    if (today == null) return null;

    final todaySlots = getSlotsByWeekday(today)
      .where((slot) => slot.isNotEmpty)
      .toList();

    for (final slot in todaySlots) {
      final startTime = _parseTime(slot.period.startTime);
      if (startTime != null && startTime.isAfter(now)) {
        return slot;
      }
    }

    return null;
  }

  /// 現在の授業を取得
  ScheduleSlot? getCurrentClass() {
    final now = DateTime.now();
    final today = _getWeekdayFromDateTime(now);
    if (today == null) return null;

    final todaySlots = getSlotsByWeekday(today)
      .where((slot) => slot.isNotEmpty)
      .toList();

    for (final slot in todaySlots) {
      final startTime = _parseTime(slot.period.startTime);
      final endTime = _parseTime(slot.period.endTime);
      
      if (startTime != null && endTime != null &&
          now.isAfter(startTime) && now.isBefore(endTime)) {
        return slot;
      }
    }

    return null;
  }

  /// DateTimeからWeekdayに変換
  Weekday? _getWeekdayFromDateTime(DateTime dateTime) {
    switch (dateTime.weekday) {
      case 1: return Weekday.monday;
      case 2: return Weekday.tuesday;
      case 3: return Weekday.wednesday;
      case 4: return Weekday.thursday;
      case 5: return Weekday.friday;
      case 6: return Weekday.saturday;
      case 7: return Weekday.sunday;
      default: return null;
    }
  }

  /// 時刻文字列をDateTimeに変換
  DateTime? _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    } catch (e) {
      logError('時刻パースエラー: $timeString', error: e);
    }
    return null;
  }
}

/// 時間割プロバイダー
final scheduleProvider = StateNotifierProvider<ScheduleNotifier, List<ScheduleSlot>>((ref) {
  return ScheduleNotifier();
});

/// 今日の時間割プロバイダー
final todayScheduleProvider = Provider<List<ScheduleSlot>>((ref) {
  ref.watch(scheduleProvider);
  final notifier = ref.read(scheduleProvider.notifier);
  return notifier.getTodaySchedule();
});

/// 次の授業プロバイダー
final nextClassProvider = Provider<ScheduleSlot?>((ref) {
  ref.watch(scheduleProvider);
  final notifier = ref.read(scheduleProvider.notifier);
  return notifier.getNextClass();
});

/// 現在の授業プロバイダー
final currentClassProvider = Provider<ScheduleSlot?>((ref) {
  ref.watch(scheduleProvider);
  final notifier = ref.read(scheduleProvider.notifier);
  return notifier.getCurrentClass();
});

/// すべての科目プロバイダー
final allSubjectsProvider = Provider<List<Subject>>((ref) {
  ref.watch(scheduleProvider);
  final notifier = ref.read(scheduleProvider.notifier);
  return notifier.getAllSubjects();
});