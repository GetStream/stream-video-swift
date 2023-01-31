---
title: Chat Integration
---

## Introduction

It's common for calling apps to have chat, as well as the opposite - chat apps to have a calling functionality. Stream's Chat and Video SDKs are perfectly compatible between each other, and can easily be integrated into an app.

:::tip
You can find example integrations, for both our UIKit and SwiftUI SDKs, in our sample apps [repository](https://github.com/GetStream/stream-video-ios-examples).
:::

In the samples, we provide a `StreamWrapper` class, that handles the creation of the different clients and UI objects for both chat and video.

## Adding chat into video

In this guide you will take a video-based application and add chat functionality with the Stream Chat SDK on top of it. Here is an example of what the end result will look like:

// TODO: add sample video

:::info
The starting point for this guide is a functioning video calling application. If you don't have one and want to follow along, feel free to do our [step-by-step tutorial](../tutorial/tutorial.md) first.
:::

The simplest way to add chat to an existing video calling app is to extend the call controls with an additional chat icon. To do this, you should implement the `makeCallControlsView` in your custom implementation of the `ViewFactory` from the Stream Video SDK:

```swift
class VideoViewFactory: ViewFactory {

    /* ... Previous code skipped. */

    // highlight-start
    func makeCallControlsView(viewModel: CallViewModel) -> some View {
        ChatCallControls(viewModel: viewModel)
    }
    // highlight-end
}

```

Inside of the `ChatCallControls` you will use a `ToggleChatButton` that looks like this:

```swift
var toggleChatButton = Button(
    action: {
        // highlight-next-line
        // 1. Toggle chat window
        withAnimation {
            chatHelper.chatShown.toggle()
        }
    },
    label: {
        // highlight-next-line
        // 2. Show button
        CallIconView(
            icon: Image(systemName: "message"),
            size: size,
            iconStyle: chatHelper.chatShown ? .primary : .transparent
        )
        // highlight-next-line
        // 3. Overlay unread indicator
        .overlay(
            chatHelper.unreadCount > 0 ?
                TopRightView(content: {
                    UnreadIndicatorView(unreadCount: chatHelper.unreadCount)
                })
            : nil
        )
    }
))
```

The code does three interesting things (see the numbered comments):

1. On tapping the button it toggles the chat window
2. Showing a button that indicates that there is a chat to open
3. It overlays an unread indicator when there's new chat messages

Here's the (simplified, [see full version](https://github.com/GetStream/stream-video-ios-examples/blob/main/VideoWithChat/VideoWithChat/Sources/ChatCallControls.swift)) implementation of the `ChatCallControls`, that handles the display of the chat inside it.

```swift
struct ChatCallControls: View {

    @ObservedObject var viewModel: CallViewModel

    @StateObject private var chatHelper = ChatHelper()

    var toggleChatButton = Button(/* button you just created */)

    public var body: some View {
        // highlight-next-line
        // 1. Arrange code in VStack
        VStack {
            HStack {
                toggleChatButton

                // Other unrelated code skipped. Check repository complete code.
            }

            // highlight-next-line
            // 2. If chat is activated, show the ChatChannelView
            if chatHelper.chatShown {
                if let channelController = chatHelper.channelController {
                    ChatChannelView(
                        viewFactory: ChatViewFactory.shared,
                        channelController: channelController
                    )
                        .frame(height: UIScreen.main.bounds.height / 3 + 50)
                        .onAppear {
                            chatHelper.markAsRead()
                        }
                } else {
                    Text("Chat not available")
                }
            }
        }
        /* more modifiers */
        // highlight-next-line
        // 3. Listen to changes in call participants and update the UI accordingly
        .onReceive(viewModel.$callParticipants, perform: { output in
            if viewModel.callParticipants.count > 1 {
                chatHelper.update(memberIds: Set(viewModel.callParticipants.map(\.key)))
            }
        })
    }
}
```

Again, the lines that are marked do the following:

1. The entire code is wrapped in a `VStack` to show content vertically, with chat being slid in from the bottom, once shown. The buttons on the other hand are wrapped in a `HStack`.
2. If `chatHelper.chatShown` is true and a `channelController` can be retrieved, the `ChatChannelView` from the Stream Chat SDK is used to display chat.
3. Subscribing to changes in the `callParticipants` allows to make sure the UI is always up-to-date.

Note that both the Video and Chat SDK should be setup with an API key and token, before displaying this view.

:::tip
Not sure how to do this? Start [here for video](https://staging.getstream.io/video/docs/ios/basics/authentication/) and [here for chat](https://getstream.io/chat/docs/sdk/ios/swiftui/getting-started/#creating-the-swiftui-context-provider-object).
:::

## Adding video into a chat app

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

In order to listen to incoming calls, you should attach the `CallModifier` to the parent view (for example the `ChatChannelListView`):

```swift
ChatChannelListView(viewFactory: ChatViewFactory.shared)
    .modifier(CallModifier(viewModel: callViewModel))
```
