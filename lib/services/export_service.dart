import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/assignments_provider.dart';
import '../utils/logger.dart';

/// データエクスポートサービス
/// 課題データをCSV、JSON、PDFなどの形式でエクスポート
class ExportService with LoggerMixin {
  /// 課題データをCSV形式でエクスポートするメソッド
  Future<String?> exportToCSV(List<Assignment> assignments, {bool includeDescriptions = false}) async {
    try {
      // CSVヘッダー
      final header = [
        '課題名',
        'コース',
        '締切日',
        '種類',
        '優先度',
        '完了状態',
        '完了日時',
        'URL',
      ];
      
      // 説明を含める場合はヘッダーに追加
      if (includeDescriptions) {
        header.add('説明');
      }
      
      // 課題データをCSV行に変換
      final rows = assignments.map((assignment) {
        final row = [
          assignment.name,
          assignment.course,
          assignment.startTime,
          assignment.moduleName,
          _getPriorityText(assignment.priority),
          assignment.isCompleted ? '完了' : '未完了',
          assignment.completedAt != null 
              ? '${assignment.completedAt!.year}/${assignment.completedAt!.month}/${assignment.completedAt!.day}'
              : '',
          assignment.url,
        ];
        
        // 説明を含める場合は追加
        if (includeDescriptions) {
          row.add(assignment.description);
        }
        
        return row;
      }).toList();
      
      // ヘッダーと行を結合
      final allRows = [header, ...rows];
      
      // CSVに変換
      final csv = const ListToCsvConverter().convert(allRows);
      
      // 一時ファイルに保存
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/assignments_$timestamp.csv');
      await file.writeAsString(csv);
      
      logSuccess('CSVエクスポート完了: ${file.path}');
      return file.path;
    } catch (e) {
      logError('CSVエクスポートエラー', error: e);
      return null;
    }
  }
  
  /// 課題データをJSON形式でエクスポートするメソッド
  Future<String?> exportToJSON(List<Assignment> assignments, {bool includeDescriptions = true}) async {
    try {
      // 課題データをMapのリストに変換
      final assignmentMaps = assignments.map((assignment) {
        final map = assignment.toMap();
        // 説明を含めない場合は削除
        if (!includeDescriptions) {
          map.remove('description');
        }
        return map;
      }).toList();
      
      // JSON文字列に変換（整形して読みやすく）
      final jsonString = const JsonEncoder.withIndent('  ').convert(assignmentMaps);
      
      // 一時ファイルに保存
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/assignments_$timestamp.json');
      await file.writeAsString(jsonString);
      
      logSuccess('JSONエクスポート完了: ${file.path}');
      return file.path;
    } catch (e) {
      logError('JSONエクスポートエラー', error: e);
      return null;
    }
  }
  
  /// エクスポートしたファイルを共有するメソッド
  Future<void> shareFile(String filePath, {String? subject}) async {
    try {
      final file = XFile(filePath);
      await Share.shareXFiles(
        [file],
        subject: subject ?? 'Moodle課題データ',
      );
      logSuccess('ファイル共有完了: $filePath');
    } catch (e) {
      logError('ファイル共有エラー', error: e);
    }
  }
  
  /// 優先度の数値を文字列に変換するヘルパーメソッド
  String _getPriorityText(int priority) {
    switch (priority) {
      case 1:
        return '低';
      case 2:
        return '中';
      case 3:
        return '高';
      default:
        return '中';
    }
  }
  
  /// ストレージ権限をリクエストするメソッド
  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }
}

/// エクスポート形式の列挙型
enum ExportFormat {
  csv,
  json,
  pdf,
}

/// エクスポート結果を表すクラス
class ExportResult {
  final bool success;
  final String? filePath;
  final String? errorMessage;
  
  ExportResult({
    required this.success,
    this.filePath,
    this.errorMessage,
  });
}