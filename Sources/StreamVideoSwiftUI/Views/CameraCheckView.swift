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
        GeometryReader { proxy in
            Group {
                if let image = viewModel.viewfinderImage, callSettings.videoOn {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .accessibility(identifier: "cameraCheckView")
                        .streamAccessibility(value: "1")
                } else {
                    ZStack {
                        Rectangle()
                            .fill(colors.lobbySecondaryBackground)

                        viewFactory.makeUserAvatar(
                            streamVideo.user,
                            with: .init(size: 80)
                        )
                        .accessibility(identifier: "cameraCheckView")
                        .streamAccessibility(value: "0")
                    }
                    .opacity(callSettings.videoOn ? 0 : 1)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .overlay(
                VStack {
                    Spacer()
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
            )
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
