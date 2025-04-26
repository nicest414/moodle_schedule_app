import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart'; // 課題一覧画面
import '../providers/assignments_provider.dart';

// Moodleにログインするための画面
// WebViewを使って学校のログインページを表示し、認証状態を管理
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late InAppWebViewController webViewController;
  final String moodleLoginUrl = 'https://moodle.cis.fukuoka-u.ac.jp/login/index.php';
  
  // ページ読み込み中かどうかを管理する状態
  bool isLoading = true;
  // エラーが発生したかどうかを管理する状態
  bool hasError = false;
  // エラーメッセージを保存する
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moodleログイン'),
        actions: [
          // リロードボタンを追加
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              webViewController.reload();
              setState(() {
                isLoading = true;
                hasError = false;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri.uri(Uri.parse(moodleLoginUrl))),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            // SSL証明書エラーを無視する設定
            onReceivedServerTrustAuthRequest: (controller, challenge) async {
              return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
            },
            // エラーページが表示されたときのハンドリング
            onReceivedError: (controller, request, error) {
              print("WebViewエラー: ${error.description}");
              setState(() {
                hasError = true;
                errorMessage = error.description;
                isLoading = false;
              });
            },
            // ページ読み込み開始時のハンドリング
            onLoadStart: (controller, url) {
              setState(() {
                isLoading = true;
              });
            },
            // ページ読み込み完了時のハンドリング
            onLoadStop: (controller, url) async {
              setState(() {
                isLoading = false;
              });
              
              // ログイン成功後のリダイレクトURLを確認
              if (url.toString().contains('/my/')) {
                // JavaScript を実行して課題データを取得
                await _fetchAssignmentData(controller);
                
                // ログイン成功時のスナックバー表示
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ログイン成功！🎉'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
                
                // ログイン成功とみなして状態を更新
                ref.read(authProvider.notifier).state = true;

                // 課題一覧画面に遷移
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              }
            },
          ),
          
          // ローディングインジケーター
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          
          // エラー表示
          if (hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    '接続エラー発生！😱',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      webViewController.reload();
                      setState(() {
                        hasError = false;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('リトライする'),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 課題データを取得する JavaScript を実行
  Future<void> _fetchAssignmentData(InAppWebViewController controller) async {
    try {
      // JavaScript 実行結果を受け取るためのコールバック登録
      controller.addJavaScriptHandler(
        handlerName: 'assignmentDataHandler',
        callback: (args) {
          if (args.isNotEmpty) {
            print('課題データ受信: ${args[0]}');
            
            // 課題データをプロバイダに保存したり、別画面に渡したり
            // ここで取得データの処理を行う
            _processAssignmentData(args[0]);
          }
          return true;
        }
      );

      // JavaScript コードを注入して実行
      await controller.evaluateJavascript(source: '''
        // 課題データを取得する関数
        async function fetchAssignmentData() {
          try {
            const sesskey = M.cfg.sesskey;
            if (!sesskey) {
              window.flutter_inappwebview.callHandler('assignmentDataHandler', { error: 'セッションキーが見つからない' });
              return;
            }
            
            const response = await fetch("/lib/ajax/service.php?sesskey=" + sesskey + "&info=core_calendar_get_action_events_by_timesort", {
              method: "POST",
              headers: {
                "Content-Type": "application/json"
              },
              body: JSON.stringify([{
                "index": 0,
                "methodname": "core_calendar_get_action_events_by_timesort",
                "args": {
                  "limitnum": 20,
                  "timesortfrom": Math.floor(Date.now() / 1000)
                }
              }])
            });
            
            const data = await response.json();
            if (data && data[0] && data[0].data && data[0].data.events) {
              // 課題データをFormatして返す
              const events = data[0].data.events;
              const formattedEvents = events.map(ev => ({
                name: ev.name,
                startTime: new Date(ev.timesort * 1000).toLocaleString(),
                course: ev.course?.fullname || '不明',
                moduleName: ev.modulename || '',
                url: ev.url || '',
                description: ev.description || ''
              }));
              
              // Flutter側にデータを送信
              window.flutter_inappwebview.callHandler('assignmentDataHandler', { events: formattedEvents });
            } else {
              window.flutter_inappwebview.callHandler('assignmentDataHandler', { error: 'データの形式が不正' });
            }
          } catch (error) {
            window.flutter_inappwebview.callHandler('assignmentDataHandler', { error: error.toString() });
          }
        }
        
        // 関数実行
        fetchAssignmentData();
      ''');
    } catch (e) {
      print('JavaScript実行エラー: $e');
      // エラーハンドリング
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('課題データの取得に失敗しました: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // 取得した課題データを処理するメソッド
  void _processAssignmentData(dynamic data) {
    if (data is Map && data.containsKey('error')) {
      // エラーハンドリング
      print('エラー発生: ${data['error']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('データ取得エラー: ${data['error']}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (data is Map && data.containsKey('events') && data['events'] is List) {
      final events = data['events'] as List;
      print('取得した課題数: ${events.length}');
      
      // Riverpodプロバイダに保存
      ref.read(assignmentsProvider.notifier).setAssignments(events);
      
      // デバッグ出力
      for (var i = 0; i < events.length; i++) {
        print('課題${i + 1}: ${events[i]['name']}');
        print('  開始: ${events[i]['startTime']}');
        print('  コース: ${events[i]['course']}');
      }
    }
  }
}
