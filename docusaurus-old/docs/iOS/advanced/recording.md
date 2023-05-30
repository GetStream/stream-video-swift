---
title: Recording Calls
---

### Call's recording features

In some cases, you want to be able to record a meeting and share the recording with the participants later on. The StreamVideo SDK has support for this use-case.

In order to support this feature, you will need to use the `Call`'s recording features, available after you join a call.

#### Recording state

The recording state of the call is available via the `CallViewModel`'s `recordingState` published property. It's an `enum`, which has the following values:
- `noRecording` - default value, there's no recording on the call.
- `requested` - recording was requested by the current user.
- `recording` - recording is in progress.

If you are not using our `CallViewModel`, you can also listen to this state via the `Call`'s property `recordingState`. 

#### Start a recording

To start a recording, you need to call the `startRecording` method of the call:

```swift
func startRecording() {
    Task {
        try await call.startRecording()
    }
}
``` 

This will change the current recording state of the call to `requested`. Since it takes several seconds before the recording is started, it's best to handle this state by presenting a progress indicator to provide a better user experience.

After the recording is started, the `recordingState` changes to `recording`.

#### Stop a recording

To stop a recording, you need to call the `stopRecording` method of the `Call`:

```swift
func stopRecording() {
    Task {
        try await call.stopRecording()
    }
}
```

This will change the current recording state of the call to `noRecording`.

#### Recording events

You can listen to the recording events and show visual indications to the users based on these events, by subscribing to the async stream of the `recordingEvents`:

```swift
func subscribeToRecordingEvents() {
    Task {
        for await event in call.recordingEvents() {
            log.debug("received an event \(event)")
            /* handle recording event */
        }
    }
}
```

#### Search recordings

You can search for recordings in a video call, using the `Call`'s `listRecordings` method:

```swift
func loadRecordings() {
    Task {
        self.recordings = try await call.listRecordings()
    }
}
```

This will return a list of recordings, that contains information about the filename, URL, as well as the start and end time. You can use the URL to present the recording in a player. Here's an example in SwiftUI:

```swift
import SwiftUI
import StreamVideo
import AVKit

struct PlayerView: View {
    
    let recording: CallRecordingInfo
    
    var body: some View {
        Group {
            if let url = URL(string: recording.url) {
                VideoPlayer(player: AVPlayer(url:  url))
            } else {
                Text("Video can't be loaded")
            }
        }
    }
}
```
