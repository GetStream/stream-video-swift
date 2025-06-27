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

    var viewModel: CallViewModel
    @ObservedObject var reactionsAdapter = InjectedValues[\.reactionsAdapter]
    var sessionTimer: SessionTimer

    @State var showTimerAlert = false
    @StateObject var snapshotViewModel: DemoSnapshotViewModel

    private let viewFactory: ViewFactory

    init(
        viewFactory: ViewFactory,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
        sessionTimer = .init(call: viewModel.call, alertInterval: 60)
        _snapshotViewModel = .init(wrappedValue: .init(viewModel))
        showTimerAlert = false
    }

    var body: some View {
        contentView
            .overlay(fireworksReactionView)
            .overlay(sessionTimerView)
            .presentsMoreControls(viewModel: viewModel)
            .chat(viewModel: viewModel, chatViewModel: chatViewModel)
            .toastView(toast: $snapshotViewModel.toast)
            .onReceive(sessionTimer.$showTimerAlert) { showTimerAlert = $0 }
    }

    @ViewBuilder
    var contentView: some View {
        CallView(viewFactory: viewFactory, viewModel: viewModel)
    }

    @ViewBuilder
    var fireworksReactionView: some View {
        if reactionsAdapter.showFireworks {
            FireworksView(
                config: FireworksConfig(intensity: .high, lifetime: .long, initialVelocity: .fast)
            )
        }
    }

    @ViewBuilder
    var sessionTimerView: some View {
        if showTimerAlert {
            DemoSessionTimerView(sessionTimer: sessionTimer)
        }
    }
}
