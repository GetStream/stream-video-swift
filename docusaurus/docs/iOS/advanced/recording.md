---
title: Recording Calls
---

### RecordingController

In some cases, you want to be able to record a meeting and share the recording with the participants later on. The StreamVideo SDK has support for this use-case.

In order to support this feature, you will need to create a new `RecordingController`, using the `StreamVideo` object:

```swift
private lazy var recordingController: RecordingController = {
    streamVideo.makeRecordingController()
}()
```

#### Recording state

The recording state of the call is available via the `CallViewModel`'s `recordingState` published property. It's an `enum`, which has the following values:
- `noRecording` - default value, there's no recording on the call.
- `requested` - recording was requested by the current user.
- `recording` - recording is in progress.

If you are not using our `CallViewModel`, you can also listen to this state via the `Call`'s property `recordingState`. 

#### Start a recording

To start a recording, you need to call the `startRecording` method of the controller, by passing the `callId` and the `callType`:

```swift
func startRecording(callId: String, callType: CallType) {
    Task {
        try await recordingController.startRecording(
            callId: callId,
            callType: callType
        )
    }
}
``` 

This will change the current recording state of the call to `requested`. Since it takes several seconds before the recording is started, it's best to handle this state by presenting a progress indicator to provide a better user experience.

After the recording is started, the `recordingState` changes to `recording`.

#### Stop a recording

To stop a recording, you need to call the `stopRecording` method of the controller, by passing the `callId` and the `callType`:

```swift
func stopRecording(callId: String, callType: CallType) {
    Task {
        try await recordingController.stopRecording(
            callId: callId,
            callType: callType
        )
    }
}
```

This wil change the current recording state of the call to `noRecording`.

#### Recording events

You can listen to the recording events and show visual indications to the users based on these events, by subscribing to the async stream of the `recordingEvents`:

```swift
func subscribeToRecordingEvents() {
    Task {
        for await event in recordingController.recordingEvents() {
            log.debug("received an event \(event)")
            /* handle recording event */
        }
    }
}
```