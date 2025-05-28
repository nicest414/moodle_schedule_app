import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../providers/auth_provider.dart';
import 'main_navigation_screen.dart'; // メインナビゲーション画面
import '../providers/assignments_provider.dart';
import '../utils/logger.dart';

// Moodleにログインするための画面
// WebViewを使って学校のログインページを表示し、認証状態を管理
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with LoggerMixin {
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
        children: [          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri.uri(Uri.parse(moodleLoginUrl))),
            // WebView設定を強化
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              databaseEnabled: true,
              clearCache: false, // キャッシュを保持してパフォーマンス向上
              cacheEnabled: true,
              // レンダリング設定
              useWideViewPort: true,
              loadWithOverviewMode: true,
              // セキュリティ設定
              allowsInlineMediaPlayback: true,
              allowsAirPlayForMediaPlayback: false,
              // クラッシュ防止設定
              disableDefaultErrorPage: true,
              supportMultipleWindows: false,
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            // SSL証明書エラーを無視する設定
            onReceivedServerTrustAuthRequest: (controller, challenge) async {
              return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
            },            // HTTPエラーも処理
            onReceivedHttpError: (controller, request, errorResponse) {
              logError("HTTPエラー: ${errorResponse.statusCode} - ${errorResponse.reasonPhrase}");
              // null安全なステータスコードチェック
              final statusCode = errorResponse.statusCode;
              if (statusCode != null && statusCode >= 500) {
                setState(() {
                  hasError = true;
                  errorMessage = "サーバーエラーが発生しました ($statusCode)";
                  isLoading = false;
                });
              }
            },            // エラーページが表示されたときのハンドリング
            onReceivedError: (controller, request, error) {
              logError("WebViewエラー: ${error.description}");
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
                hasError = false; // エラー状態をリセット
              });
            },            // ページ読み込み完了時のハンドリング
            onLoadStop: (controller, url) async {
              setState(() {
                isLoading = false;
              });
              
              // ログイン成功後のリダイレクトURLを確認
              if (url.toString().contains('/my/')) {
                try {
                  // ログイン成功とみなして状態を更新
                  ref.read(authProvider.notifier).state = true;

                  // ログイン成功時のスナックバー表示
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ログイン成功！課題データを取得中... '),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                  
                  // JavaScript を実行して課題データを取得
                  await _fetchAssignmentData(controller);
                  
                  // データ取得の完了を待つ（タイムアウト付き）
                  bool dataFetched = false;
                  int attempts = 0;
                  const maxAttempts = 10; // 最大10回チェック（5秒間）
                  
                  while (!dataFetched && attempts < maxAttempts && mounted) {
                    await Future.delayed(const Duration(milliseconds: 500));
                    final assignments = ref.read(assignmentsProvider);
                    
                    if (assignments.isNotEmpty) {
                      dataFetched = true;
                      break;
                    }
                    attempts++;
                  }
                    // 画面遷移を実行
                  if (mounted) {
                    final assignments = ref.read(assignmentsProvider);
                    
                    // データがあるかどうかに関わらずメインナビゲーション画面に遷移
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                    );
                    
                    // データが取得できなかった場合の追加メッセージ
                    if (assignments.isEmpty && attempts >= maxAttempts) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('課題データの取得に時間がかかっています... 📝'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      });
                    }
                  }                  
                } catch (e) {
                  logError('ログイン後処理エラー: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('処理中にエラーが発生: $e 😞'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
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
            logInfo('課題データ受信: ${args[0]}');
            
            // 課題データをプロバイダに保存したり、別画面に渡したり
            // ここで取得データの処理を行う
            _processAssignmentData(args[0]);
          }
          return true;
        }
      );      // 少し待ってからJavaScript実行（ページが完全に読み込まれるまで）
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // JavaScript コードを注入して実行
      await controller.evaluateJavascript(source: '''
        // 課題データを取得する非同期関数（エラーハンドリング強化版）
        // MoodleのAPIを使って今後の課題イベントを安全に取得
        async function fetchAssignmentData() {
          try {
            console.log('🔍 Moodle環境チェック開始...');
            
            // Moodleオブジェクトの存在確認
            if (typeof M === 'undefined' || !M.cfg) {
              console.warn('⚠️ Moodleオブジェクトが見つからない');
              window.flutter_inappwebview.callHandler('assignmentDataHandler', { 
                error: 'Moodleが完全に読み込まれていません。少し待ってからリトライしてください。' 
              });
              return;
            }
            
            // セッションキーの確認
            const sesskey = M.cfg.sesskey;
            if (!sesskey) {
              console.warn('⚠️ セッションキーが見つからない');
              window.flutter_inappwebview.callHandler('assignmentDataHandler', { 
                error: 'ログインセッションが無効です。再ログインしてください。' 
              });
              return;
            }
            
            console.log('✅ セッションキー確認完了');
            
            // より安全なfetch呼び出し（タイムアウト付き）
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 10000); // 10秒タイムアウト
            
            const apiUrl = window.location.origin + "/lib/ajax/service.php?sesskey=" + sesskey + "&info=core_calendar_get_action_events_by_timesort";
            console.log('🌐 API呼び出し先:', apiUrl);
            
            const response = await fetch(apiUrl, {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                "X-Requested-With": "XMLHttpRequest" // AJAX リクエストであることを明示
              },
              body: JSON.stringify([{
                "index": 0,
                "methodname": "core_calendar_get_action_events_by_timesort",
                "args": {
                  "limitnum": 30, // 適度な数に調整
                  "timesortfrom": Math.floor(Date.now() / 1000) // 現在時刻以降の課題のみ
                }
              }]),
              signal: controller.signal // タイムアウト制御
            });
            
            clearTimeout(timeoutId); // タイムアウトをクリア
            
            console.log('📡 レスポンス受信:', response.status, response.statusText);
            
            if (!response.ok) {
              throw new Error('HTTP ' + response.status + ': ' + response.statusText);
            }
            
            // レスポンスをJSONに変換
            const data = await response.json();
            console.log('📊 レスポンスデータ:', data);
            
            // データの構造を確認
            if (data && Array.isArray(data) && data[0] && data[0].data && data[0].data.events) {
              const events = data[0].data.events;
              console.log('📝 イベント数:', events.length);
              
              // 課題データをFlutter側で使いやすい形式にフォーマット
              const formattedEvents = events.map((ev, index) => ({
                id: (ev.id || ev.name?.replace(/[^a-zA-Z0-9]/g, '') || 'unknown_' + index).toString(),
                name: ev.name || '名称不明',
                startTime: new Date(ev.timesort * 1000).toLocaleString('ja-JP', {
                  year: 'numeric',
                  month: '2-digit',
                  day: '2-digit',
                  hour: '2-digit',
                  minute: '2-digit'
                }),
                course: ev.course?.fullname || ev.course?.shortname || '不明なコース',
                moduleName: ev.modulename || 'その他',
                url: ev.url || '',
                description: (ev.description || '説明なし').replace(/<[^>]*>/g, ''), // HTMLタグを除去
                timeSort: ev.timesort,
                isCompleted: false,
                priority: 2
              }));
              
              // Flutter側にデータを送信
              window.flutter_inappwebview.callHandler('assignmentDataHandler', { 
                events: formattedEvents,
                totalCount: formattedEvents.length,
                fetchTime: new Date().toISOString(),
                success: true
              });
              
              console.log('✅ 課題データ送信完了:', formattedEvents.length + '件');
              
            } else if (data && Array.isArray(data) && data[0] && data[0].data && Array.isArray(data[0].data.events) && data[0].data.events.length === 0) {
              // データは正常だが課題が0件の場合
              console.log('📭 課題データなし');
              window.flutter_inappwebview.callHandler('assignmentDataHandler', { 
                events: [],
                totalCount: 0,
                message: '現在表示する課題はありません',
                success: true
              });
            } else {
              // データの形式が想定と異なる場合
              console.error('❌ 予期しないデータ形式:', data);
              window.flutter_inappwebview.callHandler('assignmentDataHandler', { 
                error: 'APIからのデータ形式が予期しないものでした' 
              });
            }
          } catch (error) {
            // 通信エラーやJavaScriptエラーをキャッチ
            console.error('❌ 課題データ取得エラー:', error);
            let errorMessage = 'エラーが発生しました';
            
            if (error.name === 'AbortError') {
              errorMessage = 'リクエストがタイムアウトしました';
            } else if (error.message.includes('fetch')) {
              errorMessage = 'ネットワーク接続に問題があります';
            } else {
              errorMessage = error.message || error.toString();
            }
            
            window.flutter_inappwebview.callHandler('assignmentDataHandler', { 
              error: errorMessage
            });
          }
        }
        
        // メイン処理を実行（少し待ってから）
        console.log('🚀 課題データ取得を開始...');
        setTimeout(fetchAssignmentData, 1000); // 1秒待ってから実行
      ''');    } catch (e) {
      logError('JavaScript実行エラー: $e');
      // エラーハンドリング - JavaScript実行に失敗した場合
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('課題データの取得に失敗: $e 😞'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'リトライ',
              textColor: Colors.white,
              onPressed: () => _fetchAssignmentData(controller),
            ),
          ),
        );
      }
    }
  }  // 取得した課題データを処理するメソッド
  // 引数: Moodleから取得した生データ
  // 戻り値: なし（プロバイダーの状態を更新）
  void _processAssignmentData(dynamic data) {
    if (!mounted) return; // ウィジェットが破棄されている場合は処理しない
      if (data is Map && data.containsKey('error')) {
      // エラーハンドリング - MoodleのAPIエラーや通信エラーを表示
      logError('エラー発生: ${data['error']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('データ取得エラー: ${data['error']} 😫'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'リトライ',
            textColor: Colors.white,
            onPressed: () => _fetchAssignmentData(webViewController),
          ),
        ),
      );
      return;
    }
      if (data is Map && data.containsKey('events') && data['events'] is List) {
      final events = data['events'] as List;
      logSuccess('取得した課題数: ${events.length}');
      
      // データの形式を確認してからプロバイダーに保存
      try {
        if (events.isEmpty) {
          // 課題が0件の場合
          ref.read(assignmentsProvider.notifier).setAssignments([]);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('現在期限の近い課題はありません 📝'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        
        // 各課題データを安全に変換
        final formattedEvents = events.asMap().entries.map((entry) {
          final index = entry.key;
          final event = entry.value;
          
          final eventMap = Map<String, dynamic>.from(event is Map ? event : {});
          
          // 安全なID生成
          String safeId;
          if (eventMap['id'] != null) {
            safeId = eventMap['id'].toString();
          } else if (eventMap['name'] != null) {
            safeId = eventMap['name'].toString().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
            if (safeId.isEmpty) safeId = 'assignment_$index';
          } else {
            safeId = 'assignment_$index';
          }
          
          eventMap['id'] = safeId;
          return eventMap;
        }).toList();
        
        // Riverpodプロバイダに保存
        ref.read(assignmentsProvider.notifier).setAssignments(formattedEvents);
        
        // 成功メッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('課題データを${events.length}件取得完了！🎯'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );          // デバッグ出力（最初の3件のみ）
        final displayCount = events.length > 3 ? 3 : events.length;
        logDebug('=== 課題データ詳細デバッグ ===');
        for (var i = 0; i < displayCount; i++) {
          logDebug('課題${i + 1}: ${events[i]['name']}');
          logDebug('  ⏰ 日時（生データ）: "${events[i]['startTime']}" (長さ: ${events[i]['startTime'].toString().length})');
          logDebug('  📖 コース: ${events[i]['course']}');
          logDebug('  🔑 ID: ${events[i]['id']}');
          
          // 日付文字列の詳細分析
          final dateStr = events[i]['startTime'].toString();
          logDebug('  📅 日付文字列分析:');
          logDebug('    - 文字列: "$dateStr"');
          logDebug('    - 文字数: ${dateStr.length}');
          logDebug('    - 含まれる文字: ${dateStr.split('').join(', ')}');
        }
        if (events.length > 3) {
          logDebug('... 他${events.length - 3}件');
        }
        logDebug('=== デバッグ終了 ===');        
      } catch (e) {
        logError('データ変換エラー: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('データの変換に失敗: $e 😱'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'リトライ',
              textColor: Colors.white,
              onPressed: () => _fetchAssignmentData(webViewController),
            ),
          ),
        );
      }    } else {
      logWarning('予期しないデータ形式: $data');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('課題データの形式が正しくありません 🤔'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'リトライ',
            textColor: Colors.white,
            onPressed: () => _fetchAssignmentData(webViewController),
          ),
        ),
      );
    }
  }
}
