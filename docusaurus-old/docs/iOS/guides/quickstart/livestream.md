---
title: Livestream
---

### Livestream Quickstart

In this quickstart we'll build a livestreaming experience that's similar to Twitch.

- The livestream will run on Stream's Edge network of servers around the world
- You can use ultra low latency (WebRTC) based livestreaming or HLS (slight delay, but better buffering)
- We'll show how to publish to the livestream from your phone
- Stream enables you to scale to millions of viewers
- You can have multiple active participants in the livestream

Let's get started. If you want to see a fully fledged example, check out this [sample app](https://github.com/GetStream/stream-video-ios-examples/tree/main/LivestreamingSample).

### Step 1 - Prep

Before going through this tutorial, please make sure that you have the required setup:
- `StreamVideo` SDK added to your project
- Auth setup and user login
- Required permissions for camera and microphone

### Step 2 - Publishing your livestream

In a livestream experience, there are two types of users: the ones that stream their content, and the ones that join in and watch the content.

#### Publish your camera's video feed to a call

Let's see how you can publish your livestream. First, you need to create a call and join it.

In our sample app, we provide a UI to allow the user to enter the call id, and a button to create the livestream. When that button is tapped, we call the following method in the `LivestreamHomeViewModel`:

```swift
func createLivestream() {
    guard !callId.isEmpty else { return }
    let currentUser = streamVideo.user
    let call = streamVideo.makeCall(callType: .default, callId: callId, members: [currentUser])
    Task {
        do {
            loading = true
            try await call.join()
            loading = false
            self.call = call
        } catch {
            loading = false
        }
    }
}
```

The code above creates a call, and joins it.

In our `LivestreamHomeView`, we are listening to changes of the `call` property in the view model. Whenever we have an active call, we display the `LivestreamHostView`:

```swift
if let call = viewModel.call {
    LivestreamHostView(call: call) {
        call.leave()
        Task {
            try? await call.stopBroadcasting()
        }
        viewModel.call = nil
    }
}
```

The closure passed to the `LivestreamHostView` is invoked when the host leaves the call (we will get back to that later in the tutorial).

Next, let's see the contents of the `LivestreamHostView`. Note that some UI code and modifiers are removed to focus on the most important parts (please refer to our repo for the full implementation):

```swift
var body: some View {
    VStack {
        HStack {
            Text("Live")
                .opacity(call.state?.broadcasting == true ? 1 : 0)
        }
        
        GeometryReader { reader in
            if let first = participants.first {
                VideoCallParticipantView(
                    participant: first,
                    availableSize: reader.size,
                    contentMode: .scaleAspectFit,
                    edgesIgnoringSafeArea: .bottom
                ) { participant, view in
                        view.handleViewRendering(for: participant) { size, participant in }
                }
            } else {
                Color(UIColor.secondarySystemBackground)
            }
        }
        .padding()
        
        ZStack {
            HStack {
                if call.state?.broadcasting == true {
                    Button {
                        Task {
                            loading = true
                            try await call.stopBroadcasting()
                        }
                    } label: {
                        Text("Stop stream")
                    }
                } else {
                    Button {
                        Task {
                            loading = true
                            try await call.startBroadcasting()
                        }
                    } label: {
                        Text("Start stream")
                    }
                }
                
                Button {
                    onLeaveCall()
                } label: {
                    Text("Leave call")
                }
            }
            .opacity(loading ? 0 : 1)
            
            ProgressView()
                .opacity(loading ? 1 : 0)
        }
        .padding()
    }
    .onChange(of: call.state?.broadcasting, perform: { state in
        loading = false
    })
    .onAppear {
        call.startCapturingLocalVideo()
    }
    
}
```

We take the participants from the call object, and we sort them with the default sort comparators:

```swift
private var participants: [CallParticipant] {
    return call.participants.map(\.value).sorted(using: defaultComparators)
}
```

Then, we present the first participant in a `VideoCallParticipantView`, which shows the camera feed of that user. You can build a different UI here, based on the requirements of your app:

```swift
VideoCallParticipantView(
    participant: first,
    availableSize: reader.size,
    contentMode: .scaleAspectFit,
    edgesIgnoringSafeArea: .bottom
) { participant, view in
    view.handleViewRendering(for: participant) { size, participant in }
}
```

When the call is started, there's still no livestream available. We need to explicitly start it, by calling the `startBroadcasting` method from the `call` object:

```swift
try await call.startBroadcasting()
```

When this method is called, it takes few seconds until the broadcasting is started. You can show a loading spinner until the `call`'s state is updated to `broadcasting`.

You can also directly listen to the broadcasting events in the call, using the `AsyncStream` of `broadcastingEvents` in the `call` object.

When the call is being broadcasted, we show a "Stop stream" button to the hosts, to allow them to stop broadcasting:

```swift
if call.state?.broadcasting == true {
    Button {
        Task {
            loading = true
            try await call.stopBroadcasting()
        }
    } label: {
        Text("Stop stream")
    }
} else {
    Button {
        Task {
            loading = true
            try await call.startBroadcasting()
        }
    } label: {
        Text("Start stream")
    }
}
```

### Step 3 - Show the video using HLS

There are two ways how the consumers can watch the video. The first one is via WebRTC, where you will join the call with the provided id, similarly to how it was created. The seconds one is via HLS streaming. 

HLS is cheaper and has good buffering. However, it has a delay of around 15 seconds. WebRTC is ultra low latency, but has a higher cost and worse buffering.

Let's see how to watch an HLS stream. First, let's watch a call with a particular id, and check if it's being broadcasted.

```swift
func watchCall() {
    guard !watchedCallId.isEmpty else { return }
    callsController = makeCallsController()
    Task {
        try await callsController?.loadNextCalls()
        watchedCall = callsController?.calls.first
        hlsURL = URL(string: watchedCall?.hlsPlaylistUrl ?? "")
    }
}

private func makeCallsController() -> CallsController {
    let sortParam = CallSortParam(direction: .descending, field: .createdAt)
    let filters: [String: RawJSON] = ["id": .dictionary(["$eq": .string(watchedCallId)])]
    let callsQuery = CallsQuery(sortParams: [sortParam], filters: filters, watch: true)
    return streamVideo.makeCallsController(callsQuery: callsQuery)
}
```

In the UI part, we allow the users to enter a call id they want to watch. In your apps, you would probably paginate through calls, using the `CallsController`. For simplicity, in this example, we are querying and watching an exact call, with the call id provided.

Next, when we have the watched call, we are extracting the `hlsPlaylistUrl`. If it's available, we show the user a button that will let them join the livestream.

```swift
HStack {
    Text("\(watchedCall.callCid)")
    Spacer()
    if let url = viewModel.hlsURL {
    	NavigationLink {
    		LazyView(
    			PlayerView(url: url)
    		)
        } label: {
        	Text("Join livestream")
        		.foregroundColor(.white)
        		.padding(.all, 8)
        }
        .background(Color.blue)
        .cornerRadius(8)
    }
}
```

Additionally, we listen to the broadcasting events, in case the broadcasting was started after we loaded the call:

```swift
private func subscribeForBroadcastEvents() {
    broadcastEventsTask?.cancel()
    guard let callsController else { return }
    broadcastEventsTask = Task {
        for await event in callsController.broadcastEvents() {
            if let event = event as? BroadcastingStartedEvent {
                let url = event.hlsPlaylistUrl
                self.hlsURL = URL(string: url)
            } else if event is BroadcastingStoppedEvent {
                self.hlsURL = nil
            }
        }
    }
}
```

#### Player View

Finally, let's see the `PlayerView`, which will present the HLS livestream. SwiftUI's `VideoPlayer` is able to present an HLS stream, with the file format of m3u8.

```swift
struct PlayerView: View {
    
    @StateObject var playerHelper: PlayerHelper
    
    init(url: URL) {
        _playerHelper = StateObject(wrappedValue: PlayerHelper(url: url))
    }
        
    var body: some View {
        ZStack {
            VideoPlayer(player: playerHelper.player)
                .opacity(playerHelper.waitingForStreamStart ? 0 : 1)
            
            VStack(spacing: 16) {
                Text("Waiting for live stream to start")
                    .foregroundColor(.white)
                ProgressView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .opacity(playerHelper.waitingForStreamStart ? 1 : 0)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                playerHelper.setupPlayer()
            })
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
}
```

In the sample, we are also using a `PlayerHelper`. This class helps us to show a different UI while the stream is still not loaded, as well as helps us automatically react to rate changes by listening to the `AVPlayer.rateDidChangeNotification`. Please check the concrete implementation in our repo, for more details.

With that, you can now both broadcast and join livestreams, using our `StreamVideo` SDK.
