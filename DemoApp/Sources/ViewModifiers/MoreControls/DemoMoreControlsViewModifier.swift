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

    @State private var isStatsPresented = false

    fileprivate func body(content: Content) -> some View {
        content
            .halfSheet(isPresented: $viewModel.moreControlsShown) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        VStack(spacing: 8) {
                            DemoReactionSelectorView { viewModel.moreControlsShown = false }
                            DemoRaiseHandToggleButtonView(viewModel: viewModel)
                        }

                        VStack {
                            DemoMoreControlListButtonView(
                                action: {
                                    snapshotTrigger.capture()
                                },
                                label: "Capture snapshot"
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
                                    if appState.audioFilter == nil {
                                        appState.audioFilter = RobotVoiceFilter(pitchShift: 0.8)
                                    } else {
                                        appState.audioFilter = nil
                                    }
                                },
                                label: appState.audioFilter == nil ? "Robot Voice" : "Disable Robot Voice"
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
