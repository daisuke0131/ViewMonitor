# ViewMonitor

[![CI Status](http://img.shields.io/travis/Daisuke Yamashita/ViewMonitor.svg?style=flat)](https://travis-ci.org/Daisuke Yamashita/ViewMonitor)
[![Version](https://img.shields.io/cocoapods/v/ViewMonitor.svg?style=flat)](http://cocoapods.org/pods/ViewMonitor)
[![License](https://img.shields.io/cocoapods/l/ViewMonitor.svg?style=flat)](http://cocoapods.org/pods/ViewMonitor)
[![Platform](https://img.shields.io/cocoapods/p/ViewMonitor.svg?style=flat)](http://cocoapods.org/pods/ViewMonitor)

## What's ViewMonitor
ViewMonitor can measure View positions with accuracy.
This library is to check design sheet from native app.

behave like this.

![demo](assets/demo.gif)

## Usage

To run the example project, clone the repo.

## Installation
### cocoaPods
ViewMonitor is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:
```ruby
pod "ViewMonitor"
```
after that, please run 
```ruby
pod install
```

But,```/Sources/*.png``` isn`t installed.
Please these files to your project manually.

### Manually
Add all ```/Sources/*``` files to your project.

## How to use
Add ```ViewMonitor.start()``` when application started. 
Like this
```
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
  ViewMonitor.start()
  return true
}
```
After that, execution button appear.

## Author
### developer
[Daisuke Yamashita](https://github.com/daisuke0131)
### designer
[Satomi Nogawa](https://github.com/stmngw)

## License
ViewMonitor is available under the MIT license. See the LICENSE file for more info.
