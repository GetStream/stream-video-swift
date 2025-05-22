//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

extension View {

    /// Will use the provided Binding to present the Participants List.
    @ViewBuilder
    @MainActor
    public func presentParticipantListView(
        @ObservedObject viewModel: CallViewModel,
        viewFactory: some ViewFactory = DefaultViewFactory.shared
    ) -> some View {
        halfSheet(isPresented: $viewModel.participantsShown) {
            viewFactory.makeParticipantsListView(viewModel: viewModel)
                .opacity(viewModel.hideUIElements ? 0 : 1)
                .accessibility(identifier: "trailingTopView")
        }
    }
}
