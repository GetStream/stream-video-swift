//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import EffectsLibrary
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoCallView<ViewFactory: DemoAppViewFactory>: View {

    @Injected(\.appearance) var appearance
    @Injected(\.chatViewModel) var chatViewModel

    var microphoneChecker: MicrophoneChecker

    @ObservedObject var appState: AppState = .shared
    @ObservedObject var viewModel: CallViewModel
    @ObservedObject var reactionsAdapter = InjectedValues[\.reactionsAdapter]

    @State var mutedIndicatorShown = false
    @StateObject var snapshotViewModel: DemoSnapshotViewModel
    @StateObject var sessionTimer: SessionTimer
    
    private let viewFactory: ViewFactory

    init(
        viewFactory: ViewFactory,
        microphoneChecker: MicrophoneChecker,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.microphoneChecker = microphoneChecker
        self.viewModel = viewModel
        _snapshotViewModel = .init(wrappedValue: .init(viewModel))
        _sessionTimer = .init(wrappedValue: .init(call: viewModel.call, alertInterval: 60))
    }

    var body: some View {
        viewFactory
            .makeInnerCallView(viewModel: viewModel)
            .onReceive(microphoneChecker.decibelsPublisher, perform: { values in
                guard !viewModel.callSettings.audioOn else { return }
                for value in values {
                    if (value > -50 && value < 0) && !mutedIndicatorShown {
                        mutedIndicatorShown = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            mutedIndicatorShown = false
                        }
                        return
                    }
                }
            })
            .overlay(
                mutedIndicatorShown ?
                    VStack {
                        Spacer()
                        Text("You are muted.")
                            .padding(8)
                            .background(Color(UIColor.systemBackground))
                            .foregroundColor(appearance.colors.text)
                            .cornerRadius(16)
                            .padding()
                    }
                    : nil
            )
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
            .toastView(toast: $snapshotViewModel.toast)
    }
}
