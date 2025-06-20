import 'package:flutter/material.dart';
import '../models/schedule_model.dart';

/// 科目編集フォームウィジェット
class SubjectFormWidget extends StatefulWidget {
  final ScheduleSlot? slot;
  final ScrollController scrollController;
  final Function(String slotId, Subject? subject) onSave;
  final VoidCallback? onDelete;

  const SubjectFormWidget({
    super.key,
    required this.slot,
    required this.scrollController,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<SubjectFormWidget> createState() => _SubjectFormWidgetState();
}

class _SubjectFormWidgetState extends State<SubjectFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _teacherController;
  late TextEditingController _classroomController;
  late TextEditingController _descriptionController;
  
  Weekday? _selectedWeekday;
  Period? _selectedPeriod;
  Color _selectedColor = Colors.blue;
  
  bool get _isEditing => widget.slot?.subject != null;

  @override
  void initState() {
    super.initState();
    
    final subject = widget.slot?.subject;
    _nameController = TextEditingController(text: subject?.name ?? '');
    _teacherController = TextEditingController(text: subject?.teacher ?? '');
    _classroomController = TextEditingController(text: subject?.classroom ?? '');
    _descriptionController = TextEditingController(text: subject?.description ?? '');
    
    _selectedWeekday = widget.slot?.weekday;
    _selectedPeriod = widget.slot?.period;
    _selectedColor = subject?.color ?? Colors.blue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    _classroomController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          controller: widget.scrollController,
          children: [
            // ドラッグハンドル
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // タイトル
            Text(
              _isEditing ? '科目を編集' : '科目を追加',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 24),
            
            // 科目名
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '科目名 *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '科目名を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // 担当教員
            TextFormField(
              controller: _teacherController,
              decoration: const InputDecoration(
                labelText: '担当教員',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            
            // 教室
            TextFormField(
              controller: _classroomController,
              decoration: const InputDecoration(
                labelText: '教室',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            
            // 曜日・時限選択
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Weekday>(
                    value: _selectedWeekday,
                    decoration: const InputDecoration(
                      labelText: '曜日 *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    items: DefaultScheduleConfig.weekdays.map((weekday) {
                      return DropdownMenuItem(
                        value: weekday,
                        child: Text(weekday.fullName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedWeekday = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return '曜日を選択してください';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<Period>(
                    value: _selectedPeriod,
                    decoration: const InputDecoration(
                      labelText: '時限 *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    items: DefaultScheduleConfig.defaultPeriods.map((period) {
                      return DropdownMenuItem(
                        value: period,
                        child: Text('${period.number}限'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriod = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return '時限を選択してください';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 色選択
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'カラー',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DefaultScheduleConfig.subjectColors.map((color) {
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 説明
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '説明・メモ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            
            // ボタン
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveSubject,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_isEditing ? '更新' : '保存'),
                  ),
                ),
                
                if (widget.onDelete != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        _showDeleteConfirmDialog();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('削除'),
                    ),
                  ),
                ],
                
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('キャンセル'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _saveSubject() {
    if (_formKey.currentState?.validate() ?? false) {
      final subject = Subject(
        id: widget.slot?.subject?.id ?? 
            '${_selectedWeekday!.name}_${_selectedPeriod!.number}_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        teacher: _teacherController.text.trim(),
        classroom: _classroomController.text.trim(),
        color: _selectedColor,
        description: _descriptionController.text.trim(),
      );
      
      final slotId = '${_selectedWeekday!.name}_${_selectedPeriod!.number}';
      widget.onSave(slotId, subject);
    }
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 確認'),
        content: Text('「${_nameController.text}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}