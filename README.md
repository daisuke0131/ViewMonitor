![ViewMonitor](assets/viewmonitor.png)
[![Version](https://img.shields.io/cocoapods/v/ViewMonitor.svg?style=flat)](http://cocoapods.org/pods/ViewMonitor)
[![License](https://img.shields.io/cocoapods/l/ViewMonitor.svg?style=flat)](http://cocoapods.org/pods/ViewMonitor)

## What's ViewMonitor

ViewMonitor can measure view positions with accuracy.
This library is to check design sheet from native app.
behave like this.

- UIViewController
  ![demo](assets/demo.gif)
- UITableViewController
  ![demo](assets/table_demo.gif)

## Usage

To run the example project, clone the repo.

## Requirements

- iOS 15.0+
- Xcode 26.0+
- Swift 6.0+

## Installation

### Swift Package Manager

Xcode の File > Add Package Dependencies から次のURLを追加する。

```
https://github.com/daisuke0131/ViewMonitor.git
```

`Package.swift` を使う場合は次のように記述する。

```swift
dependencies: [
    .package(url: "https://github.com/daisuke0131/ViewMonitor.git", from: "2.0.0")
]
```

### cocoaPods

ViewMonitor is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line in your Podfile:

```ruby
pod "ViewMonitor"
```

This library use swift.
So, you have to add `use_frameworks!` in Podfile.
after that, please run

```ruby
pod install
```

## How to use

`ViewMonitor.start()` をアプリ起動後に呼ぶ。

```swift
import ViewMonitor

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        ViewMonitor.start()
    }
}
```

実行後、画面右上に表示されるボタンから計測を開始できる。
`Example/ViewMonitorExample` に動作するサンプルがある。

## Author

### developer

[Daisuke Yamashita](https://github.com/daisuke0131)

### designer

[Satomi Nogawa](https://github.com/stmngw)

## License

ViewMonitor is available under the MIT license. See the LICENSE file for more info.

## Other

[How to measure UIView position on Native App](http://www.slideshare.net/daisukeyamashita180/18potatotips-yamashita) at potatotips #18
