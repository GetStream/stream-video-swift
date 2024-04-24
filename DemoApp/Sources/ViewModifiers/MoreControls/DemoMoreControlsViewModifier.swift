//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
#if canImport(StreamVideoNoiseCancellation)
import StreamVideoNoiseCancellation
#endif

private struct DemoMoreControlsViewModifier: ViewModifier {

    @ObservedObject var appState: AppState = .shared
    @ObservedObject var viewModel: CallViewModel
    @Injected(\.snapshotTrigger) var snapshotTrigger
    @Injected(\.localParticipantSnapshotViewModel) var localParticipantSnapshotViewModel

    @State private var isStatsPresented = false
    @State private var isTranscribing = false

    init(viewModel: CallViewModel) {
        self.viewModel = viewModel
        isTranscribing = viewModel.call?.state.transcribing ?? false
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

                            #if canImport(StreamVideoNoiseCancellation)
                            if
                                viewModel.call?.currentUserHasCapability(.enableNoiseCancellation) == true,
                                let noiseCancellationFilter = viewModel.noiseCancellationAudioFilter {
                                DemoMoreControlListButtonView(
                                    action: {
                                        appState.audioFilter = appState.audioFilter?.id == noiseCancellationFilter.id
                                            ? nil
                                            : noiseCancellationFilter
                                    },
                                    label: appState.audioFilter?.id == "noise-cancellation"
                                        ? "Disable Noise Cancellation"
                                        : "Noise Cancellation"
                                ) {
                                    Image(
                                        systemName: appState.audioFilter?.id == "noise-cancellation"
                                            ? "circle.slash"
                                            : "waveform"
                                    )
                                }
                            }
                            #endif

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

                            DemoMoreControlListButtonView(
                                action: {
                                    Task {
                                        do {
                                            if isTranscribing {
                                                try await viewModel.call?.stopTranscriptions()
                                            } else {
                                                try await viewModel.call?.startTranscriptions()
                                            }
                                        } catch {
                                            log.error(error)
                                        }
                                    }
                                },
                                label: isTranscribing ? "Disable Transcriptions" : "Transcriptions"
                            ) {
                                Image(
                                    systemName: isTranscribing
                                        ? "captions.bubble.fill"
                                        : "captions.bubble"
                                )
                            }
                            .onReceive(viewModel.call?.state.$transcribing) { isTranscribing = $0 }

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

extension View {

    @ViewBuilder
    func presentsMoreControls(viewModel: CallViewModel) -> some View {
        modifier(DemoMoreControlsViewModifier(viewModel: viewModel))
    }
}
