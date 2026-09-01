# Puzzlio

Android / iOS 向けのパズルゲームアグリゲーターアプリです。Flutter 製で、複数の定番パズルゲームを1つのアプリにまとめて遊べます。

## 収録ゲーム

- **2048** — タイルをスワイプして数字を合成する
- **スライドパズル (15パズル)** — 4x4のピースを並べ替える
- **数独 (ナンプレ)** — 難易度（かんたん/ふつう/むずかしい）を選んで遊べる、自動生成パズル
- **陣取りパズル** — 色エリアに1本ずつ、行・列にも1本ずつ、隣接不可で旗を配置するロジックパズル。クリアするとレベルが上がり盤面が広がる

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

## 署名付きリリースビルド (Android)

`android/key.properties` が存在しない場合、リリースビルドはデバッグ用の鍵で署名されます
（ローカルの `flutter run --release` や、シークレットにアクセスできない fork からの CI が
壊れないようにするためのフォールバックです）。Play Store 等に配布する場合は、以下の手順で
自分の upload key を用意してください。

### 1. keystore を作成する

```bash
keytool -genkeypair -v \
  -keystore upload-keystore.jks \
  -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10950 \
  -alias upload
```

**この keystore とパスワードは絶対に紛失・漏洩させないでください。** Play Store で一度公開した
アプリは、同じ keystore でしか更新できません（紛失すると同じアプリIDでの更新ができなくなります）。
リポジトリには絶対にコミットしないでください（`android/.gitignore` で既に除外されています）。

### 2. ローカルビルド用に設定する

`android/key.properties.example` を `android/key.properties` にコピーし、
`storeFile` が指す場所（既定では `android/app/upload-keystore.jks`）に keystore を置いて、
パスワード類を埋めてください。

### 3. CI (GitHub Actions) で署名する

リポジトリの **Settings → Secrets and variables → Actions** に、以下のシークレットを登録してください。

| シークレット名 | 値 |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` の出力 |
| `ANDROID_KEYSTORE_PASSWORD` | keystore のパスワード (`storePassword`) |
| `ANDROID_KEY_ALIAS` | 鍵のエイリアス（例: `upload`） |
| `ANDROID_KEY_PASSWORD` | 鍵のパスワード (`keyPassword`) |

これらが設定されていれば、`.github/workflows/ci.yml` の `build-apk` ジョブが自動的に
署名付き APK をビルドします（未設定の場合は自動的にデバッグ署名にフォールバックし、
ビルド自体は失敗しません）。fork からの pull request はシークレットにアクセスできないため、
常にデバッグ署名でビルドされます。

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
    territory/
```

新しいパズルゲームを追加する場合は `lib/games/` に新しいディレクトリを作り、
`lib/screens/home_screen.dart` の `games` リストに `PuzzleGame` エントリを追加してください。
