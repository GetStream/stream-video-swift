---
title: Call State
---

## Calling state

If you are using our `CallViewModel`, the state of the call is managed for you and available as a `@Published` property called `callingState`. It can be used to show custom UI, such as incoming / outgoing call screens, depending on your use-case. If you are using our default UI components, you don't have to do any special handling about the `callingState`.

The `CallingState` enumeration has the following possible values:
- `idle` - There's no active call at the moment. In this case, your hosting view should be displayed.
- `lobby(LobbyInfo)` - The user is in the lobby before joining the call.
- `incoming(IncomingCall)` - There's an incoming call, therefore an incoming call screen needs to be displayed.
- `joining` - The user is joining a call.
- `outgoing` - The user rings someone, therefore an outgoing call needs to be displayed.
- `inCall` - The user is in a call.
- `reconnecting` - The user dropped the connection and now they are trying to reconnect.

### Example handling

If you want to build your own UI layer, here's an example how to react to the changes of the calling state in SwiftUI:

```swift
public var body: some View {
    ZStack {
        if viewModel.callingState == .outgoing {
            viewFactory.makeOutgoingCallView(viewModel: viewModel)
        } else if viewModel.callingState == .inCall {
            if !viewModel.participants.isEmpty {
                if viewModel.isMinimized {
                    MinimizedCallView(viewModel: viewModel)
                } else {
                    viewFactory.makeCallView(viewModel: viewModel)
                }
            } else {
                WaitingLocalUserView(viewModel: viewModel, viewFactory: viewFactory)
            }
        } else if case let .incoming(callInfo) = viewModel.callingState {
            viewFactory.makeIncomingCallView(viewModel: viewModel, callInfo: callInfo)
        }
    }
    .onReceive(viewModel.$callingState) { _ in
        if viewModel.callingState == .idle || viewModel.callingState == .inCall {
            utils.callSoundsPlayer.stopOngoingSound()
        }
    }
}
```

Similarly, you can listen to the UI changes via the `@Published` property in UIKit:

```swift
private func listenToIncomingCalls() {
    callViewModel.$callingState.sink { [weak self] newState in
        guard let self = self else { return }
        if case .incoming(_) = newState, self == self.navigationController?.topViewController {
            let next = CallViewController.make(with: self.callViewModel)
            CallViewHelper.shared.add(callView: next.view)
        } else if newState == .idle {
            CallViewHelper.shared.removeCallView()
        }
    }
    .store(in: &cancellables)
}
```

### Call Settings

The `CallViewModel` provides information about the current call settings, such as the camera position and whether there's an audio and video turned on. This is available as a `@Published` property called `callSettings`.

If you are building a custom UI, you should use the values from this struct to show the corresponding call controls and camera (front or back).

If you want to learn more about the call settings and how to use them, please check the following [page](../client/call-viewmodel.md).