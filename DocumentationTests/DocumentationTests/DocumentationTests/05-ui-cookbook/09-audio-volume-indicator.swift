//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    container {
        AudioVolumeIndicator(
            audioLevels: [0.8, 0.9, 0.7],
            maxHeight: 14,
            minValue: 0,
            maxValue: 1
        )
    }

    container {
        @StateObject var microphoneChecker = MicrophoneChecker()
    }

    viewContainer {
        var callViewModel = viewModel
        var microphoneChecker = MicrophoneChecker()

        MicrophoneCheckView(
            audioLevels: microphoneChecker.audioLevels,
            microphoneOn: callViewModel.callSettings.audioOn,
            isSilent: microphoneChecker.isSilent,
            isPinned: false
        )
    }
}
