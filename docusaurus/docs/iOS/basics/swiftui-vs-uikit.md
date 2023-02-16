---
title: SwiftUI vs. UIKit
---

## Overview

The SDK was developed with SwiftUI as the primary use-case in mind. However, we take the integration into UIKit-based applications very seriously. This is why we also offer an UIKit SDK that wraps the SwiftUI components so that you don't have to.

Find explanations for integrating both of the SDK on this page.

:::info
You can also have a direct view at the [SwiftUI SDK and the UIKit SDK](https://github.com/GetStream/stream-video-swift) on GitHub and see how to integrate them into your apps [on the next page](./integration.md).
:::

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
