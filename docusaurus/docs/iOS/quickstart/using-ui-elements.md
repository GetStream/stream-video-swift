---
title: Using UI elements
---

## Introduction

## Project setup and Stream Video SDK installation

This project requires a machine that is running _macOS_ as well as the latest _Xcode_ version to follow along the guide.

The first thing to do is to create a new _Xcode_ project (_File_ -> _New_ -> _Project_), select _iOS_ and _App_ and hit _Next_. Give it a name that you like and make sure that `SwiftUI` is selected under _Interface_. Save it somewhere on your machine.

// TODO: record a gif that shows the process

Now that the project is created you can add the dependency for the Stream Video SDK. In your newly created project, go to _File_ -> _Add Packages_. In the search bar on the top right, enter the URL to the SDK on GitHub (https://github.com/GetStream/stream-video-swift).

Select the package that pops up and make sure for _Dependency Rule_ to select _Branch_ -> `main`. When clicking on _Add Package_ it will take a moment but then you can select `StreamVideo` and `StreamVideoSwiftUI` in the list of packages that pop up. Hit _Add Package_ again and wait for the package loading to finish.

// TODO: record a gif that shows the process

:::note
The other package `StreamVideoUIKit` provides built-in UI elements for `UIKit`, ready for you to use and customize.
:::

With this, the project is set up and all dependencies are installed.

Before starting with the code of the application itself, let's take a look at how to initialize the Stream Video SDK. This is the low-level client that directly exposes the calling functionality to you so that you have full control. It requires a few parameters for setup:

- `apiKey`: when creating an application in the [Stream Dashboard](https://dashboard.getstream.io) you will be provided with an API key to identify your application.
- `user`: the `User` that you are logging in to the application. For this application, there are pre-built users provided.
- `token`: for the authentication with the Stream backend, a user token is required. In this example, the users will have non-expiring tokens provided for simplicity. Otherwise, this requires a backend, handling token generation.
- `videoConfig`: the `VideoConfig` object allows you to set some more advanced settings in the SDK.
- `tokenProvider`: once a token expires, this function will be called so that you can request a new token from your backend and update it. (Not necessary here, since non-expiring tokens are provided)

Now, in your `App` file (exact naming depends on the name of your project) you will add the initialization of the `StreamVideoUI` element. Paste this code into your app struct:

```swift
@State var streamVideo: StreamVideoUI?

init() {
    setupStreamVideo(with: "your-api-key", userCredentials: .demoUser)
}

private func setupStreamVideo(
    with apiKey: String,
    userCredentials: UserCredentials
) {
    streamVideo = StreamVideoUI(
        apiKey: apiKey,
        user: userCredentials.user,
        token: userCredentials.token,
        videoConfig: VideoConfig(joinVideoCallInstantly: true),
        tokenProvider: { result in
            // Call your networking service to generate a new token here.
            // When finished, call the result handler with either .success or .failure.
            result(.success(userCredentials.token))
        }
    )
}
```

:::note
The `apiKey` provided [here](https://github.com/GetStream/stream-video-ios-examples/blob/5ae414d09cbcff39e68b77c6527d8586d11d73fb/AudioRooms/AudioRooms/AppState.swift#L27) will use a Stream project that we set up for you. You can also use your application with your key. For that, visit the [Stream Dashboard](https://dashboard.getstream.io).
:::

This will not yet compile as the `UserCredentials` type does not exist yet. Therefore, create a new file called `UserCredentials` and add this code:

```swift
import Foundation
import StreamVideo

struct UserCredentials: Identifiable, Codable {
    var id: String {
        userInfo.id
    }
    let userInfo: User
    let token: UserToken
}
```

And in order to login a user, you will create a sample user as a static property of `UserCredentials`. Add the following code below your `UserCredentials` definition:

```swift
extension UserCredentials {
    static let demoUser = UserCredentials(
        user: User(
            id: "testuser",
            name: "Test User",
            imageURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/2/20/LukeTLJ.jpg")!,
            extraData: [:]
        ),
        token: try! UserToken(rawValue: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tZ29AdjAuMS4wIiwic3ViIjoidXNlci90ZXN0dXNlciIsImlhdCI6MTY2NjY5ODczMSwidXNlcl9pZCI6InRlc3R1c2VyIn0.h4lnaF6OFYaNPjeK8uFkKirR5kHtj1vAKuipq3A5nM0"
        )
    )
}

```

With that, the initial setup is done and you can start with the functionality.

## Add logic to determine current call state

The SDK is setup and now you want to be able to start and join calls and know when you receive calls. The `StreamVideoSwiftUI` SDK offers the `CallViewModel` that provides you with all necessary call-related logic.

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
    case .waitingRoom(let waitingRoomInfo):
        Text("In waiting room: \(waitingRoomInfo.callId)")
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
