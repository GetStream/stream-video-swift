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

    // VideoIconView
    var hasVideoCapability: Bool
    var isVideoEnabled: Bool

    // MicrophoneIconView
    var hasAudioCapability: Bool
    var isAudioEnabled: Bool

    // ParticipantsListButton
    var showParticipantsList: Bool
    var participantsCount: Int
    var participantsShown: Binding<Bool>

    private var canOpenChat: Bool

    private let size: CGFloat = 50
    private let cornerRadius: CGFloat = 24

    var viewModel: CallViewModel

    init(viewModel: CallViewModel, canOpenChat: Bool = true) {
        let streamVideo = InjectedValues[\.streamVideo]
        let call = viewModel.call ?? streamVideo.state.ringingCall
        let ownCapabilities = Set(call?.state.ownCapabilities ?? [])

        self.hasVideoCapability = ownCapabilities.contains(.sendVideo)
        self.isVideoEnabled = call?.state.callSettings.videoOn ?? false

        self.hasAudioCapability = ownCapabilities.contains(.sendAudio)
        self.isAudioEnabled = call?.state.callSettings.audioOn ?? false

        self.showParticipantsList = viewModel.callingState == .inCall
        self.participantsCount = call?.state.participants.endIndex ?? 0
        self.participantsShown = .init(get: { viewModel.participantsShown }, set: { viewModel.participantsShown = $0 })

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
        if hasVideoCapability {
            VideoIconView(
                isEnabled: isVideoEnabled,
                actionHandler: { [weak viewModel] in viewModel?.toggleCameraEnabled() }
            )
            .equatable()
        }
    }

    @ViewBuilder
    private var microphoneView: some View {
        if hasAudioCapability {
            MicrophoneIconView(
                isEnabled: isAudioEnabled,
                actionHandler: { [weak viewModel] in viewModel?.toggleMicrophoneEnabled() }
            )
            .equatable()
        }
    }

    @ViewBuilder
    private var participantsInfoView: some View {
        if showParticipantsList {
            ParticipantsListButton(
                count: participantsCount,
                isActive: participantsShown,
                actionHandler: { [weak viewModel] in viewModel?.participantsShown = true }
            )
            .equatable()
        }
    }

    @ViewBuilder
    private var chatView: some View {
        if let chatViewModel, chatViewModel.isChatEnabled {
            ChatIconView(viewModel: chatViewModel)
        }
    }
}
