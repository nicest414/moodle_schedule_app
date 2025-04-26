import 'package:hooks_riverpod/hooks_riverpod.dart';

// 課題データのモデルクラス
class Assignment {
  final String name;
  final String startTime;
  final String course;
  final String moduleName;
  final String url;
  final String description;

  Assignment({
    required this.name,
    required this.startTime,
    required this.course,
    required this.moduleName,
    required this.url,
    required this.description,
  });

  // MapからAssignmentインスタンスを作成するファクトリメソッド
  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      name: map['name'] ?? '',
      startTime: map['startTime'] ?? '',
      course: map['course'] ?? '',
      moduleName: map['moduleName'] ?? '',
      url: map['url'] ?? '',
      description: map['description'] ?? '',
    );
  }
}

// 課題リストを管理するNotifier
class AssignmentsNotifier extends StateNotifier<List<Assignment>> {
  AssignmentsNotifier() : super([]);

  // 課題リストをセット
  void setAssignments(List<dynamic> assignmentData) {
    state = assignmentData
        .map((data) => Assignment.fromMap(Map<String, dynamic>.from(data)))
        .toList();
  }

  // 課題を追加
  void addAssignment(Assignment assignment) {
    state = [...state, assignment];
  }

  // 課題をクリア
  void clearAssignments() {
    state = [];
  }
}

// 課題プロバイダー
final assignmentsProvider = StateNotifierProvider<AssignmentsNotifier, List<Assignment>>((ref) {
  return AssignmentsNotifier();
});