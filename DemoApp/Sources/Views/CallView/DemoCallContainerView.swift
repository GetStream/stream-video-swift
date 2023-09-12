//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI
import Intents

internal struct DemoCallContainerView: View {

    private var callId: String
    @Injected(\.streamVideo) var streamVideo
    @Injected(\.appearance) var appearance
    @StateObject var viewModel: CallViewModel
    @ObservedObject var appState = AppState.shared

    internal init(callId: String) {
        _viewModel = StateObject(wrappedValue: CallViewModel())
        self.callId = callId
    }

    internal var body: some View {
        DemoCallContentView(viewModel: viewModel, callId: callId)
            .modifier(
                DemoCallModifier(
                    viewFactory: DemoAppViewFactory.shared,
                    viewModel: viewModel,
                    chatViewModel: .init(viewModel)
                )
            )
            .onContinueUserActivity(
                NSStringFromClass(INStartCallIntent.self),
                perform: didContinueUserActivity(_:)
            )
    }

    private func didContinueUserActivity(_ userActivity: NSUserActivity) {
        let interaction = userActivity.interaction
        if let callIntent = interaction?.intent as? INStartCallIntent {

            let contact = callIntent.contacts?.first

            guard let name = contact?.personHandle?.value else { return }
            viewModel.startCall(callType: .default, callId: .unique, members: [.init(userId: name)], ring: true)
        }
    }
}
