
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../utils/logger.dart';

/// WebViewでのJavaScript実行とMoodle操作を管理するサービスクラス
/// 実際のMoodleページ構造に基づいた自動ログイン機能を提供
class WebViewService {
  static const String _tag = 'WebViewService';
  
  InAppWebViewController? _webViewController;
  bool _isInitialized = false;

  /// WebViewControllerを初期化
  /// @param controller WebViewのコントローラー
  void initialize(InAppWebViewController controller) {
    _webViewController = controller;
    _isInitialized = true;
    AppLogger.info('WebViewService initialized', tag: _tag);
  }

  /// 初期化チェック
  bool get isInitialized => _isInitialized;

  /// ローディング画面を表示
  /// わせジュールのshow_loading_screen.jsを実行
  Future<void> showLoadingScreen() async {
    if (!_isInitialized) {
      AppLogger.error('WebView not initialized', tag: _tag);
      return;
    }

    try {
      const String script = '''
        // ローディング画面を作成する関数
        (function showLoadingScreen() {
          // 既存のローディング画面があれば削除
          const existingOverlay = document.querySelector(".loading-overlay");
          const existingScreen = document.querySelector(".loading-screen");
          if (existingOverlay) existingOverlay.remove();
          if (existingScreen) existingScreen.remove();

          // 薄暗い背景を作成
          const overlay = document.createElement("div");
          overlay.classList.add("loading-overlay");
          overlay.style.position = "fixed";
          overlay.style.top = "0";
          overlay.style.left = "0";
          overlay.style.width = "100%";
          overlay.style.height = "100%";
          overlay.style.backgroundColor = "rgba(0, 0, 0, 0.5)";
          overlay.style.zIndex = "999";
          overlay.style.overflow = "hidden";
          document.body.appendChild(overlay);

          // スクロールを無効にする
          document.documentElement.style.overflow = "hidden";
          document.body.style.overflow = "hidden";

          // ローディング画面を作成
          const loadingScreen = document.createElement("div");
          loadingScreen.classList.add("loading-screen");
          loadingScreen.textContent = "読み込み中...";
          loadingScreen.style.position = "fixed";
          loadingScreen.style.top = "50%";
          loadingScreen.style.left = "50%";
          loadingScreen.style.transform = "translate(-50%, -50%)";
          loadingScreen.style.backgroundColor = "#fff";
          loadingScreen.style.padding = "20px";
          loadingScreen.style.borderRadius = "10px";
          loadingScreen.style.boxShadow = "0 0 10px rgba(0, 0, 0, 0.5)";
          loadingScreen.style.zIndex = "1000";
          loadingScreen.style.fontFamily = "Arial, sans-serif";
          loadingScreen.style.fontSize = "16px";
          loadingScreen.style.color = "#333";
          document.body.appendChild(loadingScreen);
        })();
      ''';

      await _webViewController?.evaluateJavascript(source: script);
      AppLogger.info('Loading screen shown', tag: _tag);
    } catch (e) {
      AppLogger.error('Failed to show loading screen: $e', tag: _tag);
    }
  }

  /// ローディング画面を非表示
  /// わせジュールのhide_loading_screen.jsを実行
  Future<void> hideLoadingScreen() async {
    if (!_isInitialized) {
      AppLogger.error('WebView not initialized', tag: _tag);
      return;
    }

    try {
      const String script = '''
        // ローディング画面を削除する関数
        (function hideLoadingScreen() {
          const overlay = document.querySelector(".loading-overlay");
          const loadingScreen = document.querySelector(".loading-screen");
          if (overlay) {
            overlay.remove();
            // スクロールを有効にする
            document.documentElement.style.overflow = "";
            document.body.style.overflow = "";
          }
          if (loadingScreen) loadingScreen.remove();
        })();
      ''';

      await _webViewController?.evaluateJavascript(source: script);
      AppLogger.info('Loading screen hidden', tag: _tag);
    } catch (e) {
      AppLogger.error('Failed to hide loading screen: $e', tag: _tag);
    }
  }

  /// 自動ログインチェックボックスを追加
  /// 実際のMoodleページ構造に基づいた位置に配置
  Future<void> addAutoLoginCheckbox() async {
    if (!_isInitialized) {
      AppLogger.error('WebView not initialized', tag: _tag);
      return;
    }

    try {
      const String script = '''
        (function() {
          console.log('🔍 ページ構造調査開始...');
          console.log('現在のURL:', window.location.href);
          
          // 既存のチェックボックスがあれば削除
          const existingCheckbox = document.querySelector("#auto-login-checkbox");
          if (existingCheckbox) {
            existingCheckbox.parentElement.remove();
            console.log('✅ 既存チェックボックス削除');
          }

          // チェックボックス作成関数
          function makeCheckboxContainer() {
            const checkbox = document.createElement("input");
            checkbox.type = "checkbox";
            checkbox.id = "auto-login-checkbox";

            // チェック状態をローカルストレージから復元
            const isAutoLogin = localStorage.getItem('moodle_auto_login') === 'true';
            checkbox.checked = isAutoLogin;

            // チェックボックスの変更イベント
            checkbox.addEventListener("change", function() {
              localStorage.setItem('moodle_auto_login', checkbox.checked);
              if (checkbox.checked) {
                checkbox.style.accentColor = "#ff6600";
              } else {
                checkbox.style.accentColor = "";
              }
            });

            // 初期スタイル設定
            if (checkbox.checked) {
              checkbox.style.accentColor = "#ff6600";
            }

            // ラベルを作成
            const label = document.createElement("label");
            label.htmlFor = checkbox.id;
            label.textContent = "次回から自動ログインする";
            label.style.marginLeft = "0.5em";
            label.style.paddingTop = "0.6em";
            label.style.cursor = "pointer";

            // コンテナを作成
            const container = document.createElement("div");
            container.style.display = "flex";
            container.style.alignItems = "center";
            container.style.marginBottom = "1em";
            container.style.marginTop = "1em";
            container.style.paddingLeft = "0.5em";
            container.appendChild(checkbox);
            container.appendChild(label);
            return container;
          }

          // 実際のMoodleページに基づいた挿入場所を探す
          const candidates = [
            { selector: "input[name='password']", name: "パスワード入力", insertAfter: true },
            { selector: "input[name='username']", name: "ユーザー名入力", insertAfter: true },
            { selector: ".form-group", name: "フォームグループ" },
            { selector: ".loginbox", name: "ログインボックス" },
            { selector: ".login-form", name: "ログインフォーム" },
            { selector: ".col-md-6", name: "カラム要素" },
            { selector: "form", name: "フォーム要素" },
            { selector: "#region-main", name: "メインリージョン" }
          ];

          let inserted = false;
          
          // 各候補を順番に試す
          for (const candidate of candidates) {
            const element = document.querySelector(candidate.selector);
            if (element) {
              console.log('✅ 発見:', candidate.name, '(', candidate.selector, ')');
              
              try {
                const container = makeCheckboxContainer();
                
                if (candidate.insertAfter) {
                  // 入力フィールドの場合は親要素の後に挿入
                  const parent = element.closest('.form-group') || element.parentElement;
                  if (parent && parent.parentNode) {
                    parent.parentNode.insertBefore(container, parent.nextSibling);
                    inserted = true;
                    console.log('🎯 チェックボックス追加成功 (', candidate.name, 'の後)');
                    break;
                  }
                } else {
                  // コンテナの場合は内部に追加
                  element.appendChild(container);
                  inserted = true;
                  console.log('🎯 チェックボックス追加成功 (', candidate.name, ')');
                  break;
                }
              } catch (insertError) {
                console.warn('⚠️ 挿入失敗:', candidate.name, insertError);
              }
            } else {
              console.log('❌ 見つからず:', candidate.name, '(', candidate.selector, ')');
            }
          }
          
          if (!inserted) {
            console.warn('⚠️ 適切な挿入場所が見つかりませんでした');
            // 最後の手段：body の最初に追加
            const container = makeCheckboxContainer();
            container.style.position = 'fixed';
            container.style.top = '10px';
            container.style.left = '10px';
            container.style.backgroundColor = 'white';
            container.style.padding = '10px';
            container.style.border = '1px solid #ccc';
            container.style.borderRadius = '5px';
            container.style.zIndex = '9999';
            document.body.insertBefore(container, document.body.firstChild);
            console.log('🆘 フォールバック：body上部に固定表示');
          }
        })();
      ''';

      await _webViewController?.evaluateJavascript(source: script);
      AppLogger.info('Auto login checkbox added', tag: _tag);
    } catch (e) {
      AppLogger.error('Failed to add auto login checkbox: $e', tag: _tag);
    }
  }

  /// 自動ログイン実行（ユーザー名とパスワードを自動入力）
  /// 実際のMoodleログインページに合わせた直接認証
  Future<bool> performAutoLogin(String username, String password) async {
    if (!_isInitialized) {
      AppLogger.error('WebView not initialized', tag: _tag);
      return false;
    }

    try {
      final script = '''
        (function() {
          console.log('🚀 自動ログイン開始...');
          
          try {
            // ユーザー名フィールドを探す
            const usernameSelectors = [
              'input[name="username"]',
              'input[id="username"]',
              'input[type="text"]',
              'input[placeholder*="ユーザー"]',
              'input[placeholder*="User"]',
              'input[autocomplete="username"]'
            ];
            
            let usernameField = null;
            for (const selector of usernameSelectors) {
              usernameField = document.querySelector(selector);
              if (usernameField) {
                console.log('✅ ユーザー名フィールド発見:', selector);
                break;
              }
            }
            
            // パスワードフィールドを探す
            const passwordSelectors = [
              'input[name="password"]',
              'input[id="password"]',
              'input[type="password"]',
              'input[autocomplete="current-password"]'
            ];
            
            let passwordField = null;
            for (const selector of passwordSelectors) {
              passwordField = document.querySelector(selector);
              if (passwordField) {
                console.log('✅ パスワードフィールド発見:', selector);
                break;
              }
            }
            
            if (!usernameField || !passwordField) {
              console.log('❌ ログインフィールドが見つからない');
              console.log('現在のDOM:', document.body.innerHTML.substring(0, 1000));
              return false;
            }
            
            // 値を入力
            usernameField.value = '$username';
            passwordField.value = '$password';
            
            // イベント発火（フォームバリデーション用）
            usernameField.dispatchEvent(new Event('input', { bubbles: true }));
            usernameField.dispatchEvent(new Event('change', { bubbles: true }));
            passwordField.dispatchEvent(new Event('input', { bubbles: true }));
            passwordField.dispatchEvent(new Event('change', { bubbles: true }));
            
            console.log('✅ ログイン情報入力完了');
            
            // ログインボタンを探してクリック
            const loginButtonSelectors = [
              'button[type="submit"]',
              'input[type="submit"]',
              'button[id="loginbtn"]',
              '#loginbtn',
              '.btn-primary',
              'input[value*="ログイン"]',
              'button[name="submitbutton"]',
              'form input[type="submit"]'
            ];
            
            let loginButton = null;
            for (const selector of loginButtonSelectors) {
              loginButton = document.querySelector(selector);
              if (loginButton) {
                console.log('✅ ログインボタン発見:', selector);
                break;
              }
            }
            
            if (loginButton) {
              console.log('🎯 ログインボタンをクリック');
              loginButton.click();
              return true;
            } else {
              console.log('⚠️ ログインボタンが見つからない - Enterキーを送信');
              passwordField.focus();
              passwordField.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
              return true;
            }
            
          } catch (error) {
            console.log('❌ 自動ログインエラー:', error);
            return false;
          }
        })();
      ''';

      final result = await _webViewController?.evaluateJavascript(source: script);
      final success = result == true;
      
      if (success) {
        AppLogger.info('Auto login completed successfully', tag: _tag);
      } else {
        AppLogger.warning('Auto login failed', tag: _tag);
      }
      
      return success;
    } catch (e) {
      AppLogger.error('Auto login error: $e', tag: _tag);
      return false;
    }
  }

  /// ログイン状態をチェック
  Future<bool> checkLoginStatus() async {
    if (!_isInitialized) {
      AppLogger.error('WebView not initialized', tag: _tag);
      return false;
    }

    try {
      const String script = '''
        (function() {
          // ログイン後のページかどうかを判定
          const url = window.location.href;
          const isLoggedIn = 
            url.includes('/my/') || 
            url.includes('/course/') || 
            url.includes('/user/') ||
            document.querySelector('.usermenu') !== null ||
            document.querySelector('.navbar-nav .dropdown') !== null;
          
          console.log('🔍 ログイン状態チェック:', {
            url: url,
            isLoggedIn: isLoggedIn,
            hasUserMenu: document.querySelector('.usermenu') !== null
          });
          
          return isLoggedIn;
        })();
      ''';

      final result = await _webViewController?.evaluateJavascript(source: script);
      final isLoggedIn = result == true;
      
      AppLogger.info('Login status: $isLoggedIn', tag: _tag);
      return isLoggedIn;
    } catch (e) {
      AppLogger.error('Failed to check login status: $e', tag: _tag);
      return false;
    }
  }

  /// 課題データを取得
  /// わせジュールのfetch_assignments.jsから移植
  Future<List<Map<String, dynamic>>> fetchAssignments() async {
    if (!_isInitialized) {
      AppLogger.error('WebView not initialized', tag: _tag);
      return [];
    }

    try {
      const String script = '''
        (function() {
          console.log('📋 課題データ取得開始...');
          
          // ダッシュボードで課題リストを探す
          const assignmentSelectors = [
            '.block_timeline .event-item',
            '.dashboard-card .event-item',
            '.activity-item',
            '.course-event',
            '.timeline-event-list-item'
          ];
          
          let assignments = [];
          
          for (const selector of assignmentSelectors) {
            const elements = document.querySelectorAll(selector);
            console.log(\`🔍 セレクター "\${selector}" で \${elements.length}個の要素を発見\`);
            
            elements.forEach((element, index) => {
              try {
                const titleElement = element.querySelector('.event-name, .activity-name, h3, h4, a');
                const dateElement = element.querySelector('.event-time, .activity-date, .date, time');
                const courseElement = element.querySelector('.course-name, .event-course');
                
                if (titleElement) {
                  const assignment = {
                    id: index,
                    title: titleElement.textContent?.trim() || '',
                    course: courseElement?.textContent?.trim() || '',
                    dueDate: dateElement?.textContent?.trim() || '',
                    url: titleElement.href || '',
                    type: 'assignment'
                  };
                  
                  if (assignment.title) {
                    assignments.push(assignment);
                    console.log('📝 課題発見:', assignment.title);
                  }
                }
              } catch (error) {
                console.warn('⚠️ 課題データ解析エラー:', error);
              }
            });
            
            if (assignments.length > 0) break;
          }
          
          console.log(\`✅ 課題データ取得完了: \${assignments.length}件\`);
          return assignments;
        })();
      ''';

      final result = await _webViewController?.evaluateJavascript(source: script);
      
      if (result is List) {
        List<Map<String, dynamic>> assignments = [];
        for (var item in result) {
          if (item is Map) {
            assignments.add(Map<String, dynamic>.from(item));
          }
        }
        AppLogger.info('Fetched ${assignments.length} assignments', tag: _tag);
        return assignments;
      }
      
      AppLogger.warning('No assignments found', tag: _tag);
      return [];
    } catch (e) {
      AppLogger.error('Failed to fetch assignments: $e', tag: _tag);
      return [];
    }
  }
}
