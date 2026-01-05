//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    container {
        struct TranscriptionButtonView: View {
            
            @ObservedObject var viewModel: CallViewModel
            @State private var isTranscriptionAvailable = false
            @State private var isTranscribing = false
            
            init(viewModel: CallViewModel) {
                self.viewModel = viewModel
                self.isTranscriptionAvailable = (viewModel.call?.state.settings?.transcription.mode ?? .disabled) != .disabled
                self.isTranscribing = viewModel.call?.state.transcribing == true
            }
            
            var body: some View {
                if let call = viewModel.call {
                    Group {
                        if isTranscriptionAvailable {
                            Button {
                                Task {
                                    do {
                                        if isTranscribing {
                                            try await viewModel.call?.stopTranscription()
                                        } else {
                                            try await viewModel.call?.startTranscription()
                                        }
                                    } catch {
                                        log.error(error)
                                    }
                                }
                            } label: {
                                Label {
                                    Text(isTranscribing ? "Disable Transcription" : "Transcription")
                                } icon: {
                                    Image(
                                        systemName: isTranscribing
                                            ? "captions.bubble.fill"
                                            : "captions.bubble"
                                    )
                                }
                            }
                            .onReceive(call.state.$transcribing) { isTranscribing = $0 }
                        }
                    }
                    .onReceive(call.state.$settings) {
                        guard let mode = $0?.transcription.mode else {
                            isTranscriptionAvailable = false
                            return
                        }
                        isTranscriptionAvailable = mode != .disabled
                    }
                }
            }
        }
    }
}
