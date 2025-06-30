//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import SwiftUI

struct PresentParticipantListViewModifier<Factory: ViewFactory>: ViewModifier {

    var viewFactory: Factory
    var viewModel: CallViewModel
    var publisher: AnyPublisher<Bool, Never>

    @State var participantsShown: Bool

    init(
        viewFactory: Factory,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
        publisher = viewModel
            .$participantsShown
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        participantsShown = viewModel.participantsShown
    }

    func body(content: Content) -> some View {
        content
            .halfSheet(isPresented: $participantsShown, onDismiss: { viewModel.participantsShown = false }) { contentView }
            .onReceive(publisher) { participantsShown = $0 }
    }

    @ViewBuilder
    var contentView: some View {
        viewFactory.makeParticipantsListView(viewModel: viewModel)
    }
}

extension View {

    /// Will use the provided Binding to present the Participants List.
    @ViewBuilder
    public func presentParticipantListView<Factory: ViewFactory>(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel
    ) -> some View {
        modifier(
            PresentParticipantListViewModifier(
                viewFactory: viewFactory,
                viewModel: viewModel
            )
        )
    }
}
