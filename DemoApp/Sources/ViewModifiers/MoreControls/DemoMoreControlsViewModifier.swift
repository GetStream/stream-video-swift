//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

private struct DemoMoreControlsViewModifier: ViewModifier {

    @ObservedObject var appState: AppState = .shared
    @ObservedObject var viewModel: CallViewModel
    @Injected(\.snapshotTrigger) var snapshotTrigger
    @Injected(\.localParticipantSnapshotViewModel) var localParticipantSnapshotViewModel

    @State private var isStatsPresented = false

    init(viewModel: CallViewModel) {
        self.viewModel = viewModel
        localParticipantSnapshotViewModel.call = viewModel.call
    }

    fileprivate func body(content: Content) -> some View {
        content
            .halfSheet(isPresented: $viewModel.moreControlsShown) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: {
                        if #available(iOS 15.0, *) { return 8 }
                        else { return 32 }
                    }()) {
                        VStack(spacing: 8) {
                            DemoReactionSelectorView { viewModel.moreControlsShown = false }
                            DemoRaiseHandToggleButtonView(viewModel: viewModel)
                            if #available(iOS 15.0, *) {
                                DemoBackgroundEffectSelector()
                            }
                        }

                        VStack {
                            DemoMoreControlListButtonView(
                                action: {
                                    localParticipantSnapshotViewModel.zoom()
                                },
                                label: "Zoom"
                            ) { Image(systemName: "plus.magnifyingglass") }

                            DemoMoreControlListButtonView(
                                action: {
                                    if #available(iOS 16.0, *) {
                                        localParticipantSnapshotViewModel.captureVideoFrame()
                                    } else {
                                        localParticipantSnapshotViewModel.capturePhoto()
                                    }
                                },
                                label: "Capture Photo"
                            ) { Image(systemName: "camera") }

                            DemoMoreControlListButtonView(
                                action: {
                                    snapshotTrigger.capture()
                                },
                                label: "Snapshot"
                            ) { Image(systemName: "circle.inset.filled") }

                            DemoNoiseCancellationButtonView(viewModel: viewModel)

                            DemoMoreControlListButtonView(
                                action: {
                                    appState.audioFilter = appState.audioFilter?.id.hasPrefix("robot") == true
                                        ? nil
                                        : RobotVoiceFilter(pitchShift: 0.8)
                                },
                                label: appState.audioFilter?.id.hasPrefix("robot") == true ? "Disable Robot" : "Robot filter"
                            ) {
                                Image(
                                    systemName: appState.audioFilter?.id.hasPrefix("robot") == true
                                        ? "circle.slash"
                                        : "faxmachine"
                                )
                            }

                            DemoMoreControlListButtonView(
                                action: { viewModel.toggleSpeaker() },
                                label: viewModel.callSettings.speakerOn ? "Disable Speaker" : "Speaker"
                            ) {
                                Image(
                                    systemName: viewModel.callSettings.speakerOn
                                        ? "speaker.wave.3.fill"
                                        : "speaker.fill"
                                )
                            }

                            DemoTranscriptionButtonView(viewModel: viewModel)

                            DemoMoreControlListButtonView(
                                action: { isStatsPresented = true },
                                label: "Stats"
                            ) { Image(systemName: "chart.xyaxis.line") }
                        }
                    }
                }
                .padding(.horizontal)
                .sheet(isPresented: $isStatsPresented) {
                    DemoStatsView(
                        viewModel: viewModel,
                        presentationBinding: $isStatsPresented
                    )
                }
            }
    }
}

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

struct DemoNoiseCancellationButtonView: View {

    @Injected(\.streamVideo) var streamVideo

    @ObservedObject var viewModel: CallViewModel
    @State var isNoiseCancellationAvailable = false
    @State var isActive: Bool = false

    init(viewModel: CallViewModel) {
        self.viewModel = viewModel
        if let mode = viewModel.call?.state.settings?.audio.noiseCancellation?.mode {
            isNoiseCancellationAvailable = mode != .disabled
        } else {
            isNoiseCancellationAvailable = false
        }
        isActive = streamVideo.videoConfig.noiseCancellationFilter?.id == streamVideo.videoConfig.audioProcessingModule
            .activeAudioFilter?.id
    }

    var body: some View {
        if let call = viewModel.call, let noiseCancellationAudioFilter = streamVideo.videoConfig.noiseCancellationFilter {
            Group {
                if isNoiseCancellationAvailable {
                    DemoMoreControlListButtonView(
                        action: {
                            if isActive {
                                call.setAudioFilter(nil)
                                isActive = false
                            } else {
                                call.setAudioFilter(noiseCancellationAudioFilter)
                                isActive = true
                            }
                        },
                        label: isActive ? "Disable Noise Cancellation" : "Noise Cancellation"
                    ) {
                        Image(
                            systemName: isActive
                                ? "waveform.path.ecg"
                                : "waveform.path"
                        )
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

extension View {

    @ViewBuilder
    func presentsMoreControls(viewModel: CallViewModel) -> some View {
        modifier(DemoMoreControlsViewModifier(viewModel: viewModel))
    }
}
