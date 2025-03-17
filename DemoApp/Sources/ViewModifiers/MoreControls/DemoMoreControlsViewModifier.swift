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

import ReplayKit

struct DemoBroadcastMoreControlsListButtonView: View {
    @Injected(\.appearance) private var appearance

    @State private var selection: ScreensharingType = .inApp

    @ObservedObject var viewModel: CallViewModel
    let preferredExtension: String
    @StateObject private var broadcastObserver = BroadcastObserver()

    var body: some View {
        HStack {
            inAppScreenshareButtonView

            broadcastButtonView
        }
    }

    @ViewBuilder
    private var inAppScreenshareButtonView: some View {
        DemoMoreControlListButtonView(
            action: {
                if !isCurrentUserScreenSharing {
                    viewModel.startScreensharing(type: .inApp)
                    selection = .inApp
                } else {
                    viewModel.stopScreensharing()
                }
            },
            label: selection == .inApp && isCurrentUserScreenSharing
                ? "Stop Screensharing"
                : "Screenshare",
            disabled: isInAppDisabled
        ) {
            Image(systemName: "record.circle")
                .foregroundColor(
                    isCurrentUserScreenSharing && selection == .inApp
                        ? appearance.colors.accentRed
                        : appearance.colors.text
                )
        }
        .disabled(isInAppDisabled)
        .opacity(isInAppDisabled ? 0.75 : 1)
    }

    @ViewBuilder
    private var broadcastButtonView: some View {
        ZStack {
            BroadcastPickerView(
                preferredExtension: preferredExtension,
                size: 44
            )
            .opacity(0.1)
            DemoMoreControlListButtonView(
                action: { /* No-op */ },
                label: selection == .broadcast && isCurrentUserScreenSharing
                    ? "Stop Broadcasting"
                    : "Broadcast",
                disabled: isBroadcastDisabled
            ) {
                Image(systemName: "record.circle")
                    .foregroundColor(
                        isCurrentUserScreenSharing && selection == .broadcast
                            ? appearance.colors.accentRed
                            : appearance.colors.text
                    )
            }
            .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onChange(of: broadcastObserver.broadcastState, perform: { newValue in
            if newValue == .started {
                selection = .broadcast
                viewModel.startScreensharing(type: .broadcast)
            } else if newValue == .finished {
                viewModel.stopScreensharing()
                broadcastObserver.broadcastState = .notStarted
            }
        })
        .disabled(isBroadcastDisabled)
        .onAppear { broadcastObserver.observe() }
        .opacity(isBroadcastDisabled ? 0.75 : 1)
    }

    private var isCurrentUserScreenSharing: Bool {
        viewModel.call?.state.isCurrentUserScreensharing == true
    }

    private var isDisabled: Bool {
        guard viewModel.call?.state.screenSharingSession != nil else {
            return false
        }
        return viewModel.call?.state.isCurrentUserScreensharing == false
    }

    private var isInAppDisabled: Bool {
        isDisabled || (isCurrentUserScreenSharing && selection != .inApp)
    }

    private var isBroadcastDisabled: Bool {
        isDisabled || (isCurrentUserScreenSharing && selection != .broadcast)
    }
}
