//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoTranscriptionButtonView: View {

    @ObservedObject var viewModel: CallViewModel
    @State private var isTranscriptionAvailable = false
    @State private var isTranscribing = false

    init(viewModel: CallViewModel) {
        self.viewModel = viewModel
        isTranscriptionAvailable = (viewModel.call?.state.settings?.transcription.mode ?? .disabled) != .disabled
        isTranscribing = viewModel.call?.state.transcribing == true
    }

    var body: some View {
        Group {
            if isTranscriptionAvailable {
                DemoMoreControlListButtonView(
                    action: {
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
                    },
                    label: isTranscribing ? "Disable Transcription" : "Transcription"
                ) {
                    Image(
                        systemName: isTranscribing
                            ? "captions.bubble.fill"
                            : "captions.bubble"
                    )
                }
                .onReceive(viewModel.call?.state.$transcribing) { isTranscribing = $0 }
            }
        }
        .onReceive(viewModel.call?.state.$settings) {
            guard let mode = $0?.transcription.mode else {
                isTranscriptionAvailable = false
                return
            }
            isTranscriptionAvailable = mode != .disabled
        }
    }
}
