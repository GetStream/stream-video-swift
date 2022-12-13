---
title: Screen Sharing
---

### UI Screen Sharing Component

The StreamVideo iOS SDK is able to present screen sharing tracks. This behaviour is enabled by default in the SDK, along with a standard UI that contains the screen sharing track and a list of participants.

If you want to implement your own UI when there's screen sharing in progress, you need to implement the `makeScreenSharingView` method in the `ViewFactory`. Here's an example implementation:

```swift
public func makeScreenSharingView(
    viewModel: CallViewModel,
    screensharingSession: ScreensharingSession,
    availableSize: CGSize
) -> some View {
    CustomScreenSharingView(
        viewModel: viewModel,
        screenSharing: screensharingSession,
        availableSize: availableSize
    )
}
```

In this method, the following parameters are provided:
- `viewModel` - the `CallViewModel` used in the call.
- `screensharingSession` - The current screen sharing session, that contains information about the track, as well as the participant that is sharing.
- `availableSize` - the available size to layout the rendering view.

### Call Participant Access

If you are not using our `CallViewModel` and its `screensharingSession`, you can also access the screen sharing info in the `CallParticipant` model. It has a property called `isScreensharing`, to indicate whether a participant is sharing their screen. Additionally, you can access the `screenshareTrack` (if available) from this model.