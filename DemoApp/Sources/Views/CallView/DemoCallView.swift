//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import EffectsLibrary
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoCallView<ViewFactory: DemoAppViewFactory>: View {

    @Injected(\.appearance) var appearance
    @Injected(\.chatViewModel) var chatViewModel

    var microphoneChecker: MicrophoneChecker

    var viewModel: CallViewModel

    @State var mutedIndicatorShown = false
    @State var showFireworks = false
    @StateObject var snapshotViewModel: DemoSnapshotViewModel
    
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
    }

    var body: some View {
        CallView(viewFactory: viewFactory, viewModel: viewModel)
            .overlay(FireworksReactionView())
            .overlay(SessionTimerView(call: viewModel.call))
            .presentsMoreControls(viewModel: viewModel)
            .chat(chatViewModel: chatViewModel)
            .toastView(toast: $snapshotViewModel.toast)
    }
}

struct FireworksReactionView: View {
    @ObservedObject var reactionsAdapter = InjectedValues[\.reactionsAdapter]

    var body: some View {
        if reactionsAdapter.showFireworks {
            FireworksView(config: FireworksConfig(intensity: .high, lifetime: .long, initialVelocity: .fast))
        }
    }
}

struct SessionTimerView: View {
    @StateObject var sessionTimer: SessionTimer

    init(call: Call?, alertInterval: TimeInterval = 60) {
        _sessionTimer = .init(
            wrappedValue: .init(
                call: call,
                alertInterval: alertInterval
            )
        )
    }

    var body: some View {
        if sessionTimer.showTimerAlert {
            DemoSessionTimerView(sessionTimer: sessionTimer)
        }
    }
}
