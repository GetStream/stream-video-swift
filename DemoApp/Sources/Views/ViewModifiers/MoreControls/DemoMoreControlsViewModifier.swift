//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideoSwiftUI

fileprivate struct DemoMoreControlsViewModifier: ViewModifier {

    @ObservedObject var appState: AppState = .shared
    @ObservedObject var viewModel: CallViewModel

    fileprivate func body(content: Content) -> some View {
        content
            .halfSheet(isPresented: $viewModel.moreControlsShown) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        VStack {
                            DemoReactionSelectorView()
                            DemoRaiseHandToggleButtonView(viewModel: viewModel)
                        }

                        VStack {
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
                        }
                    }
                }
                .padding(.horizontal)
            }
    }
}

extension View {

    @ViewBuilder
    func presentsMoreControls(viewModel: CallViewModel) -> some View {
        modifier(DemoMoreControlsViewModifier(viewModel: viewModel))
    }
}
