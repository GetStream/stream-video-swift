//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
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

    var viewModel: CallViewModel

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
            #endif // !targetEnvironment(simulator)
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

    var viewModel: CallViewModel
    let size: CGFloat

    @State var isActive: Bool
    var isActivePublisher: AnyPublisher<Bool, Never>

    init(viewModel: CallViewModel, size: CGFloat = 44) {
        self.viewModel = viewModel
        self.size = size

        isActive = viewModel.moreControlsShown
        isActivePublisher = viewModel
            .$moreControlsShown
            .removeDuplicates()
            .eraseToAnyPublisher()
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
                    iconStyle: isActive ? .secondaryActive : .secondary
                )
                .rotationEffect(.degrees(90))
            }
        )
        .accessibility(identifier: "moreControlsToggle")
        .onReceive(isActivePublisher) { isActive = $0 }
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

    var viewModel: DemoChatViewModel
    let size: CGFloat

    @State var isActive: Bool
    var isActivePublisher: AnyPublisher<Bool, Never>

    @State var unreadCount: Int
    var unreadCountPublisher: AnyPublisher<Int, Never>

    init(viewModel: DemoChatViewModel, size: CGFloat = 44) {
        self.viewModel = viewModel
        self.size = size

        isActive = viewModel.isChatVisible
        isActivePublisher = viewModel
            .$isChatVisible
            .removeDuplicates()
            .eraseToAnyPublisher()

        unreadCount = viewModel.unreadCount
        unreadCountPublisher = viewModel
            .$unreadCount
            .removeDuplicates()
            .eraseToAnyPublisher()
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
                    iconStyle: isActive ? .secondaryActive : .secondary
                ).overlay(overlayView)
            }
        )
        .accessibility(identifier: "chatToggle")
        .onReceive(isActivePublisher) { isActive = $0 }
        .onReceive(unreadCountPublisher) { unreadCount = $0 }
    }

    @ViewBuilder
    var overlayView: some View {
        if unreadCount > 0 {
            ControlBadgeView("\(unreadCount)")
        } else {
            EmptyView()
        }
    }
}

struct ChatView: View {

    var channelController: ChatChannelController
    var chatViewModel: DemoChatViewModel

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
