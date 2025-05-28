import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

/// 課題データのモデルクラス
/// Moodleから取得した課題情報と、アプリ内での完了状態を管理
class Assignment {
  final String id; // 課題の一意ID
  final String name;
  final String startTime;
  final String course;
  final String moduleName;
  final String url;
  final String description;
  final bool isCompleted; // 完了状態
  final DateTime? completedAt; // 完了日時
  final int priority; // 優先度（1:低、2:中、3:高）

  Assignment({
    required this.id,
    required this.name,
    required this.startTime,
    required this.course,
    required this.moduleName,
    required this.url,
    required this.description,
    this.isCompleted = false,
    this.completedAt,
    this.priority = 2, // デフォルトは中優先度
  });

  /// MapからAssignmentインスタンスを作成するファクトリメソッド
  /// Moodleからのデータを課題オブジェクトに変換
  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id']?.toString() ?? map['name']?.hashCode.toString() ?? '',
      name: map['name'] ?? '',
      startTime: map['startTime'] ?? '',
      course: map['course'] ?? '',
      moduleName: map['moduleName'] ?? '',
      url: map['url'] ?? '',
      description: map['description'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      priority: map['priority'] ?? 2,
    );
  }

  /// 課題オブジェクトをMapに変換するメソッド
  /// ローカルストレージへの保存用
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime,
      'course': course,
      'moduleName': moduleName,
      'url': url,
      'description': description,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'priority': priority,
    };
  }

  /// 課題をコピーして一部プロパティを変更するメソッド
  /// イミュータブルなオブジェクトの更新に使用
  Assignment copyWith({
    String? id,
    String? name,
    String? startTime,
    String? course,
    String? moduleName,
    String? url,
    String? description,
    bool? isCompleted,
    DateTime? completedAt,
    int? priority,
  }) {
    return Assignment(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      course: course ?? this.course,
      moduleName: moduleName ?? this.moduleName,
      url: url ?? this.url,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
    );
  }
}

/// 課題リストを管理するNotifier
/// 課題の追加、削除、完了状態の変更などを行う
class AssignmentsNotifier extends StateNotifier<List<Assignment>> {
  AssignmentsNotifier() : super([]);

  /// 課題リストをセットするメソッド
  /// Moodleから取得したデータを設定
  void setAssignments(List<dynamic> assignmentData) {
    state = assignmentData
        .map((data) => Assignment.fromMap(Map<String, dynamic>.from(data)))
        .toList();
  }

  /// 課題を追加するメソッド
  void addAssignment(Assignment assignment) {
    state = [...state, assignment];
  }

  /// 課題の完了状態を切り替えるメソッド
  /// 課題IDを指定して完了/未完了を変更
  void toggleAssignmentCompletion(String assignmentId) {
    state = state.map((assignment) {
      if (assignment.id == assignmentId) {
        return assignment.copyWith(
          isCompleted: !assignment.isCompleted,
          completedAt: !assignment.isCompleted ? DateTime.now() : null,
        );
      }
      return assignment;
    }).toList();
  }

  /// 課題の優先度を変更するメソッド
  void updateAssignmentPriority(String assignmentId, int priority) {
    state = state.map((assignment) {
      if (assignment.id == assignmentId) {
        return assignment.copyWith(priority: priority);
      }
      return assignment;
    }).toList();
  }

  /// 完了した課題を削除するメソッド
  void removeCompletedAssignments() {
    state = state.where((assignment) => !assignment.isCompleted).toList();
  }

  /// 課題をクリアするメソッド
  void clearAssignments() {
    state = [];
  }

  /// 課題をソートするメソッド
  /// 締切日順、優先度順、完了状態順でソート可能
  void sortAssignments(AssignmentSortType sortType) {
    final sortedList = List<Assignment>.from(state);
    
    switch (sortType) {      case AssignmentSortType.dueDate:
        sortedList.sort((a, b) {
          try {
            final dateA = _parseDateTime(a.startTime);
            final dateB = _parseDateTime(b.startTime);
            return dateA.compareTo(dateB);
          } catch (e) {
            print('❌ ソート中の日付パースエラー: $e');
            return 0;
          }
        });
        break;
      case AssignmentSortType.priority:
        sortedList.sort((a, b) => b.priority.compareTo(a.priority));
        break;
      case AssignmentSortType.course:
        sortedList.sort((a, b) => a.course.compareTo(b.course));
        break;
      case AssignmentSortType.completion:
        sortedList.sort((a, b) => a.isCompleted ? 1 : -1);
        break;
    }
    
    state = sortedList;
  }  /// 日付文字列をDateTimeに変換するヘルパーメソッド
  /// 複数の日付形式に対応してより柔軟にパース
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
        'yyyy-MM-dd HH:mm:ss',       // ISO形式（バックアップ）
        'yyyy-MM-dd HH:mm',          // ISO形式（秒なし）
      ];
        // 各フォーマットを順番に試す
      for (String format in dateFormats) {
        try {
          final parsed = DateFormat(format).parse(dateTimeString);
          print('✅ 日付パース成功: "$dateTimeString" → $parsed (フォーマット: $format)');
          return parsed;
        } catch (e) {
          // このフォーマットで失敗したら次を試す
          print('❌ フォーマット "$format" で失敗: $e');
          continue;
        }
      }
      
      // すべて失敗した場合はエラーログを出力して現在時刻を返す
      print('⚠️ 日付パース失敗: $dateTimeString');
      return DateTime.now();
      
    } catch (e) {
      print('❌ 日付パース例外: $e - 入力: $dateTimeString');
      return DateTime.now();
    }
  }
}

/// 課題のソート方法を定義する列挙型
enum AssignmentSortType {
  dueDate,    // 締切日順
  priority,   // 優先度順
  course,     // コース順
  completion, // 完了状態順
}

/// 課題プロバイダー
/// アプリ全体で課題データを共有するためのStateNotifierProvider
final assignmentsProvider = StateNotifierProvider<AssignmentsNotifier, List<Assignment>>((ref) {
  return AssignmentsNotifier();
});