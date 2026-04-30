//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import EffectsLibrary
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoCallView<ViewFactory: DemoAppViewFactory>: View {

    @Injected(\.chatViewModel) var chatViewModel

    @ObservedObject var appState: AppState = .shared
    @ObservedObject var viewModel: CallViewModel
    @ObservedObject var reactionsAdapter = InjectedValues[\.reactionsAdapter]

    @StateObject var sessionTimer: SessionTimer
    
    private let viewFactory: ViewFactory

    init(
        viewFactory: ViewFactory,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
        _sessionTimer = .init(wrappedValue: .init(call: viewModel.call, alertInterval: 60))
    }

    var body: some View {
        viewFactory
            .makeInnerCallView(viewModel: viewModel)
            .modifier(DemoSpeakingWhileMutedViewModifier(viewModel: viewModel))
            .overlay(
                ZStack {
                    reactionsAdapter.showFireworks
                        ? FireworksView(config: FireworksConfig(intensity: .high, lifetime: .long, initialVelocity: .fast))
                        : nil
                }
            )
            .overlay(
                sessionTimer.showTimerAlert ? DemoSessionTimerView(sessionTimer: sessionTimer) : nil
            )
            .presentsMoreControls(viewModel: viewModel)
            .chat(viewModel: viewModel, chatViewModel: chatViewModel)
            .modifier(DemoSnapshotContainerViewModifier(viewModel))
    }
}
