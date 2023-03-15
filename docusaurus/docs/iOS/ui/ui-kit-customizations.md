---
title: UIKit Customizations
---

In order to enable a smoother video integration in your UIKit projects, we provide UIKit wrappers over our SwiftUI components. In the following section, we will see how we can customize them.

### View Factory Customizations

As described in the [customizing views](./customizing-views.md) section, we allow swapping of the default UI components with your custom ones. To achieve this, you will need to create your own implementation of the `ViewFactory` protocol. 

In our UIKit components, we expose a `CallViewController` that can be easily used in UIKit based projects. The `CallViewController` uses the default `ViewFactory` implementation from the SwiftUI SDK. However, you can easily inject your own implementation, by subclassing the `CallViewController` and providing your own implementation of the `setupVideoView` method.

For example, let's extend the video call controls with a chat icon. In order to do this, you will need to implement the `makeCallControlsView` method in the `ViewFactory`:

```swift
class VideoWithChatViewFactory: ViewFactory {
    
    static let shared = VideoWithChatViewFactory()
    
    private init() {}
    
    func makeCallControlsView(viewModel: CallViewModel) -> some View {
        ChatCallControls(viewModel: viewModel)
    }
    
}
```

At the end of this guide, there's a possible implementation of  `ChatCallControls`, that you can customize as you see fit.

Next, we need to inject our custom implementation into the StreamVideo UIKit components. In order to do this, we need to create a subclass of the `CallViewController`.

```swift
class CallChatViewController: CallViewController {
    
    override func setupVideoView() {
        let videoView = makeVideoView(with: VideoWithChatViewFactory.shared)
        view.embed(videoView)
    }

}
```

Now, you can use the `CallChatViewController` in your app. There are several options how you can add the view controller in your app's view hierarchy. 

One option is to use the standard navigation patterns, such as pushing or presenting the view controller over your app's views. You can do that, if you don't need the minimized call option. However, if you want to allow users to use your app while still being in call, we recommend to add the `CallViewController` (or its subclasses) as a subview. 

Here's one example implementation that adds the view in the application window (this is needed in case you want to also navigate throughout your app while in a call):

```swift
class CallViewHelper {
    
    static let shared = CallViewHelper()
    
    private var callView: UIView?
    
    private init() {}
    
    func add(callView: UIView) {
        guard self.callView == nil else { return }
        guard let window = UIApplication.shared.windows.first else {
            return
        }
        callView.isOpaque = false
        callView.backgroundColor = UIColor.clear
        self.callView = callView
        window.addSubview(callView)
    }
    
    func removeCallView() {
        callView?.removeFromSuperview()
        callView = nil
    }
}
```

Finally, in your app, you can add the `CallViewController` with the following code:

```swift
@objc private func didTapStartButton() {
    let next = CallChatViewController.makeCallChatController(with: self.callViewModel)
    next.startCall(callId: text, type: "default", participants: selectedParticipants)
    CallViewHelper.shared.add(callView: next.view)
}
```

You can also listen to call events, and show/hide the calling view depending on the state:

```swift
private func listenToIncomingCalls() {
    callViewModel.$callingState.sink { [weak self] newState in
        guard let self = self else { return }
        if case .incoming(_) = newState, self == self.navigationController?.topViewController {
            let next = CallChatViewController.makeCallChatController(with: self.callViewModel)
            CallViewHelper.shared.add(callView: next.view)
        } else if newState == .idle {
            CallViewHelper.shared.removeCallView()
        }
    }
    .store(in: &cancellables)
}
```

You can find fully working sample apps with our UIKit components in our sample apps [repository](https://github.com/GetStream/stream-video-ios-examples).


### ChatCallControls Implementation

For reference, here's the `ChatCallControls` mentioned above.

```swift
import SwiftUI
import struct StreamChatSwiftUI.ChatChannelView
import struct StreamChatSwiftUI.UnreadIndicatorView
import StreamVideo
import StreamVideoSwiftUI

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
                    )),
                AnyView(
                    Button(
                        action: {
                            viewModel.toggleCameraEnabled()
                        },
                        label: {
                            CallIconView(
                                icon: (viewModel.callSettings.videoOn ? images.videoTurnOn : images.videoTurnOff),
                                size: size,
                                iconStyle: (viewModel.callSettings.videoOn ? .primary : .transparent)
                            )
                        }
                    )),
                AnyView(Button(
                    action: {
                        viewModel.toggleMicrophoneEnabled()
                    },
                    label: {
                        CallIconView(
                            icon: (viewModel.callSettings.audioOn ? images.micTurnOn : images.micTurnOff),
                            size: size,
                            iconStyle: (viewModel.callSettings.audioOn ? .primary : .transparent)
                        )
                    }
                )),
                AnyView(Button(
                    action: {
                        viewModel.toggleCameraPosition()
                    },
                    label: {
                        CallIconView(
                            icon: images.toggleCamera,
                            size: size,
                            iconStyle: .primary
                        )
                    }
                )),
                AnyView(Button {
                    viewModel.hangUp()
                } label: {
                    images.hangup
                        .applyCallButtonStyle(
                            color: colors.hangUpIconColor,
                            size: size
                        )
                })
            ])
            
            if chatHelper.chatShown {
                if let channelController = chatHelper.channelController {
                    ChatChannelView(
                        viewFactory: ChatViewFactory.shared,
                        channelController: channelController
                    )
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