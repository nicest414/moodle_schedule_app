import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';

/// メインのナビゲーション画面
/// ボトムナビゲーションバーで画面を切り替える
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  // 現在選択されているタブのインデックス
  int currentIndex = 0;

  // 各タブに対応する画面のリスト
  static const List<Widget> screens = [
    HomeScreen(),      // 課題一覧
    CalendarScreen(),  // カレンダー表示
    SettingsScreen(),  // 設定画面
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            activeIcon: Icon(Icons.assignment),
            label: '課題一覧',
            tooltip: '課題をリスト表示',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            activeIcon: Icon(Icons.calendar_month),
            label: 'カレンダー',
            tooltip: '課題をカレンダー表示',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            activeIcon: Icon(Icons.settings),
            label: '設定',
            tooltip: 'アプリの設定',
          ),
        ],
      ),
    );
  }
}
