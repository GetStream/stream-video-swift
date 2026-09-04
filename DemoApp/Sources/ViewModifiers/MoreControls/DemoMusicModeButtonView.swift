//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoMusicModeButtonView: View {

    @ObservedObject var viewModel: CallViewModel

    var body: some View {
        if let call = viewModel.call {
            Content(microphone: call.microphone)
        }
    }

    private struct Content: View {
        @ObservedObject var microphone: MicrophoneManager
        @State private var errorLabel: String?

        var body: some View {
            DemoMoreControlListButtonView(
                action: {
                    Task { @MainActor in await toggle() }
                },
                label: errorLabel ?? (
                    microphone.audioBitrateProfile == .musicHighQuality
                        ? "Disable Music Mode"
                        : "Music Mode"
                )
            ) {
                Image(
                    systemName: microphone.audioBitrateProfile == .musicHighQuality
                        ? "music.note"
                        : "music.note.slash"
                )
            }
        }

        private func toggle() async {
            let next: AudioBitrateProfile = microphone.audioBitrateProfile == .musicHighQuality
                ? .voiceStandard
                : .musicHighQuality
            do {
                try await microphone.setAudioBitrateProfile(next)
                errorLabel = nil
            } catch {
                errorLabel = error.localizedDescription
            }
        }
    }
}
