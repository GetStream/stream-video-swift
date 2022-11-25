---
title: Call Lifecycle
---

## CallController and Call

The `CallController` object manages everything related to a particular call, such as creating, joining a call, performing actions for a user (mute/unmute, camera change, invite, etc) and listening to events.

When a call starts, the call controller communicates with our backend infrastructure, to find the best Selective Forwarding Unit (SFU) to host the call, based on the locations of the participants. It then establishes the connection with that SFU and provides updates on all events related to a call.

You can create a new call controller via the `StreamVideo`'s method `func makeCallController(callType: CallType, callId: String)`.

It's a lower-level component than the stateful `CallViewModel`, and it's suitable if you want to create your own presentation logic and state handling. 

When you call the `joinCall` method of the `CallController`, a `Call` object is returned. This is an `@ObservableObject`, that you can use to listen to changes to participant events (joining / leaving a call).

The `Call` and the `CallController` should exist while the call is active. Afterwards, you should clean up all the state related to the call (provided you don't use our `CallViewModel`).

Every call has a call id and type. You can join a call with the same id as many times as you need. However, the call sends ringing events only the first time. If you want to receive ring events, you should always use a unique call id.

## Web Socket Connection

By default, the web socket connection with our backend is created when the `StreamVideo` client is initialized, and it's persisted throughout its lifecycle. If you go into the background, and come back, the SDK tries to re-establish this connection. The web socket connection is persisted in order to listen to events such as incoming calls, that can be presented in-app (if you're not using CallKit).

You can change this behaviour and create the web socket connection only before you start a call. This can be done by setting `persitingSocketConnection` to `false` in the `VideoConfig`, when you create the `StreamVideo` client.