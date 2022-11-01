---
title: Architecture Overview
slug: /
---

## Introduction

The StreamVideo product consists of three separate SDKs:
- low-level client - responsible for establishing calls, built on top of WebRTC.
- SwiftUI SDK - SwiftUI components for different types of call flows.
- UIKit SDK - UIKit wrapper over the SwiftUI components, for easier usage in UIKit based apps.

The low-level client is used as a dependency in the UI frameworks, and can also be used standalone if you plan to build your own UI. The UI SDKs depend on the low-level client.

## Low-Level Client

The low-level client is used for establishing audio and video calls. It integrates with Stream's backend infrastructure, and implements the WebRTC protocol. 

Here are the most important components that the low-level client provides:
- `StreamVideo` - the main SDK object.
- `CallController` - controller that deals with a particular call.
- `CallViewModel` - stateful ViewModel that contains presentation logic.

### StreamVideo

This is the main object for interfacing with the low-level client. It needs to be initialized with an API key and a user/token, before the SDK can be used. 

```swift
let streamVideo = StreamVideo(
    apiKey: "key1",
    user: user.userInfo,
    token: user.token,
    videoConfig: VideoConfig(
        persitingSocketConnection: true,
        joinVideoCallInstantly: true
    ),
    tokenProvider: { result in
    	yourNetworkService.loadToken(completion: result)
    }
)
```

Here are parameters that the `StreamVideo` class expects:
- `apiKey` - your Stream Video API key (note: it's different from chat)
- `user` - the logged in user, represented by the `UserInfo` struct.
- `token` - the user's token.
- `videoConfig` - configuration for the type of calls. The `joinVideoCallInstantly` determines if you want to use the outgoing / incoming call screens (similar to social media apps), or jump directly to a call (similar to meeting based apps).
- `tokenProvider` - called when the token expires. Use it to load a new token from your networking service.

The `StreamVideo` object should be kept alive throughout the app lifecycle. You can store it in your `App` or `AppDelegate`, or any other class whose lifecycle is tied to the one of the logged in user.

### CallController

The `CallController` class deals with a particular call. It's created before the call is started, and it should be deallocated when the call ends.

If you want to build your own presentation layer around video calls (ViewModel / Presenter), you should use this class. It provides access to call related actions, such as muting audio/video, changing the camera input, hanging up, etc.

When a call starts, the call controller communicates with our backend infrastructure, to find the best Selective Forwarding Unit (SFU) to host the call, based on the locations of the participants. It then establishes the connection with that SFU and provides updates on all events related to a call.

You can create a new call controller via the `StreamVideo`'s method `func makeCallController(callType: CallType, callId: String)`.

### CallViewModel

The `CallViewModel` is a presentation object that can be used directly if you need to implement your custom UI. It contains a `callState`, which provides information about whether the call is in a ringing mode, inside a call, or it's about to be closed. It also publishes events about the call participants, which you can use to update your UI.

The view model provides methods for starting and joining a call. It also wraps the call-related actions such as muting audio/video, changing the camera input, hanging up, for easier access from the views.

You should use this class directly, if you want to build your custom UI components. 

## SwiftUI SDK

The SwiftUI SDK provides out of the box UI components, ready to be used in your app. The currently supported flows are "ringing" mode - with outgoing / incoming screens, and the "meeting" mode, which adds users to the call directly. The `joinVideoCallInstantly` property in the `VideoConfig` determines this behaviour (as described above).

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

With this setup, the `CallViewModel` will listen to incoming call events and present the appropriate UI, based on the state.

You can customize the look and feel of the screens presented in the calling flow, by implementing the corresponding methods in our `ViewFactory`.

Most of our components are public, so you can use them as building blocks if you want to build your custom UI. 

All the texts, images, fonts and sounds used in the SDK are configurable via our `Appearance` class, to help you brand the views to be inline with your hosting app.

## UIKit SDK

The UIKit SDK provides UIKit wrappers around the SwiftUI views. Its main integration point is the `CallViewController` which you can easily push in your navigation stack, or add as a modal screen.

```swift
private func didTapStartButton() {
    let next = CallViewController.make(with: callViewModel)
    next.modalPresentationStyle = .fullScreen
    next.startCall(callId: text, participants: selectedParticipants)
    self.navigationController?.present(next, animated: true)
}
```

The `CallViewController` is created with a `CallViewModel` - the same one used in our SwiftUI SDK.

At the moment, all the customizations in the UIKit SDK, need to be done in SwiftUI.