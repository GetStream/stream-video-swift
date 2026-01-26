//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    container {
        func startRecording() {
            Task {
                try await call.startRecording()
            }
        }
    }

    container {
        func stopRecording() {
            Task {
                try await call.stopRecording()
            }
        }
    }

    container {
        func subscribeToRecordingEvents() {
            Task {
                for await event in call.subscribe() {
                    switch event {
                    case .typeCallRecordingStartedEvent(let recordingStartedEvent):
                        log.debug("received an event \(recordingStartedEvent)")
                    /* handle recording event */
                    case .typeCallRecordingStoppedEvent(let recordingStoppedEvent):
                        log.debug("received an event \(recordingStoppedEvent)")
                    /* handle recording event */
                    default:
                        break
                    }
                }
            }
        }
    }

    container {
        final class CustomObject: @unchecked Sendable {

            var recordings: [CallRecording] = []

            func loadRecordings() {
                Task {
                    self.recordings = try await call.listRecordings()
                }
            }
        }
    }

    container {
        struct PlayerView: View {

            let recording: CallRecording

            var body: some View {
                Group {
                    if let url = URL(string: recording.url) {
                        VideoPlayer(player: AVPlayer(url: url))
                    } else {
                        Text("Video can't be loaded")
                    }
                }
            }
        }
    }
}
