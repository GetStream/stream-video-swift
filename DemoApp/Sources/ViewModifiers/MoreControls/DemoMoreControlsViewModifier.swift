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
                            ) { Image(systemName: "circle.inset.filled") }

                            DemoMoreControlListButtonView(
                                action: {
                                    if #available(iOS 16.0, *) {
                                        localParticipantSnapshotViewModel.captureVideoFrame()
                                    } else {
                                        localParticipantSnapshotViewModel.capturePhoto()
                                    }
                                },
                                label: "Capture Photo"
                            ) { Image(systemName: "person.crop.square.badge.camera") }

                            DemoMoreControlListButtonView(
                                action: {
                                    snapshotTrigger.capture()
                                },
                                label: "Snapshot"
                            ) { Image(systemName: "circle.inset.filled") }

                            DemoMoreControlListButtonView(
                                action: { viewModel.toggleSpeaker() },
                                label: viewModel.callSettings.speakerOn ? "Disable Speaker" : "Speaker"
                            ) { Image(
                                systemName: viewModel.callSettings.speakerOn
                                    ? "speaker.wave.3.fill"
                                    : "speaker.fill"
                            )
                            }

                            DemoMoreControlListButtonView(
                                action: {
                                    appState.audioFilter = appState.videoFilter == nil
                                        ? RobotVoiceFilter(pitchShift: 0.8)
                                        : nil
                                },
                                label: appState.audioFilter == nil
                                    ? "Robot Voice"
                                    : "Disable Robot Voice"
                            ) { Image(systemName: "waveform") }

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
