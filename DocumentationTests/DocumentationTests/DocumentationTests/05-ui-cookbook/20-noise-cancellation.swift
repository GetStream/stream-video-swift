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
        struct NoiseCancellationButtonView: View {

            @Injected(\.streamVideo) var streamVideo

            @ObservedObject var viewModel: CallViewModel
            @State var isNoiseCancellationAvailable = false
            @State var isActive: Bool = false

            init(viewModel: CallViewModel) {
                self.viewModel = viewModel
                if let mode = viewModel.call?.state.settings?.audio.noiseCancellation?.mode {
                    self.isNoiseCancellationAvailable = mode != .disabled
                } else {
                    self.isNoiseCancellationAvailable = false
                }
                self.isActive = streamVideo.videoConfig.noiseCancellationFilter?.id == streamVideo.videoConfig.audioProcessingModule
                    .activeAudioFilter?.id
            }

            var body: some View {
                if let call = viewModel.call, let noiseCancellationAudioFilter = streamVideo.videoConfig.noiseCancellationFilter {
                    Group {
                        if isNoiseCancellationAvailable {
                            Button {
                                if isActive {
                                    call.setAudioFilter(nil)
                                    isActive = false
                                } else {
                                    call.setAudioFilter(noiseCancellationAudioFilter)
                                    isActive = true
                                }
                            } label: {
                                Label {
                                    Text(isActive ? "Disable Noise Cancellation" : "Noise Cancellation")
                                } icon: {
                                    Image(
                                        systemName: isActive
                                            ? "waveform.path.ecg"
                                            : "waveform.path"
                                    )
                                }
                            }
                        }
                    }
                    .onReceive(call.state.$settings.map(\.?.audio.noiseCancellation)) {
                        if let mode = $0?.mode {
                            isNoiseCancellationAvailable = mode != .disabled
                        } else {
                            isNoiseCancellationAvailable = false
                        }
                    }
                }
            }
        }
    }
}
