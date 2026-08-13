# Puzzlio

Android / iOS 向けのパズルゲームアグリゲーターアプリです。Flutter 製で、複数の定番パズルゲームを1つのアプリにまとめて遊べます。

## 収録ゲーム

- **2048** — タイルをスワイプして数字を合成する
- **スライドパズル (15パズル)** — 4x4のピースを並べ替える
- **数独 (ナンプレ)** — 難易度（かんたん/ふつう/むずかしい）を選んで遊べる、自動生成パズル

各ゲームはローカルにベストスコア/ベストタイムを保存します（`shared_preferences`）。

## セットアップ

[Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel) が必要です。

```bash
flutter pub get
flutter run          # 接続中のデバイス/エミュレータで起動
flutter test         # ユニット・ウィジェットテスト
flutter analyze       # 静的解析
```

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

（iOS ビルドには macOS + Xcode が必要です）

## プロジェクト構成

```
lib/
  app.dart                 # MaterialApp / テーマ
  main.dart                 # エントリポイント
  models/puzzle_game.dart   # ホーム画面用ゲームメタ情報
  services/score_service.dart # ベストスコア/タイムの永続化
  screens/home_screen.dart  # ゲーム一覧
  games/
    game_2048/
    sliding_puzzle/
    sudoku/
```

新しいパズルゲームを追加する場合は `lib/games/` に新しいディレクトリを作り、
`lib/screens/home_screen.dart` の `games` リストに `PuzzleGame` エントリを追加してください。
