---
title: Lobby View
---

The lobby view shows a preview of the call, and it lets users configure their audio/video before joining a call. Our SwiftUI SDK already provides a `LobbyView` that you can directly use in your apps.

In this cookbook, we will see how to implement this by yourself, while relying on some lower-level components from the StreamVideo SDK.

### Required dependencies

If you want to reuse the logic from our SDK, you would need three non-UI components:
- `CallViewModel` - the call view model used for managing the calls state.
- `LobbyViewModel` - provides access to features needed for the loby view.
- `MicrophoneChecker` - checks the audio state of the current user's device.

We will add these as variables in our `CustomLobbyView`.


### Custom LobbyView

First, let's define the `CustomLobbyView`, with the required dependencies:

```swift
public struct CustomLobbyView: View {
    
    @ObservedObject var callViewModel: CallViewModel
    @StateObject var viewModel = LobbyViewModel()
    @StateObject var microphoneChecker = MicrophoneChecker()
    
    var callId: String
    var callType: String
    var callParticipants: [User]
        
    public init(
        callViewModel: CallViewModel,
        callId: String,
        callType: String,
        callParticipants: [User]
    ) {
        _callViewModel = ObservedObject(wrappedValue: callViewModel)
        self.callId = callId
        self.callType = callType
        self.callParticipants = callParticipants
    }
    
    public var body: some View {
        CustomLobbyContentView(
            callViewModel: callViewModel,
            viewModel: viewModel,
            microphoneChecker: microphoneChecker,
            callId: callId,
            callType: callType,
            callParticipants: callParticipants
        )
    }
}
```

Next, let's define the `CustomLobbyContentView`:

```swift
struct LobbyContentView: View {
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    @Injected(\.streamVideo) var streamVideo
    
    @ObservedObject var callViewModel: CallViewModel
    @ObservedObject var viewModel: LobbyViewModel
    @ObservedObject var microphoneChecker: MicrophoneChecker
    
    var callId: String
    var callType: String
    var callParticipants: [User]
    
    var body: some View {
        GeometryReader { reader in
            ZStack {
                VStack {
                    Spacer()
                    Text("Waiting room")
                        .font(.title)
                        .foregroundColor(colors.text)
                        .bold()
                    
                    CameraCheckView(
                        viewModel: viewModel,
                        callViewModel: callViewModel,
                        microphoneChecker: microphoneChecker,
                        availableSize: reader.size
                    )
                    
                    if viewModel.connectionQuality == .poor {
                        Text("Please check your internet connection.")
                            .font(.caption)
                            .foregroundColor(colors.text)
                    }
                    
                    if !microphoneChecker.hasDecibelValues {
                        Text("Your mic doesn't seem to be working.")
                            .font(.caption)
                            .foregroundColor(colors.text)
                    }
                                        
                    CallSettingsView(callViewModel: callViewModel)
                    
                    JoinCallView(
                        callViewModel: callViewModel,
                        callId: callId,
                        callType: callType,
                        callParticipants: callParticipants
                    )
                }
                .padding()
                
                TopRightView {
                    Button {
                        callViewModel.callingState = .idle
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(colors.text)
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(colors.lobbyBackground.edgesIgnoringSafeArea(.all))
        }
        .onReceive(callViewModel.$edgeServer, perform: { edgeServer in
            viewModel.latencyURL = edgeServer?.latencyURL
        })
        .onAppear {
            viewModel.startCamera(front: true)
        }
        .onDisappear {
            viewModel.stopLatencyChecks()
        }
    }
}
```

Next, let's explore the `CameraCheckView`, which checks the video/audio capabilities of the current user:

```swift
struct CameraCheckView: View {
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    @Injected(\.streamVideo) var streamVideo
    
    @ObservedObject var viewModel: LobbyViewModel
    @ObservedObject var callViewModel: CallViewModel
    @ObservedObject var microphoneChecker: MicrophoneChecker
    var availableSize: CGSize
    
    var body: some View {
        Group {
            if let image = viewModel.viewfinderImage, callViewModel.callSettings.videoOn {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: availableSize.width - 32, height: availableSize.height / 2)
                    .cornerRadius(16)
            } else {
                ZStack {
                    Rectangle()
                        .fill(colors.lobbySecondaryBackground)
                        .frame(width: availableSize.width - 32, height: availableSize.height / 2)
                        .cornerRadius(16)

                    UserAvatar(imageURL: streamVideo.user.imageURL, size: 80)
                }
                .opacity(callViewModel.callSettings.videoOn ? 0 : 1)
                .frame(width: availableSize.width - 32, height: availableSize.height / 2)
            }
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    MicrophoneCheckView(
                        decibels: microphoneChecker.decibels,
                        microphoneOn: callViewModel.callSettings.audioOn,
                        hasDecibelValues: microphoneChecker.hasDecibelValues
                    )
                    Spacer()
                    ConnectionQualityIndicator(connectionQuality: viewModel.connectionQuality)
                }
                .padding()
            }
        )
    }
}
```

Here, we are using the `MicrophoneCheckView` and the `ConnectionQualityIndicator` from the SwiftUI SDK. They display the microphone state and the network quality of the current user. You can implement your own versions of these views, in case you want a different UI.

Next, we have the `CallSettingsView`, which shows the controls for changing the audio and video state of the user in the call:

```swift
struct CallSettingsView: View {
    
    @Injected(\.images) var images
    
    @ObservedObject var callViewModel: CallViewModel
    
    private let iconSize: CGFloat = 50
    
    var body: some View {
        HStack(spacing: 32) {
            Button {
                let callSettings = callViewModel.callSettings
                callViewModel.callSettings = CallSettings(
                    audioOn: !callSettings.audioOn,
                    videoOn: callSettings.videoOn,
                    speakerOn: callSettings.speakerOn
                )
            } label: {
                CallIconView(
                    icon: (callViewModel.callSettings.audioOn ? images.micTurnOn : images.micTurnOff),
                    size: iconSize,
                    iconStyle: (callViewModel.callSettings.audioOn ? .primary : .transparent)
                )
            }

            Button {
                let callSettings = callViewModel.callSettings
                callViewModel.callSettings = CallSettings(
                    audioOn: callSettings.audioOn,
                    videoOn: !callSettings.videoOn,
                    speakerOn: callSettings.speakerOn
                )
            } label: {
                CallIconView(
                    icon: (callViewModel.callSettings.videoOn ? images.videoTurnOn : images.videoTurnOff),
                    size: iconSize,
                    iconStyle: (callViewModel.callSettings.videoOn ? .primary : .transparent)
                )
            }
        }
        .padding()
    }
}
```

In this view, we are using the `CallIconView` component from the SwiftUI SDK, for displaying the mic and camera icons. This view updates the `CallSettings` of the `CallViewModel`, based on the user's selections.

Finally, we need the `JoinCallView`, which displays the button that allows users to join the call:

```swift
struct JoinCallView: View {
    
    @Injected(\.colors) var colors
    @ObservedObject var callViewModel: CallViewModel
    
    var callId: String
    var callType: String
    var callParticipants: [User]
    
    var body: some View {
        VStack(spacing: 16) {            
            Button {
                callViewModel.startCall(callId: callId, type: callType, members: callParticipants)
            } label: {
                Text("Join Call")
                    .bold()
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(colors.primaryButtonBackground)
            .cornerRadius(16)
            .foregroundColor(.white)
        }
        .padding()
        .background(colors.lobbySecondaryBackground)
        .cornerRadius(16)
    }
}
``` 

With that, we have a similar implementation to our default `LobbyView`, while reusing most of our low-level components and capabilities. Since this would be a custom implementation in your own app, you can easily modify it to suit your needs.
