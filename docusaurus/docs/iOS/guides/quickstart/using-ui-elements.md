---
title: Using UI elements
---

## Introduction

This guide demonstrates how to use UI elements with the Stream Video SDK. This means both, using the elements that ship with the SDK itself and also adding your own custom UI.

The goal is to make both possible as easy and seamless as possible to provide you with the most flexibility when building your product.

So naturally, when talking about UI elements, let's start with logic.

## Use logic from the StreamVideo SDK

One thing that is very important when using a video SDK is to be able to start and join calls and know when you receive calls. The `StreamVideoSwiftUI` SDK offers the `CallViewModel` that provides you with all necessary call-related logic.

Get started by creating a property in the `ContentView` that is a `CallViewModel`:

```swift
@StateObject var callViewModel = CallViewModel()
```

You will look at different functionalities of the `CallViewModel` in this guide, the first is its `callingState`. This `enum` tells you which state the current call is in. It's best to learn about it in code, so let's replace the `body` of the `ContentView` with a `switch` statement over the `callViewModel.callingState`.

```swift
switch callViewModel.callingState {
    case .idle:
        Text("Idle call")
    case .inCall:
        Text("In Call")
    case .incoming(let callInfo):
        Text("Incoming call: \(callInfo.id)")
    case .outgoing:
        Text("Outgoing call")
    case .reconnecting:
        Text("Reconnecting")
    case .lobby(let lobbyInfo):
        Text("In lobby: \(lobbyInfo.callId)")
    }
```

You can see all states, that a call can be in and with that show UI that is suited for that. Right now, this UI doesn't do much. In fact, you only have `Text` views that point out the state.

In the next chapter, let's have a look how to properly fill the UI with real views.

## Use views from StreamVideoSwiftUI

Having only `Text` views is not going to win you an Apple Design award, so let's fill those up with more useful ones.

Luckily, the `StreamVideoSwiftUI` package has a lot of built-in views that you can directly use. These views are internally also used when working with the `ViewFactory` ([see next chapter](#create-and-use-the-viewfactory)) but you can also directly call and use them inside of your apps.

:::tip
Since all our SDKs are open-source, you can also have a look at how this works. As an example, have a look at the [ViewFactory](https://github.com/GetStream/stream-video-swift/blob/main/Sources/StreamVideoSwiftUI/ViewFactory.swift) to see how custom views are created and used.
:::

Continuing on the previous example, let's look at how to do this. For the case of an incoming call, let's use the component from the SDK to show a proper view for that, which is called `IncomingCallView`.

Looking at the code for the view (can also be found [here](https://github.com/GetStream/stream-video-swift/blob/main/Sources/StreamVideoSwiftUI/CallingViews/IncomingCallView.swift)) the view has the following signature:

```swift
IncomingCallView(
    callInfo: IncomingCall,
    onCallAccepted: @escaping (String) -> Void,
    onCallRejected: @escaping (String) -> Void
)
```

The `callInfo` object you get in the switch case (`.incoming(let callInfo)`) is of type `IncomingCall`. The other two parameters are closures and are called when the user accepts (`onCallAccepted`) or rejects (`onCallRejected`) the incoming call.

The beauty of this is that you can now either use your own logic that handles these cases or you can again use the `callViewModel` to handle this. The best solution always depends on your use-case and we want to give you the freedom to freely choose while also providing sensible defaults.

When using the `callViewModel` the code to integrate the `IncomingCallView` could look like this (only showing this specific case of the `switch` statement):

```swift
case .incoming(let callInfo):
    IncomingCallView(callInfo: callInfo, onCallAccepted: { _ in
        viewModel.acceptCall(callId: callInfo.id, type: callInfo.type)
    }, onCallRejected: { _ in
        viewModel.rejectCall(callId: callInfo.id, type: callInfo.type)
    })
```

There are many more of the built-in components that you can use. Feel free to explore the SDK or the documentation to find out which ones are available, here are a few examples:

- `CallControlsView` ([see on GitHub](https://github.com/GetStream/stream-video-swift/blob/main/Sources/StreamVideoSwiftUI/CallView/CallControlsView.swift))
- `OutgoingCallView` ([see on GitHub](https://github.com/GetStream/stream-video-swift/blob/main/Sources/StreamVideoSwiftUI/CallingViews/OutgoingCallView.swift))
- `VideoParticipantsView` ([see on GitHub](https://github.com/GetStream/stream-video-swift/blob/main/Sources/StreamVideoSwiftUI/CallView/VideoParticipantsView.swift))
- `CallView` ([see on GitHub](https://github.com/GetStream/stream-video-swift/blob/main/Sources/StreamVideoSwiftUI/CallView/CallView.swift))
- `CallParticipantsInfoView` ([see on GitHub](https://github.com/GetStream/stream-video-swift/blob/main/Sources/StreamVideoSwiftUI/CallView/Participants/CallParticipantsInfoView.swift))

There are many more, which are all used when the `ViewFactory` uses its default function calls. But what is the `ViewFactory`, you may ask. The next chapter will take a look at it in more detail.

## Create and use the ViewFactory

The `StreamVideoSwiftUI` SDK bases the creation of views on an object called `ViewFactory`. This is something you need to implement yourself. Luckily, it is easy as creating a new Swift file, calling it `MyViewFactory` (you can name it anything you like) and pasting the following code:

```swift
import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

class MyViewFactory: ViewFactory {}
```

This doesn't look like much, but the power of the framework comes in the built-in default components that the `ViewFactory` protocol offers. It acts as a container that gives you a great amount of flexibility. You will now see the different layers it offers and how you can use both the default views as well as completely custom view implementations.

Head over to `ContentView` and first add a property inside called `viewFactory` and initialize it:

```swift
var viewFactory = MyViewFactory()
```

Now, when you look at the `switch` case you created in the previous chapter, take a look at the case `.incoming(let callInfo)`. The `viewFactory` contains a function called `makeIncomingCallView` that provides a view for that. It takes two parameters, a `CallViewModel` and an `IncomingCall`. The first is available in your view and the second is the associated value of the `enum` case.

So, you can replace the `Text` for the `.incoming` case with the following line:

```swift
viewFactory.makeIncomingCallView(viewModel: callViewModel, callInfo: callInfo)
```

That is all you need to do to use the beautiful built-in view component for incoming calls.

You can even do more checks for deciding which of the `viewFactory` methods to call to render views. The following code replaces the `Text("In Call")` view for the case `.inCall`.

```swift
case .inCall:
    if !viewModel.participants.isEmpty {
        if viewModel.isMinimized {
            MinimizedCallView(viewModel: viewModel)
        } else {
            viewFactory.makeCallView(viewModel: viewModel)
        }
    } else {
        WaitingLocalUserView(viewModel: viewModel, viewFactory: viewFactory)
    }
```

This piece of code shows that you can also mix between views from the `viewFactory` (in this case the `makeCallView`) and others such as a `MinimizedCallView` or a `WaitingLocalUserView`.

The goal is to offer you the most amount of flexibility while providing sensible default views for you to use.

Next, let's look at how to replace the default views in the `ViewFactory`.

## Custom view injection into the ViewFactory

In some cases the built-in components are not suitable but more customization is required. For this the `StreamVideoSwiftUI` SDK offers an easy way to replace the default views from the `viewFactory`.

Let's look at this in action. First, head to `ContentView` and look for the `.outgoing` case of the switch statement in the `body`. Replace the `Text("Outgoing call")` with the `viewFactory` method to create an outgoing call view:

```swift
viewFactory.makeOutgoingCallView(viewModel: callViewModel)
```

:::tip
Inside of your `ViewFactory` implementation you also get a powerful auto-complete to help you find the right functions to implement when looking to solve your use-case.
:::

You can run the app and tap the button to see the default view being rendered. To switch that out and use a custom view for that head over to your implementation of the `ViewFactory` (if you used the same naming, this is `MyViewFactory`).

Inside of the class add the following function:

```swift
func makeOutgoingCallView(viewModel: CallViewModel) -> some View {
    VStack(spacing: 20) {
        ProgressView()

        Text("Waiting for recipient to answer")
    }
}
```

The next step is...nothing. Just run the app and with that you've replace the custom implementation with your own. You even get the `CallViewModel` handed into the function call to use the available data in your custom views.

:::info
Why does that work? `ViewFactory` is just a `protocol` that has default implementations. In case you provide your own it takes these ones and otherwise falls back to the default ones.
:::

With that you have seen how to use your own implementations for views where you require more customization.

## Summary

In this guide you learned the different steps to take when using the built-in view components that the `StreamVideoSwiftUI` SDK has to offer. You learned to create your own implementation of the `ViewFactory` and how to use it.

In addition, you used custom UI making use of the properties in the `CallViewModel`. Lastly, with the powerful functionality of the `ViewFactory` you were able to replace the built-in components of the SDK with your custom implementations where needed.

Want to get started even more quickly? Check out how to add video to your application with [one single modifier](./video-call.md). Want to build something custom from scratch, only using our low-level client? Feel free to check out our guide on building an [application with audio rooms](./audio-room.md).

Have more questions? You can always reach us on [Twitter](http://twitter.com/getstream_io). Let us know what you are building with our SDKs, we love to hear your stories.
