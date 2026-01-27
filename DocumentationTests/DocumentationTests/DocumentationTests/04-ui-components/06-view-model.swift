//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    viewContainer {
        Button {
            viewModel.startCall(callType: "default", callId: callId, members: callMembers, ring: false)
        } label: {
            Text("Start a call")
        }
    }

    viewContainer {
        Button {
            viewModel.joinCall(callType: "default", callId: callId)
        } label: {
            Text("Join a call")
        }
    }

    container {
        // Apply a video filter
        viewModel.setVideoFilter(sepia)

        // Remove the video filter
        viewModel.setVideoFilter(nil)
    }

    container {
        // Start screen sharing (in-app)
        viewModel.startScreensharing(type: .inApp)

        // Start screen sharing with audio
        viewModel.startScreensharing(type: .inApp, includeAudio: true)

        // Stop screen sharing
        viewModel.stopScreensharing()
    }
}
