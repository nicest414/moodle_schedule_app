import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/assignments_provider.dart';
import '../services/export_service.dart';
import '../utils/logger.dart';

/// データエクスポート画面
/// 課題データをCSV、JSON形式でエクスポートする機能を提供
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> with LoggerMixin {
  final ExportService _exportService = ExportService();
  bool _isExporting = false;
  String? _lastExportedFilePath;
  ExportFormat _selectedFormat = ExportFormat.csv;
  bool _includeCompletedTasks = true;
  bool _includeDescriptions = false;

  @override
  Widget build(BuildContext context) {
    final assignments = ref.watch(assignmentsProvider);
    final filteredAssignments = _includeCompletedTasks 
        ? assignments 
        : assignments.where((a) => !a.isCompleted).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('データエクスポート'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 説明セクション
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'データエクスポート',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '課題データを外部ファイルとしてエクスポートします。'
                      'エクスポートしたデータは他のアプリで開いたり、バックアップとして保存できます。',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'エクスポート可能な課題数: ${filteredAssignments.length}件',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // エクスポート形式選択
            const Text(
              'エクスポート形式',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  RadioListTile<ExportFormat>(
                    title: const Text('CSV形式'),
                    subtitle: const Text('Excel、Googleスプレッドシートなどで開けます'),
                    value: ExportFormat.csv,
                    groupValue: _selectedFormat,
                    onChanged: (value) {
                      setState(() {
                        _selectedFormat = value!;
                      });
                    },
                  ),
                  RadioListTile<ExportFormat>(
                    title: const Text('JSON形式'),
                    subtitle: const Text('プログラムでの処理に適したデータ形式'),
                    value: ExportFormat.json,
                    groupValue: _selectedFormat,
                    onChanged: (value) {
                      setState(() {
                        _selectedFormat = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // エクスポートオプション
            const Text(
              'エクスポートオプション',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('完了した課題を含める'),
                    subtitle: Text(
                      '完了済み課題数: ${assignments.where((a) => a.isCompleted).length}件'
                    ),
                    value: _includeCompletedTasks,
                    onChanged: (value) {
                      setState(() {
                        _includeCompletedTasks = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('課題の説明を含める'),
                    subtitle: const Text('CSVの場合、説明文が長いと表示が崩れる可能性があります'),
                    value: _includeDescriptions,
                    onChanged: (value) {
                      setState(() {
                        _includeDescriptions = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // エクスポートボタン
            if (_isExporting)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: filteredAssignments.isEmpty 
                      ? null 
                      : () => _exportData(filteredAssignments),
                  icon: const Icon(Icons.download),
                  label: Text(
                    '${_selectedFormat == ExportFormat.csv ? 'CSV' : 'JSON'}形式でエクスポート'
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
            // 共有ボタン（エクスポート後に表示）
            if (_lastExportedFilePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _shareExportedFile(),
                    icon: const Icon(Icons.share),
                    label: const Text('エクスポートしたファイルを共有'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// データをエクスポートする
  Future<void> _exportData(List<Assignment> assignments) async {
    setState(() {
      _isExporting = true;
    });

    try {
      // ストレージ権限のリクエスト
      final hasPermission = await _exportService.requestStoragePermission();
      if (!hasPermission) {
        _showErrorSnackBar('ストレージへのアクセス権限がありません');
        setState(() {
          _isExporting = false;
        });
        return;
      }

      String? filePath;
      
      // 選択されたフォーマットに応じてエクスポート
      if (_selectedFormat == ExportFormat.csv) {
        filePath = await _exportService.exportToCSV(
          assignments, 
          includeDescriptions: _includeDescriptions
        );
      } else {
        filePath = await _exportService.exportToJSON(
          assignments,
          includeDescriptions: _includeDescriptions
        );
      }

      if (filePath != null) {
        setState(() {
          _lastExportedFilePath = filePath;
        });
        _showSuccessSnackBar('エクスポートが完了しました');
      } else {
        _showErrorSnackBar('エクスポートに失敗しました');
      }
    } catch (e) {
      logError('エクスポートエラー', error: e);
      _showErrorSnackBar('エクスポート中にエラーが発生しました: $e');
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  /// エクスポートしたファイルを共有する
  Future<void> _shareExportedFile() async {
    if (_lastExportedFilePath == null) return;
    
    try {
      final format = _selectedFormat == ExportFormat.csv ? 'CSV' : 'JSON';
      await _exportService.shareFile(
        _lastExportedFilePath!,
        subject: 'わせジュール課題データ ($format)',
      );
    } catch (e) {
      logError('ファイル共有エラー', error: e);
      _showErrorSnackBar('ファイルの共有に失敗しました');
    }
  }

  /// 成功メッセージを表示
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// エラーメッセージを表示
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}