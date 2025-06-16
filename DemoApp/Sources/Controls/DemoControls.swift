//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import class StreamChat.ChatChannelController
import struct StreamChatSwiftUI.ChatChannelView
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoControlsView: View {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    @Injected(\.chatViewModel) var chatViewModel
    @Injected(\.currentDevice) var currentDevice

    @State var showParticipantsList: Bool

    private var canOpenChat: Bool

    private let size: CGFloat = 50
    private let cornerRadius: CGFloat = 24

    var viewModel: CallViewModel

    init(viewModel: CallViewModel, canOpenChat: Bool = true) {
        showParticipantsList = viewModel.callingState == .inCall

        self.viewModel = viewModel
        self.canOpenChat = canOpenChat
    }

    var body: some View {
        HStack {
            moreControlsView
            broadcastView
            videoView
            microphoneView

            Spacer()

            participantsInfoView
            chatView
        }
        .padding(.horizontal, 16)
        .padding(.bottom)
        .onReceive(
            viewModel
                .$callingState
                .removeDuplicates()
                .map { $0 == .inCall }
        ) { showParticipantsList = $0 }
    }

    @ViewBuilder
    private var moreControlsView: some View {
        MoreControlsIconView(viewModel: viewModel)
    }

    @ViewBuilder
    private var broadcastView: some View {
        #if !targetEnvironment(simulator)
        if currentDevice.deviceType == .pad {
            BroadcastIconView(
                viewModel: viewModel,
                preferredExtension: "io.getstream.iOS.VideoDemoApp.ScreenSharing"
            )
        }
        #endif
    }

    @ViewBuilder
    private var videoView: some View {
        VideoIconView(viewModel: viewModel)
    }

    @ViewBuilder
    private var microphoneView: some View {
        MicrophoneIconView(viewModel: viewModel)
    }

    @ViewBuilder
    private var participantsInfoView: some View {
        if showParticipantsList {
            ParticipantsListButton(
                viewModel: viewModel
            )
        }
    }

    @ViewBuilder
    private var chatView: some View {
        if let chatViewModel, chatViewModel.isChatEnabled {
            ChatIconView(viewModel: chatViewModel)
        }
    }
}
