import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// 認証情報を管理するクラス
/// ログイン状態、自動ログイン設定、認証情報の保存を担当
class AuthState {
  final bool isLoggedIn;
  final bool isAutoLoginEnabled;
  final String? username;
  final String? password; // <--- パスワード用のフィールドを追加
  final String? moodleUrl;

  const AuthState({
    this.isLoggedIn = false,
    this.isAutoLoginEnabled = false,
    this.username,
    this.password, // <--- コンストラクタに追加
    this.moodleUrl,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isAutoLoginEnabled,
    String? username,
    String? password, // <--- copyWith に追加
    String? moodleUrl,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isAutoLoginEnabled: isAutoLoginEnabled ?? this.isAutoLoginEnabled,
      username: username ?? this.username,
      password: password ?? this.password, // <--- copyWith に追加
      moodleUrl: moodleUrl ?? this.moodleUrl,
    );
  }
}

/// 認証状態を管理するNotifier
/// わせジュールの自動ログイン機能を参考に実装
class AuthNotifier extends StateNotifier<AuthState> {
  static const String _tag = 'AuthNotifier';
  static const String _keyAutoLogin = 'auto_login_enabled';
  static const String _keyUsername = 'username';
  static const String _keyPassword = 'password'; // <--- パスワード保存用のキーを追加
  static const String _keyMoodleUrl = 'moodle_url';

  AuthNotifier() : super(const AuthState()) {
    _loadSettings();
  }

  /// 設定をSharedPreferencesから読み込み
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAutoLoginEnabled = prefs.getBool(_keyAutoLogin) ?? false;
      final username = prefs.getString(_keyUsername);
      final password = prefs.getString(_keyPassword); // <--- パスワードを読み込む
      final moodleUrl = prefs.getString(_keyMoodleUrl);

      state = state.copyWith(
        isAutoLoginEnabled: isAutoLoginEnabled,
        username: username,
        password: password, // <--- state にパスワードを設定
        moodleUrl: moodleUrl,
      );

      AppLogger.info('Settings loaded - Auto login: $isAutoLoginEnabled, Username: $username, Moodle URL: $moodleUrl', tag: _tag); // パスワードはログに出力しない
    } catch (e) {
      AppLogger.error('Failed to load settings: $e', tag: _tag);
    }
  }

  /// ログイン状態を設定
  /// @param isLoggedIn ログイン状態
  void setLoggedIn(bool isLoggedIn) {
    state = state.copyWith(isLoggedIn: isLoggedIn);
    AppLogger.info('Login state changed: $isLoggedIn', tag: _tag);
  }

  /// 自動ログイン設定を変更
  /// @param enabled 自動ログインを有効にするかどうか
  Future<void> setAutoLoginEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAutoLogin, enabled);
      
      state = state.copyWith(isAutoLoginEnabled: enabled);
      AppLogger.info('Auto login setting changed: $enabled', tag: _tag);
    } catch (e) {
      AppLogger.error('Failed to save auto login setting: $e', tag: _tag);
    }
  }

  /// ユーザー名を保存
  /// @param username ユーザー名
  Future<void> setUsername(String? username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (username != null) {
        await prefs.setString(_keyUsername, username);
      } else {
        await prefs.remove(_keyUsername);
      }
      
      state = state.copyWith(username: username);
      AppLogger.info('Username saved', tag: _tag);
    } catch (e) {
      AppLogger.error('Failed to save username: $e', tag: _tag);
    }
  }

  /// パスワードを保存
  /// @param password パスワード
  Future<void> setPassword(String? password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (password != null) {
        await prefs.setString(_keyPassword, password);
      } else {
        await prefs.remove(_keyPassword);
      }
      
      state = state.copyWith(password: password); // state も更新
      AppLogger.info('Password saved', tag: _tag); // 実際のパスワードはログに出力しない
    } catch (e) {
      AppLogger.error('Failed to save password: $e', tag: _tag);
    }
  }

  /// Moodle URLを保存
  /// @param url MoodleのURL
  Future<void> setMoodleUrl(String? url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (url != null) {
        await prefs.setString(_keyMoodleUrl, url);
      } else {
        await prefs.remove(_keyMoodleUrl);
      }
      
      state = state.copyWith(moodleUrl: url);
      AppLogger.info('Moodle URL saved', tag: _tag);
    } catch (e) {
      AppLogger.error('Failed to save Moodle URL: $e', tag: _tag);
    }
  }

  /// ログアウト処理
  /// 自動ログイン設定は保持したまま、ログイン状態のみリセット
  void logout() {
    state = state.copyWith(isLoggedIn: false);
    AppLogger.info('User logged out', tag: _tag);
  }

  /// 全ての認証情報をクリア
  /// 自動ログイン設定も含めて全てリセット
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAutoLogin);
      await prefs.remove(_keyUsername);
      await prefs.remove(_keyPassword); // <--- パスワードのクリア処理を追加
      await prefs.remove(_keyMoodleUrl);
      
      state = const AuthState();
      AppLogger.info('All auth data cleared', tag: _tag);
    } catch (e) {
      AppLogger.error('Failed to clear auth data: $e', tag: _tag);
    }
  }
}

/// 認証状態を管理するProvider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
