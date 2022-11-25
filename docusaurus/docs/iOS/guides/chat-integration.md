---
title: Chat Integration
---

### Introduction

It's common for calling apps to have chat, as well as the opposite - chat apps to have a calling functionality. Stream's Chat and Video SDKs are compatible between each other, and can easily be integrated into an app.

You can find example integrations, for both our UIKit and SwiftUI SDKs, in our sample apps [repo](https://github.com/GetStream/stream-video-ios-examples).

In those samples, we provide a `StreamWrapper` class, that handles the creation of the different clients and UI objects for both chat and video.

### Adding chat into video

The simplest way to add chat to an existing video calling app is to extend the call controls with an additional chat icon. To do this, you should implement the `makeCallControlsView` in the `ViewFactory` in the Video SDK:

```swift
func makeCallControlsView(viewModel: CallViewModel) -> some View {
    ChatCallControls(viewModel: viewModel)
}
```

Here's an example implementation of the `ChatCallControls`, that handles the display of the chat inside it.

```swift
struct ChatCallControls: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    private let size: CGFloat = 50
    
    @ObservedObject var viewModel: CallViewModel
    
    @StateObject private var chatHelper = ChatHelper()
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    
    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack {
            EqualSpacingHStack(views: [
                AnyView(
                    Button(
                        action: {
                            withAnimation {
                                chatHelper.chatShown.toggle()
                            }
                        },
                        label: {
                            CallIconView(
                                icon: Image(systemName: "message"),
                                size: size,
                                iconStyle: chatHelper.chatShown ? .primary : .transparent
                            )
                            .overlay(
                                chatHelper.unreadCount > 0 ?
                                    TopRightView(content: {
                                        UnreadIndicatorView(unreadCount: chatHelper.unreadCount)
                                    })
                                : nil
                            )
                        }
                    ))
                // Other unrelated code skipped. Please check the repo for the complete implementation.
            ])
            
            if chatHelper.chatShown {
                if let channelController = chatHelper.channelController {
                    ChatChannelView(viewFactory: ChatViewFactory.shared, channelController: channelController)
                        .frame(height: chatHeight)
                        .preferredColorScheme(.dark)
                        .onAppear {
                            chatHelper.markAsRead()
                        }
                } else {
                    Spacer()
                    Text("Chat not available")
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: chatHelper.chatShown ? chatHeight + 100 : 100)
        .background(
            colors.callControlsBackground
                .cornerRadius(16)
                .edgesIgnoringSafeArea(.all)
        )
        .onReceive(viewModel.$callParticipants, perform: { output in
            if viewModel.callParticipants.count > 1 {
                chatHelper.update(memberIds: Set(viewModel.callParticipants.map(\.key)))
            }
        })
    }
    
    private var chatHeight: CGFloat {
        (UIScreen.main.bounds.height / 3 + 50)
    }
    
}

struct EqualSpacingHStack: View {
    
    var views: [AnyView]
    
    var body: some View {
        HStack(alignment: .top) {
            ForEach(0..<views.count, id:\.self) { index in
                Spacer()
                views[index]
                Spacer()
            }
        }
    }   
}
```

Note that both the Video and Chat SDK should be setup with an API key and token, before displaying this view.

### Adding video into a chat app

The simplest way to add a video in a chat app is to customize the chat channel header and add a call icon in the top right corner.

Here's an example how to do that:

```swift
@MainActor
func makeChannelHeaderViewModifier(for channel: ChatChannel) -> some ChatChannelHeaderViewModifier {
    CallHeaderModifier(channel: channel, callViewModel: callViewModel)
}
```

Where the `CallHeaderModifier` looks like this:

```swift
struct CallHeaderModifier: ChatChannelHeaderViewModifier {
    
    var channel: ChatChannel
    var callViewModel: CallViewModel
        
    func body(content: Content) -> some View {
        content.toolbar {
            CallChatChannelHeader(channel: channel, callViewModel: callViewModel)
        }
    }
    
}

public struct CallChatChannelHeader: ToolbarContent {
    @Injected(\.fonts) private var fonts
    @Injected(\.utils) private var utils
    @Injected(\.colors) private var colors
    @Injected(\.chatClient) private var chatClient
    
    private var currentUserId: String {
        chatClient.currentUserId ?? ""
    }
    
    private var shouldShowTypingIndicator: Bool {
        !channel.currentlyTypingUsersFiltered(currentUserId: currentUserId).isEmpty
            && utils.messageListConfig.typingIndicatorPlacement == .navigationBar
            && channel.config.typingEventsEnabled
    }
    
    private var onlineIndicatorShown: Bool {
        !channel.lastActiveMembers.filter { member in
            member.id != chatClient.currentUserId && member.isOnline
        }
        .isEmpty
    }
    
    public var channel: ChatChannel
    @ObservedObject var callViewModel: CallViewModel
    
    public init(
        channel: ChatChannel,
        callViewModel: CallViewModel
    ) {
        self.channel = channel
        self.callViewModel = callViewModel
    }
    
    public var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            ChannelTitleView(
                channel: channel,
                shouldShowTypingIndicator: shouldShowTypingIndicator
            )
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                let participants = channel.lastActiveMembers.map { member in
                    User(
                        id: member.id,
                        name: member.name,
                        imageURL: member.imageURL,
                        extraData: [:]
                    )
                }
                callViewModel.startCall(callId: UUID().uuidString, participants: participants)
            } label: {
                Image(systemName: "phone.fill")
            }
        }
    }
}
```

It's important that we're adding a unique call id in the `startCall` method, to invoke the ringing each time.

In order to listen to incoming calls, you should attach the `CallModifier` to the parent view (e.g. the `ChatChannelListView`):

```swift
ChatChannelListView(viewFactory: ChatViewFactory.shared)
    .modifier(CallModifier(viewModel: callViewModel))
```