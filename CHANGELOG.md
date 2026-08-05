# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- InfoView に選択中ビューのクラス名を表示（[#18](https://github.com/daisuke0131/ViewMonitor/issues/18)）
- InfoView に alpha / cornerRadius を表示（[#9](https://github.com/daisuke0131/ViewMonitor/issues/9)）
- UIButton のタイトルのフォント情報（font / fontSize / fontColor）を表示

### Changed

- InfoView の行を動的化。フォント行はテキストを持つビューでのみ表示し、高さは行数に応じて可変に
- 数値表示を小数第1位に丸め、整数になる値は `.0` を省略（例: `16.666666666666668` → `16.7`、`16.0` → `16`）
- 行の書式を `x:16.0` から `x: 16` に変更（コロン後にスペース）
- 計測対象のビューを取得できない場合は、前の計測値を表示し続けず全項目 `None` を表示する防御的挙動に

### Fixed

- 実行ボタンが固定座標 `y: 20.0` に配置されており、ノッチや Dynamic Island のある端末ではステータスバーや島の下に隠れてタップできなくなっていた問題。`x` 側も `safeAreaInsets.right` を無視していたため、横向きでノッチ側に同様の問題があった。座標計算を `safeAreaInsets` を考慮した `MonitorLauncherButton.origin(inBounds:safeAreaInsets:)` に切り出して解消（[#34](https://github.com/daisuke0131/ViewMonitor/issues/34)）

## [2.0.0] - 2026-08-05

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
- iPad のマルチシーン環境で、計測オーバーレイが付与されたウィンドウ以外がアクティブだと、`MonitorOverlay.select(sender:)` が誤ったウィンドウを基準に座標変換してしまい、InfoView に表示される計測値がすべて間違っていた問題。`WindowProvider.keyWindow` を都度引き直していたため
- ホストアプリが KVO で監視しているシステムビュー（`UITabBar` / `UINavigationBar` など）でも計測用オーバーレイが表示されていた問題。`ViewHierarchyScanner.className(of:)` が `type(of:)` で実行時クラスを取得していたため、KVO による動的なサブクラス化で `NSKVONotifying_UITabBar` のような合成クラスが返され、`rejectedClassNames` に一致しなかった

### Removed

- Carthage 関連の記述
- 動作していなかった Travis CI 設定

## リリース手順

CocoaPods trunk への公開はリポジトリ所有者が手元で実行する。

タグを打つ前に、CocoaPods 経由でリソースが正しく読み込まれることを手元で確認する。`pod lib lint` は `Bundle.viewMonitor`（`Sources/ViewMonitor/Support/Bundle+ViewMonitor.swift`）の CocoaPods 用分岐を型チェックするだけで実行はしないため、実行時にしか顕在化しない不具合──今回最初に直した「実行ボタンの画像が読み込まれず単色の矩形になる」不具合とまったく同じ経路──を検出できない。使い捨てのアプリを用意し、ローカルの `ViewMonitor.podspec` を `use_frameworks!` あり／なし両方で `pod install` して実行し、実行ボタンが単色の矩形ではなく本来のアートワークで表示されることを確認する。

```bash
git tag 2.0.0
git push origin 2.0.0
pod trunk push ViewMonitor.podspec --allow-warnings
```
