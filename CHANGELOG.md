# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0]

5年ぶりの更新。Xcode 26 / Swift 6 / iOS 15+ に対応し、ビルド基盤を刷新した。

### Added

- Swift Package Manager 対応（`Package.swift`）
- GitHub Actions による CI（テスト / Example ビルド / podspec lint / SwiftLint）
- ロジック層のユニットテスト（Swift Testing）
- UIScene 対応。マルチウィンドウ環境でも正しいウィンドウを対象にする

### Changed

- **BREAKING** 最低 iOS バージョンを 15.0 に引き上げ
- **BREAKING** `ViewMonitor` を `@MainActor` 分離に変更。`start()` / `stop()` はメインアクターから呼ぶ必要がある
- **BREAKING** Carthage のサポートを終了
- **BREAKING** `detectedViewDidAppear` を `internal` に降格
- Travis CI から GitHub Actions へ移行
- Example アプリをローカル SPM 参照で再構築し、SceneDelegate 対応に
- `ViewMonitor.swift` の責務を分割（310行 → 123行）

### Fixed

- 実行ボタンの画像が読み込まれず黒／赤の単色になっていた問題。`UIImage(named:)` に絶対パスを渡していたため常に nil を返していた
- `start()` → `stop()` → `start()` の順に呼ぶと画面遷移の検知が停止する問題。swizzling が2回入れ替わり実装が元に戻っていた
- `stop()` を呼んだあとも実行ボタンが画面に残り、タップすると計測オーバーレイが復活してしまう問題
- `InfoView` でラベルを選んだあとにフォントを持たないビューを選ぶと、前のフォント名が残り続けていた問題
- 背景色が `UIColor.black` / `UIColor.white` のビューで `background:None` と表示されていた問題。グレースケール色空間を扱えていなかった

### Removed

- Carthage 関連の記述
- 動作していなかった Travis CI 設定

## リリース手順

CocoaPods trunk への公開はリポジトリ所有者が手元で実行する。

```bash
git tag 2.0.0
git push origin 2.0.0
pod trunk push ViewMonitor.podspec --allow-warnings
```
