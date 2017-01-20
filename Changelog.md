# 2.2.4
- Fixed started issue

# 2.2.3
- Fixed crash when retrying

# 2.2.2
- Fixed crash when retrying many times after each other

# 2.2.1
- Using RxSwift 3.1 with Moya 8

# 2.2.0
- Using ReactiveSwift 1.0.0

# 2.1.4
- Using ReactiveSwift beta 4

# 2.1.0 
Updated naming conventions to conform to Swift 3.0

Make sure you update your DataSource methods

```swift
func loadingView(for dataRequestView: ALDataRequestView) -> UIView?
func reloadViewController(for dataRequestView: ALDataRequestView) -> ALDataReloadType?
func emptyView(for dataRequestView: ALDataRequestView) -> UIView?
func hideAnimationDuration(for dataRequestView: ALDataRequestView) -> Double
func showAnimationDuration(for dataRequestView: ALDataRequestView) -> Double
```

And the attach method:
```swift
.attachTo(dataRequestView: dataRequestView)
```

# 2.0.0
Swift 3.0 compatible

# 1.0.4
- Fixed an issue hidden = false is not called on completion

# 1.0.3
- Fixed a bug in switching states quickly

# 1.0.2

- Allows for fading in and out of loading/error views
- Pass through error when call fails
- Fixed NoInternetConnection ReloadReason
- Fixed RxSwift issue: RequestState will now be on .Loading when the observer subscribes
- Allows nil for reload and empty view

# 1.0.1

- Fixed an retaining issue
- DataSource methods now request an optional

# 1.0.0

- Initial release
