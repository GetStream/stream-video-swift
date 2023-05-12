---
title: Interrupt Handling
---

### Video Calls Interruptions

During a video call, there can be network issues. For example, the internet connection on the user's device is lost, or the SFU that hosts the call is no longer available. The StreamVideo iOS SDK has a reconnection mechanism that tries to recover from any interruptions during the call.

#### No Network Connection

When the web socket connection to the SFU is lost, the SDK tries to reconnect. If the failure is due to lost network connection on the device, that is considered an unrecoverable error and after retrying for 30 seconds, the call will be closed.

#### Recoverable errors

When the users connect to an SFU, they receive a token with an expiry date. If the call is long, the token could expire in the meantime. When that happens, the SDK automatically fetches new token and reconnects the user. Usually that happens fast and there are no visible changes to the user's experience. 

If the SFU that hosts the call becomes unavailable, and the user has internet connection, the client SDK tries to recover from this failure. It asks our edge infrastructure for a new server to connect to, and usually reconnects after few seconds. By default, the UI SDKs present a reconnection popup while this process is happening.

### Reading the reconnection state

If you are using our `CallViewModel`, you can refer to the `callingState`'s value of `reconnecting` to listen and react to this state. If you are not using our `CallViewModel`, you can read this state via the `Call`'s `reconnecting` variable, which is also `@Published`.

### Changing the ReconnectionView

If you are using our SwiftUI SDK, and the default calling experience, in the case of a reconnection, the `ReconnectionView` is shown. You can provide your custom view to be presented instead, by implementing the `makeReconnectionView` in the `ViewFactory`:

```swift
public func makeReconnectionView(viewModel: CallViewModel) -> some View {
    CustomReconnectionView(viewModel: viewModel, viewFactory: self)
}
```

Additionally, the `ReconnectionView` is public and you can reuse it in your custom calling use-cases.