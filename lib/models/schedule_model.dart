import 'package:flutter/material.dart';

/// 曜日を表す列挙型
enum Weekday {
  monday('月曜日', 'Mon'),
  tuesday('火曜日', 'Tue'),
  wednesday('水曜日', 'Wed'),
  thursday('木曜日', 'Thu'),
  friday('金曜日', 'Fri'),
  saturday('土曜日', 'Sat'),
  sunday('日曜日', 'Sun');

  const Weekday(this.fullName, this.shortName);
  final String fullName;
  final String shortName;
}

/// 時限を表すクラス
class Period {
  final int number;
  final String startTime;
  final String endTime;

  const Period({
    required this.number,
    required this.startTime,
    required this.endTime,
  });

  @override
  String toString() => '$number限 ($startTime-$endTime)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Period &&
          runtimeType == other.runtimeType &&
          number == other.number &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode => number.hashCode ^ startTime.hashCode ^ endTime.hashCode;
}

/// 科目を表すクラス
class Subject {
  final String id;
  final String name;
  final String teacher;
  final String classroom;
  final Color color;
  final String? description;

  Subject({
    required this.id,
    required this.name,
    required this.teacher,
    required this.classroom,
    required this.color,
    this.description,
  });

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      teacher: map['teacher'] ?? '',
      classroom: map['classroom'] ?? '',
      color: Color(map['color'] ?? 0xFF2196F3), // Colors.blue equivalent
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'teacher': teacher,
      'classroom': classroom,
      'color': color.value,
      'description': description,
    };
  }

  Subject copyWith({
    String? id,
    String? name,
    String? teacher,
    String? classroom,
    Color? color,
    String? description,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      classroom: classroom ?? this.classroom,
      color: color ?? this.color,
      description: description ?? this.description,
    );
  }
}

/// 時間割のコマを表すクラス
class ScheduleSlot {
  final String id;
  final Weekday weekday;
  final Period period;
  final Subject? subject;

  ScheduleSlot({
    required this.id,
    required this.weekday,
    required this.period,
    this.subject,
  });

  factory ScheduleSlot.fromMap(Map<String, dynamic> map) {
    return ScheduleSlot(
      id: map['id'] ?? '',
      weekday: Weekday.values.firstWhere(
        (w) => w.name == map['weekday'],
        orElse: () => Weekday.monday,
      ),
      period: Period(
        number: map['period_number'] ?? 1,
        startTime: map['period_start'] ?? '09:00',
        endTime: map['period_end'] ?? '10:30',
      ),
      subject: map['subject'] != null ? Subject.fromMap(map['subject']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weekday': weekday.name,
      'period_number': period.number,
      'period_start': period.startTime,
      'period_end': period.endTime,
      'subject': subject?.toMap(),
    };
  }

  ScheduleSlot copyWith({
    String? id,
    Weekday? weekday,
    Period? period,
    Subject? subject,
  }) {
    return ScheduleSlot(
      id: id ?? this.id,
      weekday: weekday ?? this.weekday,
      period: period ?? this.period,
      subject: subject ?? this.subject,
    );
  }

  bool get isEmpty => subject == null;
  bool get isNotEmpty => subject != null;
}

/// デフォルトの時間割設定
class DefaultScheduleConfig {
  static const List<Period> defaultPeriods = [
    Period(number: 1, startTime: '09:00', endTime: '10:30'),
    Period(number: 2, startTime: '10:40', endTime: '12:10'),
    Period(number: 3, startTime: '13:00', endTime: '14:30'),
    Period(number: 4, startTime: '14:40', endTime: '16:10'),
    Period(number: 5, startTime: '16:20', endTime: '17:50'),
    Period(number: 6, startTime: '18:00', endTime: '19:30'),
  ];

  static const List<Weekday> weekdays = [
    Weekday.monday,
    Weekday.tuesday,
    Weekday.wednesday,
    Weekday.thursday,
    Weekday.friday,
  ];

  static List<Color> get subjectColors => [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.brown,
    Colors.cyan,
  ];
}