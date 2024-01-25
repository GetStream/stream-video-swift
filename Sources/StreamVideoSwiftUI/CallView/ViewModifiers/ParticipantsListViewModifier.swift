//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo

extension View {

    /// Will use the provided Binding to present the Participants List.
    @ViewBuilder
    @MainActor
    public func presentParticipantListView<Factory: ViewFactory>(
        @ObservedObject viewModel: CallViewModel,
        viewFactory: Factory
    ) -> some View {
        self.halfSheet(isPresented: $viewModel.participantsShown) {
            viewFactory.makeParticipantsListView(viewModel: viewModel)
            .opacity(viewModel.hideUIElements ? 0 : 1)
            .accessibility(identifier: "trailingTopView")
        }
    }
}
