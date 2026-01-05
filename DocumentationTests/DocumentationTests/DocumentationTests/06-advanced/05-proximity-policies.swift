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
        let call = streamVideo.call(callType: "default", callId: "chat-123")
        let policy = VideoProximityPolicy()

        do {
            try call.addProximityPolicy(policy)
        } catch {
            log.error(error)
        }
    }

    container {
        let call = streamVideo.call(callType: "default", callId: "team-meet")
        let policy = SpeakerProximityPolicy()

        do {
            try call.addProximityPolicy(policy)
        } catch {
            log.error(error)
        }
    }

    container {
        let call = streamVideo.call(callType: "default", callId: "chat-123")
        let videoPolicy = VideoProximityPolicy()
        let speakerPolicy = SpeakerProximityPolicy()

        do {
            try call.addProximityPolicy(videoPolicy)
            try call.addProximityPolicy(speakerPolicy)
        } catch {
            log.error(error)
        }
    }
}
