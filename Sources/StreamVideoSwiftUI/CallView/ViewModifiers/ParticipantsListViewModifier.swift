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
    public func presentParticipantListView<Factory: ViewFactory>(
        viewModel: CallViewModel,
        viewFactory: Factory = DefaultViewFactory.shared
    ) -> some View {
        PublisherSubscriptionView(
            initial: viewModel.participantsShown,
            publisher: viewModel.$participantsShown.eraseToAnyPublisher()
        ) { participantsShown in
            halfSheet(
                isPresented: .constant(participantsShown),
                onDismiss: { viewModel.participantsShown = false
                }
            ) {
                viewFactory.makeParticipantsListView(viewModel: viewModel)
                    .opacity(viewModel.hideUIElements ? 0 : 1)
                    .accessibility(identifier: "trailingTopView")
            }
        }
    }
}
