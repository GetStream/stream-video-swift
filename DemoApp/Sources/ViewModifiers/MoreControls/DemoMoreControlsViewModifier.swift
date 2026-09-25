//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoMoreControlsViewModifier: ViewModifier {

    @ObservedObject var appState: AppState = .shared
    @ObservedObject var viewModel: CallViewModel
    @Injected(\.snapshotTrigger) var snapshotTrigger
    @Injected(\.videoAppearance) private var videoAppearance
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
                        if #available(iOS 15.0, *) { return tokens.layout.spacingXs }
                        else { return tokens.layout.spacing2xl }
                    }()) {
                        VStack(spacing: tokens.layout.spacingXs) {
                            VStack(spacing: tokens.layout.spacingXs) {
                                DemoReactionSelectorView { viewModel.moreControlsShown = false }
                                DemoRaiseHandToggleButtonView(viewModel: viewModel)
                            }
                            .padding(.horizontal, tokens.layout.spacingMd)

                            if #available(iOS 15.0, *) {
                                DemoBackgroundEffectSelector()
                                    .padding(.top, tokens.layout.spacingMd)
                            }
                        }

                        VStack(spacing: tokens.layout.spacingXs) {
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

                            DemoMoreControlListButtonView(
                                action: { viewModel.toggleAudioOutput() },
                                label: viewModel.callSettings.audioOutputOn ? "Disable audio output" : "Enable audio output"
                            ) {
                                Image(
                                    systemName: viewModel.callSettings.audioOutputOn
                                        ? "speaker.fill"
                                        : "speaker.slash"
                                )
                            }

                            DemoTranscriptionAndClosedCaptionsButtonView(viewModel: viewModel)

                            DemoMoreThermalStateButtonView()

                            DemoMoreControlListButtonView(
                                action: { isStatsPresented = true },
                                label: "Stats"
                            ) { Image(systemName: "chart.xyaxis.line") }
                        }
                        .padding(.horizontal, tokens.layout.spacingMd)

                        if AppEnvironment.configuration != .release {
                            VStack(spacing: tokens.layout.spacingXs) {
                                Divider()

                                DemoAudioTrackButtonView()

                                DemoMusicModeButtonView(viewModel: viewModel)

                                DemoMoreLogsAndGleapButtonView()

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

                                DemoStartRecordingButtonView(
                                    viewModel: viewModel
                                ) { viewModel.moreControlsShown = false }
                            }
                            .padding(.horizontal, tokens.layout.spacingMd)
                        }
                    }
                }
                .background(Color(tokens.colors.backgroundCoreElevation1))
                .sheet(isPresented: $isStatsPresented) {
                    DemoStatsView(
                        viewModel: viewModel,
                        presentationBinding: $isStatsPresented
                    )
                }
            }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

private struct DemoMoreLogsAndGleapButtonView: View {

    @Injected(\.gleap) private var gleap

    @State private var areLogsPresented = false
    @State private var activeLogsTask: Task<Void, Error>?

    var body: some View {
        HStack {
            gleapButtonView
            logsViewButtonView
        }
    }

    private var gleapButtonView: some View {
        DemoMoreControlListButtonView(
            action: {
                activeLogsTask?.cancel()
                activeLogsTask = Task { @MainActor in
                    let logURL = try LogQueue.createLogFile()
                    gleap.showBugReport(with: logURL)
                }
            },
            label: "Report a bug"
        ) {
            Image(systemName: "ladybug.fill")
        }
    }

    private var logsViewButtonView: some View {
        DemoMoreControlListButtonView(
            action: { areLogsPresented = true },
            label: "Logs Viewer"
        ) {
            Image(systemName: "text.page")
        }.sheet(isPresented: $areLogsPresented) {
            NavigationView {
                MemoryLogViewer()
            }
        }
    }
}
