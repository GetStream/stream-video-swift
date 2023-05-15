---
title: Screen Sharing
---

### Screen sharing support

The StreamVideo iOS SDK is able to present screen sharing tracks. This behaviour is enabled by default in the SDK, along with a standard UI that contains the screen sharing track and a list of participants.

The `CallParticipant` model contains the screensharing info. It has a property called `isScreensharing`, to indicate whether a participant is sharing their screen. Additionally, you can access the `screenshareTrack` (if available) from this model.

Only users with the `screenshare` capability can start screensharing sessions. At the moment, this is only possible from the React SDK. Users can request permission to screenshare, by calling the `Call`'s `request(permissions: [Permission])` method and passing the `screenshare` option.

### UI Screen Sharing Component

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