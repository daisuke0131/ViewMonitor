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

### SwiftUI

For apps using the SwiftUI lifecycle (`@main App`), attach `.viewMonitor()`
to the root view:

```swift
import SwiftUI
import ViewMonitor

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .viewMonitor()
        }
    }
}
```

Calling `ViewMonitor.start()` from `App.init()` also works.

SwiftUI's `Text`, `Image`, and `Button` are detected through the
accessibility elements SwiftUI publishes, so measurement works without any
changes to your views. A SwiftUI sample project is available at
`Example/ViewMonitorSwiftUIExample`.

Known limitations for SwiftUI elements:

- SwiftUI elements are detected through the accessibility tree, which iOS
  builds only while an accessibility client is active (VoiceOver, UI tests,
  or Xcode's Accessibility Inspector). If no monitor buttons appear over
  SwiftUI views, attach Accessibility Inspector (Xcode > Open Developer
  Tool > Accessibility Inspector) or enable VoiceOver, then reopen the
  screen. On the simulator you can also run
  `xcrun simctl spawn booted defaults write com.apple.Accessibility AutomationEnabled 1`
  before launching the app.
- Measured values are limited to position, size, and text content
  (font / background / cornerRadius show `None`).
- Monitor buttons do not follow scrolling; they refresh on screen
  transitions.
- Views combined with `.accessibilityElement(children: .combine)` are
  measured as a single element, and `.accessibilityHidden(true)` views are
  not detected.

### Running the sample on a device

The sample runs on the simulator as-is. To run it on a physical device, code
signing needs your own team, so create a `Local.xcconfig` (git-ignored) with
your Team ID before hitting Run:

```sh
echo 'DEVELOPMENT_TEAM = XXXXXXXXXX' > Example/ViewMonitorExample/Local.xcconfig
```

## Author

### developer

[Daisuke Yamashita](https://github.com/daisuke0131)

### designer

[Satomi Nogawa](https://github.com/stmngw)

## License

ViewMonitor is available under the MIT license. See the LICENSE file for more info.

## Other

[How to measure UIView position on Native App](http://www.slideshare.net/daisukeyamashita180/18potatotips-yamashita) at potatotips #18
