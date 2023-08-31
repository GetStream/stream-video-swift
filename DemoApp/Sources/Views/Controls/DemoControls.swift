//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import struct StreamChatSwiftUI.ChatChannelView
import SwiftUI
import class StreamChat.ChatChannelController

struct AppControlsWithChat: View {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.images) var images
    @Injected(\.colors) var colors

    @Environment(\.chatVideoViewModel) var chatViewModel
    private var canOpenChat: Bool

    private let size: CGFloat = 50

    @ObservedObject var reactionsHelper = AppState.shared.reactionsHelper
    @ObservedObject var viewModel: CallViewModel
    @State private var isChatVisible = false

    init(viewModel: CallViewModel, canOpenChat: Bool = true) {
        self.viewModel = viewModel
        self.canOpenChat = canOpenChat
    }

    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 16) {
                if let chatViewModel, chatViewModel.isChatEnabled {
                    ChatIconView(viewModel: chatViewModel)
                }
                VideoIconView(viewModel: viewModel)
                MicrophoneIconView(viewModel: viewModel)
                ToggleCameraIconView(viewModel: viewModel)
                BroadcastIconView(
                    viewModel: viewModel,
                    preferredExtension: "io.getstream.iOS.VideoDemoApp.ScreenSharing"
                )
                HangUpIconView(viewModel: viewModel)
            }
            .frame(height: 85)
        }
        .frame(maxWidth: .infinity)
        .background(
            colors.callControlsBackground
                .edgesIgnoringSafeArea(.all)
        )
        .overlay(
            VStack {
                colors.callControlsBackground
                    .frame(height: 30)
                    .cornerRadius(24)
                Spacer()
            }
            .offset(y: -15)
        )
        .onReceive(chatViewModel?.$isChatVisible) { isChatVisible = canOpenChat && $0 }
        .onReceive(viewModel.$call, perform: { call in
            reactionsHelper.call = call
        })
        .halfSheetIfAvailable(isPresented: $isChatVisible, onDismiss: { chatViewModel?.isChatVisible = false }) {
            if let chatViewModel = chatViewModel, let channelController = chatViewModel.channelController {
                VStack {
                    ChatControlsHeader(viewModel: viewModel)
                    ChatView(
                        channelController: channelController,
                        chatViewModel: chatViewModel,
                        callViewModel: viewModel
                    )
                }
            }
        }
    }
}

struct ChatControlsHeader: View {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.images) var images
    @Injected(\.colors) var colors

    @Environment(\.chatVideoViewModel) var chatViewModel

    private let size: CGFloat = 50

    @ObservedObject var viewModel: CallViewModel

    init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        AppControlsWithChat(viewModel: viewModel, canOpenChat: false)
    }
}

struct ChatIconView: View {

    @Injected(\.images) var images
    @Injected(\.colors) var colors

    @ObservedObject var viewModel: StreamChatVideoViewModel
    let size: CGFloat

    init(viewModel: StreamChatVideoViewModel, size: CGFloat = 50) {
        self.viewModel = viewModel
        self.size = size
    }

    var body: some View {
        Button(
            action: {
                viewModel.isChatVisible.toggle()
            },
            label: {
                CallIconView(
                    icon: viewModel.isChatVisible ? .init(systemName: "message.fill") : .init(systemName: "message"),
                    size: size,
                    iconStyle: viewModel.isChatVisible ? .primary : .transparent
                ).overlay(
                    VStack {
                        HStack {
                            Spacer()
                            if viewModel.unreadCount > 0 {
                                Text("\(viewModel.unreadCount)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(colors.text)
                                    .padding([.leading, .trailing], 4)
                                    .padding([.top, .bottom], 2)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                                    .clipped()
                            }
                        }
                        Spacer()
                    }
                )
            }
        )
        .accessibility(identifier: "chatToggle")
    }
}

struct VideoIconView: View {

    @Injected(\.images) var images

    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat

    init(viewModel: CallViewModel, size: CGFloat = 50) {
        self.viewModel = viewModel
        self.size = size
    }

    var body: some View {
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
        .accessibility(identifier: "cameraToggle")
        .streamAccessibility(value: viewModel.callSettings.videoOn ? "1" : "0")
    }
}

struct MicrophoneIconView: View {

    @Injected(\.images) var images

    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat

    init(viewModel: CallViewModel, size: CGFloat = 50) {
        self.viewModel = viewModel
        self.size = size
    }

    var body: some View {
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
        .accessibility(identifier: "microphoneToggle")
        .streamAccessibility(value: viewModel.callSettings.audioOn ? "1" : "0")
    }
}

struct ToggleCameraIconView: View {

    @Injected(\.images) var images

    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat

    init(viewModel: CallViewModel, size: CGFloat = 50) {
        self.viewModel = viewModel
        self.size = size
    }

    var body: some View {
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
        .accessibility(identifier: "cameraPositionToggle")
        .streamAccessibility(value: viewModel.callSettings.cameraPosition == .front ? "1" : "0")
    }
}

struct HangUpIconView: View {

    @Injected(\.images) var images
    @Injected(\.colors) var colors

    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat

    init(viewModel: CallViewModel, size: CGFloat = 50) {
        self.viewModel = viewModel
        self.size = size
    }

    var body: some View {
        Button {
            viewModel.hangUp()
        } label: {
            images.hangup
                .applyCallButtonStyle(
                    color: colors.hangUpIconColor,
                    size: size
                )
        }
        .accessibility(identifier: "hangUp")
    }
}

struct AudioOutputIconView: View {

    @Injected(\.images) var images

    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat

    init(viewModel: CallViewModel, size: CGFloat = 50) {
        self.viewModel = viewModel
        self.size = size
    }

    var body: some View {
        Button(
            action: {
                viewModel.toggleAudioOutput()
            },
            label: {
                CallIconView(
                    icon: (viewModel.callSettings.audioOutputOn ? images.speakerOn : images.speakerOff),
                    size: size,
                    iconStyle: (viewModel.callSettings.audioOutputOn ? .primary : .transparent)
                )
            }
        )
    }

}

struct ChatView: View {

    var channelController: ChatChannelController
    var chatViewModel: StreamChatVideoViewModel
    var callViewModel: CallViewModel

    var body: some View {
        NavigationView {
            ChatChannelView(
                viewFactory: StreamChatViewFactory.shared,
                channelController: channelController
            )
            .onAppear { chatViewModel.markAsRead() }
            .onDisappear { chatViewModel.channelDisappeared() }
            .navigationBarHidden(true)
        }
    }
}

extension View {

    @ViewBuilder
    func halfSheetIfAvailable<Content>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View where Content : View {
        if #available(iOS 16.0, *) {
            sheet(isPresented: isPresented, onDismiss: onDismiss) {
                content()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        } else {
            sheet(isPresented: isPresented, onDismiss: onDismiss) { content() }
        }
    }
}
