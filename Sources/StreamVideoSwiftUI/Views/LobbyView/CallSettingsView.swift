//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

struct CallSettingsView: View {
    
    @Injected(\.images) var images
    
    var viewModel: LobbyViewModel
    var iconSize: CGFloat

    @State var audioOn: Bool
    var audioOnPublisher: AnyPublisher<Bool, Never>

    @State var videoOn: Bool
    var videoOnPublisher: AnyPublisher<Bool, Never>

    init(
        viewModel: LobbyViewModel,
        iconSize: CGFloat = 50
    ) {
        self.viewModel = viewModel
        self.iconSize = iconSize

        audioOn = viewModel.audioOn
        audioOnPublisher = viewModel.$audioOn.eraseToAnyPublisher()
        videoOn = viewModel.videoOn
        videoOnPublisher = viewModel.$videoOn.eraseToAnyPublisher()
    }

    var body: some View {
        HStack(spacing: 32) {
            toggleMicrophoneButton
            toggleCameraButton
        }
        .padding()
        .onReceive(audioOnPublisher) { audioOn = $0 }
        .onReceive(videoOnPublisher) { videoOn = $0 }
        .debugViewRendering()
    }

    @ViewBuilder
    var toggleMicrophoneButton: some View {
        Button {
            viewModel.toggleMicrophoneEnabled()
        } label: {
            CallIconView(
                icon: audioOn ? images.micTurnOn : images.micTurnOff,
                size: iconSize,
                iconStyle: audioOn ? .primary : .transparent
            )
            .accessibility(identifier: "microphoneToggle")
            .streamAccessibility(value: audioOn ? "1" : "0")
        }
    }

    @ViewBuilder
    var toggleCameraButton: some View {
        Button {
            viewModel.toggleCameraEnabled()
        } label: {
            CallIconView(
                icon: videoOn ? images.videoTurnOn : images.videoTurnOff,
                size: iconSize,
                iconStyle: videoOn ? .primary : .transparent
            )
            .accessibility(identifier: "cameraToggle")
            .streamAccessibility(value: videoOn ? "1" : "0")
        }
    }
}
