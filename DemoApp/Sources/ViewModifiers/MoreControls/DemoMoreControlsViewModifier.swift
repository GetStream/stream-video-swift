//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoMoreControlsViewModifier: ViewModifier {

    @ObservedObject var appState: AppState = .shared
    var viewModel: CallViewModel
    @Injected(\.snapshotTrigger) var snapshotTrigger
    @Injected(\.appearance) var appearance
    @Injected(\.localParticipantSnapshotViewModel) var localParticipantSnapshotViewModel

    @State private var isStatsPresented = false

    init(viewModel: CallViewModel) {
        self.viewModel = viewModel
        localParticipantSnapshotViewModel.call = viewModel.call
    }

    func body(content: Content) -> some View {
        PublisherSubscriptionView(
            initial: viewModel.moreControlsShown,
            publisher: viewModel.$moreControlsShown.eraseToAnyPublisher()
        ) { moreControlsShown in
            content
                .halfSheet(isPresented: .constant(moreControlsShown), onDismiss: { viewModel.moreControlsShown = false }) {
                    ScrollView(showsIndicators: false) {
                        primarySettingsView
                        secondarySettingsView
                        preReleaseSettingsView
                    }
                    .padding(.horizontal)
                }
        }
    }

    @ViewBuilder
    private var primarySettingsView: some View {
        VStack(spacing: 8) {
            DemoReactionSelectorView { viewModel.moreControlsShown = false }
            DemoRaiseHandToggleButtonView(viewModel: viewModel)
            if #available(iOS 15.0, *) {
                DemoBackgroundEffectSelector()
            }
        }
    }

    @ViewBuilder
    private var secondarySettingsView: some View {
        VStack {
            DemoNoiseCancellationButtonView(viewModel: viewModel)

            PublisherSubscriptionView(
                initial: viewModel.callSettings.speakerOn,
                publisher: viewModel.$callSettings.map(\.speakerOn).eraseToAnyPublisher()
            ) { speakerOn in
                DemoMoreControlListButtonView(
                    action: { viewModel.toggleSpeaker() },
                    label: speakerOn ? "Disable Speaker" : "Speaker"
                ) {
                    Image(
                        systemName: speakerOn
                            ? "speaker.wave.3.fill"
                            : "speaker.fill"
                    )
                }
            }

            DemoTranscriptionAndClosedCaptionsButtonView(viewModel: viewModel)

            DemoMoreThermalStateButtonView()

            DemoMoreControlListButtonView(
                action: { isStatsPresented = true },
                label: "Stats"
            ) { Image(systemName: "chart.xyaxis.line") }
                .sheet(isPresented: $isStatsPresented) {
                    DemoStatsView(
                        viewModel: viewModel,
                        presentationBinding: $isStatsPresented
                    )
                }
        }
    }

    @ViewBuilder
    private var preReleaseSettingsView: some View {
        if AppEnvironment.configuration != .release {
            VStack {
                Divider()

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
                DemoReconnectionButtonView { viewModel.moreControlsShown = false }
                #endif
            }
        }
    }
}

private struct DemoMoreLogsAndGleapButtonView: View {

    @Injected(\.gleap) private var gleap
    @Injected(\.appearance) private var appearance

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

private struct DemoMoreThermalStateButtonView: View {

    @Injected(\.thermalStateObserver) private var thermalStateObserver
    @Injected(\.colors) private var colors

    var body: some View {
        PublisherSubscriptionView(
            initial: thermalStateObserver.state,
            publisher: thermalStateObserver.statePublisher
        ) { thermalState in
            Button {} label: {
                Label(
                    title: { Text(text(for: thermalState)) },
                    icon: { icon(for: thermalState) }
                )
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            }
            .frame(height: 40)
            .buttonStyle(.borderless)
            .foregroundColor(colors.white)
            .background(background(for: thermalState))
            .clipShape(Capsule())
            .frame(maxWidth: .infinity)
            .disabled(true)
        }
    }

    private func text(for thermalState: ProcessInfo.ThermalState) -> String {
        switch thermalState {
        case .nominal:
            return "Nominal"
        case .fair:
            return "Fair"
        case .serious:
            return "Serious"
        case .critical:
            return "Critical"
        @unknown default:
            return "Unknown"
        }
    }

    @ViewBuilder
    private func icon(for thermalState: ProcessInfo.ThermalState) -> some View {
        switch thermalState {
        case .nominal:
            Image(systemName: "thermometer.low")
        case .fair:
            Image(systemName: "thermometer.medium")
        case .serious:
            Image(systemName: "thermometer.high")
        case .critical:
            Image(systemName: "flame")
        @unknown default:
            Image(systemName: "thermometer.medium.slash")
        }
    }

    @ViewBuilder
    private func background(for thermalState: ProcessInfo.ThermalState) -> some View {
        switch thermalState {
        case .nominal:
            Color.blue
        case .fair:
            Color.green
        case .serious:
            Color.orange
        case .critical:
            Color.red
        @unknown default:
            Color.clear
        }
    }
}
