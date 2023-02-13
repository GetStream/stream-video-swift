---
title: Using UI elements
---

# Introduction

# Adding Stream Video to your project

- add dependency
- create private `func` in ...App (don't forget the imports for `StreamVideo` and `StreamVideoSwiftUI`)
- need to pick an API key for that from the Stream Dashboard
- call in `init`
- create the `UserCredentials` and the `demoUser`

# Add logic to determine current call state

- initialize `CallViewModel` in ContentView as `@StateObject`
- create a `switch` over the `callViewModel.callingState`

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
    case .waitingRoom(let waitingRoomInfo):
        Text("In waiting room: \(waitingRoomInfo.callId)")
    }
```

# Create and use the ViewFactory

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

# Custom view injection into the ViewFactory

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

# Summary

In this guide you learned the different steps to take when using the built-in view components that the `StreamVideoSwiftUI` SDK has to offer. You learned to create your own implementation of the `ViewFactory` and how to use it.

In addition, you used custom UI making use of the properties in the `CallViewModel`. Lastly, with the powerful functionality of the `ViewFactory` you were able to replace the built-in components of the SDK with your custom implementations where needed.

Want to get started even more quickly? Check out how to add video to your application with [one single modifier](./video-call.md). Want to build something custom from scratch, only using our low-level client? Feel free to check out our guide on building an [application with audio rooms](./audio-room.md).

Have more questions? You can always reach us on [Twitter](http://twitter.com/getstream_io). Let us know what you are building with our SDKs, we love to hear your stories.
