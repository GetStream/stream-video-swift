---
title: Call Permissions
---

### Introduction

In some types of calls, there's a requirement to moderate the behaviour of the participants. Examples include muting a participant, or ending the call for everyone. Those capabilities are usually reserved for the hosts of the call (users with elevated capabilities). They usually have additional moderation controls in their UI, that allow them to achieve these actions.

The StreamVideo SDK has support for such capabilities, with the usage of the `Call`'s permissions features.

### Permissions features

As soon as you join a call, the `Call` object allows you to perform several permissions related actions:
- check if a user has the capabilities to perform an action
- ask for additional capabilities (for example to become a speaker in audio room)
- listen to permissions-related events
- granting and revoking permissions
- perform a moderation action (for example muting a user)

#### Checking for capabilities 

Every user has certain call capabilities, depending on their role in the call. For actions that are beyond the scope of a regular member, you need to check if the user has the appropriate capability, before showing a UI to execute it.

To perform this check, you should use the `Call`'s `currentUserHasCapability` method. In this method, you pass the capability you want to check. 

For example, if you want to check if the user has permissions to send audio, you can do it like this:

```swift
let canSendAudio = call.currentUserHasCapability(.sendAudio)
```

#### Ask for additional capabilities

In some cases, the regular users of a call can ask for additional capabilities. As an example, in audio room apps, users don't have permission to speak, but they can raise their hand to request it. If a host of the call accepts that permission, they move from a listener to a speaker in the call.

Here's how you can ask for additional capabilities via the `Call`:

```swift
func raiseHand() {
    Task {
        try await call.request(
            permissions: [.sendAudio]
        )
    }
}
```

#### Listening to permissions requests

When a user asks for additional capabilities, the hosts of the call receive an event that they can react to (approve or deny the request). You can listen to these events by subscribing to the `permissionRequests` async stream:

```swift
func subscribeForPermissionsRequests() {
    Task {
        for await request in call.permissionRequests() {
            self.permissionRequest = request
        }
    }
}
```

For example, you can present an alert based on the permission request:

```swift
YourView()
    .alert(isPresented: $viewModel.permissionPopupShown) {
        Alert(
        	title: Text("Permission request"),
            message: Text("\(viewModel.permissionRequest?.user.name ?? "Someone") raised their hand to speak."),
            primaryButton: .default(Text("Allow")) {
                viewModel.grantUserPermissions()
            },
            secondaryButton: .cancel()
        )
    }
```

#### Granting and revoking permissions

You can grant permissions by using the `grant(permissions: [Permission], for userId: String, callId: String, callType: String)` in the `Call`. Basically, you need to specify the new permissions that will be granted to the user that requested them:

```swift 
Task {
	try await call.grant(
        permissions: permissionRequest.permissions.compactMap { Permission(rawValue: $0) },
        for: permissionRequest.user.id
    )
}
```

Similarly, you can revoke permissions using the `revoke(permissions: [Permission], for userId: String, callId: String, callType: String)` in the `Call` object:

```swift
Task {
	try await call.revoke(
        permissions: [.sendAudio],
        for: revokingParticipant.userId
    )
}
```

Both of these actions will trigger permission events, that you should handle to update the UI of your app. You can listen to the async stream of `permissionUpdates` in the `Call` for these events:

```swift
Task {
	for await update in call.permissionUpdates() {
        let userId = update.user.id
        self.activeCallPermissions[userId] = update.ownCapabilities
        if userId == streamVideo.user.id
            && !update.ownCapabilities.contains("send-audio")
            && callViewModel.callSettings.audioOn {
                changeMuteState()
        }
        self.update(participants: callViewModel.callParticipants)
    }
}
```

#### Muting users

In bigger conference calls, it's useful to be able to mute everyone (or part of the participants) in the call. With the StreamVideo SDK, you can mute both the audio and the video of the participants.

In order to do this, you need to create a mute request and call the `muteUser` method in the `Call` object:

```swift
func muteUsers(ids: [String]) {
    Task {
        let muteRequest = MuteRequest(
            userIds: ids,
            muteAllUsers: true,
            audio: true,
            video: false,
            screenshare: false
        )
        try await call.muteUsers(
            with: muteRequest
        )
    }
}
```

In the request, you need to specify the list of user ids you want to mute, as well as whether it's the audio, video or screen sharing track. If you are using our `CallViewModel`, the call controls are automatically updated to reflect the state change. If you are using your custom presentation layer, you would need to directly check the changes in the `participants` array of the `Call` object for updates.

#### Ending a call

A host can also end the call for all participants. In order to do this, you need to call the `end` method in the `Call` object:

```swift
func endCallForEveryone() {
    Task {
        try await call.end()
    }
}
```

This will send a `call.ended` event and close the call for everyone.