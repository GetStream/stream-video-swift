---
title: View Slots
---

You can swap certain views in the SwiftUI SDK, by implementing your own version of the `ViewFactory` protocol. Here's a list of the supported slots that can be swapped with your custom views.

In most of these slots, the whole `CallViewModel` is provided, allowing you to update the state from these views.

### Outgoing Call View

In order to swap the outgoing call view, we will need to implement the `makeOutgoingCallView(viewModel: CallViewModel) -> some View` in the `ViewFactory`:

```swift
class CustomViewFactory: ViewFactory {
    
	func makeOutgoingCallView(viewModel: CallViewModel) -> some View {
        CustomOutgoingCallView(viewModel: viewModel)
    }

}
```

### Incoming Call View

Similarly, the incoming call view can be replaced by implementing the `makeIncomingCallView(viewModel: CallViewModel, callInfo: IncomingCall) -> some View` in the `ViewFactory`:

```swift
public func makeIncomingCallView(viewModel: CallViewModel, callInfo: IncomingCall) -> some View {
    CustomIncomingCallView(callInfo: callInfo, viewModel: viewModel)
}
```

### Call View

When the call state change to `.inCall`, the call view slot is shown. The default implementation provides several customizable parts, such as the video participants, the call controls (mute/unmute, hang up) and the top trailing view (which by default displays participants' info).

In order to swap the default call view, you will need to implement the `makeCallView(viewModel: CallViewModel) -> some View`:

```swift
public func makeCallView(viewModel: CallViewModel) -> some View {
    CustomCallView(viewModel: viewModel)
}
```

Apart from the main call view, you can also swap its building blocks.

### Call Controls View

The call controls view by default displays controls for hiding/showing the camera, muting/unmuting the microphone, changing the camera source (front/back) and hanging up. If you want to change these controls, you will need to implement the `makeCallControlsView(viewModel: CallViewModel) -> some View` method:

```swift
func makeCallControlsView(viewModel: CallViewModel) -> some View {
    CustomCallControlsView(viewModel: viewModel)
}
```

### Video Participants View

The video participants view slot presents the grid of users that are in the call. If you want to provide a different variation of the participants display, you will need to implement the `makeVideoParticipantsView` in the `ViewFactory`:

```swift
public func makeVideoParticipantsView(
    participants: [CallParticipant],
    availableSize: CGSize,
    onViewRendering: @escaping (VideoRenderer, CallParticipant) -> Void,
    onChangeTrackVisibility: @escaping @MainActor(CallParticipant, Bool) -> Void
) -> some View {
    VideoParticipantsView(
        participants: participants,
        availableSize: availableSize,
        onViewRendering: onViewRendering,
        onChangeTrackVisibility: onChangeTrackVisibility
    )
}
```

In the method, the following parameters are provided:
- `participants` - the list of participants.
- `availableSize` - the available size for the participants view.
- `onViewRendering` - called when the view is rendered. This callback should be used to attach a track to the view.
- `onChangeTrackVisibility` - callback when the track changes its visibility.

### Top Trailing View

This is the view presented in the top trailing area of the call view. By default, it displays a button that shows the list of participants. You can swap this view with your own implementation, by implementing the `makeTrailingTopView` in the `ViewFactory`:

```swift
func makeTrailingTopView(
    viewModel: CallViewModel,
    availableSize: CGSize
) -> some View {
    CustomCallParticipantsInfoView(viewModel: viewModel, availableSize: availableSize)
}
```