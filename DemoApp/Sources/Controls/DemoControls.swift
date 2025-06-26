//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
