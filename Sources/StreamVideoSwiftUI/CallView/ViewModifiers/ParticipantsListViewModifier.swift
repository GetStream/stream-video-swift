//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

struct PresentParticipantListViewModifier<Factory: ViewFactory>: ViewModifier {
    var viewFactory: Factory
    var viewModel: CallViewModel
    @State var isPresenting: Bool

    init(
        viewFactory: Factory,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
        isPresenting = viewModel.participantsShown
    }

    func body(content: Content) -> some View {
        content
            .halfSheet(isPresented: $isPresenting, onDismiss: { viewModel.participantsShown = false }) {
                viewFactory.makeParticipantsListView(viewModel: viewModel)
                    .opacity(viewModel.hideUIElements ? 0 : 1)
                    .accessibility(identifier: "trailingTopView")
            }
            .onReceive(viewModel.$participantsShown.removeDuplicates()) { isPresenting = $0 }
    }
}

extension View {

    /// Will use the provided Binding to present the Participants List.
    @ViewBuilder
    @MainActor
    public func presentParticipantListView<Factory: ViewFactory>(
        viewModel: CallViewModel,
        viewFactory: Factory = DefaultViewFactory.shared
    ) -> some View {
        modifier(
            PresentParticipantListViewModifier(
                viewFactory: viewFactory,
                viewModel: viewModel
            )
        )
    }
}
