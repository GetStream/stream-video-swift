//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import class StreamChat.ChatChannelController
import struct StreamChatSwiftUI.ChatChannelView
import struct StreamChatSwiftUI.UnreadIndicatorView
import StreamVideo
import StreamVideoSwiftUI
import StreamVideoUIKit
import SwiftUI

@MainActor
private func content() {

    container {
        class VideoWithChatViewFactory: ViewFactory {

            static let shared = VideoWithChatViewFactory()

            private init() {}

            func makeCallControlsView(viewModel: CallViewModel) -> some View {
                ChatCallControls(viewModel: viewModel)
            }
        }
    }

    container {
        class CallChatViewController: CallViewController {

            class func makeCallChatController(with callViewModel: CallViewModel) -> CallChatViewController {
                .init()
            }

            override func setupVideoView() {
                let videoView = makeVideoView(with: VideoWithChatViewFactory.shared)
                view.embed(videoView)
            }
        }

        @MainActor
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

        final class CustomObject: UIViewController {
            var callViewModel: CallViewModel { viewModel }
            var selectedParticipants: [Member] = []
            var text = ""
            var cancellables: Set<AnyCancellable> = []

            @objc func didTapStartButton() {
                let next = CallChatViewController.makeCallChatController(with: self.callViewModel)
                next.startCall(callType: "default", callId: text, members: selectedParticipants)
                CallViewHelper.shared.add(callView: next.view)
            }

            private func listenToIncomingCalls() {
                callViewModel.$callingState.sink { [weak self] newState in
                    guard let self = self else { return }
                    if case .incoming = newState, self == self.navigationController?.topViewController {
                        let next = CallChatViewController.makeCallChatController(with: self.callViewModel)
                        CallViewHelper.shared.add(callView: next.view)
                    } else if newState == .idle {
                        CallViewHelper.shared.removeCallView()
                    }
                }
                .store(in: &cancellables)
            }
        }
    }

    container {
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
                    HStack {
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
                        )
                        .frame(maxWidth: .infinity)

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
                        )
                        .frame(maxWidth: .infinity)

                        Button(
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
                        )
                        .frame(maxWidth: .infinity)

                        Button(
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
                        )
                        .frame(maxWidth: .infinity)

                        Button {
                            viewModel.hangUp()
                        } label: {
                            images.hangup
                                .applyCallButtonStyle(
                                    color: colors.hangUpIconColor,
                                    size: size
                                )
                        }
                        .frame(maxWidth: .infinity)
                    }

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
                .onReceive(viewModel.$callParticipants, perform: { _ in
                    if viewModel.callParticipants.count > 1 {
                        chatHelper.update(memberIds: Set(viewModel.callParticipants.map(\.key)))
                    }
                })
            }

            private var chatHeight: CGFloat {
                (UIScreen.main.bounds.height / 3 + 50)
            }
        }

        final class ChatHelper: ObservableObject {
            @Published var chatShown: Bool = false
            @Published var unreadCount: Int = 0
            @Published var channelController: ChatChannelController?

            init() {}

            func markAsRead() { /* Your implementation here */ }

            func update(memberIds: Set<String>) { /* Your implementation here */ }
        }
    }
}
