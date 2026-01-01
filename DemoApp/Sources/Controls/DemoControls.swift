//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import class StreamChat.ChatChannelController
import struct StreamChatSwiftUI.ChatChannelView
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct AppControlsWithChat: View {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    @Injected(\.chatViewModel) var chatViewModel
    @Injected(\.currentDevice) var currentDevice

    private var canOpenChat: Bool

    private let size: CGFloat = 50
    private let cornerRadius: CGFloat = 24

    @ObservedObject var viewModel: CallViewModel

    init(viewModel: CallViewModel, canOpenChat: Bool = true) {
        self.viewModel = viewModel
        self.canOpenChat = canOpenChat
    }

    var body: some View {
        HStack {
            MoreControlsIconView(viewModel: viewModel)

            #if !targetEnvironment(simulator)
            if !ProcessInfo.processInfo.isiOSAppOnMac, currentDevice.deviceType == .pad {
                BroadcastIconView(
                    viewModel: viewModel,
                    preferredExtension: "io.getstream.iOS.VideoDemoApp.ScreenSharing"
                )
            }
            #endif
            VideoIconView(viewModel: viewModel)
            MicrophoneIconView(viewModel: viewModel)

            Spacer()

            ParticipantsListButton(viewModel: viewModel)
            
            if let chatViewModel, chatViewModel.isChatEnabled {
                ChatIconView(viewModel: chatViewModel)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom)
    }
}

struct MoreControlsIconView: View {

    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat

    init(viewModel: CallViewModel, size: CGFloat = 44) {
        self.viewModel = viewModel
        self.size = size
    }

    var body: some View {
        Button(
            action: {
                viewModel.moreControlsShown.toggle()
            },
            label: {
                CallIconView(
                    icon: Image(systemName: "ellipsis"),
                    size: size,
                    iconStyle: viewModel.moreControlsShown ? .secondaryActive : .secondary
                )
                .rotationEffect(.degrees(90))
            }
        )
        .accessibility(identifier: "moreControlsToggle")
    }
}

struct ChatControlsHeader: View {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    @Injected(\.chatViewModel) var chatViewModel

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

    @ObservedObject var viewModel: DemoChatViewModel
    let size: CGFloat

    init(viewModel: DemoChatViewModel, size: CGFloat = 44) {
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
                    icon: .init(systemName: "bubble.left.and.bubble.right.fill"),
                    size: size,
                    iconStyle: viewModel.isChatVisible ? .secondaryActive : .secondary
                ).overlay(
                    ControlBadgeView("\(viewModel.unreadCount)")
                        .opacity(viewModel.unreadCount > 0 ? 1 : 0)
                )
            }
        )
        .accessibility(identifier: "chatToggle")
    }
}

struct ChatView: View {

    var channelController: ChatChannelController
    var chatViewModel: DemoChatViewModel
    var callViewModel: CallViewModel

    var body: some View {
        NavigationView {
            ChatChannelView(
                viewFactory: DemoChatViewFactory.shared,
                channelController: channelController
            )
            .onAppear { chatViewModel.markAsRead() }
            .onDisappear { chatViewModel.channelDisappeared() }
            .navigationBarHidden(true)
        }
    }
}
