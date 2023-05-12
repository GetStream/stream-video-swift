---
title: Audio Levels
---

### Showing Audio Levels

If you want to build a custom pre-joining (lobby) view, that's displayed to users before they join the call, you might want to show an indicator of the audio levels of the current user.

In order to do this, you can use the `MicrophoneChecker` and the `MicrophoneCheckView` from the `StreamVideo` SwiftUI SDK. The `MicrophoneChecker` is an observable class that provides updates for the last decibel values of the current user. The `MicrophoneCheckView` presents them in a reusable view component.

Both components are used in our `LobbyView`, that you can also directly use in your apps.

Here's an example usage. First, you instantiate the `MicrophoneChecker` class, e.g. as a `@StateObject`, if it's used directly in your SwiftUI views:

```swift
@StateObject var microphoneChecker = MicrophoneChecker()
```

Optionally, you can provide a `valueLimit` in the initalizer of the `MicrophoneChecker`. By default, this value is 3, which means it returns the last three decibel values. You can pass a bigger number if you want to show more values to the user.

Then, in the `MicrophoneCheckView`, you pass the decibels array, as well as whether the `microphoneChecker` has any decibel values. If this value is `false`, the UI shows warning to the user that they might have an issue with their microphone.

```swift
MicrophoneCheckView(
	decibels: microphoneChecker.decibels,
	microphoneOn: callViewModel.callSettings.audioOn,
    hasDecibelValues: microphoneChecker.hasDecibelValues                    
)
```