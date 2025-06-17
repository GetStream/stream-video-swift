//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct CameraCheckView<Factory: ViewFactory>: View {

    @Injected(\.images) var images
    @Injected(\.colors) var colors
    @Injected(\.streamVideo) var streamVideo
    
    @ObservedObject var viewModel: LobbyViewModel
    @ObservedObject var microphoneChecker: MicrophoneChecker
    var viewFactory: Factory
    var callSettings: CallSettings

    var body: some View {
        contentView
            .overlay(overlayView)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .debugViewRendering()
    }

    @ViewBuilder
    var contentView: some View {
        if let image = viewModel.viewfinderImage, callSettings.videoOn {
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .accessibility(identifier: "cameraCheckView")
                .streamAccessibility(value: "1")
        } else {
            Rectangle()
                .fill(colors.lobbySecondaryBackground)

            viewFactory.makeUserAvatar(
                streamVideo.user,
                with: .init(size: 80)
            )
            .accessibility(identifier: "cameraCheckView")
            .streamAccessibility(value: "0")
        }
    }

    @ViewBuilder
    var overlayView: some View {
        BottomView {
            HStack {
                MicrophoneCheckView(
                    audioLevels: microphoneChecker.audioLevels,
                    microphoneOn: callSettings.audioOn,
                    isSilent: microphoneChecker.isSilent,
                    isPinned: false
                )
                .accessibility(identifier: "microphoneCheckView")

                Spacer()
            }
        }
    }
}
