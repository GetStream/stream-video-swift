---
title: Video Call
---

### Video Call quickstart

In this quickstart you'll build a video call experience similar to Zoom or messenger.

- Stream's video edge network ensures a reliable call experience with low latency
- You can scale to thousands of participants
- Our Dynascale technology automatically adjusts the quality of video, codecs and resolutions.
- This saves you months of work compared to other providers.
- Opus RED creates a reliable audio connection

IMAGE PREVIEW HERE

Alright, let's get started. If you want to see a fully fledged example, check out this sample app.

### Your First App with StreamVideo

Before starting, make sure you have installed StreamVideo as explained in the [Installation](../../basics/install.md) section.

### Setting up the StreamVideo object

The simplest way to get started is to use our default SwiftUI components, that can add calling support to your views with only few lines of code.

First, we need to create the `StreamVideoUI`, with an API key and the user who's logged in your app.

```swift
streamVideo = StreamVideoUI(
    apiKey: apiKey,
    user: userCredentials.user,
    token: userCredentials.token,
    tokenProvider: { result in
        // Call your networking service to generate a new token here.
        // When finished, call the result handler with either .success or .failure.
        result(.success(userCredentials.token))
    }
)
```

`StreamVideoUI` is the main access point to our SwiftUI SDK. It's created with the following values:

- `apiKey` - your unique API key that's available in your dashboard.
- `user` - the `UserInfo` struct that contains information about the currently logged in user.
- `token` - the current user's `Token`.
- `tokenProvider` - called when a token is expired. We strongly recommend that you use token that expires (for security reasons), and provide a way for the SDK to fetch a new token when the current one expires, with the `tokenProvider` closure.

Depending on your app architecture, you can keep the `StreamVideoUI` in a place where the lifecycle is tied to the lifecycle of the currently logged in user.

In this example, for simplicity, we will add it in the SwiftUI `App` file, as a `@State` variable, and set it up on `init`. In your app, you should setup the `StreamVideoUI` object after you login your user.

```swift
import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

@main
struct VideoTutorialApp: App {

    @State var streamVideo: StreamVideoUI?

    init() {
        setupStreamVideo(with: "key1", userCredentials: .demoUser)
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

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

In this example, we're using a hardcoded demo user, with a token that never expires:

```swift
struct UserCredentials {
    let user: User
    let token: UserToken
}

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

With this, our `StreamVideoUI` object is setup, and the UI components are ready to be used inside your app.

Let's see an example on how to invoke a call. The UI would be simple - just a text field to enter the call id and a button to start the call.

```swift
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct ContentView: View {

    @StateObject var callViewModel = CallViewModel()
    @State var callId = ""

    var body: some View {
        VStack {
            TextField("Insert a call id", text: $callId)
                .textFieldStyle(.roundedBorder)
                .padding()

            Button {
                resignFirstResponder()
                callViewModel.startCall(
                    callId: callId,
                    participants: [/* Your list of participants goes here. */]
                )
            } label: {
                Text("Start a call")
            }
        }
        .padding()
        .modifier(CallModifier(viewModel: callViewModel))
    }
}
```

Here, you need to create the `CallViewModel`, which deals with the call related state and provides access to features like muting audio/video, changing the camera, starting / stopping calls etc.

In the example, we're also setting a `CallModifier` to the view. With this modifier, the calling support is added to your view. The modifier handles everything from reporting incoming / outgoing calls to showing the appropriate UI based on the call state.

### Permissions

Making a video call requires the usage of the camera and the microphone of the device. Therefore, you need to request permissions to use them in your app. In order to do this, you will need to add the following keys and values in your `Info.plist` file.

`Privacy - Camera Usage Description` - "Your_app_name requires camera access in order to capture and transmit video"
`Privacy - Microphone Usage Description` - "Your_app_name requires microphone access in order to capture and transmit audio"

Note that you should replace "Your_app_name" (or also use your custom strings instead).

With this, you should be able to test a video call between two devices. Note that you need to specify the participants list in the `startCall` method. Also, the call id should be the same on the different devices that are part of the call.
