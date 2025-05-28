
# 📚 Moodle Schedule App

福岡大学のMoodleと連携して課題管理を行うFlutterアプリです。WebViewを使用してMoodleからデータを取得し、使いやすいインターフェースで課題を管理できます。

## 主な機能

### 自動ログイン機能
- WebViewでMoodleログインページを表示
- ログイン成功を自動検知
- セッション管理による継続ログイン

### 課題管理機能
- **課題一覧表示**: 締切日順・優先度順でソート可能
- **完了状態管理**: チェックボックスで課題の完了を記録
- **優先度設定**: 高・中・低の3段階で優先度を設定
- **詳細表示**: 課題の詳細情報をボトムシートで表示

### カレンダー表示
- 月表示カレンダーで課題を視覚的に管理
- 日付別の課題一覧表示
- 課題がある日にマーカー表示

### 通知機能
- 締切前の自動通知（1〜48時間前で設定可能）
- プッシュ通知による課題リマインダー
- 完了した課題の通知自動キャンセル

### 設定機能
- **通知設定**: 通知のON/OFF、タイミング設定
- **表示設定**: ダークモード、完了課題表示、デフォルトソート
- **データ管理**: 課題データの更新、削除機能
- **統計情報**: 課題の完了状況を数値で表示

### UI/UX機能
- マテリアルデザイン3対応
- ダークモード完全対応
- 直感的なボトムナビゲーション
- レスポンシブデザイン

## 技術仕様

### 使用技術
- **フレームワーク**: Flutter 3.7+
- **状態管理**: Riverpod 2.4+
- **WebView**: flutter_inappwebview 6.1+
- **通知**: flutter_local_notifications 19.1+
- **カレンダー**: table_calendar 3.0+
- **HTTP通信**: http 1.2+

### アーキテクチャ
- **設計パターン**: MVVMパターン + Riverpod
- **データ取得方法**: WebView + JavaScript injection
- **状態管理**: StateNotifierProvider
- **ファイル構成**: Feature-based folder structure

## 📱 画面構成

```
├── ログイン画面 (login_screen.dart)
│   ├── Moodle WebView表示
│   ├── 自動ログイン検知
│   └── JavaScript課題データ取得
│
├── メインナビゲーション (main_navigation_screen.dart)
│   ├── 📋 課題一覧タブ
│   ├── 📅 カレンダータブ
│   └── ⚙️ 設定タブ
│
├── 課題一覧画面 (home_screen.dart)
│   ├── 課題リスト表示
│   ├── 完了チェック機能
│   ├── 優先度表示・変更
│   ├── ソート・フィルタ機能
│   └── 課題詳細ボトムシート
│
├── カレンダー画面 (calendar_screen.dart)
│   ├── 月間カレンダー表示
│   ├── 課題マーカー表示
│   ├── 日付選択機能
│   └── 選択日の課題一覧
│
└── 設定画面 (settings_screen.dart)
    ├── 通知設定
    ├── 表示設定
    ├── データ管理
    └── アプリ情報
```

## データフロー

### 課題データ取得フロー
1. **ログイン**: WebViewでMoodleにログイン
2. **セッション取得**: ログイン成功を検知してセッションキー取得
3. **API呼び出し**: JavaScriptでMoodle内部API呼び出し
4. **データ解析**: JSON形式の課題データを解析
5. **状態更新**: Riverpodプロバイダーに課題データを保存
6. **UI更新**: 各画面に課題データを表示

### 通知フロー
1. **設定確認**: 通知設定とタイミングを確認
2. **スケジュール**: 各課題の締切時間を計算
3. **通知登録**: flutter_local_notificationsでスケジュール登録
4. **自動送信**: 設定時刻に通知を自動送信
5. **完了処理**: 課題完了時に通知をキャンセル

## セットアップ手順

### 1. 環境準備
```bash
# Flutter SDKのインストール (3.7.0以上)
flutter --version

# プロジェクトの依存関係をインストール
flutter pub get
```

### 2. 設定ファイルの確認
```yaml
# pubspec.yaml の主要な依存関係
dependencies:
  flutter_riverpod: ^2.4.0
  flutter_inappwebview: ^6.1.5
  flutter_local_notifications: ^19.1.0
  table_calendar: ^3.0.9
  http: ^1.2.1
  intl: ^0.18.1
```

### 3. プラットフォーム固有の設定

#### Android設定
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

#### iOS設定
```xml
<!-- ios/Runner/Info.plist -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### 4. アプリのビルドと実行
```bash
# デバッグモードで実行
flutter run

# リリースビルド
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

## パフォーマンス

### 最適化項目
- **メモリ使用量**: Riverpodによる効率的な状態管理
- **通信効率**: 必要な時のみWebView通信
- **UI応答性**: 非同期処理によるスムーズな操作
- **バッテリー**: バックグラウンド処理の最小化

### パフォーマンス指標
- 起動時間: ~2-3秒
- 課題データ取得: ~1-2秒
- メモリ使用量: ~50-80MB
- APKサイズ: ~20-30MB

## 開発への貢献

### ブランチ戦略
- `main`: 安定版リリース
- `develop`: 開発版
- `feature/*`: 新機能開発
- `bugfix/*`: バグ修正

### コーディング規約
- Dart公式スタイルガイドに従う
- 関数型プログラミングパターンを優先
- クラスの使用は最小限に
- 説明的な変数名を使用（`isLoading`, `hasError`等）

## 今後の予定

### Phase 1 (短期) 
- [ ] ローカルデータの永続化 (shared_preferences)
- [ ] オフライン対応機能
- [ ] プッシュ通知の完全実装
- [ ] テストコードの追加

### Phase 2 (中期) 
- [ ] ウィジェット機能 (ホーム画面に課題表示)
- [ ] データエクスポート機能
- [ ] カスタムテーマ機能
- [ ] マルチアカウント対応

### Phase 3 (長期) 
- [ ] 他大学のMoodle対応
- [ ] AI による課題優先度自動判定
- [ ] 学習時間トラッキング
- [ ] グループ機能
- [ ] 食堂の込み具合ガイド

## サポート

### バグレポート
- GitHub Issues: 問題の詳細と再現手順を記載
- メール: 緊急度の高い問題の場合

### 機能要望
- GitHub Discussions: 新機能のアイデア
- フィードバック: 実際の使用感想

## ライセンス

このプロジェクトは MIT License の下で公開されています。詳細は [LICENSE](LICENSE) ファイルをご覧ください。

## 謝辞

- Flutter チーム: 素晴らしいフレームワークの提供
- Riverpod コミュニティ: 優れた状態管理ソリューション
- 福岡大学: 勝手に触ってます　ごめんなさい
- オープンソースコミュニティ: 各種パッケージの開発

---
