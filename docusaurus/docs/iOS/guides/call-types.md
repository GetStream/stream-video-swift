---
title: Call Types
---

When you start a call, you also need to provide the call type. Call types come with some predefined settings and permissions, depending on the video calling use-case they represent.

#### Development

The `development` call type has all the permissions enabled, and can be used during development. It's not recommended to use this call type in production, since all the participants in the calls would be able to do everything (blocking, muting everyone, etc).

For these call types, backstage is not enabled, therefore you don't have to explicitly call `goLive` in order for the call to be started.

#### Default

The `default` call type can be used for different video-calling apps, such as 1-1 calls, group calls or meetings with multiple people. Both video and audio are enabled, and backstage is disabled. It has permissions settings in place, where admins and hosts have elevated permissions over other types of users.

#### Audio Room

The `audio_room` call type is suitable for apps like Clubhouse or Twitter Spaces. It has pre-configured workflow around requesting permissions to speak for regular listeners. Backstage is enabled, and new calls are going to the backstage mode when created. You will need to explicitly call the `goLive` method to make the call active for all participants.

You can find a guide on how to handle this [here](./quickstart/audio-room.md).

#### Livestream

The `livestream` call type is configured to be used for livestreaming apps. Access to calls is granted to all authenticated users, and backstage is enabled by default.

### Sorting

The sorting of participants in a call is connected to the call type. For example, the audio room apps usually put the hosts at the top (role based sorting), then the speakers and finally the listeners. On the other hand, meeting based apps usually put the speakers and the participants with video at the top. 

The `StreamVideo` SDK comes with pre-configured functions that allow you to apply sorting to the participants list. Additionally, you can create your own sorting criteria, based on the properties available in the `CallParticipant` model.

When a call type is created, you can optionally specify the sorting comparators:

```swift
let audioRoom = CallType(name: "audio_room", sortComparators: livestreamComparators)
```

If you don't specify anything, the default sort comparators would be used. These are Swift functions that given two participants, return `ComparisonResult`.

The default comparators are the following:

```swift
public let defaultComparators: [Comparator<CallParticipant>] = [
    pinned, screensharing, dominantSpeaker, publishingVideo, publishingAudio, userId
]
```

You can add or remove comparators, as well as create your own ones, by matching the `Comparator` definition:

```swift
public typealias Comparator<Value> = (Value, Value) -> ComparisonResult
```

For example, here's how the `pinned` comparator is implemented:

```swift
public var pinned: Comparator<CallParticipant> = { (p1, p2) in
    booleanComparison(first: p1, second: p2, \.isPinned)
}

func booleanComparison<Value, T>(
    first: Value,
    second: Value,
    _ keyPath: KeyPath<Value, T>
) -> ComparisonResult {
    let boolFirst = first[keyPath: keyPath] as? Bool
    let boolSecond = second[keyPath: keyPath] as? Bool
    if boolFirst == boolSecond { return .orderedSame }
    if boolFirst == true { return .orderedDescending }
    if boolSecond == true { return .orderedAscending }
    return .orderedSame
}
```