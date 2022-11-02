---
title: Call State
---

## Calling state

If you are using our `CallViewModel`, the state of the call is managed for you and available as a `@Published` property called `callingState`. It can be used to show custom UIs, such as incoming / outgoing call screens, depending on your use-case. If you are using our default UI components, you don't have to do any special handling about the `callingState`.

The `CallingState` enum has the following possible values:
- `idle` - There's no active call at the moment. In this case, your hosting view should be displayed.
- `incoming(IncomingCall)` - There's an incoming call, therefore an incoming call screen needs to be displayed.
- `outgoing` - The user rings someone, therefore an outgoing call needs to be displayed.
- `inCall` - The user is in a call.
- `reconnecting` - The user dropped the connection and now it's trying to reconnect.

## Call Settings

The `CallViewModel` provides information about the current call settings, such as the camera position and whether there's an audio and video turned on. This is available as a `@Published` property called `callSettings`.

If you are building a custom UI, you should use the values from this struct to show the corresponding call controls and camera (front or back).

## Participants

The call participants are available as a `@Published` property called `callParticipants`. You can use this to present your custom UI that displays their video feeds.