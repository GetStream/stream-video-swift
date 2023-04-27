---
title: Chat Integration
---

## Introduction

:::warning
Still to add:

- reference to the starter projects
- explanation of the StreamWrapper class

:::

It's common for calling apps to have chat, as well as the opposite - chat apps to have a calling functionality. Stream's Chat and Video SDKs are perfectly compatible between each other, and can easily be integrated into an app.

:::tip
You can find example integrations, for both our UIKit and SwiftUI SDKs, in our sample apps [repository](https://github.com/GetStream/stream-video-ios-examples).
:::

In the samples, we provide a `StreamWrapper` class, that handles the creation of the different clients and UI objects for both chat and video.

## Adding chat into video

In this guide you will take a video-based application and add chat functionality with the Stream Chat SDK on top of it. Here is an example of what the end result will look like:

// TODO: add sample video

:::info
The starting point for this guide is a functioning video calling application. If you don't have one and want to follow along, feel free to do our [step-by-step tutorial](../../basics/tutorial) first.
:::

The simplest way to add chat to an existing video calling app is to extend the call controls with an additional chat icon. To do this, implement the `makeCallControlsView` in your custom implementation of the `ViewFactory` from the Stream Video SDK (in our case it's called `VideoWithChatViewFactory`, see [here](https://github.com/GetStream/stream-video-ios-examples/blob/main/VideoWithChat/VideoWithChat/Sources/VideoWithChatViewFactory.swift)):

```swift
class VideoWithChatViewFactory: ViewFactory {

    /* ... Previous code skipped. */

    // highlight-start
    func makeCallControlsView(viewModel: CallViewModel) -> some View {
        ChatCallControls(viewModel: viewModel)
    }
    // highlight-end
}

```

Create a new SwiftUI view called `ChatCallControls` and add the code for the `ToggleChatButton` to the file (for example at the bottom):

```swift
struct ToggleChatButton: View {

    @ObservedObject var chatHelper: ChatHelper

    var body: some View {
        Button {
            // highlight-next-line
            // 1. Toggle chat window
            withAnimation {
                chatHelper.chatShown.toggle()
            }
        }
        label: {
            // highlight-next-line
            // 2. Show button
            CallIconView(
                icon: Image(systemName: "message"),
                size: 50,
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
    }
}
```

The code does three interesting things (see the numbered comments):

1. On tapping the button it toggles the chat window
2. Showing a button that indicates that there is a chat to open
3. It overlays an unread indicator when there's new chat messages

Here's the (simplified, [see full version](https://github.com/GetStream/stream-video-ios-examples/blob/main/VideoWithChat/VideoWithChat/Sources/ChatCallControls.swift)) implementation of the `ChatCallControls` itself, that handles the display of the chat inside it.

```swift
struct ChatCallControls: View {

    @ObservedObject var viewModel: CallViewModel

    @StateObject private var chatHelper = ChatHelper()

    public var body: some View {
        // highlight-next-line
        // 1. Arrange code in VStack
        VStack {
            HStack {
                ToggleChatButton(chatHelper: chatHelper)

                // Unrelated code skipped. Check repository for complete code:
                // https://github.com/GetStream/stream-video-ios-examples/blob/main/VideoWithChat/VideoWithChat/Sources/ChatCallControls.swift
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
        .frame(maxWidth: .infinity)
        .frame(height: chatHelper.chatShown ? (UIScreen.main.bounds.height / 3 + 50) + 100 : 100)
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

In this example, you will take a chat application and add video capabilities to it. Here is how the end result will look like:

// TODO: add sample video

:::info
The starting point for this guide is a chat application built with the Stream Chat SDK. Not sure were to start? Follow along [this step-by-step tutorial](https://getstream.io/tutorials/swiftui-chat/) and you are ready for this guide.
:::

The simplest way to add video calling in a chat app is to customize the chat channel header and add a call icon in the top right corner.

To do this, you need to implement the `makeChannelHeaderViewModifier` function in your custom implementation of the `ViewFactory` from the Stream Chat SDK:

```swift
@MainActor
func makeChannelHeaderViewModifier(for channel: ChatChannel) -> some ChatChannelHeaderViewModifier {
    CallHeaderModifier(channel: channel, callViewModel: callViewModel)
}
```

For this code to compile you need a `CallHeaderModifier` that looks like this:

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
```

This creates a toolbar with the content of type `CallChatChannelHeader` that can be created like this (this is simplified code, find the [full version here](https://github.com/GetStream/stream-video-ios-examples/blob/main/ChatWithVideo/ChatWithVideo/ChatViewFactory.swift)):

```swift
public struct CallChatChannelHeader: ToolbarContent {

    private var shouldShowTypingIndicator: Bool { /* ... */ }

    public var channel: ChatChannel
    @ObservedObject var callViewModel: CallViewModel

    public var body: some ToolbarContent {
        // highlight-next-line
        // 1. Add the title of the channel in the center position
        ToolbarItem(placement: .principal) {
            ChannelTitleView(
                channel: channel,
                shouldShowTypingIndicator: shouldShowTypingIndicator
            )
        }
        // highlight-next-line
        // 2. Add a trailing item to the toolbar with a phone icon
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                // highlight-next-line
                // 3. Create and start a call with the participants from the channel
                let participants = channel.lastActiveMembers.map { member in
                    User(
                        id: member.id,
                        name: member.name,
                        imageURL: member.imageURL,
                        customData: [:]
                    )
                }
                callViewModel.startCall(callId: UUID().uuidString, type: "default", participants: participants)
            } label: {
                Image(systemName: "phone.fill")
            }
        }
    }
}
```

The interesting code steps here are:

1. The header has the title (and typing indicator) of the channel in the center position (indicated by `placement: .principal`)
2. To initiate a call a trailing icon in the form of a phone is added
3. The call is initiated with the `lastActiveMembers` of the `channel` item and started with the convenient `startCall` method of the `callViewModel`

:::note
It's important that we're adding a unique call id (for example with the `UUID().uuidString`) in the `startCall` method, to invoke the ringing each time.
:::

In order to listen to incoming calls, you should attach the `CallModifier` to the parent view (for example the `ChatChannelListView`):

```swift
ChatChannelListView(viewFactory: ChatViewFactory.shared)
    .modifier(CallModifier(viewModel: callViewModel))
```

With that you have added video calling to a functioning Stream Chat application. If you want to have a look at other examples, feel free to check out [our iOS samples repository](https://github.com/GetStream/stream-video-ios-examples).
