//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoMoreControlsViewModifier: ViewModifier {

    @ObservedObject var appState: AppState = .shared
    @ObservedObject var viewModel: CallViewModel
    @Injected(\.snapshotTrigger) var snapshotTrigger
    @Injected(\.appearance) var appearance
    @Injected(\.localParticipantSnapshotViewModel) var localParticipantSnapshotViewModel

    @State private var isStatsPresented = false

    init(viewModel: CallViewModel) {
        self.viewModel = viewModel
        localParticipantSnapshotViewModel.call = viewModel.call
    }

    func body(content: Content) -> some View {
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
                            DemoNoiseCancellationButtonView(viewModel: viewModel)

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

                            DemoTranscriptionAndClosedCaptionsButtonView(viewModel: viewModel)

                            DemoMoreControlListButtonView(
                                action: { isStatsPresented = true },
                                label: "Stats"
                            ) { Image(systemName: "chart.xyaxis.line") }
                        }

                        if AppEnvironment.configuration != .release {
                            VStack {
                                Divider()

                                DemoBroadcastMoreControlsListButtonView(
                                    viewModel: viewModel,
                                    preferredExtension: "io.getstream.iOS.VideoDemoApp.ScreenSharing"
                                )

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

                                DemoManualQualitySelectionButtonView(
                                    call: viewModel.call
                                ) { viewModel.moreControlsShown = false }

                                #if OBSERVE_RECONNECTION_NOTIFICATIONS
                                if AppEnvironment.configuration != .release {
                                    DemoReconnectionButtonView { viewModel.moreControlsShown = false }
                                }
                                #endif
                            }
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
