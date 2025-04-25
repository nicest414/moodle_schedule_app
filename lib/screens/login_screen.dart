import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../providers/auth_provider.dart';

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
}
