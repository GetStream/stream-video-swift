---
title: Call Participants
---

When users join a call, they become `CallParticipant`s. The call participants are available from the `CallViewModel`'s `callParticipants` property, as a dictionary. 

You can use this property to filter participants, based on their properties. Here's a list of the info that is available about the `CallParticipant`:
- `id`: `String` - The unique call id of the participant.
- `userId`: `String` - The user's id. This is not necessarily unique, since a user can join from multiple devices. 
- `role`: `String` - The user's role in the call.
- `name`: `String` - The user's name.
- `profileImageURL`: `URL?` - The user's profile image url.
- `trackLookupPrefix`: `String?` - The id of the track that's connected to the participant.
- `isOnline`: `Bool` - Returns whether the participant is online.
- `hasVideo`: `Bool` - Returns whether the participant has video.
- `hasAudio`: `Bool` - Returns whether the participant has audio.
- `isScreensharing`: `Bool` - Returns whether the participant is screensharing.
- `track`: `RTCVideoTrack?` - Returns the participant's video track.
- `trackSize`: `CGSize` - Returns the size of the track for the participant.
- `screenshareTrack`: `RTCVideoTrack?` - Returns the screensharing track for the participant.
- `showTrack`: `Bool` - Returns whether the track should be shown.
- `layoutPriority`: `LayoutPriority` - Determines the layout priority of the participant.
- `isSpeaking`: `Bool` - Returns whether the participant is speaking.
- `sessionId`: `String` - Returns the session id of the participant.
- `connectionQuality`: `ConnectionQuality` - Returns the connection quality of the participant.
- `joinedAt`: `Date` - Returns the date when the user joined the call.

These properties can be used to do custom filtering of the participants. For example, if you want to get the first user who is speaking, you can do the following:

```swift
var speaker: CallParticipant? {
    participants.first { $0.isSpeaking }
}
```