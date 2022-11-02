---
title: Call Events
---

You can listen to call events if you want to provide your custom handling, that's different then the one implemented in our `CallViewModel`.

The call events are available as an [AsyncStream](https://developer.apple.com/documentation/swift/asyncstream) of `CallEvent`s. The `CallEvent` enum has the following values:
- `incoming(IncomingCall)` - called when the current user receives an incoming call. Should be used to display an incoming call UI.
- `accepted(CallEventInfo)` - called when a user has accepted a call initiated by the current user.
- `rejected(CallEventInfo)` - called when a user has rejected a call initiated by the current user.
- `canceled(CallEventInfo)` - called when a call was canceled, mostly due to a timeout or if the user that rings decided to hang up.