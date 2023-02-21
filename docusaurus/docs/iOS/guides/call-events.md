---
title: Call Events
---

You can listen to call events if you want to provide your custom handling, that's different then the one implemented in our `CallViewModel`.

The call events are available as an [AsyncStream](https://developer.apple.com/documentation/swift/asyncstream) of `CallEvent`s. The `CallEvent` enumeration has the following values:
- `incoming(IncomingCall)` - called when the current user receives an incoming call. Should be used to display an incoming call UI.
- `accepted(CallEventInfo)` - called when a user has accepted a call initiated by the current user.
- `rejected(CallEventInfo)` - called when a user has rejected a call initiated by the current user.
- `canceled(CallEventInfo)` - called when a call was canceled, mostly due to a timeout or if the user that rings decided to hang up.

### Reacting to Incoming Call events

When the incoming call event is received, you will need to provide handling in your custom implementation. The handling should result into triggering one of the other events (call accepted, rejected or canceled) to the other side.

You should use the methods provided by the `StreamVideo` object to react to incoming call events. 

#### Accepting a call

Accepting a call can be done by calling the `acceptCall(callId: String, callType: CallType)` method from the `StreamVideo` object. Additionally, when you accept a call, you should also join it, by creating an instance of the `CallController` and calling its `joinCall` method.

Here's an example implementation from our `CallViewModel`:

```swift
public func acceptCall(callId: String, type: String) {
    callController = streamVideo.makeCallController(callType: callType(from: type), callId: callId)
    Task {
        try await streamVideo.acceptCall(callId: callId, callType: callType(from: type))
        enterCall(callId: callId, participantIds: participants.map(\.id))
    }
}

private func enterCall(callId: String, participantIds: [String]) {
    guard let callController = callController else {
        return
    }

    Task {
        do {
            log.debug("Starting call")
            let callType = CallType.default
            let options = VideoOptions()
            let call: Call = try await callController.joinCall(
                callType: callType,
                callId: callId,
                callSettings: callSettings,
                videoOptions: options,
                participantIds: participantIds
            )
            self.call = call
            self.updateCallStateIfNeeded()
            listenForParticipantEvents()
            log.debug("Started call")
        } catch {
            log.error("Error starting a call \(error.localizedDescription)")
            callingState = .idle
        }
    }
}
```

#### Rejecting a call

In order to reject a call, you should call `StreamVideo`'s `rejectCall(callId: String, type: String)` method. This will trigger the `rejected` call event to all involved participants, and you should use this to hide the incoming / outgoing call screens.

```swift
public func rejectCall(callId: String, type: String) {
    Task {
        try await streamVideo.rejectCall(callId: callId, callType: callType(from: type))
    }
}
```

#### Cancelling a call

Cancelling a call can be useful in two cases:
- when the caller changes their mind and stops the call.
- there's no reply from the other side and after some timeout you want to cancel the call.

To cancel a call, you need to call `StreamVideo`'s `cancelCall(callId: String, callType: CallType)` method. This will trigger the `canceled` call event to all participants, and it should be used to hide the incoming / outgoing call screens.

```swift
public func cancellCall() {
	Task {
        try await streamVideo.cancelCall(callId: call.callId, callType: call.callType)
    }
}
```