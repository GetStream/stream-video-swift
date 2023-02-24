---
title: Custom Events
---

### Introduction

In some cases, you might want to send custom events during a call. For example, if you want to build a collaborative drawing board while the call is in progress, you will need a mechanism for syncing the data between the devices. Or if you want to send some custom reactions, or even play a game, you would need an easy mechanism for passing this data to all participants in the call.

The StreamVideo SDK has support for sending custom events and listening to them.

### EventsController

In order to send custom events, you should create an instance of the `EventsController`, using the `StreamVideo` object:

```swift
let eventsController = streamVideo.makeEventsController()
```

#### Sending custom events

For example, let's see how we can send a custom reaction to all partcipiants in the call.

First, let's create a new event type:

```swift
extension EventType {
    static let customReaction: Self = "customReaction"
}
```

Then, let's create a new model that will represent this reaction:

```swift
struct CustomReaction: Identifiable, Codable {
    var id: String
    var duration: Double?
    var sound: String?
    var userSpecific: Bool = false
    var iconName: String
}
```

Next, let's see how we can send the reaction, using the `EventsController`'s method `send(event:)`:

```swift
func send(reaction: CustomReaction) {
    guard let callId, let callType else { return }
    Task {
        let customEvent = CustomEventRequest(
            callId: callId,
            callType: callType,
            type: .customReaction,
            extraData: [
                "id": .string(reaction.id),
                "duration": .number(reaction.duration ?? 0),
                "sound": .string(reaction.sound ?? ""),
                "userSpecific": .bool(reaction.userSpecific),
                "isReverted": .bool(shouldRevert(reaction: reaction))
            ]
        )
        try await eventsController.send(event: customEvent)
    }
}
```

In the code above, we are creating a `CustomEventRequest`, with the call id and call type where the user is a participant. We also provide the newly defined `customReaction` event type. Finally, we are providing our custom reaction info in the `extraData` parameter.

#### Listening to custom events

You can listen to custom events using the `customEvents()` async stream in the `EventsController`:

```swift
private func subscribeToCustomEvents() {
    Task {
        for await event in eventsController.customEvents() {
            log.debug("received an event \(event)")
            if event.type == EventType.customReaction.rawValue {
                handleReaction(with: event.extraData, from: event.user)
            }            
        }
    }        
}
```