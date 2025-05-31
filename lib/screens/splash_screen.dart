import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/webview_service_new.dart';
import '../utils/logger.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';

/// スプラッシュ画面兼バックグラウンドログイン処理画面
/// アプリ起動時に自動ログインを試行し、適切な画面に遷移する
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const String _tag = 'SplashScreen';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String _statusText = 'アプリを起動中...';
  bool _showProgressIndicator = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _performStartupSequence();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// アニメーションを初期化
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  /// 起動時の処理シーケンス
  Future<void> _performStartupSequence() async {
    try {
      AppLogger.info('Starting app initialization', tag: _tag);

      // 最小限のスプラッシュ表示時間を確保
      await Future.delayed(const Duration(milliseconds: 1000));

      // 認証情報を確認
      final authState = ref.read(authProvider);

      // 既にログイン済みの場合はメイン画面に直接遷移
      if (authState.isLoggedIn) {
        AppLogger.info(
          'User already logged in, navigating to main screen',
          tag: _tag,
        );
        setState(() {
          _statusText = '既にログイン済みです';
          _showProgressIndicator = false;
        });
        await Future.delayed(const Duration(milliseconds: 800));
        await _navigateToMain();
        return;
      }

      if (authState.isAutoLoginEnabled &&
          authState.username != null &&
          authState.password != null &&
          authState.moodleUrl != null) {
        AppLogger.info(
          'Auto login is enabled, attempting background login',
          tag: _tag,
        );
        await _attemptBackgroundLogin();
      } else {
        AppLogger.info(
          'Auto login is disabled or credentials missing, navigating to login screen',
          tag: _tag,
        );
        await _navigateToLogin();
      }
    } catch (e) {
      AppLogger.error('Error during startup sequence: $e', tag: _tag);
      await _navigateToLogin();
    }
  }

  /// バックグラウンドログインを試行
  Future<void> _attemptBackgroundLogin() async {
    setState(() {
      _statusText = 'Moodleにログイン中...';
    });

    try {
      final authState = ref.read(authProvider);
      final webViewService = WebViewService();

      AppLogger.info(
        'Attempting auto login with stored credentials',
        tag: _tag,
      );

      // タイムアウト付きでバックグラウンドログインを試行（30秒でタイムアウト）
      final success = await Future.any([
        webViewService.attemptAutoLogin(
          authState.moodleUrl!,
          authState.username!,
          authState.password!,
        ),
        Future.delayed(const Duration(seconds: 30), () => false),
      ]);

      if (success) {
        AppLogger.info('Background login successful', tag: _tag);
        ref.read(authProvider.notifier).setLoggedIn(true);

        setState(() {
          _statusText = 'ログイン成功！';
          _showProgressIndicator = false;
        });

        // 少し待ってからメイン画面に遷移
        await Future.delayed(const Duration(milliseconds: 800));
        await _navigateToMain();
      } else {
        AppLogger.warning('Background login failed or timed out', tag: _tag);
        setState(() {
          _statusText = 'ログインに失敗しました';
          _showProgressIndicator = false;
        });
        await Future.delayed(const Duration(milliseconds: 1000));
        await _navigateToLogin();
      }
    } catch (e) {
      AppLogger.error('Background login error: $e', tag: _tag);
      setState(() {
        _statusText = 'エラーが発生しました';
        _showProgressIndicator = false;
      });
      await Future.delayed(const Duration(milliseconds: 1000));
      await _navigateToLogin();
    }
  }

  /// ログイン画面に遷移
  Future<void> _navigateToLogin() async {
    setState(() {
      _statusText = 'ログイン画面に移動中...';
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  /// メイン画面に遷移
  Future<void> _navigateToMain() async {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // アプリアイコン
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.school,
                          size: 60,
                          color: theme.colorScheme.primary,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // アプリ名
                      Text(
                        'Moodle Schedule',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),

                      const SizedBox(height: 60),

                      // プログレスインジケーター
                      if (_showProgressIndicator)
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 3,
                          ),
                        )
                      else
                        Icon(Icons.check_circle, size: 40, color: Colors.white),

                      const SizedBox(height: 20),

                      // ステータステキスト
                      Text(
                        _statusText,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
