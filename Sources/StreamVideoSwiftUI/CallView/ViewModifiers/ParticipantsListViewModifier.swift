//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

extension View {

    /// Will use the provided Binding to present the Participants List.
    @ViewBuilder
    @MainActor
    public func presentParticipantListView<Factory: ViewFactory>(
        @ObservedObject viewModel: CallViewModel,
        viewFactory: Factory = DefaultViewFactory.shared
    ) -> some View {
        halfSheet(isPresented: $viewModel.participantsShown) {
            viewFactory.makeParticipantsListView(viewModel: viewModel)
                .opacity(viewModel.hideUIElements ? 0 : 1)
                .accessibility(identifier: "trailingTopView")
        }
    }
}
