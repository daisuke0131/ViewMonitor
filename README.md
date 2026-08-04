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

## Requirements

- iOS 15.0+
- Xcode 26.0+
- Swift 6.0+

## Installation

### Swift Package Manager

In Xcode, go to File > Add Package Dependencies and add the following URL.

```
https://github.com/daisuke0131/ViewMonitor.git
```

If you're using `Package.swift` directly, add it as follows:

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

Call `ViewMonitor.start()` after your app has launched.

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

Once running, tap the button that appears in the top-right corner of the screen to start measuring.
A working sample project is available at `Example/ViewMonitorExample`.

## Author

### developer

[Daisuke Yamashita](https://github.com/daisuke0131)

### designer

[Satomi Nogawa](https://github.com/stmngw)

## License

ViewMonitor is available under the MIT license. See the LICENSE file for more info.

## Other

[How to measure UIView position on Native App](http://www.slideshare.net/daisukeyamashita180/18potatotips-yamashita) at potatotips #18
