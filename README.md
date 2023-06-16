# StreamVideo iOS

<p align="center">
  <a href="https://cocoapods.org/pods/StreamVideo"><img src="https://img.shields.io/badge/CocoaPods-compatible-green" /></a>
  <a href="https://www.swift.org/package-manager/"><img src="https://img.shields.io/badge/SPM-compatible-green" /></a>
</p>
<p align="center">
  <a href="https://getstream.io/video/docs/sdk/ios/"><img src="https://img.shields.io/badge/iOS-13%2B-lightblue" /></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.6%2B-orange.svg" /></a>
  <a href="https://github.com/GetStream/stream-video-swift/actions"><img src="https://github.com/GetStream/stream-video-swift/actions/workflows/cron-checks.yml/badge.svg" /></a>
</p>
<p align="center">
  <img alt="StreamVideo" src="https://img.shields.io/endpoint?url=https://stream-sdks-size-badges.onrender.com/ios/stream-video&cacheSeconds=86400"/>
  <img alt="StreamVideoSwiftUI" src="https://img.shields.io/endpoint?url=https://stream-sdks-size-badges.onrender.com/ios/stream-video-swiftui&cacheSeconds=86400"/>
</p>

This is the official iOS SDK for StreamVideo, a platform for building apps with video and audio calling support. The repository includes both a low-level SDK and a set of reusable UI components, available in both UIKit and SwiftUI.

## Introduction

This repository contains the following parts:
- low-level client for calling (can be used standalone if you want to build your own UI)
- SwiftUI SDK (UI components developed in SwiftUI)
- UIKit SDK (wrappers for easier usage in UIKit apps)

### Main Principles

- Progressive disclosure: The SDK can be used easily with very minimal knowledge of it. As you become more familiar with it, you can dig deeper and start customizing it on all levels.
- Swift native API: Uses Swift's powerful language features to make the SDK usage easy and type-safe.
- Familiar behavior: The UI elements are good platform citizens and behave like native elements; they respect `tintColor`, padding, light/dark mode, dynamic font sizes, etc.
- Fully open-source implementation: You have access to the complete source code of the SDK on GitHub.

### Low-Level Client

The low-level client is used for establishing audio and video calls. It integrates with Stream's backend infrastructure, and implements the WebRTC protocol.

Here are the most important components that the low-level client provides:
- `StreamVideo` - the main SDK object.
- `Call` - an object that provides info about the call state, as well as methods for updating it.

#### StreamVideo

This is the main object for interfacing with the low-level client. It needs to be initialized with an API key and a user/token, before the SDK can be used.

```swift
let streamVideo = StreamVideo(
    apiKey: "key1",
    user: user.userInfo,
    token: user.token,
    videoConfig: VideoConfig(),
    tokenProvider: { result in
      yourNetworkService.loadToken(completion: result)
    }
)
```

#### Call

The `Call` class provides all the information about the call, such as its participants, whether the call is being recorded, etc. It also provides methods to perform standard actions available during a call, such as muting/unmuting users, sending reactions, changing the camera input, granting permissions, recording, etc.

You can create a new `Call` via the `StreamVideo`'s method `func call(callType: String, callId: String, members: [Member])`.

### SwiftUI SDK

The SwiftUI SDK provides out of the box UI components, ready to be used in your app.

The simplest way to add calling support to your hosting view is to attach the `CallModifier`:

```swift
struct CallView: View {

    @StateObject var viewModel: CallViewModel

    init() {
        _viewModel = StateObject(wrappedValue: CallViewModel())
    }

    var body: some View {
        HomeView(viewModel: viewModel)
            .modifier(CallModifier(viewModel: viewModel))
    }
}

```

You can customize the look and feel of the screens presented in the calling flow, by implementing the corresponding methods in our `ViewFactory`.

Most of our components are public, so you can use them as building blocks if you want to build your custom UI.

All the texts, images, fonts and sounds used in the SDK are configurable via our `Appearance` class, to help you brand the views to be inline with your hosting app.

### UIKit SDK

The UIKit SDK provides UIKit wrappers around the SwiftUI views. Its main integration point is the `CallViewController` which you can easily push in your navigation stack, or add as a modal screen.

```swift
private func didTapStartButton() {
    let next = CallViewController.make(with: callViewModel)
    next.modalPresentationStyle = .fullScreen
    next.startCall(
            callType: "default",
            callId: callId,
            members: members
        )
    self.navigationController?.present(next, animated: true)
}
```

The `CallViewController` is created with a `CallViewModel` - the same one used in our SwiftUI SDK.

At the moment, all the customizations in the UIKit SDK, need to be done in SwiftUI.

## Roadmap

Video roadmap and changelog is available [here](https://github.com/GetStream/protocol/discussions/127).

### 0.2 milestone

- [ ] Test coverage
- [ ] Stability
- [ ] Test with many participants
- [ ] CPU usage improvements
- [ ] Call Analytics

### 0.3 milestone

- [ ] Dynascale 2.0 (codecs, f resolution switches, resolution webrtc handling)
- [ ] Audio filters
- [ ] Picture-in-picture sample
- [ ] Screensharing from mobile

### 0.4 milestone

- [ ] Analytics integration
- [ ] Improved chat integration
- [ ] Tap to focus
- [ ] Picture of the video stream at highest resolution